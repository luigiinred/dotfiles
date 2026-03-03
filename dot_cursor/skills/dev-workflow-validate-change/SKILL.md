---
name: dev-workflow-validate-change
description: Visually validate code changes by analyzing the git diff, identifying affected screens, and capturing screenshots via Maestro. Delegates to maestro-take-screenshots and maestro-explore skills. Use when the user says "validate change", "visual check", "screenshot my changes", "validate the app", or wants to see what their code changes look like on a device.
---

# Validate Change

Analyze the current branch's diff against its base, determine which screens are affected, navigate to each one on a live device via Maestro, and capture screenshots for visual validation.

## Prerequisites

- A device/simulator must be running with the **current build** installed (the build should include the changes being validated)
- Maestro CLI installed

## Workflow

### Step 1: Determine Changed Screens

Analyze the git diff to identify which screens or UI areas were affected.

```bash
git diff main...HEAD --name-only
```

If on a branch created from another feature branch, detect the parent (see `dev-workflow-create-pr` for parent-branch detection logic) and diff against that instead.

#### Mapping Rules

Map changed files to screens using these heuristics:

| Changed file pattern | Affected screen |
|---|---|
| `src/features/<area>/screens/<Screen>.tsx` | That screen directly |
| `src/features/<area>/components/*` | Screens in that feature area |
| `src/features/<area>/hooks/*` | Screens in that feature area |
| `src/shared/components/**` | Any screen using that component — grep for imports to narrow down |
| `src/shared/hooks/**` | Any screen using that hook — grep for imports to narrow down |
| `src/features/navigation/*` | Dashboard (landing screen) + any restructured routes |
| GraphQL/query files | Screens that use those queries — grep for query name imports |
| Style/theme files | Dashboard as a representative sample |

**Feature area → tab mapping** (for navigation):

| Feature area | Tab / entry point |
|---|---|
| `dashboard` | Dashboard tab (landing) |
| `portfolio` | Portfolio tab (`id: portfolio-screen-tab`) |
| `account`, `profile` | Profile tab (`id: profile-screen-tab`) |
| `contributions` | Profile tab → plan details / contributions |
| `auth` | Login screen (pre-auth) |
| `onboarding` | Onboarding flow (special entry) |

Build a list of screens to capture. If more than 5 screens are affected, prioritize:
1. Directly changed screen files
2. Screens in the same feature area as changed components
3. Skip shared-component consumers unless the change is visually significant

### Step 2: Confirm Targets

Present the identified screens using AskQuestion:

- Title: "Screens to Validate"
- Question: "Based on the diff, these screens may be affected:\n\n[list]\n\nHow should I proceed?"
- Options:
  - id: "all", label: "Screenshot all of them"
  - id: "adjust", label: "Let me adjust the list"
  - id: "skip", label: "Skip validation"

If "adjust": ask the user conversationally which screens to add/remove.
If "skip": end the workflow.

### Step 3: Capture Screenshots

For each target screen, delegate to the existing maestro skills:

#### 3a. If a clear navigation path is known

Use the **maestro-take-screenshots** skill. Provide it:
- **Target**: the screen name
- **Capture type**: screenshot
- **Output name**: `validate-<screen-name>`

#### 3b. If the navigation path is unclear

Use the **maestro-explore** skill first to find the screen, then take the screenshot once found.

#### 3c. Capture sequence

Process screens in navigation-efficient order to minimize backtracking:
1. Group by tab (dashboard screens first, then portfolio, then profile)
2. Within a tab, capture shallow screens before deep ones
3. Login once; reuse the session across all captures

### Step 4: Present Results

After all screenshots are captured, summarize:

```
Visual Validation Results:

Screen                    | Status
--------------------------|--------
DashboardScreen           | Captured
PortfolioScreen           | Captured
SettingsScreen            | Captured (via maestro-explore)
PlanDetailScreen          | Skipped — couldn't navigate

Screenshots saved to .maestro/ directory.
```

Show each screenshot to the user inline (the maestro skills will handle displaying them).

If any screens couldn't be reached, note them and suggest the user check manually.

## Notes

- This skill is an orchestrator — all device interaction is handled by `maestro-take-screenshots` and `maestro-explore`.
- The build on the device must include the changes. If the user hasn't rebuilt, remind them to run `npm run ios:release` or `npm run android:release` first.
- For non-visual changes (refactors, test-only, CI config), suggest skipping validation entirely.
