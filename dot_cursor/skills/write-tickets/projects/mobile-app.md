# mobile-app

Use this config when creating JIRA tickets for the **mobile-app** repository.

**Repo:** `guideline-app/mobile-app`  
Full URL: https://github.com/guideline-app/mobile-app/

If the current workspace is this repo (e.g. `git remote get-url origin` contains `guideline-app/mobile-app`), use the fields below automatically. Do not ask the user for project/component/sprint.

## JIRA fields to set

| Field | Value | Notes |
|-------|-------|-------|
| **Project Key** | RETIRE | |
| **Component** | Consumer | Jira component ID: `17013`. Set via `components` array with this ID (MCP) or `acli jira workitem edit --key <KEY> --component "Consumer"`. |
| **Sprint** | Mobile Refinement | Custom field: `customfield_10020`. Value: `17210` (sprint ID). Or use MCP to set active sprint for the board when supported. |
| **JIRA base URL** | https://gustohq.atlassian.net | For ticket links: `[KEY](https://gustohq.atlassian.net/browse/KEY)`. |

## MCP additional_fields (when using Jira MCP)

When calling create issue with additional_fields, include:

- **components:** `[{"id": "17013"}]` or the MCP's equivalent for "Consumer"
- **customfield_10020:** `17210` (Mobile Refinement sprint ID), or use MCP to get the current active sprint ID for the board if available

## acli (fallback)

```bash
acli jira workitem edit --key <KEY> --component "Consumer"
acli jira workitem edit --key <KEY> --custom "customfield_10020=17210"
```

## Rules

- Do NOT ask the user for project/component/sprint when working in the mobile-app repo — use these defaults automatically.
- Sprint field uses `customfield_10020` in the Jira API.
- Component is set via the `components` array (MCP) or `--component "Consumer"` (acli).
