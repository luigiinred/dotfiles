---
name: maestro-explore
description: Explore the mobile app to find a specific page, screen, or component by iteratively inspecting and navigating the live device via Maestro MCP. Use when the user wants to find something in the app, navigate to a screen, locate a component, explore the app, or says "find the X screen" or "how do I get to Y".
---

# Maestro Explore

Find a target page, screen, or component in the live app by iteratively inspecting the device, deciding where to navigate, and executing taps/scrolls via Maestro MCP until the target is found. Output the navigation steps so the user knows exactly how to reach it.

## Prerequisites

- A device/simulator must be running with the app installed (release build)
- Get the device ID via `user-maestro-list_devices`
- If no device is running, start one with `user-maestro-start_device`

## Step 1: Gather Target

Collect from the user (use AskQuestion when available):

1. **Target**: What to find — a page name, component, text, feature, or UI element
2. **Account type** (optional): Single account, multiple accounts, IRA, etc. (affects login user)

## Step 2: Research Before Exploring

Before blindly navigating, look for clues in the codebase.

### 2a. Search existing Maestro flows

```
Grep: "<target keywords>" in maestro/flows/
Glob: maestro/flows/**/*.yml
```

If a flow already navigates to the target, read it to extract the path. This can shortcut the entire exploration.

### 2b. Search the source code

```
Grep: "<target keywords>" in src/
```

Look for screen names, navigation routes, tab labels, or accessibility IDs that match the target. This gives hints about where the target lives in the nav hierarchy.

### 2c. Build initial hypothesis

From your research, form a hypothesis about how to reach the target:
- Which tab? (dashboard, portfolio, profile)
- How deep? (top-level, nested screen, modal)
- Any prerequisite state? (specific account type, feature flag)

If research gives a clear path, skip directly to Step 3b and execute it. If uncertain, proceed with the explore loop.

## Step 3: Explore Loop

### 3a. Bootstrap — Login and land on dashboard

Use `user-maestro-run_flow` to launch and log in:

```yaml
appId: com.guideline.mobile
---
- runFlow:
    file: maestro/utils/login.yml
    env:
      USERNAME: <appropriate test user>
```

Default users (choose based on target):
- `single-defcon@guideline.test` — single 401k account
- `multi-defcon@guideline.test` — multiple accounts

**Initialize the navigation log:**

```
Navigation Steps:
1. Launch app and login
```

### 3b. Inspect → Decide → Act → Check (repeat)

Loop until the target is found or you've exhausted reasonable paths.

**Inspect:**

1. `user-maestro-inspect_view_hierarchy` — get all elements with text, IDs, bounds, states
2. `user-maestro-take_screenshot` — visual context of current screen

**Decide:**

Scan the hierarchy for:
- **Target found?** — If the target text, component, or element is visible, you're done. Go to Step 4.
- **Clue elements** — Buttons, tabs, or list items that might lead toward the target (e.g., if looking for "Statements", tapping "Profile" tab is a reasonable step)
- **Scrollable content** — If the screen might have the target below the fold, scroll first before navigating away

Decision priority:
1. Tap an element that exactly or partially matches the target
2. Tap a navigation element that likely leads to the target (based on your hypothesis)
3. Scroll down to reveal more content
4. Back out and try a different path

**Act:**

Execute the chosen action via `user-maestro-run_flow`:

```yaml
appId: com.guideline.mobile
---
- tapOn:
    id: <element-id>
```

Or for scrolling:

```yaml
appId: com.guideline.mobile
---
- scroll
```

**Log the step** — append to the navigation log:

```
2. Tap "Profile" tab (id: profile-screen-tab)
3. Scroll down
4. Tap "Statements"
```

**Check:**

After acting, inspect again to see the new state. If you navigated to a dead end:
- Use `user-maestro-back` or tap a back button to return
- Remove the dead-end step from the log
- Try the next most likely path

### 3c. Backtracking

If a path doesn't lead to the target:

1. Go back: `user-maestro-run_flow` with `- back` or tap the back/close button
2. Log the backtrack (but don't include dead ends in the final output)
3. Try the next candidate from the previous screen

### 3d. Bail out

If you've explored all tabs and reasonable paths (typically 10+ iterations) without finding the target:

1. Report what you searched
2. Show the closest match you found (if any)
3. Suggest the target may not exist in the current build, or may require a specific account/feature flag

## Step 4: Report Results

When the target is found:

1. **Take a screenshot** via `user-maestro-take_screenshot` to show the target
2. **Present the navigation steps** clearly:

```
Found: [target description]

Navigation Steps:
1. Launch app and login (user: single-defcon@guideline.test)
2. Tap "Profile" tab (id: profile-screen-tab)
3. Tap "Statements"
4. Tap "2025 Annual Statement"

From the dashboard, it takes 3 taps to reach this screen.
```

3. **Show the element details** from the hierarchy (text, ID, bounds) if the user needs selector info for a test

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Can't find device | `user-maestro-list_devices` then `user-maestro-start_device` |
| Login fails | Check env vars, try a different test user |
| Target might be behind a feature flag | Ask the user about account requirements |
| Target only appears on certain account types | Try different test users |
| Screen loads but is empty | Wait with `extendedWaitUntil` or `waitForAnimationToEnd` |
| Back button doesn't work | Try `user-maestro-back` (Android) or tap the back chevron by ID |
