# Project Settings

Global project settings. Skills like `dev-workflow-initialize` and `write-tickets` check this file when no project-root `.project-settings.md` exists. Only applies to workspaces listed in the Workspaces table.

## Workspaces

| Workspace Directory | Notes |
|---------------------|-------|
| mobile-app | React Native mobile app |

## Projects

### mobile-app

| Field | Value | Notes |
|-------|-------|-------|
| **Target** | `jira` | Create tickets in Jira. |

#### Jira

| Field | Value | Notes |
|-------|-------|-------|
| **Project Key** | RETIRE | JIRA project key |
| **Component** | Consumer | Jira component ID: `17013`. |
| **Sprint** | Mobile Refinement | Custom field: `customfield_10020`. Value: `17210` (sprint ID). |
| **JIRA base URL** | https://gustohq.atlassian.net | For ticket links: `[KEY](https://gustohq.atlassian.net/browse/KEY)`. |

#### Issue Type Mapping

| Ticket Type | Jira Issue Type |
|-------------|-----------------|
| Feature/Story | Story |
| Bug | Bug |
| Tech Debt | Task |
| Spike | Task |

#### MCP additional_fields (when using Jira MCP)

- **components:** `[{"id": "17013"}]`
- **customfield_10020:** `17210` (sprint ID)

#### acli (fallback)

```bash
acli jira workitem edit --key <KEY> --component "Consumer"
acli jira workitem edit --key <KEY> --custom "customfield_10020=17210"
```
