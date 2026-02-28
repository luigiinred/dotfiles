---
name: dev-workflow-create-pr
description: Create a GitHub pull request using the gh CLI. Analyzes all changes from main, generates a description following the PR template, and creates the PR if one doesn't exist. Reads .project-settings.md to determine whether the project uses Jira or GitHub Issues. Use when the user asks to create a PR, open a pull request, or submit changes for review.
---

# Create Pull Request

Create a GitHub pull request with an auto-generated description that follows the PR template.

## Prerequisites

- GitHub CLI installed and authenticated (`gh auth status`)
- Changes committed and pushed to remote
- Current branch is not `main` or `master`

## Workflow

### Step 1: Check for Existing PR

```bash
gh pr view --json number,url 2>/dev/null
```

**If PR exists**: Report the existing PR URL and ask if the user wants to update the description.

### Step 2: Get Current Branch and Verify Remote

```bash
git branch --show-current
git status
```

**If branch is `main` or `master`**: STOP and warn the user.

**If changes are not pushed**: Push first:

```bash
git push -u origin HEAD
```

### Step 3: Resolve Project Settings

Determine whether this project uses Jira or GitHub Issues by reading `.project-settings.md`. Follow the same lookup order as `dev-workflow-initialize`:

1. **Project root:** `<workspace-root>/.project-settings.md` — if it exists, use it.
2. **User home:** `~/.project-settings.md` — if it exists and the current workspace directory name appears in the Workspaces table, use it.
3. **Not found:** Default to `github` target (use current repo from `git remote get-url origin`).

Extract from the matching project block:

| Field | Used for |
|-------|----------|
| **Target** | `github` or `jira` — determines ticket system |
| **Repo** (GitHub) | GitHub repo for links (default: current repo) |
| **Project Key** (Jira) | Jira project key for ticket prefixes |
| **JIRA base URL** (Jira) | For constructing ticket links |

### Step 4: Determine Base Branch and Analyze Changes

The branch may have been created from `main` or from another feature branch. Determine the correct base branch:

```bash
# Option 1: Check git log for branch refs - other branch names appear in parentheses
# Example output: "8e6b394a (RNDCORE-12097) fix: update test"
# This indicates the branch was forked from RNDCORE-12097
git log --oneline --decorate HEAD | head -20

# Option 2: Check if there's an upstream tracking branch or PR target
gh pr view --json baseRefName --jq '.baseRefName' 2>/dev/null

# Option 3: Find the merge-base with main (may include unrelated commits if branch is stale)
git merge-base main HEAD
```

**Important:** Look for branch names in parentheses in the git log output. If you see a pattern like:

```
cd9c4c18 (HEAD -> RNDCORE-12097-suspense) refactor: migrate queries
8e6b394a (RNDCORE-12097) fix: update test
```

This means `RNDCORE-12097-suspense` was branched from `RNDCORE-12097`. The base branch is `RNDCORE-12097`, NOT main.

Once base branch is identified, run these commands:

```bash
# If parent branch is detected (e.g., RNDCORE-12097)
git diff PARENT_BRANCH..HEAD --stat
git log PARENT_BRANCH..HEAD --oneline
git diff PARENT_BRANCH..HEAD

# Example:
git diff RNDCORE-12097..HEAD --stat
```

**Fallback:** If no parent branch is detected in the log, use main:

```bash
git diff main...HEAD
git log main..HEAD --oneline
git diff main...HEAD --stat
```

### Step 5: Generate PR Description

Generate the PR description directly from the diff gathered in Step 4.

**5a. Extract ticket/issue reference** based on the target system from Step 3.

#### If target is `jira`:

Extract Jira ticket from the branch name using pattern `[A-Z]+-\d+` (e.g., RNDCORE-12345).

