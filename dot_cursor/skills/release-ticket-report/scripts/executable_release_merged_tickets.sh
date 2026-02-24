#!/usr/bin/env bash
set -eo pipefail

BOARD_ID="${1:-4462}"

if ! command -v gh &> /dev/null; then
  echo "Error: gh CLI is not installed or not in PATH."
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echo "Error: jq is not installed or not in PATH."
  exit 1
fi

if ! command -v acli &> /dev/null; then
  echo "Error: acli is not installed or not in PATH."
  exit 1
fi

if ! acli jira auth status > /dev/null 2>&1; then
  echo "Error: Not authenticated with Jira. Run 'acli jira auth login --web' first."
  exit 1
fi

TAG=$(gh release list --exclude-pre-releases --limit 1 --json tagName --jq '.[0].tagName')
echo "Latest release: $TAG"
echo ""

BODY=$(gh release view "$TAG" --json body --jq '.body')
if [ -z "$BODY" ]; then
  echo "No release notes found for $TAG"
  exit 1
fi

RELEASE_TICKETS=$(echo "$BODY" | grep -oE '(RETIRE|RNDCORE)-[0-9]+' | sort -u)

SPRINT_INFO=$(acli jira board list-sprints --id "$BOARD_ID" --state active 2>&1) || true
MOBILE_SPRINT_ID=$(echo "$SPRINT_INFO" | grep -i 'Mobile' | grep -oE '│[[:space:]]+[0-9]+[[:space:]]+│' | grep -oE '[0-9]+' | head -1)

if [ -n "$MOBILE_SPRINT_ID" ]; then
  MOBILE_SPRINT_NAME=$(echo "$SPRINT_INFO" \
    | grep -E "│[[:space:]]+${MOBILE_SPRINT_ID}[[:space:]]+│" \
    | sed -E "s/.*│[[:space:]]+${MOBILE_SPRINT_ID}[[:space:]]+│[[:space:]]+(.*)[[:space:]]+│.*/\1/" \
    | head -1 | cut -d'│' -f1 | sed 's/[[:space:]]*$//')
  echo "Sprint: $MOBILE_SPRINT_NAME (ID: $MOBILE_SPRINT_ID)"
  echo ""
  JQL="project = RETIRE AND sprint = $MOBILE_SPRINT_ID AND status = 'Merged'"
else
  echo "No active Mobile sprint found. Searching all Merged tickets..."
  echo ""
  JQL="project = RETIRE AND status = 'Merged'"
fi

MERGED_JSON=$(acli jira workitem search --jql "$JQL" --json --paginate 2>/dev/null) || true
MERGED_KEYS=$(echo "$MERGED_JSON" | jq -r '.[].key' 2>/dev/null | sort -u)

if [ -z "$MERGED_KEYS" ]; then
  echo "No tickets in 'Merged' status on board $BOARD_ID."
  exit 0
fi

OVERLAP=$(comm -12 <(echo "$RELEASE_TICKETS") <(echo "$MERGED_KEYS"))

MERGED_ONLY=$(comm -23 <(echo "$MERGED_KEYS") <(echo "$RELEASE_TICKETS"))

OVERLAP_COUNT=0
MERGED_ONLY_COUNT=0
[ -n "$OVERLAP" ] && OVERLAP_COUNT=$(echo "$OVERLAP" | grep -c .)
[ -n "$MERGED_ONLY" ] && MERGED_ONLY_COUNT=$(echo "$MERGED_ONLY" | grep -c .)
MERGED_TOTAL=$(echo "$MERGED_KEYS" | grep -c .)

echo "Board merged tickets: $MERGED_TOTAL"
echo "  In release $TAG:    $OVERLAP_COUNT"
echo "  Not in release:     $MERGED_ONLY_COUNT"
echo ""

if [ -n "$OVERLAP" ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "In release $TAG AND still in Merged column ($OVERLAP_COUNT):"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  while IFS= read -r KEY; do
    SUMMARY=$(echo "$MERGED_JSON" | jq -r --arg key "$KEY" '.[] | select(.key == $key) | .fields.summary')
    ASSIGNEE=$(echo "$MERGED_JSON" | jq -r --arg key "$KEY" '.[] | select(.key == $key) | .fields.assignee.displayName // "Unassigned"')
    PR_LINE=$(echo "$BODY" | grep -m1 "$KEY" | grep -oE '/pull/[0-9]+' | grep -oE '[0-9]+' | head -1)
    PR_LINK=""
    [ -n "$PR_LINE" ] && PR_LINK="https://github.com/guideline-app/mobile-app/pull/$PR_LINE"
    printf "  %-14s %-20s %s\n" "$KEY" "$ASSIGNEE" "$SUMMARY"
    [ -n "$PR_LINK" ] && printf "  %-14s %s\n" "" "$PR_LINK"
  done <<< "$OVERLAP"
  echo ""
fi

if [ -n "$MERGED_ONLY" ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "In Merged column but NOT in release $TAG ($MERGED_ONLY_COUNT):"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  while IFS= read -r KEY; do
    SUMMARY=$(echo "$MERGED_JSON" | jq -r --arg key "$KEY" '.[] | select(.key == $key) | .fields.summary')
    ASSIGNEE=$(echo "$MERGED_JSON" | jq -r --arg key "$KEY" '.[] | select(.key == $key) | .fields.assignee.displayName // "Unassigned"')
    printf "  %-14s %-20s %s\n" "$KEY" "$ASSIGNEE" "$SUMMARY"
  done <<< "$MERGED_ONLY"
  echo ""
fi
