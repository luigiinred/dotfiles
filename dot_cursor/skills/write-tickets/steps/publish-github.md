# Step 3 (GitHub): Publish as GitHub Issues

Take the list of finalized ticket markdown from Step 2 (write) and create each as a **GitHub issue** using the **GitHub CLI** (`gh`). Uses the same handoff files as the Jira publish step; choose this step when the user wants tickets as GitHub issues instead of Jira.

## Prerequisites

Read **`/tmp/write-tickets-manifest.json`** — the handoff from Step 2 (Write). It contains an array of finalized tickets, each with `number`, `title`, `type`, and `tempFile` (path to the ticket markdown). Read each temp file when you need its content; do NOT require the content to be passed in memory.

## Workflow

### 1. Resolve config and GitHub CLI

**Optional: `.publish-settings.md`**

1. **Check project root:** Read `<workspace-root>/.publish-settings.md`. If it exists, use it.
2. **Check user home:** If not found, read `~/.publish-settings.md`. If it exists, use it.
3. **If a config file exists:** Parse the **Target** field. If Target does not include `github` (e.g. it is `jira` only), tell the user that GitHub is not configured as a publish target and offer to run the Jira publish step instead, or to add `github` to Target. Otherwise use the **GitHub** section for type→label mapping (and optional repo override). If no config exists, proceed with defaults (current repo, suggested labels below).

**Ensure `gh` is ready:**

1. **Check `gh` is installed and authenticated:**
   ```bash
   gh auth status
   ```
   If not logged in, tell the user to run `gh auth login` and complete the flow; stop until auth succeeds.

2. **Repository:** Issues are created in the **current repository** unless the config **GitHub → Repo** field is set (e.g. `owner/repo`). If the workspace is not a git repo or has no remote, run `gh repo set-default` or have the user `cd` to the target repo. Confirm with the user if they want issues in the current repo.

### 2. Type → Labels

Map ticket `type` from the manifest to GitHub labels. Use the **GitHub** section of `.publish-settings.md` if present; otherwise use:

| Manifest type | Suggested label(s) |
|---------------|--------------------|
| Story / Feature | `story` or `enhancement` |
| Bug | `bug` |
| Task / Tech Debt / Spike | `task` or `tech-debt` / `spike` |

If a label does not exist in the repo, `gh issue create` will fail when you pass `--label`. Create it first with `gh label create "story" --color "..."` or omit labels and create issues with title and body only.

### 3. Maintain a Mapping

Keep a mapping: placeholder → issue URL (e.g. "Ticket #1" → "https://github.com/owner/repo/issues/123"). Use it to substitute placeholders in later tickets' markdown before creating them (so "Depends on Ticket #1" becomes "Depends on [#1](url)").

### 4. For Each Ticket in Order

1. **Read the temp file** for this ticket (e.g. `/tmp/ticket-N-slug.md`). This is the source of truth.

2. **Substitute placeholders in markdown:** Replace "Ticket #1", "Ticket #2", etc. in this ticket's content with the actual issue URLs (or `#1`, `#2` links) from the mapping for tickets already created. Write the substituted content to a **temporary body file** (e.g. `/tmp/gh-body-N.md`) so the body reflects cross-references. If no substitutions are needed, you can use the original temp file as the body.

3. **Create the GitHub issue** with the GitHub CLI:
   ```bash
   gh issue create --title "<ticket title>" --body-file "/tmp/gh-body-N.md"
   ```
   Optionally add labels:
   ```bash
   gh issue create --title "<ticket title>" --body-file "/tmp/gh-body-N.md" --label "story"
   ```
   Use the type→label mapping from above. Multiple labels: `--label "story" --label "priority:high"`.

4. **Parse the output.** `gh issue create` prints the new issue URL (e.g. `https://github.com/owner/repo/issues/42`). Add it to the mapping (e.g. "Ticket #1" → that URL). Confirm: "Created [issue #42](url) (Ticket N of M)."

5. **Clean up the temp body file** if you created one: delete `/tmp/gh-body-N.md`.

6. **If creation fails:** Check `gh auth status` and repo; if the label is missing, retry without that label or create the label. After 2 retries, offer:
   - Write markdown to a temp file for manual paste.
   - Skip this ticket.
   - Try again.

### 5. After All Tickets

1. **Clean up all temp files:**
   - `/tmp/write-tickets-research.md`
   - `/tmp/write-tickets-manifest.json`
   - All `/tmp/ticket-N-*.md` files
   - Any `/tmp/gh-body-N.md` files created for body substitution

2. Report: "All [N] issues created!" with each issue linked (e.g. `[#42](url)`).

## Why This Order?

Tickets are in dependency order. Creating each issue immediately gives you its URL for substituting into the next ticket's markdown (e.g. "Depends on Ticket #1" → "Depends on [#1](url)").

## Strict Rules

- **Always link issue numbers** when confirming: `[#N](issue-url)`.
- **Substitute before create:** Replace "Ticket #N" with actual issue links in the body before creating that issue.
- **Create in order** so the mapping is populated for subsequent tickets.
- **Use `gh` only** for creation — no manual API calls. Prefer `--body-file` so markdown (including newlines and code blocks) is preserved.
- **Read from temp files** — they are the source of truth; do not reconstruct content from memory.
- **Delete all temp files** (research, manifest, ticket markdown, and any gh-body-*.md) after all issues are created.

## Common Mistakes

| Mistake | Fix |
|--------|-----|
| Creating out of order | Always create in plan order so URLs exist for cross-refs |
| Not substituting placeholders | Replace "Ticket #1" etc. with issue links before creating |
| Using non-existent labels | Omit label or create it with `gh label create` first |
| Forgetting --body-file | Use `--body-file <path>` so body is read from file (preserves formatting) |
| Leaving temp files behind | Delete all `/tmp/ticket-N-*.md`, manifest, research, and gh-body-*.md |
| Wrong repo | Ensure `gh` is run in the repo where issues should be created; check with `gh repo view` |
