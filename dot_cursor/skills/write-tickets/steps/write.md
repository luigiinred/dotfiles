# Step 2: Write

Identify tickets from the gathered data, get plan approval, then generate ticket documents for each item. This step is the expert in writing JIRA tickets: use this skill's templates and the rules below. Temp files for review; no JIRA creation yet.

## Prerequisites

Read **`/tmp/write-tickets-research.md`** — this is the handoff file from Step 1 (Research). It contains:

- Requirements (what the user provided)
- Research findings (if any)
- Preserved source links

## Workflow

### 1. Identify Tickets

Analyze the requirements AND research findings to identify all distinct work items.

**Separate tickets for:** UI work, risky migrations (column deletes/renames/type changes, skippable migrations), independent features, natural checkpoints.

**One ticket for:** Model + API for same feature, simple migrations with the feature they enable, small coupled changes, work that must deploy together.

For each ticket: **Title**, **Type** (Feature/Story, Bug, Tech Debt, Spike), **Dependencies** (order).

### 2. Confirm Ticket Plan

Present a numbered list in dependency order (prerequisites first):

```
Based on your input, I've identified the following tickets:

1. Add migration for new columns
2. Add model validations and API endpoint
3. Add UI components for new feature

Does this breakdown and order look right?
```

**Confirmation loop:**

1. Present the list.
2. **ALWAYS use AskQuestion:**

   ```
   AskQuestion({
     "title": "Confirm Ticket Plan",
     "questions": [{
       "id": "plan",
       "prompt": "Does this breakdown and order look right?",
       "options": [
         {"id": "approve", "label": "Yes, looks good"},
         {"id": "adjust", "label": "Let me adjust something"},
         {"id": "abort", "label": "Cancel"}
       ]
     }]
   })
   ```

3. If "adjust": gather feedback, adjust, show again. Repeat until "approve".

Do NOT proceed to writing ticket content until the plan is approved.

### 3. For Each Ticket in the Approved Plan

1. **Generate the ticket document** from this ticket's type and the gathered data:
   - **Template:** Read this skill's `templates/` and use the right one: `feature-template.md` (Story), `bug-template.md` (Bug), `tech-debt-template.md` (Tech Debt), `spike-template.md` (Spike).
   - **Content:** Fill from this ticket's title, requirements, research findings, preserved source links, and cross-references (e.g. "Depends on Ticket #1" for earlier tickets). Follow the **Ticket writing rules** and **Tech Specs** below.
   - **Output:** Full markdown. Use ONLY the sections in the template. No local file paths — GitHub links only, using the current project's repository URL (from git remote or workspace) with file path and line numbers.

2. **Write to temp file:** `/tmp/ticket-N-slugified-title.md` (e.g. `/tmp/ticket-1-add-error-state-for-contributions.md`). Use the Write tool.

3. **Tell the user:** "Ticket N written to `/tmp/ticket-N-slug.md` — review and edit in your IDE, then confirm when ready."

4. **Confirm with AskQuestion:**

   ```
   AskQuestion({
     "title": "Confirm Ticket [N] of [M]",
     "questions": [{
       "id": "confirm",
       "prompt": "Review/edit the file, then confirm. Does this ticket look good?",
       "options": [
         {"id": "approve", "label": "Yes, looks good"},
         {"id": "feedback", "label": "I have feedback"},
         {"id": "abort", "label": "Cancel"}
       ]
     }]
   })
   ```

5. If "feedback": gather feedback, update the temp file, ask again. Repeat until "approve".

6. **Read the temp file back** (user may have edited it in their IDE). Store the file path and metadata (title, type) for this ticket. **Do NOT delete the temp file** — the publish step reads directly from it.

7. Proceed to the next ticket. When generating the next ticket's markdown, you may reference "Ticket #1", "Ticket #2", etc. — Step 3 (publish) will substitute actual JIRA keys when creating.

### After All Tickets

Write a manifest to **`/tmp/write-tickets-manifest.json`** listing all finalized tickets:

```json
{
  "tickets": [
    {"number": 1, "title": "Add migration for new columns", "type": "Story", "tempFile": "/tmp/ticket-1-add-migration.md"},
    {"number": 2, "title": "Add API endpoint", "type": "Story", "tempFile": "/tmp/ticket-2-add-api-endpoint.md"}
  ]
}
```

This manifest is the handoff to Step 3 (Publish). The publish subagent reads it to know which tickets to create and where to find the markdown.

## Templates (this skill)

Read the appropriate template from this skill's `templates/` directory for each ticket type:

| Type | Template |
|------|----------|
| Feature/Story | `templates/feature-template.md` |
| Bug | `templates/bug-template.md` |
| Tech Debt | `templates/tech-debt-template.md` |
| Spike | `templates/spike-template.md` |

## Ticket writing rules

- **Use ONLY the sections in the template.** Do not add "Dependencies", "Scope Boundaries", "In Scope", "Data Model", "Implementation Steps", "Files to Create", "Success Metrics", or other sections not in the template. Spike template allows "Open Questions"; other types do not — ask the user before writing if anything is unclear.
- **No local file paths.** Use GitHub links only. Build links from the current project's repository URL (e.g. from `git remote get-url origin`) in the form `[file.ts#L45](<repo-url>/blob/<branch>/path/file.ts#L45)`.
- **Tech Specs:** 3–5 bullet points max. Entry points only (where to start), name patterns to reuse with one link, constraints and gotchas. No "Files to Create/Modify", no long code blocks; a short code snippet is OK only when it's the clearest way to show a gotcha (e.g. required wrapper or config line).
- **Tone:** Direct, concise. Lead with what the ticket accomplishes; context second. Bullet points over paragraphs.
- **Code examples:** Use only when they clarify (e.g. bug reproduction, config snippet, gotcha). In Tech Specs prefer links; code only when it best conveys a constraint.

**Example Tech Specs** (use the current project's repo URL for links):

```markdown
## Tech Specs

- Entry point: [useUserAccounts.ts](<repo-url>/blob/main/src/features/me/hooks/useUserAccounts.ts)
- Follow pattern from [usePortfolio.ts](<repo-url>/blob/main/src/features/portfolio/hooks/usePortfolio.ts)
- Gotcha: Suspense queries require a Suspense boundary - wrap in `<Suspense fallback={<LoadingScreen />}>`
```

## Strict rules

- **Read this skill's template** for the ticket type and fill it; do not invent structure.
- **Temp file per ticket:** Write to `/tmp/ticket-N-slug.md`. Do NOT delete after approval — publish reads from it.
- **No "Open Questions" in the ticket** (except in Spike template). If something is unclear, ask the user before writing.

## Common mistakes

| Mistake | Fix |
|--------|-----|
| Writing tickets before identifying and confirming plan | Identify tickets from gathered data, get plan approval, then write |
| Adding sections not in the template | Use ONLY sections defined in this skill's templates |
| Displaying markdown only in chat | Write to temp file for IDE review/edit |
| Not reading temp file back | User may have edited — always read before confirming approval |
| Deleting temp files before publish | Keep temp files — publish reads from them and cleans up at the end |
| Using local paths in ticket content | GitHub links only |
| Long Tech Specs or code blocks | 3–5 bullets, entry points and gotchas; prefer links over code |
