# Maestro API Reference

Complete reference for all Maestro commands, selectors, and their options.

---

## Commands

### tapOn

Tap on a UI element.

```yaml
# Simple
- tapOn: "Login"

# Full options
- tapOn:
    text: "Submit"              # Text/accessibility label (regex)
    id: "submit_button"         # Accessibility ID (regex)
    index: 0                    # 0-based index when multiple match
    point: "50%, 50%"           # Screen coordinates (relative or absolute)
    enabled: true               # Match by enabled state
    checked: false              # Match by checked state
    focused: true               # Match by focused state
    selected: false             # Match by selected state
    below: "Section Title"      # Below another element
    above: "Footer"             # Above another element
    leftOf: "Label"             # Left of another element
    rightOf: "Icon"             # Right of another element
    containsChild:              # Parent with matching child
      text: "Child Text"
    childOf:                    # Child of matching parent
      id: "parent_container"
    containsDescendants:        # Parent with matching descendants
      - text: "Descendant 1"
      - id: "desc_2"
    retryTapIfNoChange: true    # Retry if no UI change detected (default: true)
    repeat: 2                   # Tap N times (min 1)
    delay: 200                  # Delay between repeated taps in ms (default: 100)
    waitToSettleTimeoutMs: 1000 # Wait for UI to settle after tap in ms
    label: "Tap login button"   # Custom step label
    optional: false             # Continue on failure (default: false)
```

### doubleTapOn

Double-tap on a UI element. Accepts all the same selectors as `tapOn`.

```yaml
- doubleTapOn: "Image"
- doubleTapOn:
    id: "zoom_button"
    # ...same selector options as tapOn
```

### longPressOn

Long press on a UI element. Accepts all the same selectors as `tapOn`.

```yaml
- longPressOn: "Menu Item"
- longPressOn:
    id: "context_trigger"
    # ...same selector options as tapOn
```

### inputText

Type text into the currently focused text field. Unicode not yet supported on Android.

```yaml
- inputText: "hello@example.com"
```

### eraseText

Erase characters from the current text field.

```yaml
- eraseText: 10    # Erase 10 characters
- eraseText        # Erase all text
```

### pressKey

Press a hardware/soft key.

```yaml
- pressKey: Enter
```

**Supported keys (case-insensitive):**

| Platform | Keys |
|----------|------|
| All | `Enter`, `Home`, `Lock`, `Backspace`, `Volume Up`, `Volume Down` |
| Android only | `Back`, `Power`, `Tab` |
| Android TV | `Remote Dpad Up/Down/Left/Right/Center`, `Remote Media Play Pause`, `Remote Media Stop`, `Remote Media Next/Previous/Rewind/Fast Forward` |

### swipe

Swipe gesture on the screen.

```yaml
# Direction-based
- swipe:
    direction: LEFT             # UP, DOWN, LEFT, RIGHT
    duration: 300               # Duration in ms (default: 400)

# Coordinate-based
- swipe:
    start: "90%, 50%"           # Start point (% or px)
    end: "10%, 50%"             # End point (% or px)
    duration: 500

# From a specific element
- swipe:
    from:
      text: "Image Gallery"     # Element to swipe from
    direction: LEFT
    duration: 300
```

### scroll

Simple scroll gesture.

```yaml
- scroll
```

### scrollUntilVisible

Scroll in a direction until an element appears.

```yaml
- scrollUntilVisible:
    element: "Load More"        # Element to find (text string or selector object)
    direction: DOWN             # UP, DOWN, LEFT, RIGHT
    timeout: 10000              # Max scroll time in ms (default: 20000)
    speed: 50                   # Scroll speed 0-100 (default: 40)
    visibilityPercentage: 80    # Consider visible at N% in viewport (default: 100)
    centerElement: true         # Center element when found (default: false)
```

### hideKeyboard

Dismiss the on-screen keyboard. May be flaky on iOS.

```yaml
- hideKeyboard
```

---

### launchApp

Launch the app under test.

