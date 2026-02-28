# Step 3: Publish

Take the list of finalized ticket markdown from Step 2 (write) and create each in the target system (GitHub Issues or Jira). Runs in plan order so keys/numbers are available for cross-references in later tickets.

## Prerequisites

Read **`/tmp/write-tickets-manifest.json`** — this is the handoff file from Step 2 (Write). It contains an array of finalized tickets, each with `number`, `title`, `type`, and `tempFile` (path to the ticket markdown). Read each temp file when you need its content — do NOT require the content to be passed in memory.

## Workflow

### 1. Resolve Publish Settings

Do this first, before creating any tickets.

**Resolve `.publish-settings.md`:**

1. **Check project root:** Read `<workspace-root>/.publish-settings.md`. If it exists, use it.
2. **Check user home:** If not found, read `~/.publish-settings.md`. If it exists, check the **Workspaces** table for the current workspace directory name (the basename of the workspace root, e.g. `mobile-app`). If the current workspace is listed, use it. If the workspace is **not** listed, treat it as not found and continue to step 3.
3. **If no matching settings found:** Use AskQuestion to prompt the user:

   ```
   AskQuestion({
     "title": "No publish settings found",
     "questions": [{
       "id": "publish_settings",
       "prompt": "No .publish-settings.md found for this project. How should I get publish config?",
       "options": [
         {"id": "create_project", "label": "Create .publish-settings.md in this project"},
         {"id": "create_home", "label": "Create ~/.publish-settings.md (global)"},
         {"id": "add_workspace", "label": "Add this workspace to existing ~/.publish-settings.md"},
         {"id": "manual", "label": "Specify manually (don't save)"}
       ]
     }]
   })
   ```

   - **"Create in project" or "Create in home":** Ask the user for the target system (GitHub or Jira) and required fields. Read this skill's `templates/publish-settings.md` for the template, fill in the user's values, and write to the chosen location. Then use it.
   - **"Add this workspace":** Read `~/.publish-settings.md`, add the current workspace directory name to the Workspaces table, and write it back. Then use it.
   - **"Specify manually":** Ask for target and required fields inline. Do not save to disk.

**After resolving settings, determine the target:**

- **Target = `github`** → Follow the **GitHub Issues** path below.
- **Target = `jira`** → Follow the **Jira** path below.

### 2. Maintain a Key/Number Mapping

Keep a mapping: placeholder → actual key/number (e.g. "Ticket #1" → "#5" for GitHub, or "Ticket #1" → "RETIRE-1115" for Jira). Use it to substitute placeholders in later tickets and when confirming created tickets.

### 3. For Each Ticket in Order

1. **Read the temp file** for this ticket (e.g. `/tmp/ticket-N-slug.md`). This is the source of truth — the user may have edited it during Step 2.

2. **Substitute placeholders in markdown:** Replace "Ticket #1", "Ticket #2", etc. in this ticket's markdown with the actual keys/numbers from the mapping (for tickets already created).

3. **Create the ticket** using the appropriate target path:

---

#### GitHub Issues Path

**Required fields from publish settings:**
- **Repo** — GitHub repo (default: current repo from `git remote get-url origin`). Format: `owner/repo`.
- **Type → labels** (optional) — maps ticket types to GitHub labels (e.g. `Story → enhancement`, `Bug → bug`).

**3a. Build the `gh issue create` command:**

```bash
gh issue create \
  --repo [REPO] \
  --title "[TICKET_TITLE]" \
  --body "$(cat /tmp/ticket-N-slug.md)" \
  --label "[LABEL]"
```

- `--label` is optional; include only if the publish settings define a type-to-label mapping for this ticket's type.
- The body is the raw markdown from the temp file (GitHub renders markdown natively).

**3b. Parse the output** for the issue URL. Extract the issue number from the URL (e.g. `https://github.com/owner/repo/issues/5` → `#5`).

**3c. Add to mapping** and confirm: "Created [#N](url) (Ticket N of M)."

---

#### Jira Path

**Required fields from publish settings:**
- **Project Key** — Jira project key
- **Component** — Component name and ID
- **Sprint** — Sprint custom field and ID
- **JIRA base URL** — For ticket links

**Prefer the Jira MCP** when available (so you can set component, current sprint, and other fields directly); fall back to `acli` if MCP is not configured or creation fails.

