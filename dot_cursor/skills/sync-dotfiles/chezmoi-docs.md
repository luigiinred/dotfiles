# chezmoi reference (for sync-dotfiles skill)

Quick reference for commands used by this skill. Full docs: <https://chezmoi.io>.

## Paths

| What | Path |
|------|------|
| Source (repo) | `~/.local/share/chezmoi` |
| Cursor managed | `~/.cursor/skills`, `~/.cursor/agents`, `~/.cursor/rules` |

## Commands

### `chezmoi update`

**Use when:** User says "update dotfiles", "pull dotfiles", or wants the latest from remote.

- Runs `git pull --autostash --rebase` in the source directory, then `chezmoi apply`.
- One command to get latest from remote and apply to home directory.
- Does **not** commit or push; only pulls and applies.

```bash
chezmoi update
```

Flags: `--apply` (default true), `--recurse-submodules` (default true). Use `--apply=false` to pull only.

### `chezmoi apply`

Applies the current source state to the home directory. Run after pulling or after editing source files.

```bash
chezmoi apply
```

### `chezmoi re-add` / `chezmoi add`

**Use when:** Capturing local edits (e.g. under `~/.cursor`) back into the source so they can be committed and pushed.

- `chezmoi re-add PATH` — re-import existing tracked paths (updates source from current files).
- `chezmoi add PATH` — add new paths not yet tracked (e.g. new skill folder).

```bash
chezmoi re-add ~/.cursor/skills ~/.cursor/agents ~/.cursor/rules
```

### Git in source directory

Commit and push are done in the source repo, not via chezmoi:

```bash
cd ~/.local/share/chezmoi
git add -A
git diff --cached --quiet || git commit -m "chore: sync cursor config"
git pull --rebase   # if syncing with remote before push
chezmoi apply       # apply merged state
git push
```

## Update vs sync (this skill)

| User intent | Action | Command(s) |
|-------------|--------|------------|
| **Update dotfiles** — get latest from remote | Pull + apply | `chezmoi update` |
| **Sync / push dotfiles** — save my local Cursor changes | Re-add → commit → pull → apply → push | See SKILL.md workflow |
