---
name: dev-workflow-start-work
description: Start or resume work on a Jira ticket by extracting ticket ID from branch name, fetching requirements via Jira MCP, creating an implementation plan, and executing it. Use when the user wants to start ticket work, resume a ticket, implement Jira requirements, begin coding on a branch, or mentions "start the ticket" or "execute the ticket".
---

# Execute Ticket

This skill automates starting or resuming work on a Jira ticket by:

1. Extracting the ticket ID from the current branch name
2. Fetching ticket details using Jira MCP
3. Creating an implementation plan
4. Confirming the plan with the user
5. Asking about commit strategy using AskQuestion tool
6. Executing the plan according to chosen commit strategy

## When to Use

Apply this skill when:

- User asks to "start the ticket" or "start work on this ticket"
- User says "execute the ticket" or "begin implementing"
- User wants to "resume ticket work"
- User mentions implementing requirements from Jira
- User is on a ticket branch and wants to start coding

## Workflow

### Step 1: Extract Ticket ID from Branch

Get the current branch name and extract the ticket ID:

```bash
git branch --show-current
```

**Expected branch format**: `RETIRE-XXXX-description` or `RETIRE-XXXX`

- If the branch contains a ticket ID (e.g., RETIRE-1871), proceed to Step 2
- If no ticket ID is found in the branch name, proceed to "No Ticket in Branch" below

### Step 2: Fetch Ticket Details

Use the Task tool with `subagent_type: "jira-expert"` to fetch the ticket details:

```
Use Task tool with:
- subagent_type: "jira-expert"
- prompt: "Fetch full details for ticket [TICKET-ID] including description, acceptance criteria, requirements, and any comments or attachments. Return a comprehensive summary."
- description: "Fetch Jira ticket details"
```

The subagent will use the Jira MCP to get:

- Ticket summary and description
- Acceptance criteria
- Requirements and specifications
- Comments and discussion
- Current status
- Any linked issues or dependencies

### Step 3: Analyze Requirements

Review the ticket details and identify:

- **Core objective**: What is the main goal?
- **Requirements**: What needs to be implemented?
- **Acceptance criteria**: How do we know it's done?
- **Technical considerations**: Are there specific approaches mentioned?
- **Dependencies**: Does this depend on other work?

### Step 4: Create Implementation Plan

Based on the requirements, create a structured plan:

1. **Break down the work** into logical steps
2. **Identify files** that need to be modified or created
3. **Determine technical approach** (architecture, patterns, libraries)
4. **List testing requirements** (unit tests, integration tests, E2E)
5. **Note any risks or blockers**

Use the TodoWrite tool to create a task list:

```
Example todos:
- [ ] Step 1: [Specific task]
- [ ] Step 2: [Specific task]
- [ ] Step 3: [Specific task]
- [ ] Step 4: Add tests
- [ ] Step 5: Verify acceptance criteria
```

### Step 5: Present Plan and Confirm

Present the plan to the user in a clear format:

```markdown
## Implementation Plan for [TICKET-ID]

**Ticket**: [Summary]

**Objective**: [Core goal]

**Approach**:

1. [Step 1 with rationale]
2. [Step 2 with rationale]
3. [Step 3 with rationale]

**Files to modify/create**:

- `path/to/file1.tsx` - [What changes]
- `path/to/file2.ts` - [What changes]

**Testing**:

- [Test approach]

**Acceptance criteria**:

- [ ] Criterion 1
- [ ] Criterion 2
```

Then ask the user: "Does this plan look good? Should I proceed with implementation?"

### Step 5.5: Ask About Commit Strategy

**BEFORE starting implementation**, use the AskQuestion tool to ask about commit strategy:

```
Use AskQuestion tool with:
- title: "Commit Strategy"
- questions: [
    {
      id: "commit_strategy",
      prompt: "How would you like me to handle commits during implementation?",
      options: [
        { id: "atomic", label: "Break work into atomic commits - commit after each logical unit of work (RECOMMENDED)" },
        { id: "single", label: "Do everything without committing - I'll review and commit at the end" },
        { id: "manual", label: "Ask me before each commit - I'll decide as we go" }
      ],
      allow_multiple: false
    }
  ]
```