- If not found, **ALWAYS use the AskQuestion tool:**
  - Title: "JIRA Ticket"
  - Question: "What's the JIRA ticket for this PR?"
  - Options:
    - id: "specify", label: "Let me specify the ticket"
    - id: "skip", label: "Skip (use placeholder)"
  - If "specify": Ask conversationally for the ticket
  - If "skip": use `RND***-xxxx`

- **Link format:**
  - If branch starts with `RETIRE`: use `https://gustohq.atlassian.net/browse/TICKET`
  - Otherwise: use the JIRA base URL from project settings, or `https://internal.guideline.tools/jira/browse/TICKET`

#### If target is `github`:

Extract GitHub issue number from the branch name using pattern `^(\d+)-` (e.g., `5-add-widget-background` → `#5`).

- If not found, **ALWAYS use the AskQuestion tool:**
  - Title: "GitHub Issue"
  - Question: "Is there a GitHub issue for this PR?"
  - Options:
    - id: "specify", label: "Let me specify the issue number"
    - id: "skip", label: "No issue — skip"
  - If "specify": Ask conversationally for the issue number
  - If "skip": omit the issue/ticket line from the description entirely

- **Link format:** `https://github.com/OWNER/REPO/issues/NUMBER` (or use `Closes #N` shorthand)

**5b. Analyze changes** from the diff — understand what changed, why, and who it impacts.

**5c. Generate the `[[[...]]]` block:**

The block format depends on the target system:

**Jira projects:**

```
[[[
**jira:** [TICKET-123](https://internal.guideline.tools/jira/browse/TICKET-123)
**what:** concise summary of changes
**why:** business justification
**who:** affected users/teams
]]]
```

**GitHub projects (with issue):**

```
[[[
**issue:** #42
**what:** concise summary of changes
**why:** business justification
**who:** affected users/teams
]]]
```

**GitHub projects (no issue) or unticketed:**

```
[[[
**what:** concise summary of changes
**why:** business justification
**who:** affected users/teams
]]]
```

**Description rules:**

- Put `[[[` and `]]]` on their own lines
- Keep what/why/who concise (1-2 sentences each)
- Use backticks for code references (class names, methods, files)
- Only use bullet points for "what" if there are multiple distinct changes
- No indentation inside the block
- No agent preamble or headers outside the block

**Examples:**

Simple Jira change (no bullets):

