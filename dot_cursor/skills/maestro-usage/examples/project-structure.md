# Project Structure Example

How to organize Maestro flows, utilities, scripts, and configuration.

---

## Directory Layout

```
maestro/
├── config.yml                    # Test suite configuration
├── utils/                        # Shared utility flows and scripts
│   ├── startApp.yml              # Launch app with clean state
│   ├── login.yml                 # Full login flow with MFA handling
│   ├── hideKeyboard.yml          # Platform-specific keyboard dismissal
│   ├── expoMenu.yml              # Dismiss dev overlays
│   ├── enableReviewerMode.yml    # Enable hidden dev settings
│   ├── createUser.js             # API: create test user
│   ├── createUserExistingAccount.js
│   ├── api.js                    # Shared JS utility functions
│   └── findLocalOnboardingAccounts.js
├── flows/                        # Test flows organized by feature
│   ├── auth/
│   │   ├── forgotPassword.yml
│   │   ├── invalidPassword.yml
│   │   ├── loginScreenInfo.yml
│   │   ├── LoginWithGustoWelcome.yml
│   │   ├── LoginAccrue.yml
│   │   ├── LoginDefconAndAccrue.yml
│   │   ├── LoginDefconAndUnsupported.yml
│   │   └── LoginPersonalIraAndUnsupported.yml
│   ├── dashboard/
│   │   ├── MultipleAccountsDashboard.yml
│   │   ├── SingleDefconDashboard.yml
│   │   ├── SingleIRADashboard.yml
│   │   ├── SingleSEPIRADashboard.yml
│   │   ├── MultipleDefconDashboard.yml
│   │   ├── DashboardAccountsScreens.yml
│   │   ├── DefconAndCashDashboard.yml
│   │   └── DefconAndHsaDashboard.yml
│   ├── contribution/
│   │   ├── changeContributionFromPercentToDollar.yml
│   │   ├── MultipleAccountsContributions.yml
│   │   ├── payPeriodEmployerMatch.yml
│   │   └── payPeriodEmployerMatchNonElectiveContributions.yml
│   ├── portfolio/
│   │   ├── shared/               # Subflows used only by portfolio tests
│   │   │   ├── _changePortfolio.yml
│   │   │   ├── _changePortfolioSuitability.yml
│   │   │   └── _customPortfolio.yml
│   │   ├── changePortfolioMultipleAccounts.yml
│   │   ├── changePortfolioSingleDefcon.yml
│   │   ├── portfolioSingleDefcon.yml
│   │   └── ...
│   ├── profile/
│   │   ├── statements.yml
│   │   ├── settings.yml
│   │   ├── planDetails.yml
│   │   └── ...
│   └── onboarding/
│       ├── shared/
│       │   └── _openOnboardingUrl.yml
│       ├── onboarding.yml
│       └── onboardingExistingAccount.yml
```

---

## Conventions

### Naming

| Pattern | Meaning |
|---------|---------|
| `_prefix.yml` | Shared subflow (not a standalone test) |
| `camelCase.yml` | Test flow names |
| `utils/` | Global utilities referenced by all features |
| `shared/` | Feature-scoped subflows (inside feature dirs) |

### Relative Paths

Flows reference utilities relative to their own location:

```
flows/auth/forgotPassword.yml     → ../../utils/startApp.yml     (2 levels up)
flows/portfolio/shared/_change.yml → ../../../utils/hideKeyboard.yml (3 levels up)
flows/dashboard/Dashboard.yml     → ../../utils/login.yml         (2 levels up)
```

### Tags

```yaml
tags:
  - util              # Utility flow — excluded from test suite
  - ignore            # Manually-run test — excluded from suite
  - dashboard         # Feature category
  - singleDefcon      # Account type
  - multipleAccounts  # Account type
  - onboarding        # Feature category
  - portfolio         # Feature category
  - accountPicker     # Specific component
```

---

## config.yml

Controls which flows are included in a `maestro test` run.

```yaml
# Include all flows recursively under flows/
flows: flows/**

# Exclude utility and manually-run flows
excludeTags:
  - ignore
  - util
  - singleSepIra     # This account is currently broken
```

**Key points:**
- `flows: flows/**` recursively includes all `.yml` files under `flows/`
- `excludeTags` removes any flow tagged with those tags
- This means `utils/` flows (tagged `util`) are never run directly — only via `runFlow`
- Broken tests can be excluded by tag without deleting them

### Running subsets

```bash
# Run all tests (respecting config.yml exclusions)
maestro test maestro/

# Run only dashboard tests
maestro test --include-tags dashboard maestro/

# Run only single-account tests, skipping portfolio
maestro test --include-tags singleDefcon --exclude-tags portfolio maestro/

# Run a single flow directly (ignores config.yml)
maestro test maestro/flows/auth/forgotPassword.yml
```

---

## How Flows Reference Each Other

```
                    config.yml
                       │
                       ▼
              ┌─── flows/** ───┐
              │                │
     flows/auth/          flows/dashboard/
     forgotPassword.yml   MultipleAccountsDashboard.yml
          │                     │
          ▼                     ▼
     utils/startApp.yml    utils/login.yml
          │                     │
          ▼                     ├──▶ utils/startApp.yml
     utils/expoMenu.yml        ├──▶ utils/hideKeyboard.yml
                                └──▶ (inline MFA logic)

     flows/onboarding/
     onboarding.yml
          │
          ├──▶ utils/createUser.js     (onFlowStart)
          └──▶ shared/_openOnboardingUrl.yml
                    │
                    └──▶ utils/startApp.yml
```

- **Test flows** call **utility flows** for setup (launch, login)
- **Utility flows** compose other utilities (startApp calls expoMenu)
- **Feature subflows** (`shared/_*.yml`) encapsulate reusable sequences within a feature
- **JS scripts** run in `onFlowStart` or via `runScript` for API setup
- Data flows from JS → YAML via `output` object (e.g., `output.onboardingLink`)
