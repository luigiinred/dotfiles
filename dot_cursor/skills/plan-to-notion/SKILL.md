---
name: plan-to-notion
description: Publish implementation plans to Notion instead of local markdown. Use whenever creating an implementation plan, architecture plan, spike plan, migration plan, or any planning document. Replaces local docs/ output with a Notion page under the Planning docs page.
---

# Plan to Notion

Publish implementation plans directly to Notion as child pages of the "Planning docs" page.

**Config:** Read [config.json](config.json) to get the `planning_page_id`.

## When This Applies

Use this skill instead of writing local markdown whenever producing:
- Implementation plans
- Architecture plans
- Spike / investigation plans
- Migration plans
- Feature plans
- Any structured planning document

**Do NOT write plans to local `docs/` directories.** Always publish to Notion.

## Notion Markdown Spec

Before writing content, fetch the Notion enhanced markdown spec:

```
FetchMcpResource: notion://docs/enhanced-markdown-spec
```

Use this spec for all content formatting.

## Plan Template

Every plan page must use this structure. Skip sections that have no content, but always include Overview, Scope, Tasks, and Open Questions.

```markdown
## Overview
One-paragraph summary of what this plan covers and why.

## Goals
- Goal 1
- Goal 2

## Non-Goals
- Explicitly out of scope item 1

## Scope
What parts of the codebase / system are affected.

| Area | Files / Modules | Impact |
|------|----------------|--------|
| ... | ... | ... |

## Approach
Narrative description of the implementation strategy. Include trade-offs considered and why this approach was chosen.

## Tasks
Ordered list of implementation steps. Each task should be actionable and independently mergeable where possible.

- [ ] Task 1 — description
- [ ] Task 2 — description
- [ ] Task 3 — description

## Risks & Mitigations
| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| ... | ... | ... |

## Open Questions
- Question 1
- Question 2

## References
- Links to tickets, PRs, docs, Figma, Slack threads
```

## Workflow

1. Read `config.json` to get `planning_page_id`
2. Generate the plan content following the template above
3. Create the Notion page immediately:

```json
CallMcpTool: user-notiongusto / notion-create-pages
{
  "parent": { "page_id": "<planning_page_id>" },
  "pages": [{
    "properties": { "title": "<Plan Title>" },
    "content": "<plan content in Notion markdown>"
  }]
}
```

4. Return the Notion page URL to the user

## Title Convention

Format: `[Project/Feature] Implementation Plan`

Examples:
- "DonutChart Implementation Plan"
- "Auth Refactor Implementation Plan"
- "iOS 18 Migration Plan"

## Integration with Other Skills

When another skill (e.g. `dev-workflow-start-work`, `investigate-create-doc`) would normally produce a local planning document, this skill takes over the output step. The investigation / research phase stays the same — only the final write destination changes from local markdown to Notion.
