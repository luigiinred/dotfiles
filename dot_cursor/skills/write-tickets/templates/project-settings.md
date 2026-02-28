# Project Settings

Project-level configuration that controls how dev-workflow-initialize, write-tickets, and other skills behave for this repo.

The `Target` field determines whether tickets are created as GitHub Issues or Jira tickets.

---

## Example: GitHub project

```markdown
# Project Settings

## Projects

### my-app

| Field | Value | Notes |
|-------|-------|-------|
| **Target** | `github` | Create tickets as GitHub issues. |

#### GitHub

| Field | Value |
|-------|-------|
| **Repo** | *(optional; default: current repo)* |
| **Type → labels** | Story → enhancement, Bug → bug, Task → task |
```

## Example: Jira project

```markdown
# Project Settings

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
| **Project Key** | PROJ | Jira project key |
| **Component** | MyComponent | Jira component ID: `12345`. |
| **Sprint** | My Sprint | Custom field: `customfield_10020`. Value: `67890` (sprint ID). |
| **JIRA base URL** | https://your-org.atlassian.net | For ticket links. |

#### Issue Type Mapping

| Ticket Type | Jira Issue Type |
|-------------|-----------------|
| Feature/Story | Story |
| Bug | Bug |
| Tech Debt | Task |
| Spike | Task |

#### MCP additional_fields (when using Jira MCP)

- **components:** `[{"id": "12345"}]`
- **customfield_10020:** `67890` (sprint ID)

#### acli (fallback)

\```bash
acli jira workitem edit --key <KEY> --component "MyComponent"
acli jira workitem edit --key <KEY> --custom "customfield_10020=67890"
\```
```

## File locations

| Location | When to use |
|----------|-------------|
| `<workspace-root>/.project-settings.md` | Project-specific (checked first). Applies automatically when working in this repo. |
| `~/.project-settings.md` | Global fallback. Only used if the Workspaces table includes the current workspace directory name. |

## Required fields

| Target | Required fields |
|--------|----------------|
| `github` | Target |
| `jira` | Target, Project Key, JIRA base URL |

All other fields are optional with sensible defaults (repo from git remote, no labels, etc.).
