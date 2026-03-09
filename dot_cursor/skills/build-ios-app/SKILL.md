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

### Find simulator

Use the preferred simulator if specified in a workspace rule. Otherwise pick a booted device or a recent iPhone:

```bash
# Use already-booted simulator if available
BOOTED=$(xcrun simctl list devices booted -j 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data.get('devices', {}).items():
    for d in devices:
        if d.get('state') == 'Booted':
            print(d['name']); sys.exit(0)
" 2>/dev/null)

if [ -z "$BOOTED" ]; then
  # Pick the latest iPhone Pro simulator available
  SIM_NAME=$(xcrun simctl list devices available -j 2>/dev/null | python3 -c "
import json, sys, re
data = json.load(sys.stdin)
candidates = []
for runtime, devices in data.get('devices', {}).items():
    if 'iOS' not in runtime: continue
    for d in devices:
        name = d['name']
        if 'iPhone' in name and d.get('isAvailable', False):
            candidates.append(name)
# Sort to prefer Pro models and higher numbers
pro = [c for c in candidates if 'Pro' in c]
pick = sorted(pro if pro else candidates, reverse=True)
print(pick[0] if pick else '')
" 2>/dev/null)
  echo "SIM_NAME: ${SIM_NAME:-No simulator found}"
else
  SIM_NAME="$BOOTED"
  echo "SIM_NAME (booted): $SIM_NAME"
fi
```

## Step 2: Build

```bash
killall Simulator 2>/dev/null; sleep 0.5
xcodebuild $PROJECT_FLAG -scheme "$SCHEME" -configuration Debug \
  -destination "platform=iOS Simulator,name=$SIM_NAME" \
  -derivedDataPath ./build build
```

If build fails, fix compilation errors before proceeding.

## Step 3: Install and Launch

```bash
# Boot simulator if needed
xcrun simctl boot "$SIM_NAME" 2>/dev/null
open -a Simulator

# Find the .app bundle
APP_PATH=$(find ./build/Build/Products/Debug-iphonesimulator -name "*.app" -maxdepth 1 | head -1)

xcrun simctl install booted "$APP_PATH"
xcrun simctl launch booted "$BUNDLE_ID"
```

## Workspace Rule Override

If the project has a `.cursor/rules/build-app.mdc` workspace rule with hardcoded values, prefer those values over auto-detection. The workspace rule is authoritative for that project.

## Troubleshooting

- **No simulator found**: Run `xcrun simctl list devices available` and pick one manually.
- **Signing errors**: Open the `.xcodeproj` in Xcode and fix Signing & Capabilities.
- **Scheme not found**: Run `xcodebuild -list` to see available schemes and use the correct one.
- **App won't launch**: Verify `BUNDLE_ID` matches the target's bundle identifier in build settings.
