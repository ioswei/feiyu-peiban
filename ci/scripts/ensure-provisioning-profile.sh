#!/usr/bin/env bash
# 确保 App Store 描述文件可用：fastlane sigh → ASC API → 仓库内文件
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

PROFILE_NAME="${PROFILE_NAME:-feiyu_AppStore_CI}"

try_fastlane() {
  command -v fastlane >/dev/null 2>&1 || return 1
  bash ci/scripts/fetch-appstore-profiles.sh
}

try_api() {
  python3 ci/scripts/ensure-appstore-profile.py
}

try_repo_file() {
  bash ci/scripts/install-repo-provisioning-profile.sh
}

if try_fastlane; then
  echo "✅ Provisioning profile via fastlane sigh"
elif try_api; then
  echo "✅ Provisioning profile via App Store Connect API"
elif try_repo_file; then
  echo "✅ Provisioning profile from Config/AppStore.mobileprovision"
else
  echo "::error::无法获取 App Store 描述文件" >&2
  exit 1
fi

# configure 步骤兼容两种变量名
PROFILE_DISPLAY="${PROVISIONING_PROFILE_NAME:-${IOS_RUNNER_PROFILE_NAME:-}}"
if [[ -n "$PROFILE_DISPLAY" ]]; then
  {
    echo "IOS_RUNNER_PROFILE_NAME<<EOF"
    printf '%s\n' "$PROFILE_DISPLAY"
    echo "EOF"
    echo "PROVISIONING_PROFILE_NAME<<EOF"
    printf '%s\n' "$PROFILE_DISPLAY"
    echo "EOF"
  } >> "${GITHUB_ENV:-/dev/null}"
fi

echo "Profile name: ${PROFILE_DISPLAY:-unknown}"
