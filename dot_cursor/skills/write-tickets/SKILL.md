---
name: write-tickets
description: Use when creating project tickets or issues (Jira or GitHub). Reads .publish-settings.md to determine target system. Runs a three-step pipeline (research → write → publish) using the steps in this skill's steps/ directory.
---

# Write Tickets

## Overview

Transform unstructured inputs (meeting notes, Slack threads, rough ideas) into well-structured project tickets or issues. Reads `.publish-settings.md` to determine whether to publish to Jira or GitHub Issues. The workflow runs three steps in sequence, each in its own **subagent**. Data is passed between steps via temp files.

## Pipeline

```
[Subagent 1: Research]  →  /tmp/write-tickets-research.md
        ↓
[Subagent 2: Write]     →  /tmp/ticket-N-*.md + /tmp/write-tickets-manifest.json
        ↓
[Subagent 3: Publish]   →  Tickets/issues created, temp files cleaned up
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
Read and follow the skill step file at: <absolute-path-to>/steps/publish.md

Read the ticket manifest from /tmp/write-tickets-manifest.json to get the list
of finalized tickets and their temp file paths.

The publish-settings template is at: <absolute-path-to>/templates/publish-settings.md

After all tickets are created, clean up all temp files:
- /tmp/write-tickets-research.md
- /tmp/write-tickets-manifest.json
- All /tmp/ticket-N-*.md files

Return the list of created ticket/issue keys with links.
```

## Shared Conventions

- **Publish settings:** The publish step resolves target system and fields from a `.publish-settings.md` file. Lookup order: **project root first** (`<workspace>/.publish-settings.md`), then **user home** (`~/.publish-settings.md`). The `Target` field determines the system: `github` for GitHub Issues, `jira` for Jira. See `steps/publish.md` for the full resolution logic.
- **Ticket document content** is produced in the write step using this skill's `templates/` (feature, bug, tech-debt, spike) and the ticket writing rules in `steps/write.md`. The write step is target-neutral — it produces markdown that works for both Jira and GitHub.
- **Ticket creation** is done in **`steps/publish.md`** which routes to the appropriate system based on the Target field. For GitHub: `gh issue create`. For Jira: Jira MCP or `acli`.
- **Links:** When showing a created ticket/issue, always use a link:
  - GitHub: `[#N](https://github.com/owner/repo/issues/N)`
  - Jira: `[KEY-N](https://your-org.atlassian.net/browse/KEY-N)`
- **No local file paths in ticket content.** Every file reference in ticket descriptions MUST be a GitHub link. See **GitHub Links** below.

## GitHub Links

**All file references in ticket/issue content MUST be GitHub links — never bare file paths.**

This applies to all ticket systems: GitHub Issues, Jira, or any other target.

### How to construct

1. **Get the repo URL:** Run `git remote get-url origin` and convert to HTTPS browse URL:
   - `git@github.com:org/repo.git` → `https://github.com/org/repo`
   - `https://github.com/org/repo.git` → `https://github.com/org/repo`

2. **Get the branch:** Use `main` for general references, or the current branch (`git branch --show-current`) for in-progress work.

3. **Build the link:**
   - File: `[filename.ts](https://github.com/org/repo/blob/main/path/to/filename.ts)`
   - File + line: `[filename.ts#L45](https://github.com/org/repo/blob/main/path/to/filename.ts#L45)`
   - File + range: `[filename.ts#L10-L25](https://github.com/org/repo/blob/main/path/to/filename.ts#L10-L25)`

### Examples

```markdown
- Entry point: [usePublicFeatureFlags.ts](https://github.com/guideline-app/mobile-app/blob/main/src/shared/providers/FeatureFlagsProvider/usePublicFeatureFlags.ts)
- Web equivalent: [useFeature.ts#L29-L39](https://github.com/guideline-app/app/blob/main/client/shared/lib/featureFlags/useFeature.ts#L29-L39)
```

### When using jira-expert subagent

When delegating to a jira-expert subagent for comments or updates, **always include this instruction in the subagent prompt:**

> All file references must be GitHub links, not bare file paths. Construct links using the repo URL `<repo-url>` in the format `[filename](repo-url/blob/main/path/to/file)`.

Resolve the repo URL before launching the subagent and pass it in the prompt.

## Handoff Files

| File | Written by | Read by | Contents |
|------|-----------|---------|----------|
| `/tmp/write-tickets-research.md` | Step 1 | Step 2 | Requirements, research findings, source links |
| `/tmp/ticket-N-*.md` | Step 2 | Step 3 | Individual ticket markdown |
| `/tmp/write-tickets-manifest.json` | Step 2 | Step 3 | Ticket list with titles, types, and temp file paths |

All temp files are cleaned up by Step 3 after tickets/issues are created.

## Steps Reference

| Step | File | Subagent Purpose |
|------|------|-----------------|
| 1 | `steps/research.md` | Gather requirements and optional research → write to handoff file |
| 2 | `steps/write.md` | Identify tickets, confirm plan, generate ticket markdown → write manifest |
| 3 | `steps/publish.md` | Create in target system (GitHub or Jira), clean up all temp files |