```
[[[
**jira:** [RNDCORE-11727](https://internal.guideline.tools/jira/browse/RNDCORE-11727)
**what:** Fix null pointer in `TenantTransferPacket#process` when user has no address
**why:** Users without addresses were causing 500 errors during transfer
**who:** Participants transferring accounts
]]]
```

Multiple Jira changes (use bullets):

```
[[[
**jira:** [RNDCORE-11728](https://internal.guideline.tools/jira/browse/RNDCORE-11728)
**what:**
- Add `BillingCalculator` service to handle fee computations
- Update `Invoice#generate` to use new calculator
- Remove deprecated `LegacyBilling` module

**why:** Legacy billing code was unmaintainable and causing calculation errors
**who:** Internal billing team, sponsors receiving invoices
]]]
```

RETIRE branch (Jira):

```
[[[
**jira:** [RETIRE-456](https://gustohq.atlassian.net/browse/RETIRE-456)
**what:** Remove unused `OldAuthenticator` class and related specs
**why:** Dead code cleanup after migration to new auth system
**who:** No user impact, internal cleanup
]]]
```

GitHub issue:

```
[[[
**issue:** #5
**what:** Add widget background style setting with none, solid, and glass options
**why:** Widgets are hard to read over busy slideshow images
**who:** Users with widget overlays on their display
]]]
```

Unticketed (GitHub or no settings):

```
[[[
**what:** Refactor drag gesture to use named coordinate space
**why:** Fixes Retina scale mismatch on macOS
**who:** macOS users dragging widgets
]]]
```

### Step 6: Create the PR

The PR body must include the `[[[...]]]` block and a screenshot placeholder.

```bash
gh pr create --draft --title "<type>: <ticket-ref> <short description>" --body "$(cat <<'EOF'
<[[[...]]] block from Step 5>

---

### Screenshot(s):
_No visual changes_

EOF
)"
```

**Title format:** Use conventional commit style. Include the ticket/issue reference when available — this is critical because release notes are generated from PR titles.

Format: `<type>: <ticket-ref> <short description>`

Jira examples:
- `feat: RETIRE-456 add portfolio rebalance alerts`
- `fix: RNDCORE-12337 handle null dynamic type in C++ bridge`

GitHub issue examples:
- `feat: #5 add widget background style setting`
- `fix: #12 handle nil placement on resize`

No ticket/issue:
- `feat: add widget background style setting`
- `refactor: migrate drag gesture to coordinate space`

Type prefixes:

- `feat:` for new features
- `fix:` for bug fixes
- `refactor:` for code restructuring
- `chore:` for maintenance

### Step 7: Report Success

Get the PR URL and format it as a clickable markdown link:

```bash
PR_URL=$(gh pr view --json url --jq '.url')
```

Then output a message with the URL as a clickable markdown link:

```
Draft PR created successfully! 🎉

[View Draft PR #<number>]($PR_URL)
```

Example output: "Draft PR created successfully! 🎉\n\n[View Draft PR #2640](https://github.com/guideline-app/mobile-app/pull/2640)"

### Step 8: Offer to Start Review

After reporting the clickable PR URL, **ALWAYS use the AskQuestion tool:**

- Title: "Start PR Review?"
- Question: "Would you like me to review the PR for code quality, security, and best practices?"
- Options:
  - id: "review", label: "Yes, review it"
  - id: "done", label: "No, I'm done"

Based on the response:

- "review" → Use the `dev-workflow-review-pr` skill to perform a comprehensive code review
- "done" → End the workflow

## Checklist

```
PR Creation Progress:
- [ ] Verified no existing PR
- [ ] Confirmed changes are pushed
- [ ] Resolved project settings (Jira vs GitHub vs none)
- [ ] Determined correct base branch (may not be main)
- [ ] Analyzed diff from base branch
- [ ] Generated PR description with [[[...]]] block
- [ ] Created draft PR with gh CLI
- [ ] Reported PR URL as clickable markdown link
- [ ] Offered to start PR review
```

## Edge Cases

### No `.project-settings.md` found

Default to `github` target. Use the current repo from `git remote get-url origin`. Do NOT prompt to create project settings during PR creation — just use the default and move on.

### Branch has no ticket/issue

For Jira: use `N/A` or ask the user for the ticket ID.
For GitHub: omit the issue line and proceed without it.

### Branch created from another feature branch (not main)

When a branch is created from another feature branch:

1. Run `git log --oneline --decorate HEAD` and look for branch names in parentheses
2. If you see `(PARENT-BRANCH-NAME)` on a commit that isn't HEAD, that's the parent branch
3. Diff against that branch name directly

Example:

```bash
# Git log shows:
# cd9c4c18 (HEAD -> RNDCORE-12097-suspense) refactor: migrate queries
# 8e6b394a (RNDCORE-12097) fix: update test
#
# The parent branch is RNDCORE-12097

git diff RNDCORE-12097..HEAD --stat  # Shows only this branch's changes
git log RNDCORE-12097..HEAD --oneline  # Shows only this branch's commits
```

This ensures the PR description only reflects changes in THIS branch, not inherited changes from the parent branch.

### Large diff (>1000 lines)

Focus summary on high-level changes. Group by feature area or file type.

### No commits ahead of main

STOP - nothing to create a PR for. Inform the user.

### Branch is stale (main has diverged significantly)

The diff against main may include many unrelated changes. Identify the actual fork point:

```bash
git merge-base main HEAD
```

And consider if the branch needs to be rebased before creating the PR.

## Notes

- Always push changes before creating PR
- Review the generated description for accuracy before the PR is created
- For visual changes, remind the user to add screenshots after PR creation
