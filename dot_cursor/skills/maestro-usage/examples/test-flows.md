# Test Flow Examples

Complete test flows that verify specific user journeys.

---

## Simple Assertion Flow (loginScreenInfo.yml)

Minimal test — launch, tap, assert, close.

```yaml
appId: com.guideline.mobile
---
- runFlow: ../../utils/startApp.yml

- tapOn:
    id: login-help-button

- assertVisible: For employees
- assertVisible: For business owners

- tapOn:
    id: getting-started-close
```

**Key patterns:**
- No env vars or tags needed for simple tests
- Calls `startApp` utility, then runs its own assertions
- Multiple `assertVisible` to verify screen content

---

## Negative Testing (invalidPassword.yml)

Tests error handling by submitting wrong credentials.

```yaml
appId: com.guideline.mobile
env:
  USERNAME: single-defcon@guideline.test
  PASSWORD: incorrect_password
  MFA_CODE: 123456

---
- runFlow: ../../utils/startApp.yml

- tapOn:
    id: email-address-field

- inputText: ${USERNAME}
- tapOn:
    id: password-field
- inputText: ${PASSWORD}

- runFlow: ../../utils/hideKeyboard.yml

- tapOn:
    id: submit-login-button

- assertVisible: Invalid email or password.
```

**Key patterns:**
- Override default password with a known-bad value
- Doesn't call `login.yml` utility (needs to stop before successful login)
- Asserts error message is displayed

---

## Form Validation (forgotPassword.yml)

Tests a multi-step form with validation.

```yaml
appId: com.guideline.mobile

tags:
  - ignore

---
- runFlow: ../../utils/startApp.yml

- tapOn:
    id: forgot-password-button

- assertVisible: Forgot your password?
- assertVisible: Provide your email address and we'll send you instructions to reset your password.

# Test 1: Submit empty form
- tapOn: Send
- assertVisible: Invalid email

# Test 2: Submit invalid email
- tapOn:
    id: text-input-flat
- inputText: bad-email
- runFlow: ../../utils/hideKeyboard.yml
- tapOn: Send
- assertVisible: Invalid email

# Test 3: Submit valid email
- tapOn:
    id: text-input-flat
- inputText: "@example.com"
- runFlow: ../../utils/hideKeyboard.yml
- tapOn: Send
- assertVisible: Instructions sent!
```

**Key patterns:**
- `tags: [ignore]` — excluded from normal test runs (run manually)
- Tests multiple validation scenarios in sequence
- Checks both failure and success states

---

## Dashboard Navigation (MultipleAccountsDashboard.yml)

Tests scrolling, swiping, and navigating between screens.

```yaml
appId: com.guideline.mobile

env:
  DEFAULT_USERNAME: multiple-accounts@guideline.test

tags:
  - dashboard
  - multipleAccounts
  - accountPicker

---
- runFlow:
    file: ../../utils/login.yml
    env:
      USERNAME: ${USERNAME || DEFAULT_USERNAME}

- assertVisible:
    text: "Total retirement savings"

# Swipe bottom sheet up
- swipe:
    from:
      text: "Bottom sheet handle"
    direction: UP

- assertVisible:
    id: "unified-balance-breakdown-item"

# Regex: matches "2024 savings", "2025 savings", etc.
- assertVisible:
    text: '20\d{2} savings'

# Scroll down to find elements below the fold
- scrollUntilVisible:
    element:
      id: "manage-contribution-button"

- scrollUntilVisible:
    element:
      text: "Recent transactions"

- scrollUntilVisible:
    element:
      text: "View all transactions"

# Navigate to transactions screen and back
- tapOn:
    text: "View all transactions"

- tapOn:
    id: "screen-header-close-button"
```

**Key patterns:**
- `runFlow` with `file:` and `env:` to override login credentials
- `swipe: { from: { text: ... }, direction: UP }` — swipe from a specific element
- `scrollUntilVisible` — scroll to find off-screen elements
- Regex in assertions: `'20\d{2} savings'` matches any year
- Multiple descriptive tags for filtering

---

## Contribution Change (changeContributionFromPercentToDollar.yml)

Tests form interaction with erase and re-input.

```yaml
appId: com.guideline.mobile

env:
  DEFAULT_USERNAME: single-defcon@guideline.test

tags:
  - singleDefcon

---
- runFlow:
    file: ../../utils/login.yml
    env:
      USERNAME: ${USERNAME || DEFAULT_USERNAME}

- tapOn: Manage contributions

- tapOn:
    id: option-cents

- tapOn:
    id: currency-traditional-input

- eraseText
- assertVisible: You are opting out of contributions.
- inputText: 100
```

**Key patterns:**
- `eraseText` (no argument) clears all text in the focused field
- Assert intermediate state after clearing (zero-contribution warning)
- Simple, focused test — one specific user action

---

## Shared Subflows (changePortfolioMultipleAccounts.yml)

Uses shared subflows with index-based element selection.

```yaml
appId: com.guideline.mobile

env:
  DEFAULT_USERNAME: multiple-accounts@guideline.test

tags:
  - portfolio
  - multiple-accounts

---
- runFlow:
    file: ../../utils/login.yml
    env:
      USERNAME: ${USERNAME || DEFAULT_USERNAME}

- tapOn:
    id: portfolio-screen-tab

# Change portfolio for first account
- tapOn:
    id: "account-selector-card"
    index: 0
- runFlow: ./shared/_changePortfolio.yml
- runFlow: ./shared/_changePortfolioSuitability.yml

- tapOn:
    id: "screen-header-close-button"

# Change portfolio for second account
- tapOn:
    id: "account-selector-card"
    index: 1
- runFlow: ./shared/_changePortfolio.yml
- runFlow: ./shared/_changePortfolioSuitability.yml
- tapOn:
    id: "screen-header-close-button"
```

**Key patterns:**
- `index: 0` and `index: 1` to select between identical elements
- Shared subflows in `./shared/` prefixed with `_` (convention)
- Repeats the same subflow sequence for each account
- Relative paths: `./shared/` for sibling directory

---

## Statements (statements.yml)

Tests navigation with regex ID matching.

```yaml
appId: com.guideline.mobile
env:
  DEFAULT_USERNAME: single-defcon@guideline.test

tags:
  - singleDefcon

---
- runFlow:
    file: ../../utils/login.yml
    env:
      USERNAME: ${USERNAME || DEFAULT_USERNAME}
      USERNAME_PREFIX: ${USERNAME_PREFIX || ''}

- tapOn:
    id: profile-screen-tab

- tapOn: Statements

- tapOn:
    id: "statement-link-.*"

- assertVisible: Download Statement
```

**Key patterns:**
- `id: "statement-link-.*"` — regex ID matches any statement link (dynamic IDs)
- Passing optional `USERNAME_PREFIX` through to the login utility
