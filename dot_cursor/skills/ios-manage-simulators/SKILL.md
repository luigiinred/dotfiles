---
name: ios-manage-simulators
description: Create, delete, and manage iOS Simulator devices using xcrun simctl. Use when the user wants to create a simulator, delete a simulator, list simulators, reset a simulator, clone a device, rename a device, or manage simulator lifecycle (boot, shutdown, erase).
---

# iOS Simulator Management

All commands use `xcrun simctl`. The `<device>` argument accepts a UDID or the special string `booted` (picks one booted device).

## Discovery

### List devices, device types, and runtimes

```bash
# All devices with state (Booted/Shutdown) and UDID
xcrun simctl list devices

# Available device types (needed for create)
xcrun simctl list devicetypes

# Available runtimes (needed for create)
xcrun simctl list runtimes

# JSON output for scripting
xcrun simctl list devices --json
```

### Find a device UDID by name

```bash
xcrun simctl list devices | grep "iPhone 17 Pro"
```

## Naming Convention

Derive the simulator name from the git remote so devices are project-scoped:

```bash
PROJECT=$(git remote get-url origin | sed 's/.*\///' | sed 's/\.git$//')
# e.g. "PhotoShoot"
```

Use `$PROJECT` as the device name in all create/clone commands below.

## Create

```bash
PROJECT=$(git remote get-url origin | sed 's/.*\///' | sed 's/\.git$//')

# xcrun simctl create <name> <device-type> <runtime>
xcrun simctl create "$PROJECT" "iPhone 17 Pro" "iOS 26.2"

# Using identifier strings instead of display names
xcrun simctl create "$PROJECT" \
  com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro \
  com.apple.CoreSimulator.SimRuntime.iOS-26-2
```

Returns the new device UDID on success. Capture it:

```bash
PROJECT=$(git remote get-url origin | sed 's/.*\///' | sed 's/\.git$//')
UDID=$(xcrun simctl create "$PROJECT" "iPhone 17 Pro" "iOS 26.2")
echo "Created: $UDID"
```

## Clone

```bash
# xcrun simctl clone <source-device> <new-name>
xcrun simctl clone "iPhone 17 Pro" "iPhone 17 Pro Clone"
xcrun simctl clone <UDID> "Cloned Device"
```

Clones an existing device including its data. Returns the new UDID.

## Rename

```bash
# xcrun simctl rename <device> <new-name>
xcrun simctl rename booted "My Renamed Device"
xcrun simctl rename <UDID> "New Name"
```

## Lifecycle

### Boot and shutdown

```bash
xcrun simctl boot <device>
xcrun simctl shutdown <device>
xcrun simctl shutdown all        # shut down every booted simulator
```

### Open Simulator.app (shows booted device)

```bash
open -a Simulator
```

### Boot + open in one go

```bash
xcrun simctl boot "iPhone 17 Pro" 2>/dev/null; open -a Simulator
```

## Reset (Erase)

Wipes all content and settings, returning the device to a clean state. Device must be shut down first.

```bash
xcrun simctl shutdown <device> 2>/dev/null
xcrun simctl erase <device>

# Erase all simulators
xcrun simctl erase all
```

## Delete

```bash
# Delete a specific device
xcrun simctl delete <device>

# Delete all devices with unavailable runtimes
xcrun simctl delete unavailable

# Delete ALL simulators (use with caution)
xcrun simctl delete all
```

**Important**: A device must be shut down before it can be deleted. Shut it down first:

```bash
xcrun simctl shutdown <device> 2>/dev/null
xcrun simctl delete <device>
```

## App Operations (bonus)

```bash
# Install an app
xcrun simctl install booted /path/to/App.app

# Launch an app by bundle ID
xcrun simctl launch booted com.example.MyApp

# Uninstall an app
xcrun simctl uninstall booted com.example.MyApp

# Terminate a running app
xcrun simctl terminate booted com.example.MyApp
```

## Common Recipes

### Create a fresh device, boot it, and open Simulator

```bash
PROJECT=$(git remote get-url origin | sed 's/.*\///' | sed 's/\.git$//')
UDID=$(xcrun simctl create "$PROJECT" "iPhone 17 Pro" "iOS 26.2")
xcrun simctl boot "$UDID"
open -a Simulator
```

### Tear down a device completely

```bash
xcrun simctl shutdown <device> 2>/dev/null
xcrun simctl delete <device>
```

### Clean up unavailable/stale simulators

```bash
xcrun simctl delete unavailable
```

### Reset a device to factory state without deleting

```bash
xcrun simctl shutdown <device> 2>/dev/null
xcrun simctl erase <device>
xcrun simctl boot <device>
```
