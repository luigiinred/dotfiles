# Publish Settings

Configuration for publishing tickets to a target system (GitHub Issues or Jira).

The `Target` field determines which system tickets are created in. Each target has its own required fields.

## Workspaces

Maps workspace directory names to confirm this config applies. Only used in the global `~/.publish-settings.md` — project-root files apply automatically.

| Workspace Directory | Notes |
|---------------------|-------|
| my-project | Example project |

## Projects

Each project block has a `### Name` heading matching the repo name or workspace directory.

---

### ExampleGitHubProject

| Field | Value | Notes |
|-------|-------|-------|
| **Target** | `github` | Create tickets as GitHub issues. |

#### GitHub

| Field | Value |
|-------|-------|
| **Repo** | *(optional; default: current repo from `git remote get-url origin`)* |
| **Type → labels** | *(optional; e.g. Story → enhancement, Bug → bug, Task/Spike → task)* |

---

### ExampleJiraProject

| Field | Value | Notes |
|-------|-------|-------|
| **Target** | `jira` | Create tickets in Jira. |

#### Jira

| Field | Value | Notes |
|-------|-------|-------|
| **Project Key** | EXAMPLE | Jira project key |
| **Component** | MyComponent | Component name. Jira component ID: `12345`. |
| **Sprint** | My Sprint | Custom field: `customfield_10020`. Value: `67890` (sprint ID). |
| **JIRA base URL** | https://your-org.atlassian.net | For ticket links: `[KEY](https://your-org.atlassian.net/browse/KEY)`. |

#### Issue Type Mapping

| Ticket Type | Jira Issue Type |
|-------------|-----------------|
| Feature/Story | Story |
| Bug | Bug |
| Tech Debt | Task |
| Spike | Task |

#### MCP additional_fields (when using Jira MCP)

When calling create issue with additional_fields, include:

- **components:** `[{"id": "12345"}]`
- **customfield_10020:** `67890` (sprint ID)

#### acli (fallback)

```bash
acli jira workitem edit --key <KEY> --component "MyComponent"
acli jira workitem edit --key <KEY> --custom "customfield_10020=67890"
```
