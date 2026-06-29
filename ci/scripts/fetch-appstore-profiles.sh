#!/usr/bin/env bash
# fastlane sigh 拉取 App Store Profile（单 App，无扩展；参考 ios-testflight-toolkit）
set -euo pipefail

: "${APP_STORE_CONNECT_API_KEY_JSON:?required}"
: "${APPLE_TEAM_ID:?required}"
: "${BUNDLE_ID:?required}"
: "${SIGNING_DIR:?required}"

APP_NAME="${APP_NAME:-飞语陪伴}"
PROFILE_NAME="${PROFILE_NAME:-feiyu_AppStore_CI}"

fetch_profile() {
  local bundle_id="$1"
  local profile_name="$2"
  local filename="$3"
  fastlane sigh \
    --api_key_path "$APP_STORE_CONNECT_API_KEY_JSON" \
    --app_identifier "$bundle_id" \
    --team_id "$APPLE_TEAM_ID" \
    --platform ios \
    --provisioning_name "$profile_name" \
    --filename "$filename" \
    --output_path "$SIGNING_DIR" \
    --force
}

install_profile() {
  local src="$1"
  local prefix="$2"
  local var_name="${prefix}_PROFILE_NAME"
  local plist="${SIGNING_DIR}/${prefix}.plist"
  local profile_dir="$HOME/Library/MobileDevice/Provisioning Profiles"

  mkdir -p "$profile_dir"
  security cms -D -i "$src" > "$plist"
  local uuid name
  uuid="$(/usr/libexec/PlistBuddy -c 'Print UUID' "$plist")"
  name="$(/usr/libexec/PlistBuddy -c 'Print Name' "$plist")"
  cp "$src" "$profile_dir/${uuid}.mobileprovision"

  printf -v "$var_name" '%s' "$name"
  export "$var_name"

  if [[ -n "${GITHUB_ENV:-}" ]]; then
    {
      echo "${var_name}<<EOF"
      printf '%s\n' "$name"
      echo "EOF"
    } >> "$GITHUB_ENV"
    {
      echo "PROVISIONING_PROFILE_NAME<<EOF"
      printf '%s\n' "$name"
      echo "EOF"
    } >> "$GITHUB_ENV"
  fi
}

mkdir -p "$SIGNING_DIR"

echo "▶ 拉取 App Store Profile (fastlane sigh --force)..."
fetch_profile "$BUNDLE_ID" "$PROFILE_NAME" "runner.mobileprovision"
install_profile "${SIGNING_DIR}/runner.mobileprovision" "IOS_RUNNER"

echo "✅ Profile ready: ${IOS_RUNNER_PROFILE_NAME}"
