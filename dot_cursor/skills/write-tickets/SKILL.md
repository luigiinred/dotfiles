---
name: write-tickets
description: Use when creating Jira tickets, writing project tickets, user stories, bug reports, or tech debt items. This is the skill to use for Jira ticket creation. Gathers requirements interactively, identifies all tickets needed from input, explores codebase for tech context, uses the technical-writer skill to generate each ticket document to a temp file for review, then creates them in JIRA using the jira-expert subagent (RETIRE project for mobile). Falls back to clipboard copy if subagent fails.
---

# Write Tickets

**Use this skill for creating Jira tickets.** Do not use other "create ticket" or "create Jira" skills—write-tickets is the canonical workflow.

## Overview

Transform unstructured inputs (meeting notes, Slack threads, rough ideas) into well-structured, technically-refined project tickets. Analyzes input to identify all tickets needed, determines proper ordering based on dependencies, then for each ticket: **writes the ticket markdown to a temporary file** for the user to review and edit in their IDE, then creates the ticket in JIRA (or copies to clipboard) and deletes the temp file. JIRA creation uses the jira-expert subagent (mobile defaults: RETIRE, component Consumer, sprint Mobile Refinement). Falls back to clipboard copy if subagent fails.

## Process

### Step 1: Gather Inputs (Upfront)

**ALWAYS use AskQuestion** to gather all initial information upfront. Use multiple question objects in a single call:

```
AskQuestion({
  "title": "Ticket Creation Setup",
  "questions": [
    {
      "id": "start",
      "prompt": "I'll help you create well-structured Jira tickets. Ready to provide requirements?",
      "options": [
        {"id": "proceed", "label": "Yes, I'll provide requirements now"},
        {"id": "abort", "label": "Cancel"}
      ]
    },
    {
      "id": "search_codebase",
      "prompt": "Should I search the codebase for relevant patterns?",
      "options": [
        {"id": "yes", "label": "Yes, search the codebase"},
        {"id": "no", "label": "No, skip"}
      ]
    },
    {
      "id": "search_online",
      "prompt": "Should I search online for established patterns/solutions?",
      "options": [
        {"id": "yes", "label": "Yes, search online"},
        {"id": "no", "label": "No, skip"}
      ]
    }
  ]
})
```

If user selects "proceed", ask conversationally: "Please provide your requirements (paste description, meeting notes, Slack threads, etc.)"

**After gathering requirements, determine output mode:**

- Check for JIRA MCP by trying to call the JIRA user info tool
- **If JIRA is available**, use AskQuestion:

  ```
  AskQuestion({
    "title": "Ticket Creation Method",
    "questions": [{
      "id": "method",
      "prompt": "Would you like me to create these tickets in JIRA automatically?",
      "options": [
        {"id": "jira", "label": "Yes, create in JIRA"},
        {"id": "clipboard", "label": "No, copy to clipboard one at a time"}
      ]
    }]
  })
  ```

  If JIRA selected and not in mobile-app (which has defaults), **use AskQuestion** for project/component:

  ```
  AskQuestion({
    "title": "JIRA Project Configuration",
    "questions": [{
      "id": "config",
      "prompt": "Which project and component should I use?",
      "options": [
        {"id": "specify", "label": "Let me specify"},
        {"id": "fetch", "label": "Show me available options"}
      ]
    }]
  })
  ```

  If "fetch" selected, fetch and present components as numbered list using AskQuestion

- **If JIRA is not available:** Use manual copy/paste mode automatically

**Mobile ticket defaults:** When creating tickets in the mobile-app codebase, read `{baseDir}/assets/mobile-jira-fields.md` for project, component, and sprint defaults. Use **component: Consumer** and **sprint: Mobile Refinement** for mobile tickets. Do NOT ask the user for project, component, or sprint - use the defaults automatically.

Do NOT proceed until you have at least #1.

**Trust defaults:** If the user skips optional fields or fields with defaults, accept it and move on. Don't ask again - use the default or proceed without that info.

**Preserve source links (automatically):** If the user provides actual URLs (Google Docs, Slack threads, Confluence pages, etc.) along with their input, automatically extract and save these links to include in the relevant tickets' Additional Context sections. Do NOT ask the user which links to preserve - just do it. This helps future readers reference the original source material. **Only preserve actual URLs** - if the user pastes content from a Slack conversation but doesn't provide a link to it, do NOT add a vague reference like "Slack conversation with X".

### Step 2: Research (if requested)

