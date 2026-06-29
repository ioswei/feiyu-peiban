#!/usr/bin/env bash
set -euo pipefail

: "${APPLE_TEAM_ID:?APPLE_TEAM_ID is required}"
: "${APPSTORE_ISSUER_ID:?APPSTORE_ISSUER_ID is required}"
: "${APPSTORE_KEY_ID:?APPSTORE_KEY_ID is required}"
: "${APPSTORE_API_KEY_PATH:?APPSTORE_API_KEY_PATH is required}"

SCHEME="${SCHEME:-FlnutSpeakPlus}"
PROJECT="${XCODE_PROJECT:-FlnutSpeakPlus.xcodeproj}"
CONFIGURATION="${BUILD_CONFIGURATION:-Release}"
ARCHIVE_PATH="${ARCHIVE_PATH:-build/FlnutSpeakPlus.xcarchive}"
EXPORT_PATH="${EXPORT_PATH:-build/export}"
EXPORT_OPTIONS_TEMPLATE="${EXPORT_OPTIONS_TEMPLATE:-ci/ExportOptions.appstore-automatic.plist}"
EXPORT_OPTIONS_PATH="${RUNNER_TEMP:-/tmp}/ExportOptions.plist"

AUTH_FLAGS=(
  -allowProvisioningUpdates
  -authenticationKeyPath "$APPSTORE_API_KEY_PATH"
  -authenticationKeyID "$APPSTORE_KEY_ID"
  -authenticationKeyIssuerID "$APPSTORE_ISSUER_ID"
)

mkdir -p build

sed -e "s/__APPLE_TEAM_ID__/${APPLE_TEAM_ID}/g" "$EXPORT_OPTIONS_TEMPLATE" > "$EXPORT_OPTIONS_PATH"

xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -archivePath "$ARCHIVE_PATH" \
  -destination "generic/platform=iOS" \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
  "${AUTH_FLAGS[@]}" \
  | xcpretty

xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS_PATH" \
  "${AUTH_FLAGS[@]}" \
  | xcpretty

IPA_PATH="$(find "$EXPORT_PATH" -maxdepth 1 -name '*.ipa' -print -quit)"
if [[ -z "$IPA_PATH" ]]; then
  echo "No IPA found in ${EXPORT_PATH}"
  exit 1
fi

echo "IPA_PATH=${IPA_PATH}" >> "${GITHUB_ENV:-/dev/null}"
echo "Built IPA: ${IPA_PATH}"
