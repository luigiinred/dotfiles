---
name: worktree-manager
description: Create and configure git worktrees for parallel development. Use when the user wants to start a new worktree, work on multiple branches simultaneously, set up an isolated development environment, or mentions worktree.
---

# Worktree Manager

Create fully configured git worktrees for parallel development.

## Workflow

### Step 1: Get Branch Name

If not provided, **ALWAYS use the AskQuestion tool:**

- Title: "Branch Name Required"
- Question: "What branch name should I use for this worktree?"
- Options:
  - id: "specify", label: "Let me specify a branch name"
  - id: "abort", label: "Abort"

If the user selects "specify", ask conversationally for the branch name (e.g., RETIRE-1234).

### Step 2: Determine Paths

- `[MAIN_WORKTREE]` = current workspace root (e.g., `/Users/timmy.garrabrant/Developer/mobile-app`)
- `[PROJECT_NAME]` = basename of main worktree (e.g., `mobile-app`)
- `[NEW_WORKTREE]` = `../[PROJECT_NAME]-[BRANCH_NAME]`

### Step 3: Check Prerequisites

```bash
# Check for existing branch
git branch --list [BRANCH_NAME]

# Check for existing worktree
git worktree list | grep [BRANCH_NAME]
```

If exists, **ALWAYS use the AskQuestion tool:**

- Title: "Branch/Worktree Already Exists"
- Question: "A branch or worktree named [BRANCH_NAME] already exists. How would you like to proceed?"
- Options:
  - id: "use", label: "Use existing branch"
  - id: "suffix", label: "Create with suffix (e.g., [BRANCH_NAME]-2)"
  - id: "abort", label: "Abort"

Based on the response:

- "use" → Use existing branch if worktree doesn't exist, or navigate to existing worktree
- "suffix" → Create new branch/worktree with numeric suffix
- "abort" → Stop the workflow

### Step 4: Create Worktree

**For a NEW branch (based on origin/main):**

```bash
git fetch origin main
git worktree add [NEW_WORKTREE] -b [BRANCH_NAME] origin/main
```

**For an EXISTING branch:**

```bash
# Fetch the branch if it's remote-only
git fetch origin [BRANCH_NAME]

# Create worktree using existing branch (no -b flag)
git worktree add [NEW_WORKTREE] [BRANCH_NAME]
```

If unclear whether they want a new branch or to use an existing one, **ALWAYS use the AskQuestion tool:**

- Title: "New or Existing Branch?"
- Question: "Would you like to create a new branch or use an existing one?"
- Options:
  - id: "new", label: "Create new branch"
  - id: "existing", label: "Use existing branch"

Based on the response, use the appropriate workflow above.

### Step 5: Copy Required Files

Copy .env from the main worktree (not .env.example):

```bash
cp [MAIN_WORKTREE]/.env [NEW_WORKTREE]/.env
```

### Step 6: Install Dependencies

```bash
cd [NEW_WORKTREE]
npm install
```

Monitor progress - this takes several minutes.

### Step 7: Report Success

```
Worktree created!

Branch: [BRANCH_NAME]
Location: [NEW_WORKTREE]
Based on: origin/main

Files copied: .env
Dependencies: installed
```

### Step 8: Open in Cursor

**ALWAYS use the AskQuestion tool:**

- Title: "Open in Cursor?"
- Question: "Worktree created successfully at [NEW_WORKTREE]. Would you like me to open it in a new Cursor window?"
- Options:
  - id: "open", label: "Yes, open it"
  - id: "skip", label: "No, I'll open it manually"

Based on the response:

- "open" → Run `cursor [NEW_WORKTREE]`
- "skip" → End the workflow

## Cleanup

```bash
# Remove worktree
git worktree remove [NEW_WORKTREE]

# Delete branch if merged
git branch -d [BRANCH_NAME]
```

## Error Handling

- **Branch exists**: Ask to use existing or create with suffix
- **Worktree exists**: Ask to remove/recreate or use existing
- **Missing .env in main worktree**: Warn user that .env is missing from main worktree and must be created manually
- **npm install fails**: Show error, suggest `rm -rf node_modules && npm install`
