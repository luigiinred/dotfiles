#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${PANDA_BASE_URL:-http://app.gusto-dev.com:3000}"
COOKIE_FILE="/tmp/gusto_cookies.txt"

STATE="CA"
BENEFITS_TYPE="external"
BUILD_MULTIPLE="1"
SKIP_CONTRACTORS="0"
DISMISS_NOTIFICATIONS="1"
ONBOARDING_COMPANY="0"  # 0 = yes generate payrolls, 1 = no

while [[ $# -gt 0 ]]; do
  case $1 in
    --state) STATE="$2"; shift 2 ;;
    --benefits) BENEFITS_TYPE="$2"; shift 2 ;;
    --employees) BUILD_MULTIPLE="$2"; shift 2 ;;
    --skip-contractors) SKIP_CONTRACTORS="$2"; shift 2 ;;
    --no-payrolls) ONBOARDING_COMPANY="1"; shift ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ ! -f "$COOKIE_FILE" ]]; then
  echo "ERROR: No cookie file at ${COOKIE_FILE}. Run get-auth-token.sh first." >&2
  exit 1
fi

echo "Fetching demo accounts page for CSRF token ..."
CSRF_TOKEN=$(curl -s -b "$COOKIE_FILE" -c "$COOKIE_FILE" "${BASE_URL}/panda/demo_accounts" \
  | grep -o 'name="authenticity_token" value="[^"]*"' \
  | head -1 \
  | sed 's/name="authenticity_token" value="//;s/"$//')

if [[ -z "$CSRF_TOKEN" ]]; then
  echo "ERROR: Could not fetch CSRF token from demo accounts page. Are you authenticated?" >&2
  exit 1
fi

ENCODED_TOKEN=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''${CSRF_TOKEN}'''))")

echo "Creating demo account (state=${STATE}, benefits=${BENEFITS_TYPE}, multiple_employees=${BUILD_MULTIPLE}) ..."

HTTP_CODE=$(curl -s -b "$COOKIE_FILE" -c "$COOKIE_FILE" \
  -X POST "${BASE_URL}/panda/demo_accounts/create_account_async" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "authenticity_token=${ENCODED_TOKEN}&demo_account%5Bbenefits_type%5D=${BENEFITS_TYPE}&demo_account%5Bfiling_address_state%5D=${STATE}&demo_account%5Bsetup_retirement_benefits%5D=1&demo_account%5Bbuild_multiple%5D=${BUILD_MULTIPLE}&demo_account%5Bskip_contractors%5D=${SKIP_CONTRACTORS}&demo_account%5Bdismiss_notifications%5D=${DISMISS_NOTIFICATIONS}&demo_account%5Bonboarding_company%5D=${ONBOARDING_COMPANY}&demo_account%5Bemployee_work_state%5D=${STATE}" \
  -o /dev/null -w "%{http_code}")

if [[ "$HTTP_CODE" == "302" ]]; then
  echo "Demo account creation submitted successfully."
  echo ""
  echo "The account is being built asynchronously by Sidekiq."
  echo "Check ${BASE_URL}/panda/demo_accounts in your browser for the account details."
  echo ""
  echo "Once ready, log into the demo company at:"
  echo "  URL:      ${BASE_URL}/login"
  echo "  Password: password5"
  echo "  (Use the payroll admin email shown on the Panda demo accounts page)"
else
  echo "ERROR: Form submission failed with HTTP ${HTTP_CODE}" >&2
  exit 1
fi
