# Publish Settings

Where to create tickets and how to connect to each target. Lookup order: **project root** (`<workspace>/.publish-settings.md`), then **user home** (`~/.publish-settings.md`).

## Publish target

| Field | Value | Notes |
|-------|-------|-------|
| **Target** | `jira` \| `github` \| `jira,github` | Where tickets are created. Use one or both (comma-separated). The write-tickets skill uses this to choose which publish step(s) apply. |

---

## Jira (when target includes `jira`)

| Field | Value | Notes |
|-------|-------|-------|
| **Project Key** | EXAMPLE | JIRA project key |
| **Component** | MyComponent | Component name. Jira component ID: `12345`. |
| **Sprint** | My Sprint | Custom field: `customfield_10020`. Value: `67890` (sprint ID). |
| **JIRA base URL** | https://your-org.atlassian.net | For ticket links: `[KEY](https://your-org.atlassian.net/browse/KEY)`. |

### Issue type mapping

| Ticket Type | JIRA Issue Type |
|-------------|-----------------|
| Feature/Story | Story |
| Bug | Bug |
| Tech Debt | Task |
| Spike | Task |

### MCP additional_fields (when using Jira MCP)

- **components:** `[{"id": "12345"}]`
- **customfield_10020:** `67890` (sprint ID)

### acli (fallback)

```bash
acli jira workitem edit --key <KEY> --component "MyComponent"
acli jira workitem edit --key <KEY> --custom "customfield_10020=67890"
```

---

## GitHub (when target includes `github`)

| Field | Value | Notes |
|-------|-------|-------|
| **Repo** | (optional) | Default: current repo (`gh` uses cwd). Set e.g. `owner/repo` to override. |
| **Type → labels** | (optional) | Map ticket type to GitHub labels. If omitted, use defaults below. |

### Default type → label mapping

| Ticket Type | Label(s) |
|-------------|----------|
| Story / Feature | `story` or `enhancement` |
| Bug | `bug` |
| Task / Tech Debt / Spike | `task` or `tech-debt` / `spike` |

Create missing labels with `gh label create <name> --color <hex>` before publishing, or omit labels to avoid failures.
