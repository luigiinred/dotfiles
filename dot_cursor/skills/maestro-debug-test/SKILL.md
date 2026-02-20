---
name: maestro-debug-test
description: Debug and fix a failing Maestro E2E test in a diagnose-fix-rerun loop. Analyzes the failure screenshot, failed step, and device view hierarchy via Maestro MCP, applies a fix, and re-runs until the test passes. Use when a Maestro test just failed, the user says "debug this test", "why did this fail", or wants to fix a Maestro test failure.
---

# Debug Maestro Test Failure

Diagnose a Maestro test failure, apply a fix, and re-run in a loop until the test passes.

## Prerequisites

- A Maestro test was already run and **failed** (e.g. via `maestro-run-test` skill or manual run)
- The device/simulator is still running with the app at the failure point
- Results are in `build/maestro-results/` (or the user provides an alternate path)

## Workflow

Repeat the **Diagnose → Fix → Re-run** loop until the test passes (or you determine the issue is in the app, not the test).

### Step 1: Diagnose

#### 1a. Locate failure artifacts

Find the most recent results directory and its contents:

```bash
ls -la build/maestro-results/
ls -la build/maestro-results/$(ls -t build/maestro-results/ | head -1)/
```

Look for:
- `screenshot-❌-*.png` — failure screenshot
- `commands-*.json` — full command execution log
- `ai-*.json` / `ai-report-*.html` — AI-generated summary (if present)

#### 1b. Read the failure screenshot

Use the Read tool on the `screenshot-❌-*.png` file to see the visual state at failure time. Note what screen is displayed, any error messages, loading states, or unexpected UI.

#### 1c. Read the test flow

Read the `.yml` test file that failed and all sub-flows it references (`runFlow` entries). Identify the **failed step** from the test output — the command and selector that could not be resolved.

#### 1d. Inspect the live device

The device is frozen at the failure point. Use **both** Maestro MCP tools:

- `user-maestro-take_screenshot` — current visual state
- `user-maestro-inspect_view_hierarchy` — all elements with text, IDs, bounds, and states

Search the hierarchy for:
- The element the test was looking for (exact text or ID match)
- Similar elements with slightly different text, IDs, or casing
- Whether the expected element exists but is off-screen or hidden

#### 1e. Compare expected vs actual

| | Expected (from test YAML) | Actual (from device) |
|---|---|---|
| **Screen** | What screen should the test be on? | What screen is actually showing? |
| **Element** | What text/ID is the test looking for? | Is it present? Under a different name? |
| **State** | What state should the app be in? | Is it loading, showing an error, or on a different screen? |

#### 1f. Determine root cause

| Category | Symptoms | How to confirm |
|----------|----------|----------------|
| **Text changed** | Element not found, but similar text in hierarchy | Search for partial match |
| **ID changed** | ID not found in hierarchy | Search by visible text instead |
| **Wrong screen** | Expected element doesn't exist anywhere | Screenshot shows unexpected screen |
| **Loading/timing** | Spinner or skeleton visible | Hierarchy contains loading indicators |
| **Off-screen** | Element in hierarchy but not in screenshot | Bounds outside viewport |
| **Conditional flow** | A `when` guard skipped a required step | Check env vars and conditional logic |
| **New modal/sheet** | Overlay blocking interaction | Screenshot/hierarchy show modal |

### Step 2: Fix

Apply the **minimal change** to the test YAML to resolve the failure:

- Only change what's needed to fix the current failure
- Preserve headers (appId, env, tags) and existing comments
- Match existing patterns in the file
- If a conditional flow (`when: ${VAR == true}`) skips a step the app now always requires, make it unconditional

Common fixes:

| Symptom | Fix |
|---------|-----|
| Text not found | Update selector to match current accessibility text |
| Element off-screen | Add `scrollUntilVisible` before the tap/assert |
| Screen still loading | Add `extendedWaitUntil` with timeout |
| New modal/sheet | Add optional dismiss: `tapOn: text: "Got it", optional: true` |
| Element ID renamed | Update `id` to match current hierarchy |
| Navigation path changed | Add/update tap steps for new intermediate screens |
| Conditional skipped needed step | Set env var or make step unconditional |

### Step 3: Re-run

Clean results and re-run the test:

```bash
rm -rf build/maestro-results
maestro test --test-output-dir=build/maestro-results <path-to-test.yml>
```

### Step 4: Evaluate

- **Test passed** → Report the fix summary and stop.
- **Test failed on a new step** → Go back to Step 1 with the new failure.
- **Same step fails again** → Re-diagnose; the fix was insufficient. Try a different approach.
- **3+ failed attempts on the same step** → Stop and report the issue to the user. It may be an app bug rather than a test issue.

## Reporting

After each loop iteration, briefly report:
1. **Failed step** and root cause
2. **Fix applied** (what changed and why)
3. **Re-run result** (pass / new failure / same failure)

When the loop ends (pass or bail), give a final summary of all changes made.
