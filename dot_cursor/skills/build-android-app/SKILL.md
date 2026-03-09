---
name: build-android-app
description: Build, install, and launch an Android app on an emulator after code changes. Auto-detects Gradle wrapper, build variant, application ID, and emulator. Use after making code changes to verify compilation, when the user says "build the app", "run the app", "launch on emulator", or when a workspace rule says to build after changes.
---

# Build Android App on Emulator

After making code changes, build and launch the app on an Android Emulator to verify compilation.

## Step 1: Detect Project Settings

Run these commands to discover project configuration. Cache the results for the session.

### Find Gradle wrapper

```bash
if [ -f "./gradlew" ]; then
  GRADLE_CMD="./gradlew"
elif [ -f "../gradlew" ]; then
  GRADLE_CMD="../gradlew"
else
  echo "ERROR: No gradlew found. Ensure you are in the project root."
  exit 1
fi
echo "GRADLE_CMD: $GRADLE_CMD"
```

### Find build variant

```bash
# List available build variants from the app module
$GRADLE_CMD :app:tasks --group=build 2>/dev/null | grep -oP 'assemble\K[A-Z][a-zA-Z]+' | sort -u
```

Pick the debug variant for local development. Prefer `internalDebug` if available (common for apps with internal/production flavors), otherwise fall back to `debug`.

Store the result as `BUILD_VARIANT` (e.g. `internalDebug`). Derive the Gradle task as `assemble${BUILD_VARIANT}` (e.g. `assembleInternalDebug`).

### Find application ID

```bash
$GRADLE_CMD :app:properties 2>/dev/null | grep 'applicationId' | head -1 | awk '{print $NF}'
```

If that doesn't return results, parse `app/build.gradle` or `app/build.gradle.kts`:

```bash
grep -E 'applicationId\s' app/build.gradle* 2>/dev/null | head -1 | grep -oP '"[^"]+"' | tr -d '"'
```

For flavored builds, the application ID may have a suffix. Check the flavor block for `applicationIdSuffix` to get the full ID.

Store the result as `APP_ID`.

### Find emulator (project-branch naming convention)

Emulators are named `{project}_{git_branch}`, where `project` is derived from the git remote URL and `git_branch` is the current git branch. Underscores replace characters that are invalid in AVD names. This ensures each project+branch combination has its own isolated emulator.

```bash
PROJECT=$(git remote get-url origin | sed 's/.*\///' | sed 's/\.git$//')
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
# AVD names only allow alphanumeric, hyphens, underscores, and dots
AVD_NAME=$(echo "${PROJECT}_${GIT_BRANCH}" | sed 's/[^a-zA-Z0-9._-]/_/g')
echo "AVD_NAME: $AVD_NAME"
```

Check if the emulator exists. If not, create it using a recent Pixel device and the latest installed system image:

```bash
AVD_EXISTS=$($ANDROID_HOME/emulator/emulator -list-avds 2>/dev/null | grep -x "$AVD_NAME")

if [ -z "$AVD_EXISTS" ]; then
  # Find latest installed system image (prefer google_apis x86_64)
  SYSTEM_IMAGE=$(sdkmanager --list_installed 2>/dev/null | grep 'system-images' | grep 'google_apis' | grep -v 'google_apis_playstore' | tail -1 | awk '{print $1}')

  if [ -z "$SYSTEM_IMAGE" ]; then
    # Fall back to any available system image
    SYSTEM_IMAGE=$(sdkmanager --list_installed 2>/dev/null | grep 'system-images' | tail -1 | awk '{print $1}')
  fi

  if [ -z "$SYSTEM_IMAGE" ]; then
    echo "ERROR: No system images installed. Install one via Android Studio SDK Manager or:"
    echo "  sdkmanager 'system-images;android-35;google_apis;x86_64'"
    exit 1
  fi

  echo "Creating AVD '$AVD_NAME' with system image $SYSTEM_IMAGE"
  echo "no" | avdmanager create avd -n "$AVD_NAME" -k "$SYSTEM_IMAGE" -d "pixel_6"
  echo "Created: $AVD_NAME"
else
  echo "AVD '$AVD_NAME' already exists"
fi
```

### Boot emulator

