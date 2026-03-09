---
name: cleanup-android-emulators
description: Delete all Android emulators created by the build-android-app skill. Finds AVDs matching the {project}_{branch} naming convention, shuts down any that are running, and deletes them. Use when the user says "cleanup emulators", "delete emulators", "remove avds", or "clean up android emulators".
---

# Cleanup Android Emulators

Remove all AVDs that follow the `{project}_{branch}` naming convention used by the build-android-app skill.

## Step 1: List matching AVDs

AVDs created by the build-android-app skill are named `{project}_{branch}`, where `project` comes from the git remote. Non-matching AVDs (e.g. ones created manually in Android Studio) are left untouched.

```bash
PROJECT=$(git remote get-url origin 2>/dev/null | sed 's/.*\///' | sed 's/\.git$//')

if [ -z "$PROJECT" ]; then
  echo "ERROR: Not in a git repo. Run from a project directory to derive the project name."
  exit 1
fi

PREFIX="${PROJECT}_"
ALL_AVDS=$($ANDROID_HOME/emulator/emulator -list-avds 2>/dev/null)
MATCHING_AVDS=$(echo "$ALL_AVDS" | grep "^${PREFIX}")

if [ -z "$MATCHING_AVDS" ]; then
  echo "No AVDs matching '${PREFIX}*' found. Nothing to clean up."
  exit 0
fi

echo "AVDs matching '${PREFIX}*':"
echo "$MATCHING_AVDS"
echo ""
echo "AVDs that will NOT be touched:"
echo "$ALL_AVDS" | grep -v "^${PREFIX}" || echo "  (none)"
```

Show this output to the user and confirm before proceeding.

## Step 2: Shut down running emulators

Before deleting, shut down any matching AVDs that are currently running. Never shut down non-matching emulators.

```bash
for SERIAL in $(adb devices | grep 'emulator-' | awk '{print $1}'); do
  AVD_ON_SERIAL=$(adb -s "$SERIAL" emu avd name 2>/dev/null | head -1 | tr -d '\r')
  if echo "$MATCHING_AVDS" | grep -qx "$AVD_ON_SERIAL"; then
    echo "Shutting down '$AVD_ON_SERIAL' on $SERIAL..."
    adb -s "$SERIAL" emu kill 2>/dev/null
    sleep 1
  fi
done
```

## Step 3: Delete AVDs

```bash
for AVD in $MATCHING_AVDS; do
  echo "Deleting AVD '$AVD'..."
  $ANDROID_HOME/cmdline-tools/latest/bin/avdmanager delete avd -n "$AVD" 2>&1
done

echo ""
echo "Cleanup complete. Remaining AVDs:"
$ANDROID_HOME/emulator/emulator -list-avds 2>/dev/null || echo "  (none)"
```
