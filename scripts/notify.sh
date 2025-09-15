#!/usr/bin/env bash
set -euo pipefail

ENDPOINT="https://ashgw.me/api/v1/notify"

# Mask token
echo "::add-mask::${INPUT_TOKEN}"

# Only required validation: token presence
if [[ -z "${INPUT_TOKEN:-}" ]]; then
  echo "::error::token is required"
  echo "ok=false" >> "$GITHUB_OUTPUT"
  echo "http_code=0" >> "$GITHUB_OUTPUT"
  exit 1
fi

# Default type to SERVICE if not provided; normalize to UPPER
if [[ -z "${INPUT_TYPE:-}" ]]; then
  INPUT_TYPE="SERVICE"
else
  # normalize to uppercase (tolerate lowercase in workflows)
  INPUT_TYPE="$(printf '%s' "${INPUT_TYPE}" | tr '[:lower:]' '[:upper:]')"
fi

# Still require title/message
for req in INPUT_TITLE INPUT_MESSAGE; do
  if [[ -z "${!req:-}" ]]; then
    echo "::error::${req#INPUT_} is required"
    echo "ok=false" >> "$GITHUB_OUTPUT"
    echo "http_code=0" >> "$GITHUB_OUTPUT"
    exit 1
  fi
done

# JSON escape helper
json_escape() {
  local s="${1}"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

TYPE_ESC=$(json_escape "${INPUT_TYPE}")
TITLE_ESC=$(json_escape "${INPUT_TITLE}")
MESSAGE_ESC=$(json_escape "${INPUT_MESSAGE}")
SUBJECT_ESC=$(json_escape "${INPUT_SUBJECT}")
TO_ESC=$(json_escape "${INPUT_TO}")

# Build minimal JSON (include optional keys only if provided)
payload='{"type":"'"${TYPE_ESC}"'","title":"'"${TITLE_ESC}"'","message":"'"${MESSAGE_ESC}"'"}'
if [[ -n "${INPUT_SUBJECT}" ]]; then
  payload=${payload%?}',"subject":"'"${SUBJECT_ESC}"'"}'
fi
if [[ -n "${INPUT_TO}" ]]; then
  payload=${payload%?}',"to":"'"${TO_ESC}"'"}'
fi

resp_file="$(mktemp)"
http_code="$(
  curl -sS -o "${resp_file}" -w "%{http_code}" \
    -H "x-api-token: ${INPUT_TOKEN}" \
    -H "Content-Type: application/json" \
    -X POST "${ENDPOINT}" \
    --data-binary "${payload}" \
    || true
)"

ok="false"
case "${http_code}" in
  2??) ok="true" ;;
  *) ok="false" ;;
esac

echo "ok=${ok}" >> "$GITHUB_OUTPUT"
echo "http_code=${http_code}" >> "$GITHUB_OUTPUT"

if [[ "${ok}" != "true" ]]; then
  echo "::error::Request failed with HTTP ${http_code}"
  exit 1
fi

