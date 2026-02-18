# Mobile Jira Fields

Use these defaults when creating tickets for the mobile-app codebase.

## Project

| Field | Value |
|-------|-------|
| Project Key | RETIRE |

## Required Fields

| Field | Value | Jira ID |
|-------|-------|---------|
| Component | Consumer | `17013` |
| Sprint | Mobile Refinement | `17210` (customfield_10020) |

## Notes

- Do NOT ask the user for project/component when working in mobile-app - use these defaults automatically
- Sprint field uses `customfield_10020` in the Jira API
- Component is set via the `components` array field with the component ID
