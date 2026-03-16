---
name: panda-create-user
description: Create a demo user and company on local Panda via curl. Authenticates against the local dev server, submits the demo account form, and returns login credentials. Use when the user asks to create a local user, demo account, demo company, or needs a test account on local Panda.
---

# Panda Create User

Create a demo account on the local Zenpayroll dev server via curl.

## Prerequisites

- Local server must be running (`bin/server`)
- Server accessible at `http://app.gusto-dev.com:3000`

## Workflow

### Step 1: Authenticate

Run the auth script to get a session cookie:

```bash
bash ~/.cursor/skills/panda-create-user/scripts/get-auth-token.sh
```

This logs in as `manage_all_super_user@gusto-dev.com` and saves cookies to `/tmp/gusto_cookies.txt`.

Verify output shows `Login successful`.

### Step 2: Create Demo Account

Run the create script with the saved cookies:

```bash
bash ~/.cursor/skills/panda-create-user/scripts/create-demo-account.sh
```

The script accepts optional arguments to customize the account:

| Argument | Default | Options |
|----------|---------|---------|
| `--state` | `CA` | Any US state abbreviation |
| `--benefits` | `external` | `external`, `hi`, `new_plans` |
| `--employees` | `1` (yes) | `1` (multiple) or `0` (single) |
| `--skip-contractors` | `0` (no) | `1` (skip) or `0` (include) |
| `--no-payrolls` | not set | flag to skip generating payrolls |

Example with options:

```bash
bash ~/.cursor/skills/panda-create-user/scripts/create-demo-account.sh --state NY --benefits hi --employees 0
```

### Step 3: Verify

The script prints success/failure. The demo account is created asynchronously via Sidekiq, so it may take 30-60 seconds to fully populate.

The user can log into the demo company at `http://app.gusto-dev.com:3000/login` using the payroll admin email shown on the Panda demo accounts page with password `password5`.

## Troubleshooting

- **Server not running**: Start with `bin/server` from the zenpayroll root
- **Auth fails**: Server may need `rails db:migrate` or the Colima VM may need restarting (`colima stop gusto && colima start gusto`)
- **Port 3000 in use**: Kill the process with `lsof -ti :3000 | xargs kill`
- **Cookie file missing**: Re-run Step 1 to get fresh cookies
