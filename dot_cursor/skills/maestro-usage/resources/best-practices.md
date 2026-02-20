# Maestro Best Practices

Patterns, pitfalls, and strategies for writing stable, maintainable Maestro tests.

---

## Selector Strategy

### Prefer `id` over `text`

Text changes with localization, copy updates, and dynamic content. IDs are stable across all these.

```yaml
# Fragile — breaks if copy changes
- tapOn: "Continue to Dashboard"

# Stable
- tapOn:
    id: "continue_button"
```

When `id` isn't available, use `text` with regex for flexibility:

```yaml
- tapOn:
    text: ".*Continue.*"
```

### Use relational selectors to disambiguate

When multiple elements share the same text (e.g., several "Buy" buttons), use relational selectors instead of brittle `index` values.

```yaml
# Fragile — index changes if items reorder
- tapOn:
    text: "Buy"
    index: 2

# Stable — anchored to context
- tapOn:
    text: "Buy"
    below: "Wireless Headphones"
```

### Combine selectors for precision

```yaml
- tapOn:
    id: "action_button"
    enabled: true
    below: "Account Settings"
```

### Avoid `point` unless necessary

Coordinate-based taps break across screen sizes and orientations. Only use `point` when an element has no text, ID, or relational anchor.

---

## Waiting and Timing

### Never use fixed sleeps

Maestro has no `sleep` command by design. Use explicit waits instead.

### Use `extendedWaitUntil` for async content

```yaml
- extendedWaitUntil:
    visible: "Dashboard"
    timeout: 10000
```

Set timeouts based on realistic worst-case load times, not arbitrary large values.

### Use `waitForAnimationToEnd` after navigation

```yaml
- tapOn: "Profile"
- waitForAnimationToEnd
- assertVisible: "Profile Settings"
```

### Add waits before assertions, not after taps

The pattern is: **tap → wait → assert**. The wait ensures the next screen has loaded before you check for elements.

---

## Flow Organization

### Use subflows for shared sequences

Extract login, navigation, and setup steps into reusable subflows:

```
maestro/
├── flows/
│   ├── auth/
│   │   └── loginAndVerify.yml
│   ├── dashboard/
│   │   └── checkBalance.yml
│   └── profile/
│       └── editProfile.yml
└── utils/
    ├── login.yml
    ├── startApp.yml
    └── navigateTo.yml
```

Reference them with `runFlow`:

```yaml
- runFlow:
    file: "../../utils/login.yml"
    env:
      USERNAME: ${USERNAME}
```

### Group tests by feature

Organize flows into directories matching app features. This makes it easy to run targeted test suites:

```bash
maestro test maestro/flows/dashboard/
```

### Use tags for test categories

```yaml
tags:
  - smoke
  - regression
  - profile
```

Run selectively: `maestro test --include-tags smoke flows/`

### Keep flows focused

Each flow should test one user journey. If a flow exceeds ~50 steps, consider splitting it.

---

## Assertions

### Assert after every significant navigation

Don't just tap through screens — verify you arrived at the right place.

```yaml
- tapOn: "Settings"
- waitForAnimationToEnd
- assertVisible: "Account Settings"    # Verify we're on the right screen
```

### Assert both presence and absence

```yaml
- assertVisible: "Success"
- assertNotVisible: "Error"
```

### Use `optional: true` for dismissible UI

Pop-ups, banners, tooltips, and cookie consents may or may not appear:

```yaml
- tapOn:
    text: "Dismiss"
    optional: true
```

The flow continues whether or not the element was found.

---

## Test Data and State

### Always `clearState` at the start

```yaml
- launchApp:
    clearState: true
```

This ensures each test run starts from a clean state, eliminating cross-test contamination.

### Use environment variables for test data

```yaml
env:
  USERNAME: "test_user@example.com"
  PASSWORD: "test_password"
  ACCOUNT_ID: "12345"
```

This makes it easy to override for different environments or test accounts.

### Don't rely on server-side state

If a test needs specific data (e.g., a transaction), either:
1. Use `runScript` with HTTP requests to set up the data
2. Use a dedicated test account with known, stable data
3. Create the data as part of the flow itself

---

## Handling Flakiness

### Common causes and fixes

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Element not found | Screen hasn't loaded yet | Add `extendedWaitUntil` before the tap |
| Tap does nothing | Animation in progress | Add `waitForAnimationToEnd` before tap |
| Tap hits wrong element | Multiple matches | Add relational selector or `index` |
| Test passes locally, fails in CI | Timing differences | Increase `extendedWaitUntil` timeouts |
| Inconsistent text matching | Dynamic content | Use regex: `text: ".*partial.*"` |
| Keyboard covers element | Keyboard blocking tap target | Add `hideKeyboard` before tap |

