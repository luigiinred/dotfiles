# Step 3: Publish

Take the list of finalized ticket markdown from Step 2 (write) and create each in JIRA. Runs in plan order so JIRA keys are available for cross-references in later tickets. **Prefer the Jira MCP** when available (so you can set component, current sprint, and other fields directly); fall back to `acli` if MCP is not configured or creation fails.

## Prerequisites

You need from Step 2 (write):

- **List of finalized tickets:** For each, { title, type, tempFilePath }. The markdown content lives in the temp files from Step 2 (e.g. `/tmp/ticket-1-slug.md`). Read each temp file when you need its content — do NOT require the content to be passed in memory.

## Workflow

### 1. JIRA Config

Do this first, before creating any tickets.

**Resolve project config:**

- **Current repo:** Determine the current repository (e.g. run `git remote get-url origin` or use workspace context). Normalize to an identifier like `guideline-app/mobile-app` (owner/repo).
- **Match a project:** This skill has a **`projects/`** directory. Each `.md` file (e.g. `projects/mobile-app.md`) is a project keyed by repo. Check if the current repo matches the **repo** in a project file. Example: repo contains `guideline-app/mobile-app` → use **`projects/mobile-app.md`**.
- **If matched:** Read that project file (e.g. `projects/mobile-app.md`) for JIRA fields to set (project key, component, sprint, JIRA base URL). Use those values. Do NOT ask the user for project/component/sprint.
- **If not matched:** Ask the user whether to use a project config:
  - Use AskQuestion: "Should I use a project config for JIRA fields?"
  - Options: list each project in `projects/` (e.g. "mobile-app — for https://github.com/guideline-app/mobile-app") plus "No — I'll specify project/component/sprint myself".
  - If they pick a project: read that project's .md file (e.g. `projects/mobile-app.md`) and use its fields.
  - If they pick "No": use AskQuestion or MCP to get project/component/sprint (or "Show me available options").
- **Prefer Jira MCP:** If a Jira/Atlassian MCP server is configured, use it for creation. Call `getAccessibleAtlassianResources` (or equivalent) to get `cloudId`. Use project/component/sprint from the resolved config. The MCP allows setting **component** and **current sprint** (and other fields) on create via additional_fields.
- **Fallback: acli.** If MCP is not available or you need a fallback, run `acli jira auth status`. If not authenticated, tell the user to run `acli jira auth login --web` and complete the browser flow; stop until auth succeeds.
- **JIRA base URL** for links: From the project's README or user input. When displaying a ticket key, always use a link: `[KEY](<jira-base-url>/browse/KEY)`.

### 2. Maintain a Key Mapping

Keep a mapping: placeholder → JIRA key (e.g. "Ticket #1" → "RETIRE-1115"). Use it to substitute placeholders in later tickets and when confirming created tickets.

### 3. For Each Ticket in Order

1. **Read the temp file** for this ticket (e.g. `/tmp/ticket-N-slug.md`). This is the source of truth — the user may have edited it during Step 2.

2. **Substitute placeholders in markdown:** Replace "Ticket #1", "Ticket #2", etc. in this ticket's markdown with the actual JIRA keys from the mapping (for tickets already created).

