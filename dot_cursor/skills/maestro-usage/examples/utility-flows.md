# Utility Flow Examples

Reusable flows that other tests call via `runFlow`. Typically live in a `utils/` directory.

---

## App Launch (startApp.yml)

Launches the app with a clean state and passes build configuration via launch arguments.

```yaml
appId: com.guideline.mobile
env:
  DEFAULT_BUILD_ENV: staging

tags:
  - util

---
- launchApp:
    clearState: true
    arguments:
      isE2E: true
      buildEnv: ${BUILD_ENV || DEFAULT_BUILD_ENV}

# Dismiss any dev overlay if present
- runFlow: ./expoMenu.yml
```

**Key patterns:**
- `clearState: true` ensures clean slate every run
- `arguments` passes launch args to the app (app must read these)
- `${BUILD_ENV || DEFAULT_BUILD_ENV}` — env var with fallback default
- `tags: [util]` — excluded from test suite via `config.yml`

---

## Login (login.yml)

Handles the full login flow including MFA setup and dismissing optional dialogs.

```yaml
appId: com.guideline.mobile
env:
  DEFAULT_USERNAME: single-defcon@guideline.test
  PASSWORD: password123
  MFA_CODE: 123456

tags:
  - util

---
- runFlow: ./startApp.yml

- assertVisible:
    id: email-address-field

- tapOn:
    id: email-address-field

# Supports optional prefix for username — e.g. "reviewer-" prefix
- inputText: "${USERNAME_PREFIX || ''}${USERNAME || DEFAULT_USERNAME}"
- tapOn:
    id: password-field
- inputText: ${PASSWORD}

- runFlow: ./hideKeyboard.yml

- tapOn:
    id: submit-login-button

# iOS keychain save prompt — may or may not appear
- tapOn:
    text: "Not now"
    optional: true

# MFA setup — conditional on which MFA method is shown
- runFlow:
    when:
      visible:
        id: "mfa-method-select-Implicit"
    commands:
      - waitForAnimationToEnd
      - tapOn:
          id: "mfa-method-select-Implicit"
      - inputText: ${MFA_CODE}
      - assertVisible: "How do you want to secure your account?"
      - tapOn: ".*Authy."
      - tapOn: "Continue"
      - inputText: ${MFA_CODE}

- runFlow:
    when:
      visible:
        id: "mfa-method-select-Authenticator"
    commands:
      - tapOn:
          id: "mfa-method-select-Authenticator"
      - inputText: ${MFA_CODE}

# Interstitial screens — may or may not appear
- tapOn:
    text: Continue
    optional: true

- tapOn:
    text: Done
    optional: true
```

**Key patterns:**
- `optional: true` on taps that may or may not be needed (system dialogs, optional screens)
- Conditional `runFlow` with `when: { visible: ... }` for branching logic
- Env var defaults: callers override `USERNAME`, otherwise the default is used
- Regex in text selectors: `".*Authy."` matches partial text
- Composing utilities: calls `startApp.yml` and `hideKeyboard.yml`

---

## Hide Keyboard (hideKeyboard.yml)

Platform-specific keyboard dismissal.

```yaml
appId: com.guideline.mobile

tags:
  - util

---
- runFlow:
    when:
      platform: android
    commands:
      - hideKeyboard

- runFlow:
    when:
      platform: iOS
    commands:
      - tapOn:
          point: "50%,15%"
```

**Key patterns:**
- `when: { platform: android }` / `when: { platform: iOS }` for platform branching
- On iOS, `hideKeyboard` can be flaky — tapping above the keyboard is more reliable
- `point: "50%,15%"` uses relative coordinates (works across screen sizes)

---

## Hidden Menu Access (enableReviewerMode.yml)

Taps a hidden menu button multiple times to reveal developer settings.

```yaml
appId: com.guideline.mobile

tags:
  - util

---
- tapOn:
    id: gmenu

- runFlow:
    when:
      notVisible: "Settings"
    commands:
      - repeat:
          times: 9
          commands:
            - tapOn:
                id: gmenu
                retryTapIfNoChange: false
                optional: true

- tapOn: Settings
- tapOn:
    id: dev-option-Reviewer mode
- tapOn:
    id: screen-header-close-button
```

**Key patterns:**
- `repeat` to tap multiple times (hidden menu requires rapid taps)
- `retryTapIfNoChange: false` — disables automatic retry since the tap intentionally doesn't change the hierarchy each time
- `when: { notVisible: "Settings" }` — only repeat if the menu hasn't appeared yet
- `optional: true` on repeated taps that might not all succeed
