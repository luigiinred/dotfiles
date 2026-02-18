---
name: sync-dotfiles
description: Sync Cursor skills, agents, and other dotfiles to chezmoi after changes. Use automatically after creating, editing, or deleting files in ~/.cursor/skills/ or ~/.cursor/agents/, or when the user asks to sync dotfiles, update chezmoi, or push dotfiles.
---

# Sync Dotfiles to chezmoi

After any change to managed dotfiles, sync them to chezmoi and push.

## Trigger Conditions

Run this skill **automatically** (without being asked) whenever you have just:
- Created, edited, or deleted a file in `~/.cursor/skills/`
- Created, edited, or deleted a file in `~/.cursor/agents/`

Also run when the user explicitly asks to sync or push dotfiles.

## Workflow

1. **Re-add changed paths**

   ```bash
   chezmoi re-add ~/.cursor/skills ~/.cursor/agents
   ```

   If only skills changed, scope to just that path. Adjust as needed.

2. **Check for actual changes**

   ```bash
   cd ~/.local/share/chezmoi && git status --short
   ```

   If no changes, stop here — nothing to sync.

3. **Commit and push**

   ```bash
   cd ~/.local/share/chezmoi && git add -A && git commit -m "$(cat <<'EOF'
   chore: sync cursor config
   EOF
   )" && git push
   ```

   Use a more specific commit message when the change is clear (e.g. `chore: add new skill foo-bar`).

## Notes

- Never commit files outside `dot_cursor/` without explicit user request.
- If `chezmoi re-add` fails on a new file (not yet tracked), use `chezmoi add` instead.
