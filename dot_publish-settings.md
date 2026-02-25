# Publish Settings

Configuration for publishing tickets to JIRA.

## Workspaces

| Workspace Directory | Notes |
|---------------------|-------|
| mobile-app | React Native mobile app |

## Fields

| Field | Value | Notes |
|-------|-------|-------|
| **Project Key** | RETIRE | JIRA project key |
| **Component** | Consumer | Jira component ID: `17013`. |
| **Sprint** | Mobile Refinement | Custom field: `customfield_10020`. Value: `17210` (sprint ID). |
| **JIRA base URL** | https://gustohq.atlassian.net | For ticket links: `[KEY](https://gustohq.atlassian.net/browse/KEY)`. |

## Issue Type Mapping

| Ticket Type | JIRA Issue Type |
|-------------|-----------------|
| Feature/Story | Story |
| Bug | Bug |
| Tech Debt | Task |
| Spike | Task |

## MCP additional_fields (when using Jira MCP)

When calling create issue with additional_fields, include:

- **components:** `[{"id": "17013"}]`
- **customfield_10020:** `17210` (sprint ID)

## acli (fallback)

```bash
acli jira workitem edit --key <KEY> --component "Consumer"
acli jira workitem edit --key <KEY> --custom "customfield_10020=17210"
```
