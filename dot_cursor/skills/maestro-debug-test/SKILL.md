---
name: maestro-debug-test
description: Run a Maestro E2E test, and if it fails, diagnose and fix it in a loop until it passes. Analyzes failure screenshots, failed steps, and device view hierarchy via Maestro MCP to determine root cause, applies fixes, and re-runs. Use when the user says "debug this test", "fix this maestro test", "why is this test failing", or wants to get a Maestro test passing.
---

# Debug Maestro Test

Run a Maestro test and, if it fails, enter a diagnose-fix-rerun loop until it passes.

The user provides a path to a `.yml` flow file. If relative, resolve from workspace root.

## Step 1: Run the test

Verify the path exists, clean previous results, and run:

```bash
ls <resolved-path>
rm -rf build/maestro-results
maestro test --test-output-dir=build/maestro-results <resolved-path>
```

If the user specifies extra flags (e.g. `--include-tags`, `--device`), append them.

- **Exit code 0** → All tests passed. Report success and stop.
- **Non-zero** → Test failed. Continue to Step 2.

## Step 2: Diagnose

#### 2a. Locate failure artifacts

```bash
ls -la build/maestro-results/$(ls -t build/maestro-results/ | head -1)/
```

Look for: `screenshot-❌-*.png`, `commands-*.json`, `ai-*.json`

#### 2b. Read the failure screenshot

Use the Read tool on `screenshot-❌-*.png` to see visual state at failure time.

#### 2c. Read the test flow

Read the `.yml` file and all sub-flows it references (`runFlow` entries). Identify the **failed step** from the test output.

#### 2d. Inspect the live device

The device is frozen at the failure point. Use **both** Maestro MCP tools:

- `user-maestro-take_screenshot` — current visual state
- `user-maestro-inspect_view_hierarchy` — all elements with text, IDs, bounds, and states

Search the hierarchy for:
- The element the test was looking for (exact text or ID match)
- Similar elements with slightly different text, IDs, or casing
- Whether the expected element exists but is off-screen or hidden

#### 2e. Compare expected vs actual

| | Expected (from test YAML) | Actual (from device) |
|---|---|---|
| **Screen** | What screen should the test be on? | What screen is actually showing? |
| **Element** | What text/ID is the test looking for? | Is it present? Under a different name? |
| **State** | What state should the app be in? | Is it loading, showing an error, or on a different screen? |

#### 2f. Determine root cause

| Category | Symptoms | How to confirm |
|----------|----------|----------------|
| **Text changed** | Element not found, but similar text in hierarchy | Search for partial match |
| **ID changed** | ID not found in hierarchy | Search by visible text instead |
| **Wrong screen** | Expected element doesn't exist anywhere | Screenshot shows unexpected screen |
| **Loading/timing** | Spinner or skeleton visible | Hierarchy contains loading indicators |
| **Off-screen** | Element in hierarchy but not in screenshot | Bounds outside viewport |
| **Conditional flow** | A `when` guard skipped a required step | Check env vars and conditional logic |
| **New modal/sheet** | Overlay blocking interaction | Screenshot/hierarchy show modal |

## Step 3: Fix

Apply the **minimal change** to the test YAML to resolve the failure:

- Only change what's needed to fix the current failure
- Preserve headers (appId, env, tags) and existing comments
- Match existing patterns in the file

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

## Step 4: Re-run and evaluate

Clean results and re-run:

```bash
rm -rf build/maestro-results
maestro test --test-output-dir=build/maestro-results <resolved-path>
```

- **Test passed** → Report the fix summary and stop.
- **Test failed on a new step** → Go back to Step 2 with the new failure.
- **Same step fails again** → Re-diagnose; the fix was insufficient. Try a different approach.
- **3+ failed attempts on the same step** → Stop and report. It may be an app bug, not a test issue.

## Reporting

After each loop iteration, briefly report:
1. **Failed step** and root cause
2. **Fix applied** (what changed and why)
3. **Re-run result** (pass / new failure / same failure)

When the loop ends (pass or bail), give a final summary of all changes made.
