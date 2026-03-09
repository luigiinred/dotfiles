---
name: build-ios-app
description: Build, install, and launch an iOS app on the Simulator after code changes. Auto-detects project file, scheme, bundle ID, and simulator. Use after making code changes to verify compilation, when the user says "build the app", "run the app", "launch on simulator", or when a workspace rule says to build after changes.
---

# Build iOS App on Simulator

After making code changes, build and launch the app on the iOS Simulator to verify compilation.

## Step 1: Detect Project Settings

Run these commands to discover project configuration. Cache the results for the session.

### Find project file

```bash
# Prefer .xcworkspace (CocoaPods/SPM), fall back to .xcodeproj
WORKSPACE=$(ls -d *.xcworkspace 2>/dev/null | head -1)
if [ -n "$WORKSPACE" ]; then
  PROJECT_FLAG="-workspace $WORKSPACE"
else
  XCODEPROJ=$(ls -d *.xcodeproj 2>/dev/null | head -1)
  PROJECT_FLAG="-project $XCODEPROJ"
fi
echo "PROJECT_FLAG: $PROJECT_FLAG"
```

### Find scheme

```bash
# List schemes and pick the first non-test, non-UI-test scheme
xcodebuild $PROJECT_FLAG -list -json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
key = 'workspace' if 'workspace' in data else 'project'
schemes = data[key]['schemes']
# Prefer schemes that aren't test targets
app_schemes = [s for s in schemes if 'Test' not in s and 'test' not in s]
print(app_schemes[0] if app_schemes else schemes[0])
"
```

Store the result as `SCHEME`.

### Find bundle identifier

```bash
xcodebuild $PROJECT_FLAG -scheme $SCHEME -showBuildSettings 2>/dev/null \
  | grep 'PRODUCT_BUNDLE_IDENTIFIER' | head -1 | awk '{print $NF}'
```

Store the result as `BUNDLE_ID`.

### Find simulator (project-branch naming convention)

Simulators are named `{project} - {git_branch}`, where `project` is derived from the git remote URL and `git_branch` is the current git branch. This ensures each project+branch combination has its own isolated simulator.

```bash
PROJECT=$(git remote get-url origin | sed 's/.*\///' | sed 's/\.git$//')
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
SIM_NAME="${PROJECT} - ${GIT_BRANCH}"
echo "SIM_NAME: $SIM_NAME"
```

Check if the simulator exists. If not, create it using the latest available iPhone Pro device type and iOS runtime:

```bash
SIM_EXISTS=$(xcrun simctl list devices available | grep "$SIM_NAME" | head -1)

if [ -z "$SIM_EXISTS" ]; then
  # Pick the latest iPhone Pro device type
  DEVICE_TYPE=$(xcrun simctl list devicetypes | grep "iPhone.*Pro (" | head -1 | sed 's/.*(\(.*\))/\1/')
  # Pick the latest iOS runtime
  RUNTIME=$(xcrun simctl list runtimes available | grep "iOS" | tail -1 | sed 's/.*(\(.*\))/\1/')

  echo "Creating simulator '$SIM_NAME' with device type $DEVICE_TYPE and runtime $RUNTIME"
  SIM_UDID=$(xcrun simctl create "$SIM_NAME" "$DEVICE_TYPE" "$RUNTIME")
  echo "Created: $SIM_UDID"
else
  echo "Simulator '$SIM_NAME' already exists"
fi
```

Get the UDID for use in subsequent commands:

```bash
DEVICE_UDID=$(xcrun simctl list devices available | grep "$SIM_NAME" | head -1 | grep -oE '[0-9A-F-]{36}')
echo "DEVICE_UDID: $DEVICE_UDID"
```

## Step 2: Build

```bash
# Terminate any running instance first — the build may fail if the binary is in use
xcrun simctl terminate "$DEVICE_UDID" "$BUNDLE_ID" 2>/dev/null

xcodebuild $PROJECT_FLAG -scheme "$SCHEME" -configuration Debug \
  -destination "platform=iOS Simulator,id=$DEVICE_UDID" \
  -derivedDataPath ./build build
```

If build fails, fix compilation errors before proceeding.

## Step 3: Install and Launch

```bash
# Boot simulator if needed
xcrun simctl boot "$DEVICE_UDID" 2>/dev/null
open -a Simulator

# Find the .app bundle
APP_PATH=$(find ./build/Build/Products/Debug-iphonesimulator -name "*.app" -maxdepth 1 | head -1)

xcrun simctl install "$DEVICE_UDID" "$APP_PATH"
xcrun simctl launch "$DEVICE_UDID" "$BUNDLE_ID"
```

## Workspace Rule Override

If the project has a `.cursor/rules/build-and-run-verification.mdc` workspace rule with hardcoded values (workspace, scheme, bundle ID), prefer those values over auto-detection for those specific settings. The workspace rule is authoritative for that project. The simulator naming convention (`{project} - {git_branch}`, where project comes from the git remote) always applies regardless of workspace rule.

## Troubleshooting

- **No simulator found**: Run `xcrun simctl list devices available` and check naming.
- **Signing errors**: Open the `.xcodeproj` in Xcode and fix Signing & Capabilities.
- **Scheme not found**: Run `xcodebuild -list` to see available schemes and use the correct one.
- **App won't launch**: Verify `BUNDLE_ID` matches the target's bundle identifier in build settings.
