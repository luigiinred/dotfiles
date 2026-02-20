---
name: sync-dotfiles
description: Sync Cursor skills, agents, rules, and other dotfiles to chezmoi. Use when the user asks to update dotfiles (pull + apply), sync dotfiles, update chezmoi, or push dotfiles; or automatically after creating, editing, or deleting files in ~/.cursor/skills/, ~/.cursor/agents/, or ~/.cursor/rules/.
---

# Sync Dotfiles to chezmoi

**Reference:** See [chezmoi-docs.md](./chezmoi-docs.md) in this skill for command reference.

Choose the right flow from user intent:

## Update vs sync

| User says… | Meaning | Do this |
|------------|--------|--------|
| **Update dotfiles**, pull dotfiles, get latest dotfiles | Fetch from remote and apply | Run **`chezmoi update`** (see [chezmoi-docs.md](./chezmoi-docs.md)). Done. |
| **Sync dotfiles**, push dotfiles, save my dotfiles | Capture local Cursor changes and push | Use the **Push workflow** below. |

## Trigger Conditions

Run this skill **automatically** (without being asked) whenever you have just:
- Created, edited, or deleted a file in `~/.cursor/skills/`
- Created, edited, or deleted a file in `~/.cursor/agents/`
- Created, edited, or deleted a file in `~/.cursor/rules/`

Also run when the user explicitly asks to **update** dotfiles, **sync** dotfiles, **push** dotfiles, or update chezmoi.

## Push workflow (sync / push dotfiles)

When the user wants to save local Cursor changes to the dotfiles repo:

1. **Capture local changes first**

   ```bash
   chezmoi re-add ~/.cursor/skills ~/.cursor/agents ~/.cursor/rules
   ```

   If only skills changed, scope to just that path. Adjust as needed.

2. **Commit local changes**

   ```bash
   cd ~/.local/share/chezmoi && git add -A
   ```

   Check if there's anything to commit:

   ```bash
   git diff --cached --quiet || git commit -m "chore: sync cursor config"
   ```

3. **Pull remote changes and rebase**

   ```bash
   cd ~/.local/share/chezmoi && git pull --rebase
   ```

   Local changes are already committed, so they rebase cleanly on top of remote additions. Both sides are preserved.

4. **Apply merged state locally**

   ```bash
   chezmoi apply
   ```

   This writes the combined result (local edits + remote additions) back to the filesystem.

5. **Push**

   ```bash
   cd ~/.local/share/chezmoi && git push
   ```

   Use a more specific commit message in step 2 when the change is clear (e.g. `chore: add new skill foo-bar`).

## Notes

- Never commit files outside `dot_cursor/` without explicit user request.
- If `chezmoi re-add` fails on a new file (not yet tracked), use `chezmoi add` instead.
