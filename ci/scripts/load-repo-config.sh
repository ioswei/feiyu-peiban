#!/usr/bin/env bash
set -euo pipefail

# 从仓库 Config/ 与 docs/配置信息.md 加载 CI 环境变量（对齐 ios-testflight-toolkit 命名，无 Shorebird）。

ROOT="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/../.." && pwd)}"
CONFIG_DIR="${ROOT}/Config"
CONFIG_DOC="${ROOT}/docs/配置信息.md"
SIGNING_DIR="${ROOT}/build/signing"
P12_FILE="${CONFIG_DIR}/P12证书.p12"
P12_FILE="$(cd "$(dirname "$P12_FILE")" && pwd)/$(basename "$P12_FILE")"

if [[ ! -f "$CONFIG_DOC" ]]; then
  echo "缺少配置: ${CONFIG_DOC}"
  exit 1
fi

if [[ ! -f "$P12_FILE" ]]; then
  echo "缺少证书: ${P12_FILE}"
  exit 1
fi

read_config_value() {
  local pattern="$1"
  awk -v pat="$pattern" '$0 ~ pat { getline; print; exit }' "$CONFIG_DOC" | tr -d '[:space:]'
}

P12_PASSWORD="$(read_config_value 'P12证书密码')"
APPLE_TEAM_ID="$(read_config_value 'Apple Team ID')"
APPSTORE_ISSUER_ID="$(read_config_value 'Issuer ID')"
APPSTORE_KEY_ID="$(read_config_value '秘钥ID')"
BUNDLE_ID="$(read_config_value 'Bundle ID')"

if [[ -z "$P12_PASSWORD" || -z "$APPLE_TEAM_ID" || -z "$APPSTORE_ISSUER_ID" || -z "$APPSTORE_KEY_ID" || -z "$BUNDLE_ID" ]]; then
  echo "docs/配置信息.md 需包含: P12证书密码、Apple Team ID、Issuer ID、秘钥ID、Bundle ID"
  exit 1
fi

P8_FILE="${CONFIG_DIR}/Usr-P8/AuthKey_${APPSTORE_KEY_ID}.p8"
if [[ ! -f "$P8_FILE" ]]; then
  echo "缺少 API 密钥: ${P8_FILE}"
  exit 1
fi
P8_FILE="$(cd "$(dirname "$P8_FILE")" && pwd)/$(basename "$P8_FILE")"

source "${ROOT}/ci/scripts/allocate-build-number.sh"
BUILD_NUMBER="${BUILD_NUMBER:-10000}"
MARKETING_VERSION="1.0.0"
BUILD_NAME="1.0.0"

KEYCHAIN_PASSWORD="${KEYCHAIN_PASSWORD:-$(openssl rand -base64 32)}"
APP_NAME="${APP_NAME:-飞语陪伴}"
TESTFLIGHT_GROUP="${TESTFLIGHT_GROUP:-test}"
DISTRIBUTE_EXTERNAL="${DISTRIBUTE_EXTERNAL:-true}"
NOTIFY_EXTERNAL_TESTERS="${NOTIFY_EXTERNAL_TESTERS:-true}"
SUBMIT_BETA_REVIEW="${SUBMIT_BETA_REVIEW:-true}"
WAIT_TIMEOUT_SECONDS="${WAIT_TIMEOUT_SECONDS:-3600}"
WHATS_NEW="${WHATS_NEW:-修复若干问题并优化体验。}"

mkdir -p "$SIGNING_DIR"

append_env() {
  local key="$1"
  local value="$2"
  local github_env="${GITHUB_ENV:-/dev/null}"
  if [[ "$value" == *$'\n'* || "$value" == *" "* ]]; then
    {
      echo "${key}<<EOF"
      printf '%s\n' "$value"
      echo "EOF"
    } >> "$github_env"
  else
    echo "${key}=${value}" >> "$github_env"
  fi
}

append_env "P12_FILE_PATH" "$P12_FILE"
append_env "P12_PASSWORD" "$P12_PASSWORD"
append_env "KEYCHAIN_PASSWORD" "$KEYCHAIN_PASSWORD"
append_env "APPLE_TEAM_ID" "$APPLE_TEAM_ID"
append_env "TEAM_ID" "$APPLE_TEAM_ID"
append_env "APPSTORE_ISSUER_ID" "$APPSTORE_ISSUER_ID"
append_env "APPSTORE_KEY_ID" "$APPSTORE_KEY_ID"
append_env "ASC_KEY_ID" "$APPSTORE_KEY_ID"
append_env "ASC_ISSUER_ID" "$APPSTORE_ISSUER_ID"
append_env "ASC_KEY_PATH" "$P8_FILE"
append_env "APPSTORE_API_KEY_PATH" "$P8_FILE"
append_env "BUNDLE_ID" "$BUNDLE_ID"
append_env "APP_NAME" "$APP_NAME"
append_env "SIGNING_DIR" "$SIGNING_DIR"
append_env "BUILD_NUMBER" "$BUILD_NUMBER"
append_env "BUILD_NAME" "$BUILD_NAME"
append_env "MARKETING_VERSION" "$MARKETING_VERSION"
append_env "TESTFLIGHT_GROUP" "$TESTFLIGHT_GROUP"
append_env "DISTRIBUTE_EXTERNAL" "$DISTRIBUTE_EXTERNAL"
append_env "NOTIFY_EXTERNAL_TESTERS" "$NOTIFY_EXTERNAL_TESTERS"
append_env "SUBMIT_BETA_REVIEW" "$SUBMIT_BETA_REVIEW"
append_env "WAIT_TIMEOUT_SECONDS" "$WAIT_TIMEOUT_SECONDS"
append_env "WHATS_NEW" "$WHATS_NEW"
append_env "EXPORT_OPTIONS_PLIST" "${ROOT}/ci/ExportOptions.generated.plist"
append_env "PROFILE_NAME" "feiyu_AppStore_CI"

echo "Loaded CI config (Team: ${APPLE_TEAM_ID}, Bundle: ${BUNDLE_ID}, Build: ${BUILD_NAME}+${BUILD_NUMBER})"