```yaml
# Simple (uses appId from header)
- launchApp

# Full options
- launchApp:
    appId: "com.other.app"      # Override app ID
    clearState: true            # Clear app data before launch
    clearKeychain: true         # Clear iOS keychain (iOS only)
    stopApp: true               # Stop app before launching (default: true)
    permissions:                # Set app permissions
      notifications: allow     # allow | deny | unset
      location: deny
      camera: allow
      all: unset               # Default for unlisted permissions
```

### stopApp

Stop the current or a specified app.

```yaml
- stopApp                          # Stop current app
- stopApp: "com.example.other"     # Stop specific app
```

### killApp

Kill the app. On Android, this simulates system-initiated process death. On iOS/Web, same as `stopApp`.

```yaml
- killApp
```

### openLink

Open a URL or deep link.

```yaml
# Simple
- openLink: "https://example.com"

# Full options
- openLink:
    link: "myapp://deep/path"
    autoVerify: true            # Auto-verify web link to open in app (default: false)
    browser: false              # Force open in browser on Android (default: false)
```

### clearState

Clear app data/state.

```yaml
- clearState                           # Current app
- clearState: "com.example.other"      # Specific app
```

### clearKeychain

Clear the iOS keychain. iOS only.

```yaml
- clearKeychain
```

### back

Press the system back button. Android only.

```yaml
- back
```

---

### assertVisible

Assert that a UI element is visible on screen.

```yaml
# Simple
- assertVisible: "Welcome"

# Full options
- assertVisible:
    text: "Sign In"
    id: "sign_in_button"
    index: 0
    enabled: true
    checked: false
    focused: true
    selected: false
    # All relational selectors also supported (above, below, etc.)
    label: "Verify Sign In button"
    optional: false
```

### assertNotVisible

Assert that a UI element is NOT visible on screen.

```yaml
- assertNotVisible: "Loading Spinner"
- assertNotVisible:
    text: "Error"
    id: "error_text"
```

### assertTrue

Assert a JavaScript expression evaluates to truthy.

```yaml
- assertTrue: "2 + 2 === 4"
- assertTrue:
    condition: "${output.count} > 0"
    label: "Check count is positive"
```

---

### extendedWaitUntil

Wait for an element to appear or disappear with a timeout.

```yaml
# Wait for element to appear
- extendedWaitUntil:
    visible: "Submit Button"
    timeout: 5000               # Timeout in ms

# Wait for element to disappear
- extendedWaitUntil:
    notVisible:
      text: "Loading"
      id: "loader"
    timeout: 3000
```

### waitForAnimationToEnd

Wait until all animations on screen settle.

```yaml
- waitForAnimationToEnd
- waitForAnimationToEnd:
    timeout: 5000               # Max wait in ms
```

---

### runFlow

Run a subflow from a file or inline. Supports conditional execution.

```yaml
# From file
- runFlow:
    file: "utils/login.yaml"
    env:
      USERNAME: "test_user"
      PASSWORD: "secret"

# Inline commands
- runFlow:
    commands:
      - tapOn: "Settings"
      - tapOn: "Logout"

# Conditional (only if element is visible)
- runFlow:
    when:
      visible: "User Profile"
    file: "flows/profile_check.yaml"

# Conditional (platform-specific)
- runFlow:
    when:
      platform: iOS
    commands:
      - tapOn: "iOS-specific Button"
```

**Condition types for `when`:**

| Condition | Description |
|-----------|-------------|
| `visible: {selector}` | Element is visible |
| `notVisible: {selector}` | Element is not visible |
| `platform: Android\|iOS\|Web` | Current platform matches |
| `true: ${expression}` | JavaScript expression is truthy |

Multiple conditions are ANDed.

### runScript

Execute a JavaScript file.

```yaml
# Simple
- runScript: "scripts/setup.js"

# Full options
- runScript:
    file: "scripts/validate.js"
    env:
      CHECK_MODE: "strict"
    when:
      platform: Android
```

**In the JS file**, access env vars directly by name. Use the `output` object to pass data back:

```javascript
var name = "User_" + Date.now();
output.generatedName = name;
console.log("Created: " + name); // Logs to CLI output
```

Use in subsequent YAML steps: `${output.generatedName}`

**HTTP requests in JS:**

