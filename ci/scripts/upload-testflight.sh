#!/usr/bin/env bash
set -euo pipefail

: "${APPSTORE_ISSUER_ID:?APPSTORE_ISSUER_ID is required}"
: "${APPSTORE_KEY_ID:?APPSTORE_KEY_ID is required}"
: "${IPA_PATH:?IPA_PATH is required}"

if [[ -n "${APPSTORE_API_KEY_PATH:-}" && -f "$APPSTORE_API_KEY_PATH" ]]; then
  KEY_PATH="$APPSTORE_API_KEY_PATH"
elif [[ -n "${APPSTORE_PRIVATE_KEY:-}" ]]; then
  KEY_DIR="${HOME}/.private_keys"
  KEY_PATH="${KEY_DIR}/AuthKey_${APPSTORE_KEY_ID}.p8"
  mkdir -p "$KEY_DIR"
  printf '%s\n' "$APPSTORE_PRIVATE_KEY" > "$KEY_PATH"
  chmod 600 "$KEY_PATH"
else
  echo "APPSTORE_API_KEY_PATH or APPSTORE_PRIVATE_KEY is required"
  exit 1
fi

UPLOAD_ARGS=(
  --upload-app
  --type ios
  --file "$IPA_PATH"
  --apiKey "$APPSTORE_KEY_ID"
  --apiIssuer "$APPSTORE_ISSUER_ID"
  --apiKeyPath "$KEY_PATH"
)

xcrun altool "${UPLOAD_ARGS[@]}"
