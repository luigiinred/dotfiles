---
name: dev-workflow-initialize
description: Start working on a ticket/issue by fetching details and creating a git branch in a new worktree. Reads .publish-settings.md to determine target (Jira or GitHub). Use when the user wants to start a ticket, begin work on an issue, or create a branch for a task. For unticketed work, asks for a short description to build the branch name.
---

# Start Ticket

Start working on a ticket or issue by fetching its details and creating a feature branch in a new worktree based on origin/main. Reads `.publish-settings.md` to determine whether the project uses Jira or GitHub Issues.

## Workflow

### Step 1: Resolve Publish Settings

Read `.publish-settings.md` to determine the target system. Follow the lookup order from the `publish-settings.mdc` rule:

1. **Project root:** `<workspace-root>/.publish-settings.md` — if it exists, use it.
2. **User home:** `~/.publish-settings.md` — if it exists and the current workspace directory name appears in the Workspaces table, use it.
3. **Not found:** Default to `github` and use the current repo (from `git remote get-url origin`).

Extract from the matching project block:

| Field | Used for |
|-------|----------|
| **Target** | `github` or `jira` — determines ticket system |
| **Repo** (GitHub) | GitHub repo for `gh` commands (default: current repo) |
| **Project Key** (Jira) | Jira project key for ticket prefixes and fetching |
| **JIRA base URL** (Jira) | For constructing ticket links |

### Step 2: Get Ticket Number

If the user hasn't provided a ticket number, **ALWAYS use the AskQuestion tool.**

**If target is `github`:**

- Title: "Which Issue?"
- Question: "What GitHub issue would you like to start?"
- Options:
  - id: "ticket", label: "Specify an issue number (e.g., #5)"
  - id: "unticketed", label: "Unticketed work (no issue)"

**If target is `jira`:**

- Title: "Which Ticket?"
- Question: "What Jira ticket would you like to start?"
- Options:
  - id: "ticket", label: "Specify a ticket number (e.g., PROJ-123)"
  - id: "unticketed", label: "Unticketed work (no ticket)"

Based on the response:

- "ticket" → Ask conversationally for the ticket/issue number
- "unticketed" → Ask for a brief description of the work to generate a branch name (e.g., "add widget background settings")

### Step 3: Fetch Ticket Details

Skip this step for unticketed work.

**If target is `github`:**

```bash
gh issue view [NUMBER] --repo [REPO]
```

Present: issue number, title, state, labels, body (condensed).

**If target is `jira`:**

Use the `jira-expert` subagent to fetch issue `[TICKET_NUMBER]`.

Present: ticket key, type, status, priority, summary, description (condensed), sprint and epic info if available.

### Step 4: Generate Branch Name

Generate a kebab-case summary:

1. Take the ticket title/summary (or the user's description for unticketed work)
2. Convert to lowercase
3. Replace spaces and special characters with hyphens
4. Remove consecutive hyphens
5. Keep it concise (3-5 words max)

Branch name format depends on the source:

| Source | Format | Example |
|--------|--------|---------|
| GitHub issue | `[NUMBER]-[kebab-summary]` | `5-add-widget-background` |
| Jira ticket | `[KEY]-[kebab-summary]` | `RETIRE-123-add-user-auth` |
| Unticketed | `[kebab-summary]` | `widget-background-settings` |

### Step 5: Determine Worktree Paths

- `[MAIN_WORKTREE]` = current workspace root
- `[PROJECT_NAME]` = basename of main worktree (e.g., `AerialFrame`)
- `[BRANCH_NAME]` = generated branch name from Step 4
- `[NEW_WORKTREE]` = `../[PROJECT_NAME]-[BRANCH_NAME]`

### Step 6: Check Prerequisites

```bash
git branch --list [BRANCH_NAME]
git worktree list | grep [BRANCH_NAME]
```

If branch or worktree exists, **ALWAYS use the AskQuestion tool:**

- Title: "Branch/Worktree Already Exists"
- Question: "A branch or worktree named [BRANCH_NAME] already exists. How would you like to proceed?"
- Options:
  - id: "switch", label: "Switch to existing worktree"
  - id: "suffix", label: "Create with suffix (e.g., [BRANCH_NAME]-2)"
  - id: "abort", label: "Abort"

Based on the response:

- "switch" → Navigate to existing worktree
- "suffix" → Create new worktree with numeric suffix
- "abort" → Stop the workflow

### Step 7: Create Worktree with New Branch

```bash
git fetch origin main
git worktree add [NEW_WORKTREE] -b [BRANCH_NAME] origin/main
```

### Step 8: Copy Required Files & Install Dependencies

Only run each sub-step if the relevant file exists in the main worktree:

```bash
# Copy .env if it exists
[ -f [MAIN_WORKTREE]/.env ] && cp [MAIN_WORKTREE]/.env [NEW_WORKTREE]/.env

# Trust mise config if .mise.toml exists
[ -f [NEW_WORKTREE]/.mise.toml ] && cd [NEW_WORKTREE] && mise trust

# Install dependencies based on what dependency manager the project uses
cd [NEW_WORKTREE]
if [ -f package.json ]; then npm install; fi
if [ -f Podfile ]; then pod install; fi
if [ -f Package.swift ]; then swift package resolve; fi
```

Skip sub-steps cleanly when files don't exist — no warnings needed.

### Step 9: Report Success

```
Started [TICKET_REF]: "[Summary]"

Worktree created!
Branch: [BRANCH_NAME]
Location: [NEW_WORKTREE]
Based on: origin/main
```

Where `[TICKET_REF]` is:
- GitHub: `#N` with link to the issue
- Jira: `KEY-N` with link to Jira
- Unticketed: the description the user provided

### Step 10: Open in Cursor

**ALWAYS use the AskQuestion tool:**

- Title: "Open in Cursor?"
- Question: "Worktree created successfully at [NEW_WORKTREE]. Would you like me to open it in a new Cursor window?"
- Options:
  - id: "open", label: "Yes, open it"
  - id: "skip", label: "No, I'll open it manually"

Based on the response:

- "open" → Run `cursor [NEW_WORKTREE]`
- "skip" → Continue to next step

### Step 11: Prompt to Start Work

**ALWAYS use the AskQuestion tool:**

- Title: "Start Implementation?"
- Question: "Would you like me to start working on this ticket now?"
- Options:
  - id: "start", label: "Yes, start implementing"
  - id: "stop", label: "No, I'll do it myself"

Based on the response:

- "start" → Begin analyzing the codebase and implementing the requirements from the ticket description
- "stop" → End the workflow

## Error Handling

- **Ticket/issue not found**: Report the error and ask for a valid number
- **Branch exists**: Ask if user wants to switch to existing worktree or create with suffix
- **Worktree exists**: Ask to remove/recreate or use existing
- **Missing .env in main worktree**: Skip silently (only copy if it exists)
- **mise trust fails**: Warn but continue (not critical)
- **Dependency install fails**: Show error and suggest cleanup commands
- **Dirty working directory**: Warn about uncommitted changes (informational)

## Cleanup

When done with a ticket:

```bash
git worktree remove [NEW_WORKTREE]
git branch -d [BRANCH_NAME]
```
