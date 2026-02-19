---
name: write-tickets
description: Use when creating Jira tickets, writing project tickets, user stories, bug reports, or tech debt items. This is the skill for Jira ticket creation. Runs a three-step pipeline (research → write → publish) using the steps in this skill's steps/ directory.
---

# Write Tickets

## Overview

Transform unstructured inputs (meeting notes, Slack threads, rough ideas) into well-structured project tickets. The workflow has three steps; each step is defined in this skill's **`steps/`** directory. Read and follow the step file for each phase.

1. **Step 1: Research** — Gather requirements and optional research (codebase/online). Data only; no ticket list yet. → **`steps/research.md`**
2. **Step 2: Write** — Identify tickets from the data, confirm plan, then generate each ticket document (technical-writer + temp file for review), collect approved markdown. → **`steps/write.md`**
3. **Step 3: Publish** — Create tickets in JIRA in order (acli, ADF, component/sprint). Temp markdown files for review; no clipboard. → **`steps/publish.md`**

Run all three in sequence for the full flow, or start at a later step when the user is partway through.

## Pipeline

```
steps/research.md     (gather requirements, optional research — data only)
        ↓
steps/write.md        (identify tickets, confirm plan, then technical-writer → temp file → approve → read back)
        ↓
steps/publish.md      (create in JIRA, in order — acli, ADF, component/sprint)
```

## How to Run

- **Full flow:** Read and follow `steps/research.md`, then `steps/write.md`, then `steps/publish.md` in order.
- **Step 1 (Research):** Read and follow `steps/research.md`. When gathering is complete (requirements + optional research), proceed to Step 2.
- **Step 2 (Write):** You need gathered data from Step 1. Read and follow `steps/write.md` (it will identify tickets, confirm plan, then write each). When all tickets are finalized, proceed to Step 3.
- **Step 3 (Publish):** You need the list of finalized tickets. Read and follow `steps/publish.md` (it resolves JIRA config at the start, then creates each ticket with acli/ADF).

**Skipping steps:** If the user already has gathered data or an approved plan → start at `steps/write.md`. If they already have finalized ticket markdown → start at `steps/publish.md`.

## Shared Conventions

- **JIRA settings:** The publish step resolves JIRA fields (project key, component, sprint, base URL, issue type mapping) from a `.jira-settings.md` file. Lookup order: **project root first** (`<workspace>/.jira-settings.md`), then **user home** (`~/.jira-settings.md`). If neither exists, the user is prompted to create one or specify fields manually. See `steps/publish.md` for the full resolution logic and file template.
- **Ticket document content** is produced in the write step using this skill's `templates/` (feature, bug, tech-debt, spike) and the ticket writing rules in `steps/write.md`. The write step is the expert for JIRA ticket content.
- **JIRA creation** is done in **`steps/publish.md`** (acli, markdown→ADF, workitem create, component/sprint). Never use a separate jira-expert subagent for creation.
- **Links:** When showing a ticket key, always use a link: `[RETIRE-1234](https://gustohq.atlassian.net/browse/RETIRE-1234)`.
- **No local file paths in ticket content.** Use GitHub links only, using the current project's repository URL (e.g. from `git remote get-url origin` or the workspace context).

## Steps Reference

| Step | File | Purpose |
|------|------|--------|
| 1 | `steps/research.md` | Gather requirements and optional research (data only) |
| 2 | `steps/write.md` | Identify tickets, confirm plan, then generate ticket markdown (technical-writer + temp file), collect approved content |
| 3 | `steps/publish.md` | Create in JIRA in order (acli, ADF); fallback = temp file for manual paste |
