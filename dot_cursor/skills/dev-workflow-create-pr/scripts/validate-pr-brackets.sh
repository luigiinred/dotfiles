#!/bin/bash
# Validate PR body contains required [[[ ]]] brackets

# Read JSON from stdin
input=$(cat)

# Extract the command from tool_input
command=$(echo "$input" | jq -r '.tool_input.command // ""')

# Only check gh pr create commands
if ! echo "$command" | grep -q "gh pr create"; then
	exit 0
fi

# Check for bracket pattern in the command
if ! echo "$command" | grep -qE '\[{3}' || ! echo "$command" | grep -qE '\]{3}'; then
	cat >&2 <<-'EOF'

	# [FAIL]: /dev-workflow-create-pr (@../SKILL.md)
	------------------------------------------
	# [ERROR]: PR body missing required [[[ and ]]] brackets from template.
	# [REASON]: Triple bracket blocks are parsed into our CHANGELOG. Omitting them is strictly disallowed.
	# [FIX]:
	#	 - The brackets MUST be present in the PR body, AND
	#	 - The brackets MUST enclose these fields:

	[[[
	**jira:** ...
	**what:** ...
	**why:** ...
	**who:** ...
	]]]
	EOF
	exit 2
fi

exit 0