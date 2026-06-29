#!/usr/bin/env bash
set -euo pipefail

# 从仓库内 Config/ 与 docs/配置信息.md 加载 CI 所需环境变量。

ROOT="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/../.." && pwd)}"
CONFIG_DIR="${ROOT}/Config"
CONFIG_DOC="${ROOT}/docs/配置信息.md"
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

if [[ -z "$P12_PASSWORD" || -z "$APPLE_TEAM_ID" || -z "$APPSTORE_ISSUER_ID" || -z "$APPSTORE_KEY_ID" ]]; then
  echo "docs/配置信息.md 需包含: P12证书密码、Apple Team ID、Issuer ID、秘钥ID"
  exit 1
fi

P8_FILE="${CONFIG_DIR}/Usr-P8/AuthKey_${APPSTORE_KEY_ID}.p8"
if [[ ! -f "$P8_FILE" ]]; then
  echo "缺少 API 密钥: ${P8_FILE}"
  exit 1
fi
P8_FILE="$(cd "$(dirname "$P8_FILE")" && pwd)/$(basename "$P8_FILE")"

KEYCHAIN_PASSWORD="${KEYCHAIN_PASSWORD:-$(openssl rand -base64 32)}"

GITHUB_ENV="${GITHUB_ENV:-/dev/null}"
{
  echo "P12_FILE_PATH=${P12_FILE}"
  echo "P12_PASSWORD=${P12_PASSWORD}"
  echo "KEYCHAIN_PASSWORD=${KEYCHAIN_PASSWORD}"
  echo "APPLE_TEAM_ID=${APPLE_TEAM_ID}"
  echo "APPSTORE_ISSUER_ID=${APPSTORE_ISSUER_ID}"
  echo "APPSTORE_KEY_ID=${APPSTORE_KEY_ID}"
  echo "APPSTORE_API_KEY_PATH=${P8_FILE}"
} >> "$GITHUB_ENV"

echo "Loaded CI config from repository (Team: ${APPLE_TEAM_ID}, Key: ${APPSTORE_KEY_ID})"
