# PR Description

Use this structure for pull request descriptions. Keep each section concise (1–2 sentences unless multiple distinct changes).

**Output format:** Use the block below. When the description is used for `gh pr create` or a GitHub PR, the caller may wrap it in `[[[` and `]]]` delimiters per repo convention.

---

**jira:** [TICKET-123](link)

Use the ticket ID from the branch (e.g. `RETIRE-456`, `RNDCORE-11727`). Link format:
- Branch starts with `RETIRE`: `https://gustohq.atlassian.net/browse/TICKET`
- Otherwise: `https://internal.guideline.tools/jira/browse/TICKET`

**what:** One sentence or a short bullet list.

Single focused change: one clear sentence (e.g. "Fix null pointer in `TenantTransferPacket#process` when user has no address").

Multiple distinct changes: use bullets, one line per change. Use backticks for code (classes, methods, files).

**why:** Business or technical justification in 1–2 sentences.

Why this change is needed. Reference user impact, bugs, or tech debt being addressed.

**who:** Who is affected (users, teams, or "No user impact" for internal cleanup).

---

## Rules

- No preamble or extra headers outside the block.
- No indentation inside the block.
- Keep what/why/who concise; avoid vague language.
- Use backticks for code references (e.g. `TenantTransferPacket`, `Invoice#generate`).
