---
name: dev-workflow-full
description: Run the full ticket lifecycle end-to-end without manually triggering each step. Chains start-ticket, execute-ticket, prepare-commit, create-pr, and review-github-pr in sequence. Use when the user says "full workflow", "end to end", "run the whole thing", or wants to go from ticket to reviewed PR in one go.
---

# Full Dev Workflow

Run the complete ticket lifecycle back-to-back: create branch, implement, commit, open PR, and review.

## Pipeline

```
dev-workflow-start-ticket
        ↓
dev-workflow-execute-ticket  (includes dev-workflow-prepare-commit when atomic)
        ↓
  [final commit if needed]   (dev-workflow-prepare-commit)
        ↓
dev-workflow-create-pr
        ↓
dev-workflow-review-github-pr
```

## Workflow

### Step 1: Start Ticket

Read and follow `~/.cursor/skills/dev-workflow-start-ticket/SKILL.md`.

This creates the worktree, branch, copies `.env`, runs `npm install`, and optionally opens in Cursor.

When the skill asks "Start Implementation?" at the end, **select "Yes"** automatically and proceed to Step 2 (do not wait for user input at that prompt).

### Step 2: Execute Ticket

Read and follow `~/.cursor/skills/dev-workflow-execute-ticket/SKILL.md`.

This fetches ticket details, creates an implementation plan, and executes it. The commit strategy prompt still goes to the user (atomic vs single vs manual).

- If **atomic** or **manual** commit strategy: `dev-workflow-prepare-commit` runs during implementation as part of execute-ticket. Proceed to Step 3 when implementation is complete.
- If **single** commit strategy: proceed to Step 2.5.

### Step 2.5: Final Commit (single-commit strategy only)

If the user chose "single commit at end" in execute-ticket, all changes are uncommitted. Read and follow `~/.cursor/skills/dev-workflow-prepare-commit/SKILL.md` to review, lint, test, and commit.

When prepare-commit offers to push, **select "Yes"** to push before the PR step.

### Step 3: Create PR

Read and follow `~/.cursor/skills/dev-workflow-create-pr/SKILL.md`.

This pushes (if not already pushed), generates a PR description, and creates the PR.

When create-pr offers "Start PR Review?", **select "Yes"** automatically and proceed to Step 4.

### Step 4: Review PR

Read and follow `~/.cursor/skills/dev-workflow-review-github-pr/SKILL.md`.

This fetches the PR diff and Jira context, reviews for code quality and security, and posts inline comments.

### Step 5: Done

Report the final status:

```
Full workflow complete!

Ticket: [TICKET-ID]
Branch: [BRANCH-NAME]
Worktree: [PATH]
PR: [PR-URL]
Review: Posted inline comments
```

## Skipping Steps

If the user is partway through the workflow (e.g., already on a branch with work in progress), detect the current state and skip completed steps:

- **Already on a feature branch with a worktree**: Skip Step 1, start at Step 2
- **Implementation done, changes uncommitted**: Start at Step 2.5
- **Changes committed and pushed**: Start at Step 3
- **PR already exists**: Start at Step 4

Use `git status`, `git log`, and `gh pr view` to detect the current state.

## Interruptions

If any step fails or the user aborts, stop the pipeline and report which step failed and why. The user can re-run the full workflow later and it will pick up from where it left off (see "Skipping Steps" above).
