---
name: write-tickets
description: Use when creating Jira tickets, writing project tickets, user stories, bug reports, or tech debt items. This is the skill for Jira ticket creation. Runs a three-step pipeline (research → write → publish) using the steps in this skill's steps/ directory.
---

# Write Tickets

## Overview

Transform unstructured inputs (meeting notes, Slack threads, rough ideas) into well-structured project tickets. The workflow runs three steps in sequence, each in its own **subagent**. Data is passed between steps via temp files.

## Pipeline

```
[Subagent 1: Research]  →  /tmp/write-tickets-research.md
        ↓
[Subagent 2: Write]     →  /tmp/ticket-N-*.md + /tmp/write-tickets-manifest.json
        ↓
[Subagent 3: Publish]   →  JIRA tickets created, temp files cleaned up
```

## How to Run

Launch each step as a **subagent** in sequence. Each subagent reads its step file and follows it. Pass the handoff file paths in the subagent prompt so it knows where to read/write.

**Skipping steps:** If the user already has gathered data → start at Step 2. If they already have finalized ticket markdown in temp files → start at Step 3.

### Step 1: Research

Launch a subagent with this prompt:

```
Read and follow the skill step file at: <absolute-path-to>/steps/research.md

When research is complete, write the gathered data to /tmp/write-tickets-research.md
using this format:

  ## Requirements
  <the user's requirements>

  ## Research Findings
  <codebase and/or online research results, or "None">

  ## Source Links
  <preserved URLs from user input, or "None">

Return a summary of what was gathered.
```

When the subagent returns, proceed to Step 2.

### Step 2: Write

Launch a subagent with this prompt:

```
Read and follow the skill step file at: <absolute-path-to>/steps/write.md

Read the gathered data from /tmp/write-tickets-research.md — this contains
the requirements, research findings, and source links from Step 1.

The ticket templates are at: <absolute-path-to>/templates/

After all tickets are finalized, write a manifest to /tmp/write-tickets-manifest.json:
{
  "tickets": [
    {"number": 1, "title": "...", "type": "Story|Bug|Task", "tempFile": "/tmp/ticket-1-slug.md"},
    ...
  ]
}

Return the ticket plan summary and manifest path.
```

When the subagent returns, proceed to Step 3.

### Step 3: Publish

Launch a subagent with this prompt:

```
Read and follow the skill step file at: <absolute-path-to>/steps/publish-jira.md

Read the ticket manifest from /tmp/write-tickets-manifest.json to get the list
of finalized tickets and their temp file paths.

The publish-settings template is at: <absolute-path-to>/templates/publish-settings.md

After all tickets are created, clean up all temp files:
- /tmp/write-tickets-research.md
- /tmp/write-tickets-manifest.json
- All /tmp/ticket-N-*.md files

Return the list of created JIRA ticket keys with links.
```

## Shared Conventions

- **Publish settings:** A single config file **`.publish-settings.md`** controls where tickets go and how to connect. Lookup order: **project root** (`<workspace>/.publish-settings.md`), then **user home** (`~/.publish-settings.md`). The file has a **Target** field: `jira`, `github`, or `jira,github`. When Target includes `jira`, the **Jira** section (project key, component, sprint, base URL, issue type mapping) is used by `steps/publish-jira.md`. When Target includes `github`, the **GitHub** section (optional type→labels, optional repo) is used by `steps/publish-github.md`. If no file exists, the user is prompted to create one or specify manually. Template: `templates/publish-settings.md`.
- **Ticket document content** is produced in the write step using this skill's `templates/` (feature, bug, tech-debt, spike) and the ticket writing rules in `steps/write.md`.
- **Jira creation** is in **`steps/publish-jira.md`** (MCP or acli); **GitHub Issues creation** is in **`steps/publish-github.md`** (GitHub CLI). Never use a separate jira-expert subagent for creation.
- **Links:** When showing a ticket key, always use a link: `[RETIRE-1234](https://gustohq.atlassian.net/browse/RETIRE-1234)`.
- **No local file paths in ticket content.** Use GitHub links only, using the current project's repository URL (e.g. from `git remote get-url origin` or the workspace context).

## Handoff Files

| File | Written by | Read by | Contents |
|------|-----------|---------|----------|
| `/tmp/write-tickets-research.md` | Step 1 | Step 2 | Requirements, research findings, source links |
| `/tmp/ticket-N-*.md` | Step 2 | Step 3 | Individual ticket markdown |
| `/tmp/write-tickets-manifest.json` | Step 2 | Step 3 | Ticket list with titles, types, and temp file paths |

All temp files are cleaned up by Step 3 after JIRA tickets are created.

## Steps Reference

| Step | File | Subagent Purpose |
|------|------|-----------------|
| 1 | `steps/research.md` | Gather requirements and optional research → write to handoff file |
| 2 | `steps/write.md` | Identify tickets, confirm plan, generate ticket markdown → write manifest |
| 3 | `steps/publish-jira.md` | Create in JIRA in order, clean up all temp files |
