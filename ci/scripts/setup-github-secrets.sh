#!/usr/bin/env bash
set -euo pipefail

# 从本地 Config/ 与 docs/配置信息.md 同步 GitHub Actions Secrets。
# 依赖：gh CLI 已登录且有 repo secret 写入权限。

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CONFIG_DIR="${ROOT}/Config"
CONFIG_DOC="${ROOT}/docs/配置信息.md"

P12_FILE="${CONFIG_DIR}/P12证书.p12"
P8_FILE="${CONFIG_DIR}/Usr-P8/AuthKey_KN9KZ9QXJZ.p8"

if ! command -v gh >/dev/null 2>&1; then
  echo "请先安装并登录 GitHub CLI: https://cli.github.com/"
  exit 1
fi

if [[ ! -f "$P12_FILE" ]]; then
  echo "缺少证书: ${P12_FILE}"
  exit 1
fi

if [[ ! -f "$P8_FILE" ]]; then
  echo "缺少 App Store Connect API 密钥: ${P8_FILE}"
  exit 1
fi

if [[ ! -f "$CONFIG_DOC" ]]; then
  echo "缺少配置文档: ${CONFIG_DOC}"
  exit 1
fi

read_config_value() {
  local pattern="$1"
  awk -v pat="$pattern" '$0 ~ pat { getline; print; exit }' "$CONFIG_DOC" | tr -d '[:space:]'
}

P12_PASSWORD="$(read_config_value 'P12证书密码')"
APPSTORE_ISSUER_ID="$(read_config_value 'Issuer ID')"
APPSTORE_KEY_ID="$(read_config_value '秘钥ID')"

if [[ -z "$P12_PASSWORD" || -z "$APPSTORE_ISSUER_ID" || -z "$APPSTORE_KEY_ID" ]]; then
  echo "docs/配置信息.md 需包含: P12证书密码、Issuer ID、秘钥ID"
  exit 1
fi

TMPKC="$(mktemp -d)/build.keychain-db"
KC_PASS="$(openssl rand -base64 24)"
trap 'security delete-keychain "$TMPKC" >/dev/null 2>&1 || true' EXIT

security create-keychain -p "$KC_PASS" "$TMPKC"
security unlock-keychain -p "$KC_PASS" "$TMPKC"
security import "$P12_FILE" -k "$TMPKC" -P "$P12_PASSWORD" -T /usr/bin/codesign >/dev/null

IDENTITY_LINE="$(security find-identity -v -p codesigning "$TMPKC" | grep 'Apple Distribution' | head -1 || true)"
if [[ -z "$IDENTITY_LINE" ]]; then
  echo "P12 中未找到 Apple Distribution 证书"
  exit 1
fi

APPLE_TEAM_ID="$(echo "$IDENTITY_LINE" | sed -nE 's/.*\(([A-Z0-9]{10})\).*/\1/p')"
if [[ -z "$APPLE_TEAM_ID" ]]; then
  echo "无法从证书解析 Team ID"
  exit 1
fi

BUILD_CERTIFICATE_BASE64="$(base64 -i "$P12_FILE" | tr -d '\n')"
APPSTORE_PRIVATE_KEY="$(cat "$P8_FILE")"
KEYCHAIN_PASSWORD="$(openssl rand -base64 32)"

echo "目标仓库: $(gh repo view --json nameWithOwner -q .nameWithOwner)"
echo "Bundle ID: com.ivangaro.feiyuunte"
echo "Team ID: ${APPLE_TEAM_ID}"
echo "App Store Key ID: ${APPSTORE_KEY_ID}"
echo ""

gh secret set BUILD_CERTIFICATE_BASE64 --body "$BUILD_CERTIFICATE_BASE64"
gh secret set P12_PASSWORD --body "$P12_PASSWORD"
gh secret set KEYCHAIN_PASSWORD --body "$KEYCHAIN_PASSWORD"
gh secret set APPLE_TEAM_ID --body "$APPLE_TEAM_ID"
gh secret set APPSTORE_ISSUER_ID --body "$APPSTORE_ISSUER_ID"
gh secret set APPSTORE_KEY_ID --body "$APPSTORE_KEY_ID"
gh secret set APPSTORE_PRIVATE_KEY --body "$APPSTORE_PRIVATE_KEY"

echo ""
echo "GitHub Secrets 已同步完成。"
echo "在 Actions 中手动运行「App Store Release」，或推送 tag（如 v1.0.0）触发打包上传。"
