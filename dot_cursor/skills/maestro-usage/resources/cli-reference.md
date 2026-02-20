# Maestro CLI Reference

Complete reference for all Maestro CLI commands and their flags, sourced from `maestro --help`.

---

## Global Options

These flags can be used with any command:

| Flag | Description |
|------|-------------|
| `-h`, `--help` | Display help message |
| `-v`, `--version` | Display CLI version |
| `--verbose` | Enable verbose logging |
| `--[no-]ansi`, `--[no-]color` | Enable/disable colors and ANSI output |
| `-p`, `--platform=<platform>` | Select platform to run on (`ios`, `android`, `web`) |
| `--udid`, `--device=<deviceId>` | Device ID to run on. Comma-separated for multiple: `--device "Emu_1,Emu_2"` |

### Finding Device IDs

```bash
# Android
adb devices

# iOS
xcrun simctl list devices booted
```

---

## maestro test

Run one or more flows locally on a simulator/emulator.

```
maestro test [OPTIONS] <flowFiles>...
```

### Arguments

| Argument | Description |
|----------|-------------|
| `<flowFiles>...` | One or more flow files or directories containing flows |

### Options

| Flag | Description |
|------|-------------|
| `-e`, `--env=KEY=VAL` | Pass environment variables (repeatable) |
| `-c`, `--continuous` | Watch mode — re-runs test on file change |
| `--config=<file>` | Workspace config YAML (default: `config.yaml` in root) |
| `--format=<format>` | Report format: `JUNIT`, `HTML`, `NOOP` (default) |
| `--output=<file>` | Report output file path |
| `--include-tags=<tags>` | Only run flows with these tags (comma-separated) |
| `--exclude-tags=<tags>` | Skip flows with these tags (comma-separated) |
| `--debug-output=<path>` | Custom path for debug logs/screenshots (default: `~/.maestro/tests/`) |
| `--flatten-debug-output` | No subfolders or timestamps in debug output (useful for CI) |
| `--test-output-dir=<path>` | Directory for screenshots and test artifacts (separate from debug output) |
| `--test-suite-name=<name>` | Name for the test suite |
| `--headless` | Run in headless mode (web only) |
| `--analyze` | [Beta] Enhance output with AI insights |
| `-s`, `--shards=<N>` | Number of parallel shards |
| `--shard-all=<N>` | Run all tests across N connected devices |
| `--shard-split=<N>` | Split tests evenly across N connected devices |
| `--[no-]reinstall-driver` | Reinstall driver before test (iOS: xctestrunner; Android: driver + server apps) |
| `--api-key=<key>` | [Beta] API key |
| `--api-url=<url>` | [Beta] API base URL |

### Examples

```bash
# Run a single flow
maestro test flow.yaml

# Run multiple flows
maestro test login.yaml dashboard.yaml checkout.yaml

# Run all flows in a directory
maestro test maestro/flows/

# With env vars
maestro test -e USERNAME=test@example.com -e PASSWORD=secret flow.yaml

# Generate JUnit report
maestro test --format junit --output results/report.xml flows/

# Generate HTML report
maestro test --format html flows/

# Filter by tags
maestro test --include-tags smoke,critical flows/
maestro test --exclude-tags slow flows/
maestro test --include-tags regression --exclude-tags flaky flows/

# Watch mode (re-runs on save)
maestro test -c flow.yaml

# On a specific device
maestro --device emulator-5554 test flow.yaml

# Parallel sharding across devices
maestro test --shard-split 3 flows/

# CI-friendly debug output
maestro test --debug-output ./test-debug --flatten-debug-output flows/

# With workspace config
maestro test --config maestro/config.yaml flows/
```

---

## maestro cloud

Run tests in Maestro Cloud — no local simulator/emulator needed. Blocks until complete by default.

```
maestro cloud [OPTIONS]
```

### Options

| Flag | Description |
|------|-------------|
| `--apiKey`, `--api-key=<key>` | API key (required) |
| `--projectId`, `--project-id=<id>` | Project ID |
| `--app-file=<file>` | App binary (.apk, .ipa, .zip) |
| `--appBinaryId`, `--app-binary-id=<id>` | ID of previously uploaded app binary |
| `--flows=<path>` | Flow file or directory |
| `-e`, `--env=KEY=VAL` | Environment variables (repeatable) |
| `--include-tags=<tags>` | Only run flows with these tags |
| `--exclude-tags=<tags>` | Skip flows with these tags |
| `--format=<format>` | Report format: `JUNIT`, `HTML`, `NOOP` |
| `--output=<file>` | Report output file (default: `report.xml`) |
| `--async` | Exit immediately, don't wait for results |
| `--name=<name>` | Name for the upload |
| `--test-suite-name=<name>` | Test suite name |
| `--config=<file>` | Workspace config YAML |
| `--device-locale=<locale>` | Device locale (e.g., `de_DE`) |
| `--device-model=<model>` | Device model (e.g., `iPhone-11`). iOS only. |
| `--device-os=<os>` | OS version (e.g., `iOS-18-2`). iOS only. |
| `--android-api-level=<level>` | Android API level |
| `--mapping=<file>` | dSYM (iOS) or Proguard mapping (Android) |
| `--branch=<branch>` | Branch name for the upload |
| `--commitSha`, `--commit-sha=<sha>` | Commit SHA for the upload |
| `--pullRequestId`, `--pull-request-id=<id>` | PR ID for the upload |
| `--repoName`, `--repo-name=<name>` | Repository name |
| `--repoOwner`, `--repo-owner=<owner>` | Repository owner |
| `--apiUrl`, `--api-url=<url>` | API base URL |

