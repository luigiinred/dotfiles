# JIRA Settings

JIRA configuration for ticket creation in this project.

## Fields

| Field | Value | Notes |
|-------|-------|-------|
| **Project Key** | EXAMPLE | JIRA project key |
| **Component** | MyComponent | Component name. Jira component ID: `12345`. |
| **Sprint** | My Sprint | Custom field: `customfield_10020`. Value: `67890` (sprint ID). |
| **JIRA base URL** | https://your-org.atlassian.net | For ticket links: `[KEY](https://your-org.atlassian.net/browse/KEY)`. |

## Issue Type Mapping

| Ticket Type | JIRA Issue Type |
|-------------|-----------------|
| Feature/Story | Story |
| Bug | Bug |
| Tech Debt | Task |
| Spike | Task |

## MCP additional_fields (when using Jira MCP)

When calling create issue with additional_fields, include:

- **components:** `[{"id": "12345"}]`
- **customfield_10020:** `67890` (sprint ID)

## acli (fallback)

```bash
acli jira workitem edit --key <KEY> --component "MyComponent"
acli jira workitem edit --key <KEY> --custom "customfield_10020=67890"
```
