# chezmoi reference (for sync-dotfiles skill)

Quick reference for every chezmoi command this skill uses. Each command below links to the official reference.

## Paths

| What | Path |
|------|------|
| Source (repo) | `~/.local/share/chezmoi` |
| Cursor managed | `~/.cursor/skills`, `~/.cursor/agents`, `~/.cursor/rules` |

## Commands

### `chezmoi update`

**Reference:** <https://chezmoi.io/reference/commands/update/>

**Use when:** User says "update dotfiles", "pull dotfiles", or wants the latest from remote.

- Runs `git pull --autostash --rebase` in the source directory, then `chezmoi apply`.
- One command to get latest from remote and apply to home directory.
- Does **not** commit or push; only pulls and applies.

```bash
chezmoi update
```

Flags: `-a, --apply` (default true), `--recurse-submodules` (default true). Use `--apply=false` to pull only.

### `chezmoi apply`

**Reference:** <https://chezmoi.io/reference/commands/apply/>

Applies the current source state to the home directory. Run after pulling or after editing source files.

```bash
chezmoi apply
```

### `chezmoi re-add` / `chezmoi add`

**Reference:** [re-add](https://chezmoi.io/reference/commands/re-add/), [add](https://chezmoi.io/reference/commands/add/)

**Use when:** Capturing local edits (e.g. under `~/.cursor`) back into the source so they can be committed and pushed.

- `chezmoi re-add PATH` — re-import existing tracked paths (updates source from current files).
- `chezmoi add PATH` — add new paths not yet tracked (e.g. new skill folder).

```bash
chezmoi re-add ~/.cursor/skills ~/.cursor/agents ~/.cursor/rules
```

### `chezmoi git [args...]`

**Reference:** <https://chezmoi.io/reference/commands/git/>

Runs git in the source directory. Use this for all git operations; do not `cd` to the source or run `git` directly. Put `--` before git flags (e.g. `-m`, `--rebase`) so chezmoi doesn’t interpret them.

```bash
chezmoi git add -A
chezmoi git -- commit -m "chore: sync cursor config"
chezmoi git -- pull --rebase
chezmoi git push
```

Examples with flags: `chezmoi git -- diff --cached --quiet`, `chezmoi git -- commit -m "message"`.

## Update vs sync (this skill)

| User intent | Action | Command(s) |
|-------------|--------|------------|
| **Update dotfiles** — get latest from remote | Pull + apply | `chezmoi update` |
| **Sync / push dotfiles** — save my local Cursor changes | Re-add → `chezmoi git` add/commit → `chezmoi git pull --rebase` → `chezmoi apply` → `chezmoi git push` | See SKILL.md workflow |