```javascript
var resp = http.get("https://api.example.com/users");
var data = json(resp.body);
output.userId = data[0].id;

// POST with body
var resp2 = http.post("https://api.example.com/users", {
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ name: "Test User" })
});
```

Available methods: `http.get()`, `http.post()`, `http.put()`, `http.delete()`, `http.request()`.

Response fields: `ok` (boolean), `status` (int), `body` (string), `headers` (object).

### repeat

Repeat commands a fixed number of times or while a condition is true.

```yaml
# Fixed count
- repeat:
    times: 3
    commands:
      - tapOn: "Next"

# While condition
- repeat:
    while:
      visible: "Load More"
    commands:
      - tapOn: "Load More"
      - waitForAnimationToEnd
```

### retry

Retry commands on failure. Max retries: 3.

```yaml
# Inline commands
- retry:
    maxRetries: 3               # 0-3, default: 1
    commands:
      - tapOn:
          id: "flaky_button"

# From file
- retry:
    maxRetries: 2
    file: "flows/unstable_step.yaml"
```

---

### copyTextFrom

Copy text from a UI element into `maestro.copiedText`.

```yaml
- copyTextFrom:
    text: "Price: .*"
    id: "price_label"
```

Access the copied text in JS via `maestro.copiedText` or paste with `pasteText`.

### setClipboard

Set arbitrary text to the clipboard (without reading from UI).

```yaml
- setClipboard: "custom text"
```

Supports JavaScript expressions for dynamic values.

### pasteText

Paste clipboard contents into the currently focused field.

```yaml
- pasteText
```

---

### setLocation

Spoof GPS coordinates.

```yaml
- setLocation:
    latitude: 37.7749
    longitude: -122.4194
```

### setOrientation

Set device orientation.

```yaml
- setOrientation: landscape    # portrait | landscape
```

### addMedia

Add media files to the device gallery/camera roll.

```yaml
- addMedia:
    - "./assets/test_image.png"     # Supported: png, jpeg, jpg, gif, mp4
    - "./assets/test_video.mp4"
```

### toggleAirplaneMode

Toggle airplane mode on/off.

```yaml
- toggleAirplaneMode
```

### setPermissions

Set app permissions (typically done via `launchApp`, but available standalone).

```yaml
- setPermissions:
    notifications: allow       # allow | deny | unset
    location: deny
    camera: allow
```

### travel

Simulate device movement between GPS points.

```yaml
- travel:
    points:
      - "37.7749,-122.4194"    # lat,lng
      - "34.0522,-118.2437"
    speed: 50                  # meters per second
```

---

### takeScreenshot

Capture a screenshot.

```yaml
- takeScreenshot: "login_screen.png"
- takeScreenshot:
    path: "./screenshots/step1.png"   # Relative to workspace
```

### startRecording

Start video recording.

```yaml
- startRecording: "test_session.mp4"
```

### stopRecording

Stop video recording.

```yaml
- stopRecording
```

---

### assertWithAI (Experimental)

AI-powered visual assertion. Takes a screenshot and asks an LLM if the assertion is true.

```yaml
- assertWithAI:
    assertion: "Login form with email and password fields is visible"
```

`optional: true` by default for AI commands.

### assertNoDefectsWithAI (Experimental)

AI-powered defect detection. Checks for cut-off text, overlapping elements, misalignment.

```yaml
- assertNoDefectsWithAI
```

### extractTextWithAI (Experimental)

AI-powered text extraction from the screen.

```yaml
# Simple (result in ${aiOutput})
- extractTextWithAI: "CAPTCHA value"

# With custom variable
- extractTextWithAI:
    query: "Title of the first item"
    outputVariable: "firstItemTitle"
```

---

## Selectors Reference

### Core Selectors

| Selector | Type | Description |
|----------|------|-------------|
| `text` | string (regex) | Visible text or accessibility label |
| `id` | string (regex) | Accessibility identifier / resource ID |
| `index` | int (0-based) | Pick Nth match when multiple elements match |
| `point` | string | Screen coordinates: `"50%, 50%"` (relative) or `"100, 250"` (absolute) |
| `css` | string | CSS selector (web only, no regex) |