**Based on user's response:**

- **atomic**: Follow the atomic commit workflow (Step 6a)
- **single**: Complete all work without committing (Step 6b)
- **manual**: Ask before each commit opportunity (Step 6c)

### Step 6a: Execute with Atomic Commits (RECOMMENDED)

For users who chose **atomic commits**:

1. **Mark first todo as in_progress**
2. **Read relevant files** to understand current state
3. **Make changes** for a single logical unit of work
4. **Commit immediately** using the `dev-workflow-prepare-commit` skill
5. **Move to next todo** and repeat

**CRITICAL**: Work in atomic commits. Each commit should represent a single, focused change.

After completing each logical step or todo, use the `dev-workflow-prepare-commit` skill to:

- Review your changes
- Run linter and tests
- Generate a conventional commit message
- Create an atomic commit

Continue this cycle until all todos are complete and acceptance criteria are met.

### Step 6b: Execute Without Committing

For users who chose **single commit at end**:

1. **Mark first todo as in_progress**
2. **Read relevant files** to understand current state
3. **Make all changes** across todos without committing
4. **Update todo status** as you complete each one
5. **Continue** until all work is complete
6. **Inform user** when ready for review and commit

**Do NOT use dev-workflow-prepare-commit skill** or create any commits during implementation.

Once all work is complete, inform the user:
"All implementation is complete. Changes are ready for your review and commit."

### Step 6c: Execute with Manual Commit Decisions

For users who chose **ask before each commit**:

1. **Mark first todo as in_progress**
2. **Read relevant files** to understand current state
3. **Make changes** for a logical unit of work
4. **When reaching a commit point**, describe what you've done and ask:
   "I've completed [description of changes]. Would you like me to commit these changes now?"
5. **If yes**: Use the `dev-workflow-prepare-commit` skill
6. **If no**: Continue to next todo
7. **Repeat** until all work is complete

Use the AskQuestion tool at each commit point with:

```
{
  id: "should_commit",
  prompt: "I've completed [specific changes]. Commit now?",
  options: [
    { id: "yes", label: "Yes, commit these changes" },
    { id: "no", label: "No, keep working" }
  ]
}
```

## Atomic Commit Workflow (When Selected)

**When the user chooses atomic commits**, work in atomic commits throughout the implementation. Each commit should focus on a single idea or change.

### What is an Atomic Commit?

An atomic commit is a single, focused change that:

- Addresses one logical concept or task
- Can be understood and reviewed independently
- Passes all tests and linting
- Has a clear, descriptive commit message

### When to Commit

Create a commit after completing:

- A single feature component
- A specific bug fix
- A refactoring of one area
- Adding tests for a specific function
- Updating configuration for one aspect

### How to Create Atomic Commits

After completing each logical unit of work:

1. **Use the dev-workflow-prepare-commit skill**: "Prepare commit"
   - Reviews your changes
   - Runs linter checks
   - Runs relevant tests
   - Generates conventional commit message
   - Creates the commit

2. **Continue to next task**: Move to the next todo item

3. **Repeat**: Continue the cycle until all work is complete

### Example Atomic Commit Flow

For a ticket requiring: "Add user profile screen with avatar upload"

**Commit 1**: Create profile screen component structure
**Commit 2**: Add user data fetching and display
**Commit 3**: Implement avatar upload functionality
**Commit 4**: Add tests for profile screen
**Commit 5**: Add tests for avatar upload

Each commit is focused, testable, and reviewable on its own.

### Benefits

- **Easier code review**: Reviewers can understand each change in isolation
- **Safer rollbacks**: Can revert specific changes without affecting others
- **Clearer history**: Git log tells the story of how the feature was built
- **Better debugging**: Can bisect to find which specific commit introduced an issue

## No Ticket in Branch

If the branch name doesn't contain a ticket ID:

Use AskQuestion tool to present options:

