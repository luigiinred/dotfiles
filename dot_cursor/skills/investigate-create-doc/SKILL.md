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

## Phase 2 — Define Questions (DO NOT INVESTIGATE YET)

The goal of this phase is to understand **what needs to be answered**, not to answer anything.

1. Do a **light** codebase scan — just enough to identify the shape of the problem (file names, export names, rough structure). Do NOT read full files or trace consumers yet.
2. From the topic, context, and light scan, produce a list of **questions that need answering**.
3. Group questions by area/theme. Each group may become a sub-doc later.
4. Write the questions to the README immediately using the "Questions to Answer" section in the template.

**STOP HERE.** Present the questions to the user and get confirmation before proceeding. The user may add, remove, or reword questions.

```
Questions to answer:

## {Area 1}
- Q: {question}?
- Q: {question}?

## {Area 2}
- Q: {question}?

Does this cover everything, or should I add/change any questions?
```

---

## Phase 3 — Plan the Investigation

After the user confirms the questions:

1. Map each question group to a sub-doc
2. Decide scope:
   - **Single doc** — if all questions fit in one cohesive document (under ~200 lines of findings)
   - **Multi-doc** — if there are 2+ distinct areas worth their own deep-dive
3. Present the proposed doc structure:

```
docs/{dir-name}/README.md          ← overview, questions, links
docs/{dir-name}/{area-name}.md     ← answers for each area
```

Get confirmation before investigating.

---

## Phase 4 — Investigate Each Area (Parallel Subagents)

**Launch one subagent per area** using the Task tool. Run up to 4 in parallel; queue the rest.

Each subagent receives a self-contained prompt with:
1. The area name and its questions to answer
2. Known entry points / file paths for that area
3. The full context from Phase 1 (topic, background, any user notes)
4. Instructions on what to return

### Subagent prompt template

```
Investigate "{area-name}" in this codebase. Answer these questions:

{paste the questions for this area from the README}

Context: {topic and background from Phase 1}
Entry points: {known files/functions for this area}

For each question, gather evidence by:
- Finding definitions: where the code lives, what it exports
- Tracing dependencies: what it imports/calls/depends on
- Finding ALL consumers: grep for imports, exclude .spec. and .test. files
- Reading each consumer to confirm what specific data it uses
- Checking for overlap: does other code do the same thing differently?
- Noting issues: bugs, tech debt, deprecations, inconsistencies

Return a structured report with:
- Answer to each question with supporting evidence (file paths, code references)
- A table of all consumers found (Consumer | File | What it uses)
- A list of issues/observations
- Any related areas that connect to other parts of the investigation
```

Use `subagent_type: "explore"` with thoroughness "very thorough" for each.

### After all subagents return

1. Collect all results
2. Cross-reference findings between areas (look for contradictions or missing connections)
3. Proceed to Phase 5

---

## Phase 5 — Write the Documents

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

## Phase 6 — Review & Finalize

1. Re-read all generated docs for consistency
2. Verify all cross-links are correct
3. Check that every sub-doc is linked from the README
4. Confirm no placeholder text remains
5. Present a summary to the user of what was created
