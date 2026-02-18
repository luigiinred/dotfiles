# Step 1: Research

Gather inputs and do optional research. This step only collects data — no ticket identification or plan approval yet.

## Workflow

### 1. Gather Inputs (Upfront)

**ALWAYS use AskQuestion** to gather all initial information upfront:

```
AskQuestion({
  "title": "Ticket Creation Setup",
  "questions": [
    {
      "id": "start",
      "prompt": "I'll help you create well-structured Jira tickets. Ready to provide requirements?",
      "options": [
        {"id": "proceed", "label": "Yes, I'll provide requirements now"},
        {"id": "abort", "label": "Cancel"}
      ]
    },
    {
      "id": "search_codebase",
      "prompt": "Should I search the codebase for relevant patterns?",
      "options": [
        {"id": "yes", "label": "Yes, search the codebase"},
        {"id": "no", "label": "No, skip"}
      ]
    },
    {
      "id": "search_online",
      "prompt": "Should I search online for established patterns/solutions?",
      "options": [
        {"id": "yes", "label": "Yes, search online"},
        {"id": "no", "label": "No, skip"}
      ]
    }
  ]
})
```

If user selects "proceed", ask conversationally: "Please provide your requirements (paste description, meeting notes, Slack threads, etc.)"

Do NOT proceed until you have requirements.

**Trust defaults:** If the user skips optional fields, accept it and move on.

**Preserve source links (automatically):** If the user provides URLs (Google Docs, Slack, Confluence), extract and save them for use in ticket Additional Context. Only preserve actual URLs — no vague "Slack conversation with X" without a link.

### 2. Research (if requested)

Do this BEFORE identifying tickets. Research often simplifies scope.

**Online research (if requested):**
- Search for established patterns, built-in config, or known solutions
- Check library/framework docs
- Look for similar issues and solutions

**Codebase exploration (if requested):**
- Existing functionality (avoid duplicate work)
- Reusable utilities, services, configs
- READMEs, AGENTS.md, conventions

**Critical rule:** No assumptions. Only include findings VERIFIED to exist. Use GitHub links to specific files and line numbers, using the current project's repository URL (e.g. from `git remote get-url origin` or the workspace).

## Output for Step 2

When gathering is complete, you have:

- **Requirements:** What the user provided (description, meeting notes, etc.).
- **Research findings (if any):** Codebase and/or online research results.
- **Preserved source links:** URLs from user input for ticket Additional Context.

Proceed to **Step 2: Write** — read and follow `steps/write.md`. The write step will identify tickets from this data and get plan approval before writing.

## Common Mistakes

| Mistake | Fix |
|--------|-----|
| Proceeding without requirements | Always gather inputs first |
| Making assumptions about codebase | Only include verified findings |
| Losing source links | Automatically preserve URLs from user input |