```
Options:
1. "I'm working on a specific ticket" → Prompt for ticket ID
2. "This is unticketed work (use RETIRE-1908)" → Use placeholder ticket
3. "Let me check out a different branch" → List recent branches
4. "I want to create a new branch for a ticket" → Use dev-workflow-initialize skill
```

**If user provides ticket ID**: Proceed with that ticket (Step 2)
**If unticketed work**: Use RETIRE-1908 as placeholder, create plan based on user description
**If switching branches**: Help them switch, then re-run workflow
**If creating new branch**: Delegate to the `dev-workflow-initialize` skill

## Edge Cases

### Ticket Not Found

If Jira MCP cannot find the ticket:

- Verify the ticket ID format (should be RETIRE-XXXX)
- Check if user has access to the ticket
- Confirm the ticket exists in Jira
- Offer to proceed with a manual description

### Jira MCP Unavailable

If the Jira MCP is not available:

- Inform the user that Jira integration is unavailable
- Ask user to provide ticket requirements manually
- Create plan based on user-provided information
- Document this limitation in the plan

### Ambiguous Requirements

If the ticket requirements are unclear:

- Ask clarifying questions before creating the plan
- Document assumptions in the plan
- Suggest discussing with the ticket author if needed

### Large or Complex Tickets

If the ticket is very large:

- Break it into smaller phases
- Create a high-level plan first
- Ask which phase to start with
- Consider suggesting splitting the ticket

## Best Practices

1. **Ask about commit strategy upfront** - Use AskQuestion tool before starting implementation
2. **Respect user's commit preference** - Follow atomic, single, or manual strategy as chosen
3. **Always read existing code** before making changes
4. **Follow project conventions** - check similar implementations
5. **Implement tests** for new functionality
6. **Update documentation** if needed
7. **Verify linter passes** when using dev-workflow-prepare-commit skill
8. **Check acceptance criteria** before marking complete
9. **Ask questions** if requirements are ambiguous
10. **Keep todos updated** regardless of commit strategy

## Integration with Other Skills

This skill works well with:

- **dev-workflow-initialize**: For creating new branches with tickets
- **dev-workflow-prepare-commit**: Used when atomic or manual commit strategy is chosen
- **push-changes**: For pushing commits when work is complete
- **dev-workflow-create-pr**: For opening pull requests after pushing
- **fix-all-tests**: If tests need updating during implementation

## Example Usage

**User**: "Start the ticket"

**Agent**:

1. Checks branch: `RETIRE-1871-android-splash-screen`
2. Extracts ticket: RETIRE-1871
3. Launches jira-expert subagent to fetch details
4. Analyzes requirements
5. Creates plan with todos:
   - [ ] Configure Android splash screen resources
   - [ ] Update app manifest for splash screen
   - [ ] Add tests for splash screen behavior
6. Presents plan: "I need to implement Android splash screen changes..."
7. Waits for confirmation
8. **Asks about commit strategy** using AskQuestion tool
9. **User selects**: "Break work into atomic commits" (atomic)
10. Begins implementation
11. **Completes first todo**: Configure resources
12. **Uses dev-workflow-prepare-commit skill**: Creates commit "feat(android): add splash screen resources"
13. **Completes second todo**: Update manifest
14. **Uses dev-workflow-prepare-commit skill**: Creates commit "feat(android): configure splash screen in manifest"
15. **Completes third todo**: Add tests
16. **Uses dev-workflow-prepare-commit skill**: Creates commit "test(android): add splash screen tests"
17. Verifies acceptance criteria and marks ticket complete

## Troubleshooting

**Issue**: Branch name doesn't match expected format

- **Solution**: Look for any pattern like RETIRE-XXXX, even if not at start of name

**Issue**: Subagent returns insufficient detail

- **Solution**: Ask follow-up questions or use direct Jira MCP calls for specific fields

**Issue**: Plan is too vague

- **Solution**: Explore codebase to understand patterns, reference similar features

**Issue**: User wants to modify the plan

- **Solution**: Update todos and plan based on feedback before executing
