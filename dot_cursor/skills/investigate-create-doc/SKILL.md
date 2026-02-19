---
name: investigate-create-doc
description: Investigate a codebase topic and produce structured markdown documentation. Collects investigation scope, explores the code, and writes a README plus sub-docs for each area. Use when the user asks to investigate, spike, research, analyze, or document how something works in the codebase.
---

# Investigate & Document

Investigate a codebase topic and produce a structured set of markdown documents with findings.

## Phase 1 — Scope the Investigation

Use AskQuestion to collect:

### 1. Topic

Ask: "What should I investigate?" — free text. Examples:
- "How account context works"
- "All the ways we fetch user data"
- "The authentication flow"

### 2. Context

Ask: "Any context I should know before starting?" — free text, optional. Examples:
- "We're planning to refactor this area"
- "Focus on hooks that query GraphQL"
- "Related to ticket RETIRE-1874"

### 3. Known areas / entry points

Ask: "Any specific files, functions, or areas I should start from?" — free text, optional.

### 4. Directory name

Suggest a kebab-case name derived from the topic. Ask the user to confirm or override.
Output goes to: `docs/{directory-name}/`

---

## Phase 2 — Plan the Investigation

1. Explore the codebase starting from entry points (or search broadly if none given)
2. Identify distinct areas/topics that emerge
3. Decide scope:
   - **Single doc** — if the topic fits in one cohesive document (under ~200 lines of findings)
   - **Multi-doc** — if there are 2+ distinct sub-topics worth their own deep-dive

Present the plan to the user:

```
I found N distinct areas to investigate:
1. {area-name} — {one-line description}
2. {area-name} — {one-line description}
...

I'll create:
  docs/{dir-name}/README.md          ← overview + links
  docs/{dir-name}/{area-name}.md     ← deep-dive per area
```

Get confirmation before writing.

---

## Phase 3 — Investigate Each Area

For each area, use explore/search subagents to gather:

- **Definitions**: where the code lives, what it exports
- **Dependencies**: what it imports/calls/depends on
- **Consumers**: what uses it (grep for imports, exclude test files)
- **Data flow**: inputs → transformations → outputs
- **Overlap**: does other code do the same thing differently?
- **Issues**: bugs, tech debt, deprecations, inconsistencies

Be exhaustive with consumers — read each file to confirm what it actually uses.

---

## Phase 4 — Write the Documents

### Directory structure

```
docs/{investigation-name}/
├── README.md                    ← main overview, links to sub-docs
├── {area-1}.md                  ← deep-dive on first area
├── {area-2}.md                  ← deep-dive on second area
└── ...
```

For single-doc investigations, just create `docs/{investigation-name}/README.md`.

### README.md format

Use the template at [templates/readme-template.md](templates/readme-template.md).

Key rules:
- Start with context (why this investigation exists)
- Include an "At a Glance" summary table
- Link to every sub-doc
- End with key findings and recommendations
- Cross-link sub-docs to each other where they relate

### Sub-doc format

Use the template at [templates/sub-doc-template.md](templates/sub-doc-template.md).

Key rules:
- Self-contained — readable without the README
- Link back to README and to related sub-docs
- Include code references with file paths
- Tables for structured data (consumers, return values, etc.)

### Cross-linking

When sub-docs reference each other, use relative links:

```markdown
See [Account Capabilities](./account-capabilities.md) for how capabilities are fetched.
```

In the README, link to each sub-doc:

```markdown
| Area | Document |
|------|----------|
| Account Capabilities | [account-capabilities.md](./account-capabilities.md) |
```

---

## Phase 5 — Review & Finalize

1. Re-read all generated docs for consistency
2. Verify all cross-links are correct
3. Check that every sub-doc is linked from the README
4. Confirm no placeholder text remains
5. Present a summary to the user of what was created
