#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${PANDA_BASE_URL:-http://app.gusto-dev.com:3000}"
COOKIE_FILE="/tmp/gusto_cookies.txt"
EMAIL="manage_all_super_user@gusto-dev.com"
PASSWORD="password1"

rm -f "$COOKIE_FILE"

echo "Fetching CSRF token from ${BASE_URL}/login ..."
CSRF_TOKEN=$(curl -s -c "$COOKIE_FILE" -b "$COOKIE_FILE" "${BASE_URL}/login" \
  | grep -o 'csrf-token" content="[^"]*"' \
  | sed 's/csrf-token" content="//;s/"$//')

if [[ -z "$CSRF_TOKEN" ]]; then
  echo "ERROR: Could not fetch CSRF token. Is the server running at ${BASE_URL}?" >&2
  exit 1
fi

echo "Logging in as ${EMAIL} ..."
ENCODED_TOKEN=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''${CSRF_TOKEN}'''))")

HTTP_CODE=$(curl -s -c "$COOKIE_FILE" -b "$COOKIE_FILE" \
  -X POST "${BASE_URL}/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "authenticity_token=${ENCODED_TOKEN}&user%5Bemail%5D=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${EMAIL}'))")&user%5Bpassword%5D=${PASSWORD}" \
  -o /dev/null -w "%{http_code}")

if [[ "$HTTP_CODE" == "302" ]]; then
  echo "Login successful. Cookies saved to ${COOKIE_FILE}"
else
  echo "ERROR: Login failed with HTTP ${HTTP_CODE}" >&2
  exit 1
fi
