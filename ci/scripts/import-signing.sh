#!/usr/bin/env bash
set -euo pipefail

: "${BUILD_CERTIFICATE_BASE64:?BUILD_CERTIFICATE_BASE64 is required}"
: "${P12_PASSWORD:?P12_PASSWORD is required}"
: "${KEYCHAIN_PASSWORD:?KEYCHAIN_PASSWORD is required}"
: "${PROVISIONING_PROFILE_BASE64:?PROVISIONING_PROFILE_BASE64 is required}"

KEYCHAIN_PATH="${RUNNER_TEMP:-/tmp}/build.keychain-db"
CERT_PATH="${RUNNER_TEMP:-/tmp}/build_certificate.p12"
PROFILE_PATH="${RUNNER_TEMP:-/tmp}/build.mobileprovision"
PROFILE_DIR="${HOME}/Library/MobileDevice/Provisioning Profiles"

echo "$BUILD_CERTIFICATE_BASE64" | base64 --decode > "$CERT_PATH"
echo "$PROVISIONING_PROFILE_BASE64" | base64 --decode > "$PROFILE_PATH"

security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"

security import "$CERT_PATH" \
  -P "$P12_PASSWORD" \
  -A \
  -t cert \
  -f pkcs12 \
  -k "$KEYCHAIN_PATH"
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"

security list-keychain -d user -s "$KEYCHAIN_PATH"

mkdir -p "$PROFILE_DIR"
PROFILE_PLIST="${RUNNER_TEMP:-/tmp}/profile.plist"
security cms -D -i "$PROFILE_PATH" > "$PROFILE_PLIST"
PROFILE_UUID="$(/usr/libexec/PlistBuddy -c 'Print :UUID' "$PROFILE_PLIST")"
cp "$PROFILE_PATH" "$PROFILE_DIR/${PROFILE_UUID}.mobileprovision"

PROFILE_NAME="$(/usr/libexec/PlistBuddy -c 'Print :Name' "$PROFILE_PLIST")"
echo "PROVISIONING_PROFILE_NAME=${PROFILE_NAME}" >> "${GITHUB_ENV:-/dev/null}"
echo "Installed provisioning profile: ${PROFILE_NAME} (${PROFILE_UUID})"

rm -f "$CERT_PATH"