3. **Create the ticket in JIRA.** Prefer MCP; fall back to acli if MCP is unavailable or creation fails.

   **Option A — Prefer: Jira MCP**

   - Call the MCP's **create issue** tool (e.g. `createJiraIssue`) with: `cloudId`, `projectKey`, `issueTypeName` (Story/Bug/Task/Improvement), `summary` (ticket title), `description` (markdown — many MCPs accept markdown for description).
   - Use **additional_fields** (or the MCP's equivalent) to set **component** and **sprint** (e.g. `components` array, sprint custom field such as `customfield_10020` for the active sprint). This avoids separate edit calls and ensures component and current sprint are set on create.
   - If the MCP exposes a way to get the current/active sprint for the board, use that for sprint when the project config doesn't specify a fixed sprint ID.
   - Parse the response for the new issue key; add it to the mapping and confirm. If the MCP call fails, retry once; if it still fails, fall back to Option B for this ticket.

   **Option B — Fallback: acli**

   **3a. Convert markdown to ADF.** The description field MUST be ADF when using acli — raw markdown will not render in JIRA.

   | Markdown | ADF node type |
   |----------|---------------|
   | `## Heading` | `heading` with `attrs.level: 2` |
   | `### Heading` | `heading` with `attrs.level: 3` |
   | Plain paragraph | `paragraph` |
   | `- item` (bullet list) | `bulletList` > `listItem` > `paragraph` |
   | `1. item` (ordered list) | `orderedList` > `listItem` > `paragraph` |
   | `- [ ]` / `- [x]` (checkbox) | `bulletList` > `listItem` > `paragraph` with ☐ / ☑ prefix |
   | `` `code` `` (inline) | `text` with `marks: [{"type": "code"}]` |
   | `**bold**` | `text` with `marks: [{"type": "strong"}]` |
   | `[text](url)` | `text` with `marks: [{"type": "link", "attrs": {"href": "url"}}]` |
   | Code block | `codeBlock` with `attrs.language` |

   ADF doc: `{"type": "doc", "version": 1, "content": [...]}`. Parse inline formatting; don't dump markdown into plain text nodes.

   **3b. Build workitem JSON** and write to `/tmp/jira-workitem.json`:

   ```json
   {
     "projectKey": "<project key>",
     "type": "Story|Bug|Task|Improvement",
     "summary": "<ticket title>",
     "description": { ... ADF object ... }
   }
   ```

   **3c. Create the ticket:**

   ```bash
   acli jira workitem create --from-json /tmp/jira-workitem.json
   ```

   Parse the output to extract the JIRA key. If it fails: auth → tell user to re-auth; validation → fix JSON and retry (up to 2 retries); after 2 retries → go to Fallback below.

   **3d. Set component and sprint** (from project config or user input):

   ```bash
   acli jira workitem edit --key <KEY> --component "Consumer"
   acli jira workitem edit --key <KEY> --custom "customfield_10020=<sprint-id>"
   ```

   If these fail, report to the user but don't block — the ticket is already created.

   **3e. Clean up:** Delete `/tmp/jira-workitem.json`.

   **3f. Add key to mapping** and confirm: "Created [KEY](url) (Ticket N of M)."

4. **Fallback if creation failed (MCP and acli):** Offer:

   ```
   AskQuestion({
     "title": "JIRA Creation Failed",
     "questions": [{
       "id": "fallback",
       "prompt": "Failed to create ticket (MCP or acli). Write markdown to a temp file for manual paste?",
       "options": [
         {"id": "tempfile", "label": "Yes, write to temp file"},
         {"id": "skip", "label": "Skip this ticket"},
         {"id": "retry", "label": "Try again"}
       ]
     }]
   })
   ```

   If "tempfile": write markdown to e.g. `/tmp/ticket-N-manual-paste.md`, tell the user the path, continue to next ticket. If "retry": retry the create flow for this ticket.

### After All Tickets

1. **Clean up all temp files:** Delete all `/tmp/ticket-N-*.md` temp files from Step 2. These are no longer needed now that the tickets are created in JIRA.
2. "All [N] tickets created!" with each key as a link.

## Why This Order?

Tickets are in dependency order (prerequisites first). Creating each ticket immediately gives you its JIRA key for substituting into the next ticket's markdown (e.g. "Depends on RETIRE-1115").

## Strict Rules

- **Always link ticket keys** when confirming: `[KEY](<jira-base-url>/browse/KEY)`.
- **Substitute before create:** Replace "Ticket #N" with actual keys in markdown before creating that ticket.
- **Create in order** so the mapping is populated for subsequent tickets.
- **When using acli:** Use ADF for descriptions (raw markdown will not render). Parse `**bold**`, `[links](url)`, `` `code` `` into proper ADF nodes and marks. Clean up `/tmp/jira-workitem.json` after each create.
- **When using MCP:** Prefer setting component and current sprint (and other fields) in the create call via additional_fields so they are set on create.
- **Never use a jira-expert subagent** for creation — do it inline in this step.

## Common Mistakes

| Mistake | Fix |
|--------|-----|
| Creating out of order | Always create in plan order so keys exist for cross-refs |
| Not substituting placeholders | Replace "Ticket #1" etc. with real keys before creating |
| Printing key without link | Use [KEY](url) format |
| Skipping MCP when available | Prefer Jira MCP first so component/sprint can be set on create |
| Raw markdown in description (acli) | With acli, convert to ADF; use `--from-json` with ADF |
| Forgetting to parse inline formatting (acli) | Split text at **bold**, links, code; apply marks |
| Not offering fallback when creation fails | Offer temp file or retry; honor user choice |
| Leaving `/tmp/jira-workitem.json` behind | Delete after each acli create |
| Reconstructing ticket content from memory | Read from temp files — they are the source of truth |
| Leaving ticket temp files behind | Delete all `/tmp/ticket-N-*.md` files after all tickets are created |
