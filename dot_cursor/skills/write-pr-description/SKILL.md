---
name: write-pr-description
description: Use when asked to "write a PR", "create a PR", "push and PR", after pushing a branch, or when preparing to run gh pr create
---

# Write PR Description

Generate a PR description from branch changes.

## When to Use

**ALWAYS invoke this skill when you hear:**

- "write a PR" / "write the PR" / "PR description"
- "create a PR" / "open a PR" / "make a PR"
- "push and PR" / "push and create PR"
- After `git push` when user mentions PR in same message
- Before running `gh pr create`

**Even if:**

- You think you already know how to write the PR
- The changes seem simple
- You already read the diff

**Why:** This skill ensures consistent PR format and copies to clipboard. Skipping it means inconsistent output and extra steps for the user.

## Workflow

1. **Gather changes**

If it looks like the user is using the Jujutsu source control tool then instead of the git commands use.

```bash
  jj status # Find the bookmark(branch) which is usually found just before the | on the line starting with Working copy
  jj diff -r '(ancestors(@) | descendants(@)) ~ immutable()' # changes from mainline
```

You can tell if somebody is using jujutsu by running `which jj` if an executable is found and running `jj root` does not return an error they are using jj. The default should be to use the git commands below.

```bash
git diff origin/main...HEAD      # committed changes on branch
git diff --cached                # staged changes
```

2. **Extract JIRA ticket**
   - Parse branch name for pattern `[A-Z]+-\d+` (e.g., RNDCORE-12345)
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
     - Otherwise: use `https://internal.guideline.tools/jira/browse/TICKET`

3. **Analyze changes** - understand what changed, why, and who it impacts

4. **Output ONLY this format:**

```
[[[
**jira:** [TICKET-123](https://internal.guideline.tools/jira/browse/TICKET-123)
**what:** concise summary of changes
**why:** business justification
**who:** affected users/teams
]]]
```

5. **Copy to clipboard (macOS)**

   After generating the PR description, automatically copy it to the clipboard:

   ```bash
   cat <<'EOF' | pbcopy
   [[[
   **jira:** [TICKET-123](https://internal.guideline.tools/jira/browse/TICKET-123)
   **what:** concise summary of changes
   **why:** business justification
   **who:** affected users/teams
   ]]]
   EOF
   ```

   Then confirm: "PR description copied to clipboard!"

## Output Rules

**DO:**

- When asked to create a PR description:
  - Output ONLY the `[[[...]]]` block
  - Wrap output in a code fence (```) so the raw markdown is copyable
  - Automatically copy the PR description to clipboard using `pbcopy` (macOS)
- When asked to create a PR:
  - Use the generated `[[[...]]]` block to fill the placeholder in the PR template (`.github/PULL_REQUEST_TEMPLATE.md`)
- Don't add any indentation to any of the text within the `[[[...]]]` block
- Put `[[[` on its own line before the first content line
- Put `]]]` on its own line after the last content line
- Keep what/why/who concise (1-2 sentences each)
- Use specific language, not vague descriptions
- Use backticks for code references (class names, methods, files, etc.) e.g. `TenantTransferPacket`
- Only use bullet points for "what" if there are multiple distinct changes; for simple PRs, use plain text

**DO NOT:**

- Add agent preamble or headers
- Add bullet lists or expanded details after the block

## Examples

### Simple change (no bullets needed)

For branch `RNDCORE-11727-fix-tenant-packet` with a single focused change:

```
[[[
**jira:** [RNDCORE-11727](https://internal.guideline.tools/jira/browse/RNDCORE-11727)
**what:** Fix null pointer in `TenantTransferPacket#process` when user has no address
**why:** Users without addresses were causing 500 errors during transfer
**who:** Participants transferring accounts
]]]
```

### Multiple changes (use bullets)

For branch `RNDCORE-11728-refactor-billing` with multiple distinct changes:

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

### RETIRE branch

For branch `RETIRE-456-cleanup-legacy-code`:

```
[[[
**jira:** [RETIRE-456](https://gustohq.atlassian.net/browse/RETIRE-456)
**what:** Remove unused `OldAuthenticator` class and related specs
**why:** Dead code cleanup after migration to new auth system
**who:** No user impact, internal cleanup
]]]
```

## Edge Cases

| Situation                 | Action                                                 |
| ------------------------- | ------------------------------------------------------ |
| No JIRA in branch         | Ask user, allow "skip" for placeholder                 |
| No changes found          | Warn: "No staged or committed changes found"           |
| Large diff (100+ files)   | Summarize at directory/subsystem level                 |
| Base branch not main      | Ask user for base branch                               |
| Branch starts with RETIRE | Use Atlassian link: `gustohq.atlassian.net/browse/...` |