### Examples

```bash
# Basic cloud run
maestro cloud --api-key $MAESTRO_API_KEY --app-file app.apk --flows flows/

# Using a project ID
maestro cloud --api-key $KEY --project-id $PID --app-file app.zip --flows flows/

# With CI metadata
maestro cloud --api-key $KEY \
  --app-file app.ipa \
  --flows flows/ \
  --branch main \
  --commit-sha $(git rev-parse HEAD) \
  --repo-name my-app \
  --repo-owner my-org

# Async (don't wait for results)
maestro cloud --api-key $KEY --app-file app.apk --flows flows/ --async

# With JUnit report
maestro cloud --api-key $KEY --app-file app.apk --flows flows/ --format junit --output results.xml

# Specific iOS device/OS
maestro cloud --api-key $KEY --app-file app.ipa --flows flows/ --device-model iPhone-11 --device-os iOS-18-2
```

---

## maestro record

Record a video of a flow execution. Produces a polished video for demos and bug reports.

```
maestro record [OPTIONS] <flowFile> [<outputFile>]
```

### Options

| Flag | Description |
|------|-------------|
| `<flowFile>` | The flow file to record |
| `[<outputFile>]` | Output video file (only with `--local`) |
| `--local` | [Beta] Render locally instead of in cloud |
| `-e`, `--env=KEY=VAL` | Environment variables (repeatable) |
| `--config=<file>` | Workspace config YAML |
| `--debug-output=<path>` | Custom debug output path |
| `--apple-team-id=<id>` | Apple Team ID (10-char string) |

### Examples

```bash
# Record via cloud
maestro record flow.yaml

# Record locally
maestro record --local flow.yaml output.mp4

# With env vars
maestro record -e USERNAME=test flow.yaml
```

---

## maestro studio

Launch an interactive browser-based IDE for writing and testing flows. Provides a visual element picker and a REPL for executing commands.

```
maestro studio
```

No additional options. Use global `--device` flag to target a specific device:

```bash
maestro --device emulator-5554 studio
```

---

## maestro start-device

Start or create a simulator/emulator matching the Maestro Cloud device specs.

```
maestro start-device --platform=<platform> [OPTIONS]
```

### Options

| Flag | Description |
|------|-------------|
| `--platform=<platform>` | **Required.** `ios` or `android` |
| `--os-version=<version>` | OS version. iOS: `16`, `17`, `18`. Android: `28`-`33`. |
| `--device-locale=<locale>` | Locale code (e.g., `de_DE`) |
| `--force-create` | Override existing device if it already exists |

**Supported device types:** iPhone 11 (iOS), Pixel 6 (Android).

### Examples

```bash
maestro start-device --platform ios
maestro start-device --platform android --os-version 33
maestro start-device --platform ios --os-version 18 --device-locale en_US
maestro start-device --platform android --force-create
```

---

## maestro mcp

Start the Maestro MCP server, exposing device/automation commands as MCP tools over STDIO for LLM agents.

```
maestro mcp [OPTIONS]
```

| Flag | Description |
|------|-------------|
| `--working-dir=<dir>` | Base directory for resolving file paths |

---

## maestro chat

Ask questions about Maestro documentation and code using Maestro GPT.

```
maestro chat [OPTIONS]
```

| Flag | Description |
|------|-------------|
| `--apiKey`, `--api-key=<key>` | API key |
| `--apiUrl`, `--api-url=<url>` | API base URL |
| `--ask=<question>` | Get an answer and exit immediately (non-interactive) |

### Examples

```bash
# Interactive chat
maestro chat

# One-shot question
maestro chat --ask "How do I scroll until an element is visible?"
```

---

## maestro download-samples

Download sample apps and flows for trying Maestro without your own app.

```
maestro download-samples [-o <outputDirectory>]
```

| Flag | Description |
|------|-------------|
| `-o`, `--output=<dir>` | Output directory |

---

## maestro login / logout

Authenticate with Maestro Cloud.

```bash
maestro login
maestro logout
```

---

## maestro bugreport

Generate a bug report for the Maestro team.

```bash
maestro bugreport
```

---

## config.yaml (Workspace Configuration)

Place a `config.yaml` in your test directory root (or pass via `--config`) to control test suite execution.

```yaml
# Execution order and failure handling
executionOrder:
  continueOnFailure: false        # Stop on first failure (default: false)
  flowsOrder:
    - "setup.yaml"                # Run this first
    - "*"                         # Then all other top-level flows

# Flow inclusion patterns
#   *           — all top-level flows
#   subFolder/* — all flows in a subfolder
#   **          — all flows recursively
```

### Pattern Examples

```yaml
executionOrder:
  flowsOrder:
    - "auth/login.yaml"           # Specific flow first
    - "auth/*"                    # Then all auth flows
    - "dashboard/*"               # Then dashboard
    - "**"                        # Then everything else recursively
```

---

## Environment Variables

### Shell-level Maestro env vars

| Variable | Description |
|----------|-------------|
| `MAESTRO_CLI_*` | CLI configuration variables |
| `MAESTRO_CLOUD_*` | Cloud configuration variables |
| `MAESTRO_*` | Any `MAESTRO_`-prefixed var is accessible in JavaScript scripts |

### Precedence

1. `-e` flag on CLI (highest priority)
2. `env` in flow header
3. Shell environment variables with `MAESTRO_` prefix
