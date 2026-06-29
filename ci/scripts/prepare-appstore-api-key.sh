#!/usr/bin/env bash
set -euo pipefail

: "${APPSTORE_ISSUER_ID:?APPSTORE_ISSUER_ID is required}"
: "${APPSTORE_KEY_ID:?APPSTORE_KEY_ID is required}"
: "${APPSTORE_PRIVATE_KEY:?APPSTORE_PRIVATE_KEY is required}"

KEY_DIR="${RUNNER_TEMP:-/tmp}/appstoreconnect"
KEY_PATH="${KEY_DIR}/AuthKey_${APPSTORE_KEY_ID}.p8"

mkdir -p "$KEY_DIR"
printf '%s\n' "$APPSTORE_PRIVATE_KEY" > "$KEY_PATH"
chmod 600 "$KEY_PATH"

echo "APPSTORE_API_KEY_PATH=${KEY_PATH}" >> "${GITHUB_ENV:-/dev/null}"
echo "Prepared App Store Connect API key at ${KEY_PATH}"
