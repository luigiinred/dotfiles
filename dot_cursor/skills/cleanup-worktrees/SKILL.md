---
name: cleanup-worktrees
description: List and remove old git worktrees sorted by last activity. Shows when each worktree was last touched and lets the user pick which ones to remove. Also cleans up the associated local branch and AVD emulator if one exists. Use when the user says "cleanup worktrees", "remove worktrees", "delete old worktrees", "clean up branches", or "list worktrees".
---

# Cleanup Worktrees

List all git worktrees sorted by last activity, and interactively remove stale ones.

## Step 1: List worktrees with last-touched time

Worktrees live at `../worktrees/[PROJECT_NAME]/[BRANCH_NAME]` per the worktree-manager skill. The main worktree is always excluded from cleanup.

```bash
PROJECT_NAME=$(basename "$(git rev-parse --show-toplevel)")
WORKTREES_DIR="$(git rev-parse --show-toplevel)/../worktrees/${PROJECT_NAME}"

echo "=== Worktrees for ${PROJECT_NAME} ==="
echo ""
printf "%-40s %-20s %s\n" "BRANCH" "LAST TOUCHED" "PATH"
printf "%-40s %-20s %s\n" "------" "------------" "----"

git worktree list --porcelain | grep '^worktree ' | sed 's/^worktree //' | while read -r WT_PATH; do
  # Skip the main worktree
  MAIN=$(git rev-parse --show-toplevel)
  if [ "$WT_PATH" = "$MAIN" ]; then
    continue
  fi

  # Get branch name
  BRANCH=$(git worktree list | grep "^${WT_PATH} " | awk '{print $NF}' | tr -d '[]')

  # Find last modification time (most recently modified file in the worktree)
  if [ -d "$WT_PATH" ]; then
    LAST_MODIFIED=$(find "$WT_PATH" -maxdepth 3 -not -path '*/build/*' -not -path '*/node_modules/*' -not -path '*/.gradle/*' -not -path '*/.git/*' -type f -exec stat -f '%m %Sm' -t '%Y-%m-%d %H:%M' {} + 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
  else
    LAST_MODIFIED="(directory missing)"
  fi

  printf "%-40s %-20s %s\n" "$BRANCH" "$LAST_MODIFIED" "$WT_PATH"
done | sort -t$'\t' -k2
```

Present this table to the user.

## Step 2: Ask which to remove

Use the AskQuestion tool:

- Title: "Worktree Cleanup"
- Question: "Which worktrees would you like to remove?"
- Options: one per worktree showing `{branch} (last touched {date})`, plus "Cancel"
- `allow_multiple: true`

If no worktrees exist besides main, report that and stop.

## Step 3: Remove selected worktrees

For each selected worktree:

### 3a. Shut down and delete associated AVD emulator (if any)

The build-android-app skill creates AVDs named `{project}_{branch}`. Check if one exists and clean it up.

```bash
AVD_NAME=$(echo "${PROJECT_NAME}_${BRANCH}" | sed 's/[^a-zA-Z0-9._-]/_/g')

# Check if this AVD exists
if $ANDROID_HOME/emulator/emulator -list-avds 2>/dev/null | grep -qx "$AVD_NAME"; then
  # Shut down if running
  for SERIAL in $(adb devices | grep 'emulator-' | awk '{print $1}'); do
    AVD_ON_SERIAL=$(adb -s "$SERIAL" emu avd name 2>/dev/null | head -1 | tr -d '\r')
    if [ "$AVD_ON_SERIAL" = "$AVD_NAME" ]; then
      echo "  Shutting down emulator '$AVD_NAME' on $SERIAL..."
      adb -s "$SERIAL" emu kill 2>/dev/null
      sleep 1
    fi
  done

  echo "  Deleting AVD '$AVD_NAME'..."
  $ANDROID_HOME/cmdline-tools/latest/bin/avdmanager delete avd -n "$AVD_NAME" 2>&1
fi
```

### 3b. Remove the worktree

```bash
echo "Removing worktree at $WT_PATH..."
git worktree remove "$WT_PATH" --force 2>&1
```

### 3c. Delete the local branch (if merged)

```bash
# Try safe delete first (only if merged)
git branch -d "$BRANCH" 2>/dev/null

if [ $? -ne 0 ]; then
  echo "  Branch '$BRANCH' is not fully merged. Skipping branch deletion."
  echo "  To force-delete: git branch -D $BRANCH"
fi
```

## Step 4: Summary

```bash
echo ""
echo "=== Cleanup Complete ==="
echo "Removed worktrees: [list]"
echo "Deleted AVDs: [list]"
echo "Deleted branches: [list]"
echo ""
echo "Remaining worktrees:"
git worktree list
```

## Notes

- The main worktree is never listed for removal.
- Unmerged branches are not force-deleted — the user is informed and can do it manually.
- AVD cleanup is best-effort; if `avdmanager` or `ANDROID_HOME` is not available, skip silently and note it in the summary.
- iOS simulators follow a similar naming convention (`{project} - {branch}`). If `xcrun simctl` is available, also clean up matching simulators using: `xcrun simctl delete "$SIM_UDID"`.
