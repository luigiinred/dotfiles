#!/usr/bin/env bash
set -eo pipefail

if ! command -v gh &> /dev/null; then
  echo "Error: gh CLI is not installed or not in PATH."
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echo "Error: jq is not installed or not in PATH."
  exit 1
fi

TAG="${1:-}"

if [ -z "$TAG" ]; then
  TAG=$(gh release list --exclude-pre-releases --limit 1 --json tagName --jq '.[0].tagName')
  echo "Most recent release: $TAG"
else
  echo "Release: $TAG"
fi

echo ""

BODY=$(gh release view "$TAG" --json body --jq '.body')

if [ -z "$BODY" ]; then
  echo "No release notes found for $TAG"
  exit 1
fi

TICKETS=$(echo "$BODY" | grep -oE '(RETIRE|RNDCORE)-[0-9]+' | sort -t'-' -k1,1 -k2,2n | uniq)

if [ -z "$TICKETS" ]; then
  echo "No tickets found in release notes."
  exit 0
fi

RETIRE_TICKETS=$(echo "$TICKETS" | grep '^RETIRE-' || true)
RNDCORE_TICKETS=$(echo "$TICKETS" | grep '^RNDCORE-' || true)

RETIRE_COUNT=$(echo "$RETIRE_TICKETS" | grep -c . || echo 0)
RNDCORE_COUNT=$(echo "$RNDCORE_TICKETS" | grep -c . || echo 0)
NO_TICKET_COUNT=$(echo "$BODY" | grep -E '^\* ' | grep -vcE '(RETIRE|RNDCORE)-[0-9]+' || echo 0)
TOTAL=$((RETIRE_COUNT + RNDCORE_COUNT))

echo "Found $TOTAL tickets ($RETIRE_COUNT RETIRE, $RNDCORE_COUNT RNDCORE, $NO_TICKET_COUNT untracked)"
echo ""

if [ -n "$RETIRE_TICKETS" ]; then
  echo "RETIRE tickets:"
  echo "───────────────────────────────────────────────────"
  while IFS= read -r TICKET; do
    PR_LINE=$(echo "$BODY" | grep -m1 "$TICKET" | sed -E 's/^\* //' | sed -E 's/ by @.*//' | sed -E 's/ in https:.*//')
    printf "  %-14s %s\n" "$TICKET" "$PR_LINE"
  done <<< "$RETIRE_TICKETS"
  echo ""
fi

if [ -n "$RNDCORE_TICKETS" ]; then
  echo "RNDCORE tickets:"
  echo "───────────────────────────────────────────────────"
  while IFS= read -r TICKET; do
    PR_LINE=$(echo "$BODY" | grep -m1 "$TICKET" | sed -E 's/^\* //' | sed -E 's/ by @.*//' | sed -E 's/ in https:.*//')
    printf "  %-14s %s\n" "$TICKET" "$PR_LINE"
  done <<< "$RNDCORE_TICKETS"
  echo ""
fi

NO_TICKET_LINES=$(echo "$BODY" | grep -E '^\* ' | grep -vE '(RETIRE|RNDCORE)-[0-9]+' || true)

if [ -n "$NO_TICKET_LINES" ]; then
  NO_TICKET_COUNT=$(echo "$NO_TICKET_LINES" | grep -c . || echo 0)
  echo "No ticket ($NO_TICKET_COUNT):"
  echo "───────────────────────────────────────────────────"
  while IFS= read -r LINE; do
    CLEANED=$(echo "$LINE" | sed -E 's/^\* //' | sed -E 's/ by @.*//' | sed -E 's/ in https:.*//')
    echo "  $CLEANED"
  done <<< "$NO_TICKET_LINES"
  echo ""
fi

PR_NUMBERS=$(echo "$BODY" | grep -oE '/pull/[0-9]+' | grep -oE '[0-9]+' | sort -un)

if [ -n "$PR_NUMBERS" ]; then
  QUERY='query { repository(owner: "guideline-app", name: "mobile-app") {'
  i=0
  while IFS= read -r PR; do
    QUERY="$QUERY pr$i: pullRequest(number: $PR) { number headRefName }"
    i=$((i+1))
  done <<< "$PR_NUMBERS"
  QUERY="$QUERY }}"

  BRANCHES=$(gh api graphql -f query="$QUERY" --jq '.data.repository | to_entries[] | "\(.value.number)\t\(.value.headRefName)"' 2>/dev/null | sort -t$'\t' -k2)

  if [ -n "$BRANCHES" ]; then
    BRANCH_COUNT=$(echo "$BRANCHES" | grep -c . || echo 0)
    echo "Merged branches ($BRANCH_COUNT):"
    echo "───────────────────────────────────────────────────"
    while IFS=$'\t' read -r PR_NUM BRANCH; do
      printf "  %-50s https://github.com/guideline-app/mobile-app/pull/%s\n" "$BRANCH" "$PR_NUM"
    done <<< "$BRANCHES"
    echo ""
  fi
fi

echo "Full changelog: $(echo "$BODY" | grep -oE 'https://github.com/.*/compare/.*' | head -1)"
