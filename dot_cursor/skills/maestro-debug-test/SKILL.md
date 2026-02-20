---
name: maestro-debug-test
description: Debug a failing Maestro E2E test by analyzing the failure screenshot, identifying the failed step, and inspecting the device view hierarchy via Maestro MCP. Use when a Maestro test just failed, the user says "debug this test", "why did this fail", or wants to understand a Maestro test failure.
---

# Debug Maestro Test Failure

Analyze a Maestro test failure using the screenshot, failed step, and live device view hierarchy to determine root cause.

## Prerequisites

- A Maestro test was already run and **failed** (e.g. via `maestro-run-test` skill or manual run)
- The device/simulator is still running with the app at the failure point
- Results are in `build/maestro-results/` (or the user provides an alternate path)

## Instructions

### 1. Locate failure artifacts

Find the most recent results directory and its contents:

```bash
ls -la build/maestro-results/
ls -la build/maestro-results/$(ls -t build/maestro-results/ | head -1)/
```

Look for:
- `screenshot-❌-*.png` — failure screenshot
- `commands-*.json` — full command execution log
- `ai-*.json` / `ai-report-*.html` — AI-generated summary (if present)

### 2. Read the failure screenshot

Use the Read tool on the `screenshot-❌-*.png` file to see the visual state of the app at failure time. Note what screen is displayed, any error messages, loading states, or unexpected UI.

### 3. Read the test flow

Read the `.yml` test file that failed and all sub-flows it references (`runFlow` entries). Identify the **failed step** from the test output — the command and selector that could not be resolved.

### 4. Inspect the live device

The device is frozen at the failure point. Use **both** Maestro MCP tools to get the full picture:

- `user-maestro-take_screenshot` — current visual state (may differ slightly from saved screenshot if time has passed)
- `user-maestro-inspect_view_hierarchy` — structured list of all elements with text, IDs, bounds, and states

The view hierarchy is the most important artifact. Search it for:
- The element the test was looking for (exact text or ID match)
- Similar elements with slightly different text, IDs, or casing
- Whether the expected element exists but is off-screen or hidden

### 5. Compare expected vs actual

Build a clear diagnosis by comparing:

| | Expected (from test YAML) | Actual (from device) |
|---|---|---|
| **Screen** | What screen should the test be on? | What screen is actually showing? |
| **Element** | What text/ID is the test looking for? | Is it present? Under a different name? |
| **State** | What state should the app be in? | Is it loading, showing an error, or on a different screen? |

### 6. Determine root cause

Common failure categories:

| Category | Symptoms | How to confirm |
|----------|----------|----------------|
| **Text changed** | Element not found, but similar text exists in hierarchy | Search hierarchy for partial match |
| **ID changed** | ID not found in hierarchy | Search hierarchy for the element by visible text instead |
| **Wrong screen** | Expected element doesn't exist anywhere in hierarchy | Screenshot shows unexpected screen |
| **Loading/timing** | Screen shows spinner or loading skeleton | Hierarchy contains loading indicators |
| **Off-screen** | Element exists in hierarchy but not visible in screenshot | Element bounds are outside viewport |
| **Conditional flow** | A `when` guard skipped a required step | Check env vars and conditional logic in the flow |
| **New modal/sheet** | Unexpected overlay blocking interaction | Screenshot shows modal; hierarchy has overlay elements |

### 7. Report findings

Summarize with:
1. **Failed step**: The exact command and selector that failed
2. **Root cause**: Why it failed (from the categories above)
3. **Evidence**: What you saw in the screenshot and view hierarchy that confirms the diagnosis
4. **Suggested fix**: Minimal change to the test YAML or app configuration to resolve it

If the user wants to proceed with a fix, hand off to the `fix-maestro-test` skill or apply the fix directly.