Do this BEFORE identifying tickets - research findings often drastically simplify the scope.

**Online research (if requested):**

- Search for established patterns, built-in configurations, or known solutions
- Check library/framework documentation for relevant features
- Look for similar issues and how others solved them

**Codebase exploration (if requested):**

- **Existing functionality:** Does this already exist? Could be duplicate work.
- **Reusable infrastructure:** Utilities, services, configs that handle related concerns
- **Documentation:** READMEs, AGENTS.md, inline docs explaining conventions

**Critical rule:** No assumptions. Only include findings VERIFIED to exist. Research often reveals that a "multi-ticket feature" is actually a "5-line config change."

**Output format:** Use GitHub links to specific files and line numbers when referencing code. Repository URL: `https://github.com/guideline-app/mobile-app/`

### Step 3: Identify Tickets

Analyze the input AND research findings to identify all distinct work items. Consider:

**What makes something a separate ticket?**

- UI work (different skillset, often different reviewer)
- Risky or complex migrations that warrant isolated review/deploy:
  - Skippable migrations (see `lib/migrate/skippable_migration.rb`) - always separate
  - Column deletes, renames, or type changes - always separate
  - Any migration that could fail or needs manual intervention
- Independent features that don't need each other
- Natural checkpoints where work could be paused and value delivered

**What should stay as ONE ticket?**

- Model + API changes for the same feature (these are tightly coupled)
- Simple migrations bundled with the feature they enable (adding a nullable column, for example)
- Changes so small they'd create overhead as separate tickets
- Work that must be deployed together

For each ticket identified, determine:

- **Title:** Concise description of what the ticket accomplishes
- **Type:** Feature/Story, Bug, or Tech Debt
- **Dependencies:** Which other tickets (if any) must be completed first

### Step 4: Confirm Ticket Plan

Present a simple numbered list showing the tickets in dependency order (prerequisites first):

```
Based on your input, I've identified the following tickets:

1. Add migration for new columns
2. Add model validations and API endpoint
3. Add UI components for new feature

Does this breakdown and order look right?
```

**Confirmation loop:**

1. Present the list
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

3. If "adjust" selected: gather feedback conversationally, adjust and show again
4. Repeat until "approve" is selected

Do NOT proceed to writing tickets until the plan is approved.

### Step 5: Write Tickets

**Issue type mapping:** When creating tickets in JIRA, map ticket types to JIRA issue types:

- Feature/Story → "Story" (or "Improvement" if enhancing existing functionality)
- Bug → "Bug"
- Tech Debt → "Task" or "Improvement"

**Generating the ticket document:** Use the **technical-writer skill** to produce the ticket markdown. Do not write the ticket body from scratch.

1. **Read the technical-writer skill** so you follow its principles and template structure.
2. **Document type:** Use `ticket-story`, `ticket-bug`, or `ticket-tech-debt` to match this ticket's type.
3. **Collected knowledge to pass:** This ticket's title, requirements, research findings (if any), context, preserved source links, and any cross-references to already-created JIRA keys (e.g., "Depends on RETIRE-1115").
4. **Template:** Read the template from the technical-writer skill's `templates/` directory: `templates/ticket-story-template.md`, `templates/ticket-bug-template.md`, `templates/ticket-tech-debt-template.md`, or `templates/ticket-spike-template.md`.
5. **Produce:** Generate the full ticket markdown following the technical-writer skill's rules (Tech Specs, no extra sections, GitHub links only, etc.). Then continue with the temp file review workflow below.

**Temp file workflow:** Always write ticket markdown to a temporary file instead of displaying it in chat. This lets the user review and edit the ticket in their IDE before creation.

- **File location:** `/tmp/ticket-N-slugified-title.md` (e.g., `/tmp/ticket-1-add-error-state-for-contributions.md`)
- **Write** the generated markdown to the temp file using the Write tool.
- **Tell the user** the file is ready for review: "Ticket N written to `/tmp/ticket-N-slug.md` — review and edit it in your IDE, then confirm when ready."
- **On approval:** Read the file contents back (in case the user edited it) before creating the ticket.
- **After creation (or clipboard copy):** Delete the temp file using the Delete tool.

The workflow differs based on output mode:

#### JIRA Subagent Mode

**ALWAYS use the jira-expert subagent** to create tickets in JIRA. Generate document (via technical-writer), write to temp file, get approval, read file back, create, and delete the temp file — for each ticket before moving to the next.