```bash
# Check if an emulator is already running
RUNNING_SERIAL=$(adb devices | grep emulator | head -1 | awk '{print $1}')

if [ -z "$RUNNING_SERIAL" ]; then
  # Launch emulator in background
  nohup $ANDROID_HOME/emulator/emulator -avd "$AVD_NAME" -no-snapshot-load &>/dev/null &
  echo "Booting emulator '$AVD_NAME'..."

  # Wait for device to come online
  adb wait-for-device
  # Wait for boot to complete
  while [ "$(adb shell getprop sys.boot_completed 2>/dev/null)" != "1" ]; do
    sleep 2
  done
  echo "Emulator booted"
  DEVICE_SERIAL=$(adb devices | grep emulator | head -1 | awk '{print $1}')
else
  echo "Emulator already running: $RUNNING_SERIAL"
  DEVICE_SERIAL="$RUNNING_SERIAL"
fi
echo "DEVICE_SERIAL: $DEVICE_SERIAL"
```

If a physical device is connected and preferred, use its serial instead. List devices with `adb devices`.

## Step 2: Build

```bash
# Stop the running app first — hot-swap may conflict with a fresh install
adb -s "$DEVICE_SERIAL" shell am force-stop "$APP_ID" 2>/dev/null

$GRADLE_CMD :app:assemble${BUILD_VARIANT}
```

If build fails, fix compilation errors before proceeding.

For faster incremental builds, Gradle's build cache is enabled by default. If you suspect a stale cache, add `--no-build-cache` to the build command.

## Step 3: Install and Launch

```bash
# Find the APK — path depends on flavor/build type
APK_PATH=$(find app/build/outputs/apk -name "*.apk" -path "*/${BUILD_VARIANT}/*" 2>/dev/null | head -1)

if [ -z "$APK_PATH" ]; then
  # Broader search if variant directory structure differs
  APK_PATH=$(find app/build/outputs/apk -name "*.apk" | head -1)
fi

echo "Installing: $APK_PATH"
adb -s "$DEVICE_SERIAL" install -r "$APK_PATH"

# Find the launcher activity
LAUNCHER_ACTIVITY=$(aapt dump badging "$APK_PATH" 2>/dev/null | grep 'launchable-activity' | grep -oP "name='[^']+'" | head -1 | grep -oP "'[^']+'" | tr -d "'")

if [ -z "$LAUNCHER_ACTIVITY" ]; then
  # Fall back: launch via monkey (opens the default launcher activity)
  adb -s "$DEVICE_SERIAL" shell monkey -p "$APP_ID" -c android.intent.category.LAUNCHER 1
else
  adb -s "$DEVICE_SERIAL" shell am start -n "$APP_ID/$LAUNCHER_ACTIVITY"
fi
```

## Workspace Rule Override

If the project has a `.cursor/rules/build-and-run-verification.mdc` workspace rule with hardcoded values (build variant, application ID, Gradle task), prefer those values over auto-detection for those specific settings. The workspace rule is authoritative for that project. The emulator naming convention (`{project}_{git_branch}`, where project comes from the git remote) always applies regardless of workspace rule.

## Troubleshooting

- **No emulator found**: Run `$ANDROID_HOME/emulator/emulator -list-avds` and check naming. Ensure `ANDROID_HOME` or `ANDROID_SDK_ROOT` is set.
- **No system images**: Install via `sdkmanager 'system-images;android-35;google_apis;x86_64'` or use Android Studio SDK Manager.
- **Build fails with SDK errors**: Ensure `local.properties` has the correct `sdk.dir` path or `ANDROID_HOME` is set.
- **APK not found**: Check `app/build/outputs/apk/` for the correct variant directory structure.
- **App won't launch**: Verify `APP_ID` matches the flavor's application ID. Check `adb logcat` for crash logs.
- **Gradle daemon issues**: Run `$GRADLE_CMD --stop` to kill stale daemons, then rebuild.
- **Emulator won't boot**: Try `emulator -avd "$AVD_NAME" -wipe-data` to reset the emulator, or delete and recreate the AVD.
- **Multiple devices**: If both emulator and physical device are connected, specify the target with `-s $DEVICE_SERIAL` on all `adb` commands.