### Use `retry` for genuinely flaky steps

```yaml
- retry:
    maxRetries: 2
    commands:
      - tapOn:
          id: "load_more"
      - assertVisible: "Item 11"
```

Only use `retry` for steps with known instability (network calls, animations). Don't blanket-retry everything — it masks real bugs.

### Use `retryTapIfNoChange: false` to speed up

The default behavior re-taps if the UI hierarchy didn't change. If you know the tap is valid but doesn't change the hierarchy (e.g., toggling a switch), disable it:

```yaml
- tapOn:
    id: "toggle_switch"
    retryTapIfNoChange: false
```

---

## JavaScript Integration

### Keep scripts small and focused

Each script should do one thing: generate data, make an API call, or compute a value.

### Use `output` to pass data back

```javascript
// scripts/createUser.js
var resp = http.post("https://api.example.com/test-users", {
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ name: "Test User " + Date.now() })
});
var user = json(resp.body);
output.userId = user.id;
output.email = user.email;
```

```yaml
- runScript: scripts/createUser.js
- inputText: ${output.email}
```

### Use `console.log()` for debugging

Console output appears in the Maestro CLI output, helpful for diagnosing failures.

---

## Platform-Specific Handling

### Conditional flows by platform

```yaml
- runFlow:
    when:
      platform: iOS
    commands:
      - tapOn: "Allow"          # iOS permission dialog

- runFlow:
    when:
      platform: Android
    commands:
      - tapOn: "While using the app"  # Android permission dialog
```

### Platform quirks

| Platform | Quirk |
|----------|-------|
| iOS | `hideKeyboard` can be flaky; consider tapping elsewhere to dismiss |
| iOS | `clearKeychain` available, Android doesn't have equivalent |
| Android | `back` is Android-only; iOS uses swipe gestures |
| Android | `killApp` simulates process death (useful for testing state restoration) |
| Android | Unicode in `inputText` not fully supported |

---

## Debugging Failed Tests

### Step 1: Read the error output

Maestro shows which step failed and its index. Note the step number.

### Step 2: Take a screenshot at the failure point

Add `takeScreenshot` before the failing step to see the actual screen state:

```yaml
- takeScreenshot: "debug_before_tap.png"
- tapOn: "Missing Element"
```

### Step 3: Inspect the view hierarchy

Use `maestro studio` or the Maestro MCP `inspect_view_hierarchy` to see what elements are actually on screen and their properties.

### Step 4: Check for timing issues

If the element exists but isn't found, add a wait:

```yaml
- extendedWaitUntil:
    visible:
      id: "target_element"
    timeout: 10000
- tapOn:
    id: "target_element"
```

### Step 5: Check for overlapping elements

Modals, sheets, and toasts can cover target elements. Dismiss them first or use `scrollUntilVisible` to bring elements into view.

---

## CI/CD Integration

### Use `--format junit` for CI reporting

```bash
maestro test --format junit --output results/report.xml flows/
```

### Set appropriate timeouts

CI environments are slower than local machines. Increase `extendedWaitUntil` timeouts via env vars:

```yaml
env:
  WAIT_TIMEOUT: "10000"
---
- extendedWaitUntil:
    visible: "Dashboard"
    timeout: ${WAIT_TIMEOUT}
```

Override in CI: `maestro test -e WAIT_TIMEOUT=20000 flows/`

### Use `clearState: true` in CI

Always start from a clean slate in CI to avoid state leakage between test runs.

### Use tags to separate smoke vs full regression

```bash
# Quick smoke test in PR checks
maestro test --include-tags smoke flows/

# Full regression in nightly builds
maestro test flows/
```

---

## Performance Tips

### Minimize `clearState` calls

`clearState` is slow — it fully resets the app. Use it once at the start of a flow, not between steps.

### Batch assertions

Instead of asserting after every micro-action, assert after logical checkpoints.

```yaml
# Too granular
- tapOn: "Email"
- assertVisible: "Email"           # Unnecessary
- inputText: "test@example.com"
- assertVisible: "test@example.com" # Unnecessary
- tapOn: "Password"
- inputText: "secret"
- tapOn: "Login"
- assertVisible: "Dashboard"       # This is the one that matters

# Right level
- tapOn: "Email"
- inputText: "test@example.com"
- tapOn: "Password"
- inputText: "secret"
- tapOn: "Login"
- waitForAnimationToEnd
- assertVisible: "Dashboard"
```

### Use `scrollUntilVisible` instead of repeated scrolls

```yaml
# Bad — guessing how many scrolls
- scroll
- scroll
- scroll
- tapOn: "Item at bottom"

# Good — scroll exactly as needed
- scrollUntilVisible:
    element: "Item at bottom"
    direction: DOWN
```
