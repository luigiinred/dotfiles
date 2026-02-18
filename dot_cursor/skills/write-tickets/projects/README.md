# Project configs

Each **`.md` file** in this directory is a **project** that defines which JIRA fields to use when creating tickets for that repo. Example: `mobile-app.md`.

## How it's used

- **If the current workspace is one of these projects:** Use that project's config automatically. Do not ask the user for project/component/sprint.
- **If the current workspace is not a known project:** Ask the user whether to use a project config. Use AskQuestion:
  - "Should I use a project config for JIRA fields?"
  - Options: list each project file (e.g. "mobile-app — for guideline-app/mobile-app") plus "No — I'll specify project/component/sprint" or "Let me specify".

Matching is by repository: compare the current repo (e.g. from `git remote get-url origin`) to the **repo** in each project's .md file. For example `https://github.com/guideline-app/mobile-app` or `git@github.com:guideline-app/mobile-app.git` → **mobile-app** (use `projects/mobile-app.md`).

## Adding a project

Add a file `projects/<name>.md` that includes:

- **Repo:** The GitHub repo identifier (e.g. `guideline-app/mobile-app` or full URL).
- **JIRA fields:** Project key, component (name and ID if needed), sprint (name and custom field ID), JIRA base URL for links.
- **Notes:** Any rules (e.g. "Do not ask user for project/component/sprint when in this repo").
