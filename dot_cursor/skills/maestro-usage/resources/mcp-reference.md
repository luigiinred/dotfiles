# Maestro MCP Tool Reference

The Maestro MCP server (`user-maestro-*`) provides tools for controlling devices and running flows directly from the agent. Use these instead of shell commands when interacting with devices programmatically.

---

## Device Management

### list_devices

List all available simulators/emulators that can be launched.

**Parameters:** None

**Returns:** List of devices with IDs, names, platforms, and states.

**When to use:** Before starting a device — find available device IDs.

---

### start_device

Start a simulator or emulator.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `device_id` | string | No | Specific device ID from `list_devices` |
| `platform` | string | No | `ios` or `android` (default: `ios`) |

Provide either `device_id` or `platform`, not both. Returns the device ID of the started device.

**When to use:** When no device is running and you need one for testing.

---

### launch_app

Launch an app on a connected device.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `device_id` | string | Yes | Device ID to launch on |
| `appId` | string | Yes | Bundle ID (iOS) or package name (Android) |

---

### stop_app

Stop an app on a connected device.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `device_id` | string | Yes | Device ID |
| `appId` | string | Yes | Bundle ID or package name to stop |

---

## Interaction

### tap_on

Tap on a UI element by selector.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `device_id` | string | Yes | Device ID |
| `text` | string | No | Text content to match (from `inspect_view_hierarchy` `text` field) |
| `id` | string | No | Element ID to match (from `inspect_view_hierarchy` `id` field) |
| `index` | int | No | 0-based index if multiple elements match |
| `use_fuzzy_matching` | bool | No | Fuzzy/partial matching (default: `true`) or exact regex (`false`) |
| `enabled` | bool | No | Match by enabled state |
| `checked` | bool | No | Match by checked state |
| `focused` | bool | No | Match by focused state |
| `selected` | bool | No | Match by selected state |

Provide at least one of `text` or `id` to identify the element.

**When to use:** Interacting with elements during interactive test building or debugging.

---

### input_text

Type text into the currently focused text field.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `device_id` | string | Yes | Device ID |
| `text` | string | Yes | Text to input |

**When to use:** After tapping on a text field to focus it.

---

### back

Press the back button on the device.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `device_id` | string | Yes | Device ID |

---

## Inspection

### take_screenshot

Capture a screenshot of the current device screen.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `device_id` | string | Yes | Device ID |

**Returns:** Screenshot image of the current screen.

**When to use:** Visual confirmation of current screen state, debugging, or documenting.

---

### inspect_view_hierarchy

Get the full view hierarchy of the current screen in CSV format.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `device_id` | string | Yes | Device ID |

**Returns:** CSV data with columns for each UI element: bounds (x, y, width, height), text content, resource IDs, and interaction states (clickable, enabled, checked).

**When to use:** Before any interaction — find element text, IDs, and bounds to determine the right selector. This is the primary tool for understanding what's on screen.

**Important:** Always call this before `tap_on` or `run_flow` to avoid guessing at selectors.

---

## Flow Execution

### run_flow

Execute one or more Maestro commands as inline YAML. Preferred for ad-hoc commands and interactive exploration.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `device_id` | string | Yes | Device ID |
| `flow_yaml` | string | Yes | YAML-formatted Maestro flow content |
| `env` | object | No | Environment variables to inject (e.g., `{"APP_ID": "com.example"}`) |

**YAML format options:**

```yaml
# Single command
- tapOn: "Login"
```

```yaml
# Multiple commands
- tapOn: "Email"
- inputText: "test@example.com"
- tapOn: "Submit"
```

```yaml
# With header
appId: com.example.app
---
- launchApp:
    clearState: true
- tapOn: "Login"
```

**When to use:** Running ad-hoc commands, testing individual steps, interactive debugging. Syntax is validated automatically — no need to call `check_flow_syntax` first.

---

### run_flow_files

Run one or more Maestro test YAML files from disk.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `device_id` | string | Yes | Device ID |
| `flow_files` | string | Yes | Comma-separated file paths (e.g., `"flow1.yaml,flow2.yaml"`) |
| `env` | object | No | Environment variables to inject |

**When to use:** Running complete test flows from existing files. If a relative path fails, try the absolute path.

---

### check_flow_syntax

Validate the syntax of a Maestro flow without executing it.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `flow_yaml` | string | Yes | YAML content to validate |

**When to use:** Validating generated YAML before writing to a file. Not needed before `run_flow` (syntax is checked automatically during execution).

---

## Documentation

### cheat_sheet

Get the complete Maestro command syntax cheat sheet.

**Parameters:** None

**Returns:** Comprehensive reference of all Maestro commands, parameters, and syntax examples.

**When to use:** Quick lookup of command syntax, especially for less common commands.

---

### query_docs

Search the Maestro documentation for specific topics.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `question` | string | Yes | Natural language question about Maestro |

**Returns:** Relevant documentation excerpts and links.

**When to use:** Finding information about specific Maestro features, troubleshooting, or learning about capabilities not covered in this reference.

---

## Common Workflows

### Interactive Test Building

```
1. list_devices → find device ID
2. start_device (if needed)
3. launch_app
4. inspect_view_hierarchy → see what's on screen
5. run_flow (single command) → test a step
6. inspect_view_hierarchy → verify result
7. Repeat 5-6, building up the YAML file
8. run_flow_files → run the complete flow end-to-end
```

### Debugging a Failing Test

```
1. run_flow_files → run the test, note which step fails
2. take_screenshot → see actual screen state at failure
3. inspect_view_hierarchy → find available elements
4. Compare expected vs actual selectors
5. run_flow → test the fix in isolation
6. run_flow_files → re-run the full flow
```

### Quick Smoke Test

```
1. list_devices → find running device
2. run_flow with inline YAML:
   - launchApp: { clearState: true }
   - extendedWaitUntil: { visible: "Home", timeout: 10000 }
   - assertVisible: "Dashboard"
```
