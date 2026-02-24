#!/usr/bin/env bash
set -eo pipefail

BOARD_ID="${1:-4462}"

if ! command -v acli &> /dev/null; then
  echo "Error: acli is not installed or not in PATH."
  exit 1
fi

if ! acli jira auth status > /dev/null 2>&1; then
  echo "Error: Not authenticated. Run 'acli jira auth login --web' first."
  exit 1
fi

if [ -z "$BOARD_ID" ]; then
  echo "Available boards for RETIRE project:"
  echo ""
  acli jira board search --project RETIRE
  echo ""
  echo "Usage: $0 <board_id>"
  echo "  Example: $0 4462"
  exit 0
fi

echo "Finding active sprints for board $BOARD_ID..."
echo ""

SPRINT_INFO=$(acli jira board list-sprints --id "$BOARD_ID" --state active 2>&1) || true

SPRINT_IDS=$(echo "$SPRINT_INFO" | grep -oE '│[[:space:]]+[0-9]+[[:space:]]+│' | grep -oE '[0-9]+')

if [ -z "$SPRINT_IDS" ]; then
  echo "No active sprints found (board may be kanban). Searching all Merged tickets..."
  echo ""
  acli jira workitem search \
    --jql "project = RETIRE AND status = 'Merged'" \
    --fields "key,summary,assignee,issuetype" \
    --paginate
  exit 0
fi

while IFS= read -r SPRINT_ID; do
  SPRINT_NAME=$(echo "$SPRINT_INFO" \
    | grep -E "│[[:space:]]+${SPRINT_ID}[[:space:]]+│" \
    | sed -E "s/.*│[[:space:]]+${SPRINT_ID}[[:space:]]+│[[:space:]]+(.*)[[:space:]]+│.*/\1/" \
    | head -1 \
    | sed 's/[[:space:]]*$//' \
    | cut -d'│' -f1 \
    | sed 's/[[:space:]]*$//')

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Sprint: $SPRINT_NAME (ID: $SPRINT_ID)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  acli jira workitem search \
    --jql "project = RETIRE AND sprint = $SPRINT_ID AND status = 'Merged'" \
    --fields "key,summary,assignee,issuetype" \
    --paginate
  echo ""
done <<< "$SPRINT_IDS"
