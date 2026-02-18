---
name: dev-workflow-full
description: Run the full ticket lifecycle end-to-end without manually triggering each step. Chains initialize, start-work, prepare-commit, create-pr, and review-pr in sequence. Supports autopilot (no prompts) or pair (interactive) mode. Use when the user says "full workflow", "end to end", "run the whole thing", or wants to go from ticket to reviewed PR in one go.
---

# Full Dev Workflow

Run the complete ticket lifecycle back-to-back: create branch, implement, commit, open PR, and review.

## Pipeline

```
dev-workflow-initialize
        ↓
dev-workflow-start-work  (includes dev-workflow-prepare-commit when atomic)
        ↓
  [final commit if needed]   (dev-workflow-prepare-commit)
        ↓
dev-workflow-create-pr
        ↓
dev-workflow-review-pr
```

## Step 0: Choose Mode and Collect Info

**ALWAYS use the AskQuestion tool:**

- Title: "Workflow Mode"
- Questions:
  - id: "mode", prompt: "How would you like to run the workflow?", options:
    - id: "autopilot", label: "Autopilot - collect info upfront, then run everything without prompting"
    - id: "pair", label: "Pair - walk through each step together, I'll confirm at each decision point"

### If Autopilot: Collect Everything Upfront

Gather all required inputs in a **single AskQuestion call** before doing any work:

- id: "ticket", prompt: "Which Jira ticket?", options:
  - id: "specify", label: "I'll provide a ticket number"
  - id: "unticketed", label: "Unticketed work (use RETIRE-1908)"
- id: "open_cursor", prompt: "Open the new worktree in Cursor?", options:
  - id: "yes", label: "Yes, open in Cursor"
  - id: "no", label: "No, stay here"

If "specify", ask conversationally for the ticket number.

**Autopilot defaults** (applied automatically, no prompts):

| Decision Point | Default |
|---|---|
| Branch name | Auto-generated from ticket title |
| Branch/worktree conflict | Create with numeric suffix |
| Commit strategy | Atomic commits |
| Unstaged changes | Stage all changes |
| Minor code issues | Fix automatically |
| Lint errors | Fix automatically (`--fix`) |
| Test failures | **STOP** -- always stop on test failures regardless of mode |
| Commit message | Auto-generated conventional commit |
| Push after commit | Yes |
| Critical issues (secrets, etc.) | **STOP** -- always stop on critical issues regardless of mode |

### If Pair: Proceed Normally

Each sub-skill runs with its full interactive prompts. The user confirms at every decision point. This is the standard behavior of each individual skill.

## Step 1: Initialize

Read and follow `~/.cursor/skills/dev-workflow-initialize/SKILL.md`.

- **Autopilot**: Use the ticket number collected in Step 0. Skip the "Which Ticket?" prompt. Auto-generate branch name. Skip "Open in Cursor?" (use collected answer). Skip "Start Implementation?" (always yes).
- **Pair**: All prompts go to the user as normal.

## Step 2: Start Work

Read and follow `~/.cursor/skills/dev-workflow-start-work/SKILL.md`.

- **Autopilot**: Present the implementation plan for review (always show the plan -- this is the one pause in autopilot). After user confirms, use atomic commit strategy automatically. Skip the commit strategy prompt. During implementation, run `dev-workflow-prepare-commit` after each logical unit with all defaults (stage all, auto-fix minor issues, auto-fix lint, auto-generate message, auto-push).
- **Pair**: All prompts go to the user as normal (plan confirmation, commit strategy, per-commit decisions).

## Step 2.5: Final Commit (single-commit strategy only, pair mode)

Only applies in pair mode when the user chose "single commit at end". Read and follow `~/.cursor/skills/dev-workflow-prepare-commit/SKILL.md`. Auto-push when done.

This step never runs in autopilot (autopilot always uses atomic commits).

## Step 3: Create PR

Read and follow `~/.cursor/skills/dev-workflow-create-pr/SKILL.md`.

- **Autopilot**: Push if needed. Generate PR description and create the PR. Skip "Start PR Review?" (always yes). Proceed directly to Step 4.
- **Pair**: All prompts go to the user as normal.

## Step 4: Review PR

Read and follow `~/.cursor/skills/dev-workflow-review-pr/SKILL.md`.

- **Autopilot**: Review the current branch's PR automatically. Skip the "Which PR?" prompt.
- **Pair**: All prompts go to the user as normal.

## Step 5: Done

Report the final status:

```
Full workflow complete!

Mode: [Autopilot / Pair]
Ticket: [TICKET-ID]
Branch: [BRANCH-NAME]
Worktree: [PATH]
Commits: [N] atomic commits
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

## Hard Stops (Both Modes)

These always halt the pipeline regardless of mode:

- **Test failures**: Stop and report. Never skip failing tests.
- **Critical security issues**: Hardcoded secrets, API keys, credentials. Stop and report.
- **Git/gh errors**: Push failures, auth issues. Stop and report.

The user can re-run the workflow after fixing the issue and it will pick up from where it left off (see "Skipping Steps").
