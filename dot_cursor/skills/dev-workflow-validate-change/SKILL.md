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

### Step 1: Analyze Diff — Screens and Accounts

Analyze the git diff to identify which screens are affected and which test accounts are needed.

```bash
git diff main...HEAD --name-only
```

If on a branch created from another feature branch, detect the parent (see `dev-workflow-create-pr` for parent-branch detection logic) and diff against that instead.

#### 1a. Map files to screens

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

If more than 5 screens are affected, prioritize:
1. Directly changed screen files
2. Screens in the same feature area as changed components
3. Skip shared-component consumers unless the change is visually significant

#### 1b. Determine test accounts

Pick the test account(s) by examining which data shapes / account types the changed code touches. Also check existing maestro flows for the affected screens — they already specify the right `DEFAULT_USERNAME`.

```bash
# Find existing flows for the affected screens and extract their test accounts
grep -r 'DEFAULT_USERNAME' maestro/flows/<feature-area>/
```

**Test account reference:**

| Account | Username | Use when |
|---|---|---|
| Single 401k (Defcon) | `single-defcon@guideline.test` | Default for most screens |
| Multiple 401k (Defcon) | `multiple-defcon@guideline.test` | Multi-plan 401k logic, account switcher |
| Multiple account types | `multiple-accounts@guideline.test` | Account chooser, mixed account views |
| Personal IRA | `personal-ira@guideline.test` | IRA-specific screens, IRA contributions |
| SEP IRA | `sep-ira@guideline.test` | SEP IRA plan details |
| IRA + HSA | `ira-and-hsa@guideline.test` | Mixed unsupported account handling |
| Defcon + HSA | `defcon-with-hsa@guideline.test` | HSA-related dashboard views |
| Defcon + Cash | `defcon-and-cash@guideline.test` | Cash account dashboard views |
| Year-in-review | `year-in-review@guideline.test` | Annual statements |

**Selection heuristics:**

- If the diff touches IRA-specific code (file paths contain `ira`, `Ira`, or IRA type checks), use `personal-ira@guideline.test`
- If the diff touches account switching, account selectors, or multi-account layouts, use `multiple-accounts@guideline.test`
- If the diff touches SEP IRA, use `sep-ira@guideline.test`
- If the diff is generic / shared UI, use `single-defcon@guideline.test` (the default)
- If the change affects rendering that varies by account type, capture with **multiple accounts** to cover the most variation in one login

When multiple account types are needed (e.g., a shared component that renders differently per account type), plan separate capture passes — one login per account type.

### Step 2: Confirm Targets and Accounts

Present the identified screens and test accounts using AskQuestion:

- Title: "Screens to Validate"
- Question: "Based on the diff, here's the capture plan:\n\n**Screens:**\n[list of screens]\n\n**Test account(s):**\n[account(s) and why]\n\nHow should I proceed?"
- Options:
  - id: "all", label: "Screenshot all of them"
  - id: "adjust", label: "Let me adjust the list"
  - id: "skip", label: "Skip validation"

If "adjust": ask the user conversationally which screens to add/remove and which accounts to use.
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