1. Maintain a mapping of placeholder → JIRA key (e.g., "Ticket #1" → "RETIRE-1115"). **When displaying or confirming a ticket number, always use a link:** `[KEY](https://gustohq.atlassian.net/browse/KEY)` (e.g. [RETIRE-1115](https://gustohq.atlassian.net/browse/RETIRE-1115)).

2. For each ticket in the approved plan:
   - **Generate the ticket document** using the technical-writer skill (document type + collected knowledge + template as above)
   - Replace any placeholder references with actual JIRA keys from the mapping
   - **Write to temp file** at `/tmp/ticket-N-slug.md` using the Write tool
   - Tell the user: "Ticket N written to `/tmp/ticket-N-slug.md` — review and edit, then confirm when ready."
   - **ALWAYS use AskQuestion:**

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

   - If "feedback" selected: gather feedback conversationally, update the temp file, and ask again
   - When approved: **Read the temp file back** (the user may have edited it), then use the **jira-expert subagent** via the Task tool:

     ```
     Task({
       "subagent_type": "jira-expert",
       "description": "Create JIRA ticket",
       "prompt": "Create a new JIRA ticket with the following details:\n\n**Title:** [ticket title]\n**Issue Type:** [Story/Bug/Task]\n**Project:** RETIRE\n**Component:** Consumer\n**Sprint:** Mobile Refinement\n\n**Description (in Markdown format):**\n\n[full ticket markdown read from temp file]\n\nPlease create this ticket and return the JIRA key (e.g., RETIRE-XXXX) with a link to the ticket."
     })
     ```

   - If the subagent **succeeds**: Extract the JIRA key from the response, add it to the mapping, **delete the temp file** using the Delete tool, and confirm: "Created [RETIRE-1115](https://gustohq.atlassian.net/browse/RETIRE-1115) (Ticket N of M)"
   
   - If the subagent **fails**: Offer fallback using AskQuestion:

     ```
     AskQuestion({
       "title": "Ticket Creation Failed",
       "questions": [{
         "id": "fallback",
         "prompt": "Failed to create ticket in JIRA. Would you like me to copy the markdown to your clipboard so you can paste it manually?",
         "options": [
           {"id": "copy", "label": "Yes, copy to clipboard"},
           {"id": "skip", "label": "No, skip this ticket"},
           {"id": "retry", "label": "Retry with subagent"}
         ]
       }]
     })
     ```

     If "copy" selected: Use pbcopy to copy the temp file contents, **delete the temp file**, then confirm and continue to next ticket.

3. After all tickets: Confirm "All [N] tickets created!" with each key as a link (e.g. [RETIRE-1115](https://gustohq.atlassian.net/browse/RETIRE-1115)). Verify all temp files have been deleted.

**Why this order?** Tickets are sorted in dependency order (prerequisites first). Creating each ticket immediately after approval means its JIRA key is available for subsequent tickets that reference it.

#### Manual Copy/Paste Mode

Generate (via technical-writer), write to temp file, approve, copy, and delete — for each ticket before moving to the next:

1. For each ticket in the approved plan:
   - **Generate the ticket document** using the technical-writer skill (document type + collected knowledge + template as in Step 5 above)
   - **Write to temp file** at `/tmp/ticket-N-slug.md` using the Write tool
   - Tell the user: "Ticket N written to `/tmp/ticket-N-slug.md` — review and edit, then confirm when ready."
   - **ALWAYS use AskQuestion:**

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

   - If "feedback" selected: gather feedback conversationally, update the temp file, and ask again
   - When approved: **Read the temp file back** (the user may have edited it), copy contents to clipboard using pbcopy, then **delete the temp file**
   - Confirm: "Ticket N of M copied to clipboard. Paste it into JIRA, then say 'continue' for the next ticket."
   - Wait for user to say continue before proceeding

2. After all tickets: Confirm "All [N] tickets complete!" Verify all temp files have been deleted.

## Templates

**Ticket document content is produced by the technical-writer skill.** Use that skill's ticket templates (in the technical-writer skill's `templates/` directory):

- **Feature / Story:** `templates/ticket-story-template.md`
- **Bug Report:** `templates/ticket-bug-template.md`
- **Tech Debt:** `templates/ticket-tech-debt-template.md`
- **Spike:** `templates/ticket-spike-template.md`

When generating each ticket, read the technical-writer skill and its template so the output follows its structure and principles (Tech Specs, Markdown, GitHub links only, etc.).

**Write-tickets assets:** This skill's `assets/` directory contains `mobile-jira-fields.md` for JIRA project/component/sprint defaults when in the mobile-app codebase. Do not use write-tickets for ticket body templates—technical-writer owns those.

### Output Format

Always use Markdown (technical-writer produces Markdown). It works for both JIRA API creation and manual copy/paste into JIRA's UI.

## Strict Rules

**Generate ticket documents via the technical-writer skill.** For each ticket, read the technical-writer skill and use its document type + template + principles to produce the markdown. Do not write ticket bodies from scratch or from write-tickets' own template text.

**Use ONLY the template sections.** The technical-writer ticket templates define the exact structure. Do not add sections like "Dependencies", "Scope Boundaries", "In Scope", "Open Questions", "Data Model", "Implementation Steps", "Files to Create", or "Success Metrics".

**No local file paths. Ever.** Always use GitHub links like `[file.rb#L45](https://github.com/org/repo/blob/main/path/file.rb#L45)`. If you write `/Users/...` or `app/models/...` without a link, you're doing it wrong.

**No "Open Questions" in the ticket.** If you have questions, ask the user BEFORE generating the ticket. The ticket should be actionable, not a list of things to figure out later.

## Common Mistakes

| Mistake                                               | Fix                                                                                        |
| ----------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| Proposing tickets before researching                  | Research first - a "multi-ticket feature" is often a "5-line config change"                |
| Diving into ticket generation before gathering inputs | Always gather inputs first. Do not proceed without requirements.                           |
| Writing tickets without confirming the plan first     | Always get approval on the ticket list/order before writing any tickets.                   |
| Using local file paths                                | Always use GitHub links with line numbers                                                  |
| Making up GitHub repository URLs                      | Always use `https://github.com/guideline-app/mobile-app/` - never guess or use other URLs  |
| Writing a full tech spec                              | Keep Tech Specs to implementation hints only                                               |
| Including code examples                               | Tech Specs are bullet points with links, NOT code blocks                                   |
| Adding extra sections                                 | Use ONLY the sections in the template                                                      |
| Including "Open Questions"                            | Ask questions BEFORE writing the ticket                                                    |
| Skipping confirmation loop                            | Always ask if ticket looks good before finalizing                                          |
| Asking for project/component/sprint in mobile-app     | Use RETIRE, Consumer, and **sprint: Mobile Refinement** automatically for mobile tickets   |
| Using JIRA wiki markup instead of Markdown            | Always use Markdown - it works for both API and manual paste into JIRA UI                  |
| Printing a ticket key without a link                  | Always format as a link: `[RETIRE-1234](https://gustohq.atlassian.net/browse/RETIRE-1234)` |
| Making assumptions about codebase                     | Only include verified findings. No "likely" or "probably."                                 |
| Listing every related file                            | Point to 1-2 entry points, trust implementer to explore                                    |
| More than 5 Tech Specs bullets                        | Cut to the most essential; less is more                                                    |
| "Files to Create/Modify" sections                     | Don't prescribe file structure - give entry points and patterns                            |
| Creating one mega-ticket when input suggests multiple | Analyze input for natural ticket boundaries; confirm plan before writing                   |
| Wrong ticket order                                    | Dependencies/prerequisites come first in the list                                          |
| Splitting too granularly (model vs API)               | Model + API for same feature should be ONE ticket; UI can be separate                      |
| Losing source links from user input                   | Automatically preserve links to meeting notes, docs, Slack in Additional Context           |
| Asking user which links to preserve                   | Don't ask - automatically include all URLs from user input in relevant tickets             |
| Adding vague source references without URLs           | Only include actual URLs - no "Slack conversation with X" without a link                   |
| Bundling risky migrations with feature work           | Skippable migrations, column deletes/renames always get their own ticket                   |
| Displaying ticket markdown in chat instead of a file  | Always write to `/tmp/ticket-N-slug.md` — user reviews/edits in IDE, not in chat           |
| Not reading temp file back before creating            | User may have edited the file — always Read it back before JIRA creation or pbcopy         |
| Not deleting temp files after creation                | Delete each temp file after the ticket is created or copied to clipboard                   |
| Forgetting to pbcopy                                  | Copy each ticket to clipboard as it's approved (manual mode or subagent fallback)          |
| Not using jira-expert subagent                        | ALWAYS use the jira-expert subagent for JIRA ticket creation                               |
| Not offering fallback when subagent fails             | If subagent fails, offer to copy markdown to clipboard via AskQuestion                     |
| Writing ticket content without technical-writer       | Use the technical-writer skill to generate each ticket document; then create the ticket    |