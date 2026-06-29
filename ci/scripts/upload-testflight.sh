#!/usr/bin/env bash
set -euo pipefail

: "${APPSTORE_ISSUER_ID:?APPSTORE_ISSUER_ID is required}"
: "${APPSTORE_KEY_ID:?APPSTORE_KEY_ID is required}"
: "${APPSTORE_PRIVATE_KEY:?APPSTORE_PRIVATE_KEY is required}"
: "${IPA_PATH:?IPA_PATH is required}"

KEY_DIR="${HOME}/.private_keys"
KEY_PATH="${KEY_DIR}/AuthKey_${APPSTORE_KEY_ID}.p8"

mkdir -p "$KEY_DIR"
printf '%s\n' "$APPSTORE_PRIVATE_KEY" > "$KEY_PATH"
chmod 600 "$KEY_PATH"

xcrun altool --upload-app \
  --type ios \
  --file "$IPA_PATH" \
  --apiKey "$APPSTORE_KEY_ID" \
  --apiIssuer "$APPSTORE_ISSUER_ID"