**Regex notes**: `text` and `id` are regex by default. Escape special chars: `\$`, `\[`, `\(`.

**Platform specifics**:
- Android Compose: Use `Modifier.semantics { testTagsAsResourceId = true }` for test tag discovery as IDs.
- Flutter: Use visible text or Semantics Labels for `text`, Semantics Identifiers for `id`. Flutter Keys are not supported.

### Relational Selectors

| Selector | Description |
|----------|-------------|
| `above: {selector}` | Element above the anchor (by screen bounds) |
| `below: {selector}` | Element below the anchor |
| `leftOf: {selector}` | Element left of the anchor |
| `rightOf: {selector}` | Element right of the anchor |
| `containsChild: {selector}` | Parent with a direct child matching selector |
| `childOf: {selector}` | Element that is a direct child of matching parent |
| `containsDescendants: [{selector}, ...]` | Parent with all specified descendants (any depth) |

Positional selectors use screen coordinates, not DOM hierarchy. Combine with `id`/`text`/state selectors for precision.

```yaml
# Tap the "Delete" button inside the "Basket" container
- tapOn:
    text: Delete
    childOf:
      id: basket_container

# Tap the icon to the right of "Settings"
- tapOn:
    traits: square
    rightOf: Settings

# Assert vertical ordering
- assertVisible:
    text: "Top"
    above:
      text: "Middle"
      above:
        text: "Bottom"
```

### State Selectors

| Selector | Values | Description |
|----------|--------|-------------|
| `enabled` | `true` / `false` | Interactive vs disabled/grayed-out |
| `checked` | `true` / `false` | Checkbox/switch/radio toggle state |
| `focused` | `true` / `false` | Has keyboard input focus |
| `selected` | `true` / `false` | Selected tab, segment, or list item |

### Element Traits

| Trait | Description |
|-------|-------------|
| `traits: text` | Any element containing text |
| `traits: long-text` | Element with 200+ characters |
| `traits: square` | Element with width/height within 3% of each other |

### Dimension Matchers

Match elements by size:

```yaml
- tapOn:
    width: 100          # Exact width in px
    height: 100         # Exact height in px
    tolerance: 10       # Acceptable deviation in px
```

---

## Environment Variables & Parameters

### Defining defaults in flow header

```yaml
env:
  USERNAME: "default@example.com"
  TIMEOUT: "5000"
---
- inputText: ${USERNAME}
- extendedWaitUntil:
    visible: "Dashboard"
    timeout: ${TIMEOUT}
```

### Overriding at runtime

```bash
maestro test -e USERNAME=other@example.com flow.yaml
```

### Passing to subflows

```yaml
- runFlow:
    file: "login.yaml"
    env:
      USERNAME: ${USERNAME}
      PASSWORD: "override_password"
```

### System env vars

Any env var prefixed with `MAESTRO_` is accessible in JavaScript scripts.

---

## CLI Reference

### maestro test

```bash
maestro test flow.yaml                          # Run single flow
maestro test flow1.yaml flow2.yaml              # Run multiple flows
maestro test myTests/                           # Run all flows in directory
maestro test --format junit myTests/            # JUnit XML report
maestro test --format html myTests/             # HTML report
maestro test --output results.xml myTests/      # Custom report filename
maestro test -e KEY=VAL flow.yaml               # Pass env variable
maestro test --include-tags smoke myTests/      # Filter by tag
maestro test --exclude-tags slow myTests/       # Exclude by tag
```

### maestro studio

Launches an interactive browser-based IDE for writing and testing flows.

```bash
maestro studio
```

### maestro cloud

Run tests in Maestro Cloud (CI/CD friendly, no local device needed).

```bash
maestro cloud --api-key KEY --project-id ID app.zip flows/
maestro cloud --format junit flows/             # With report
```

### config.yaml (Test Suite Configuration)

Place in the test directory to control execution:

```yaml
executionOrder:
  continueOnFailure: false     # Stop on first failure
  flowsOrder:
    - "setup.yaml"             # Run first
    - "*"                      # Then all other flows
```

Flow inclusion patterns: `*` (all top-level), `subFolder/*` (all in subfolder), `**` (recursive).