**Option A — Prefer: Jira MCP**

- Call the MCP's **create issue** tool with: `cloudId`, `projectKey`, `issueTypeName` (Story/Bug/Task/Improvement), `summary` (ticket title), `description` (markdown).
- Use **additional_fields** to set **component** and **sprint** on create.
- Parse the response for the new issue key; add it to the mapping and confirm. If the MCP call fails, retry once; if it still fails, fall back to Option B.

**Option B — Fallback: acli**

**3a. Check auth:** `acli jira auth status`. If not authenticated, tell the user to run `acli jira auth login --web`.

**3b. Convert markdown to ADF.** The description field MUST be ADF when using acli — raw markdown will not render in Jira.

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

**3c. Build workitem JSON** and write to `/tmp/jira-workitem.json`:

```json
{
  "projectKey": "<project key>",
  "type": "Story|Bug|Task|Improvement",
  "summary": "<ticket title>",
  "description": { ... ADF object ... }
}
```

**3d. Create:** `acli jira workitem create --from-json /tmp/jira-workitem.json`

Parse the output to extract the Jira key. If it fails after 2 retries → go to Fallback.

**3e. Set component and sprint** (from publish settings):

```bash
acli jira workitem edit --key <KEY> --component "<Component>"
acli jira workitem edit --key <KEY> --custom "customfield_10020=<sprint-id>"
```

**3f. Clean up:** Delete `/tmp/jira-workitem.json`.

**3g. Add key to mapping** and confirm: "Created [KEY](jira-base-url/browse/KEY) (Ticket N of M)."

---

4. **Fallback if creation failed (any target):** Offer:

   ```
   AskQuestion({
     "title": "Ticket Creation Failed",
     "questions": [{
       "id": "fallback",
       "prompt": "Failed to create ticket. Write markdown to a temp file for manual paste?",
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

1. **Clean up all temp files:** Delete these files — they are no longer needed:
   - `/tmp/write-tickets-research.md` (Step 1 handoff)
   - `/tmp/write-tickets-manifest.json` (Step 2 handoff)
   - All `/tmp/ticket-N-*.md` files (ticket markdown from Step 2)
2. "All [N] tickets created!" with each key/number as a link.

## Why This Order?

Tickets are in dependency order (prerequisites first). Creating each ticket immediately gives you its key/number for substituting into the next ticket's markdown (e.g. "Depends on #5" for GitHub or "Depends on RETIRE-1115" for Jira).

## Strict Rules

- **Always link ticket keys/numbers** when confirming:
  - GitHub: `[#N](https://github.com/owner/repo/issues/N)`
  - Jira: `[KEY](jira-base-url/browse/KEY)`
- **Substitute before create:** Replace "Ticket #N" with actual keys/numbers in markdown before creating that ticket.
- **Create in order** so the mapping is populated for subsequent tickets.
- **GitHub:** Use `gh issue create` with raw markdown body. No ADF conversion needed.
- **Jira with acli:** Use ADF for descriptions (raw markdown will not render). Parse `**bold**`, `[links](url)`, `` `code` `` into proper ADF nodes and marks. Clean up `/tmp/jira-workitem.json` after each create.
- **Jira with MCP:** Prefer setting component and current sprint in the create call via additional_fields.
- **Never use a jira-expert subagent** for creation — do it inline in this step.

## Common Mistakes

| Mistake | Fix |
|--------|-----|
| Creating out of order | Always create in plan order so keys exist for cross-refs |
| Not substituting placeholders | Replace "Ticket #1" etc. with real keys/numbers before creating |
| Printing key without link | Use [KEY](url) or [#N](url) format |
| Using Jira path for GitHub target | Check the Target field from publish settings first |
| Raw markdown in Jira description (acli) | With acli, convert to ADF; use `--from-json` with ADF |
| Forgetting to parse inline formatting (acli) | Split text at **bold**, links, code; apply marks |
| Not offering fallback when creation fails | Offer temp file or retry; honor user choice |
| Leaving `/tmp/jira-workitem.json` behind | Delete after each acli create |
| Reconstructing ticket content from memory | Read from temp files — they are the source of truth |
| Leaving ticket temp files behind | Delete all `/tmp/ticket-N-*.md` files after all tickets are created |
