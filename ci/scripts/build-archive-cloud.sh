#!/usr/bin/env bash
set -euo pipefail

: "${APPLE_TEAM_ID:?APPLE_TEAM_ID is required}"
: "${PROVISIONING_PROFILE_NAME:?PROVISIONING_PROFILE_NAME is required}"

SCHEME="${SCHEME:-FlnutSpeakPlus}"
PROJECT="${XCODE_PROJECT:-FlnutSpeakPlus.xcodeproj}"
CONFIGURATION="${BUILD_CONFIGURATION:-Release}"
ARCHIVE_PATH="${ARCHIVE_PATH:-build/FlnutSpeakPlus.xcarchive}"
EXPORT_PATH="${EXPORT_PATH:-build/export}"
EXPORT_OPTIONS_PATH="${EXPORT_OPTIONS_PLIST:-ci/ExportOptions.generated.plist}"

mkdir -p build

if [[ -n "${KEYCHAIN_PATH:-}" && -n "${KEYCHAIN_PASSWORD:-}" ]]; then
  security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
  security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
  security list-keychain -d user -s "$KEYCHAIN_PATH"
fi

xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -archivePath "$ARCHIVE_PATH" \
  -destination "generic/platform=iOS" \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
  CODE_SIGN_IDENTITY="Apple Distribution" \
  PROVISIONING_PROFILE_SPECIFIER="$PROVISIONING_PROFILE_NAME"

xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS_PATH"

IPA_PATH="$(find "$EXPORT_PATH" -maxdepth 1 -name '*.ipa' -print -quit)"
if [[ -z "$IPA_PATH" ]]; then
  echo "No IPA found in ${EXPORT_PATH}"
  exit 1
fi

echo "IPA_PATH=${IPA_PATH}" >> "${GITHUB_ENV:-/dev/null}"
echo "Built IPA: ${IPA_PATH}"
