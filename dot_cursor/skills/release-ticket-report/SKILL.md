---
name: release-ticket-report
description: Generate a release readiness report comparing the latest GitHub release with the Jira board's Merged column. Identifies tickets that need to be moved to Done. Use when the user asks for a release report, wants to check release status, asks what tickets need to be moved to Done, or says "release report".
---

# Release Ticket Report

Generate a markdown report cross-referencing the latest GitHub release with the Mobile sprint's Merged column on the Consumer Jira board (4462).

## Prerequisites

- `gh` CLI authenticated (`gh auth status`)
- `acli` CLI authenticated (`acli jira auth login --web`)
- `jq` installed

## Workflow

### Step 1: Gather Data

Run these three commands in parallel using the Shell tool:

```bash
SKILL_DIR=".cursor/skills/release-ticket-report/scripts"

# 1. Latest release tickets
$SKILL_DIR/list_release_tickets.sh

# 2. Mobile sprint merged tickets
$SKILL_DIR/list_merged_tickets.sh 4462

# 3. Cross-reference: release vs merged column
$SKILL_DIR/release_merged_tickets.sh 4462
```

### Step 2: Categorize Tickets

From the command output, build three lists:

1. **Move to Done**: Tickets in the latest release AND still in Merged column (released but not transitioned)
2. **Pending release**: Tickets in Merged column but NOT in the latest release (merged, awaiting next release)
3. **Release summary**: All tickets from the release notes, grouped by RETIRE / RNDCORE / untracked

### Step 3: Generate Report

Output the report directly to the user in this format:

```markdown
# Release Report: <tag>

## Action Required: Move to Done

These tickets shipped in <tag> but are still in the Merged column. They should be transitioned to **Done**.

| Ticket                  | Assignee | Summary | PR              |
| ----------------------- | -------- | ------- | --------------- |
| [RETIRE-123](jira-link) | Name     | Summary | [#456](gh-link) |

## Pending Next Release

These tickets are merged but not yet released.

| Ticket                  | Assignee | Summary |
| ----------------------- | -------- | ------- |
| [RETIRE-789](jira-link) | Name     | Summary |

## Release Summary (<tag>)

**X tickets** (Y RETIRE, Z RNDCORE, W untracked)

<collapsed details of all release tickets if useful>
```

Jira link format: `https://gustohq.atlassian.net/browse/TICKET-KEY`

### Step 4: Offer to Transition

After presenting the report, if there are tickets that need to move to Done, use the **AskQuestion tool**:

- Title: "Transition Tickets"
- Prompt: "Would you like me to move these tickets to Done in Jira?"
- Options:
  - id: "all", label: "Yes, move all to Done"
  - id: "pick", label: "Let me pick which ones"
  - id: "skip", label: "No, just the report"

**If "all"**: Transition each ticket:

```bash
acli jira workitem transition --key TICKET-KEY --status "Done"
```

**If "pick"**: Use AskQuestion with `allow_multiple: true` listing each ticket as an option, then transition the selected ones.

**If "skip"**: End the workflow.

### Step 5: Confirm

After transitioning, verify by re-running:

```bash
$SKILL_DIR/release_merged_tickets.sh 4462
```

Report the updated counts to confirm the transitions succeeded.

## Scripts

All utility scripts live in the `scripts/` directory of this skill:

- **`list_release_tickets.sh [tag]`**: List all tickets from a GitHub release (defaults to latest)
- **`list_merged_tickets.sh [board_id]`**: List tickets in the Merged column per sprint (defaults to board 4462)
- **`release_merged_tickets.sh [board_id]`**: Cross-reference release tickets with Merged column on the Mobile sprint
