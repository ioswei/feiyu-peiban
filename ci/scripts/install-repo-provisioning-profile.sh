#!/usr/bin/env bash
# 安装仓库内已提交的描述文件
set -euo pipefail

ROOT="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/../.." && pwd)}"
PROFILE_SRC="${ROOT}/Config/AppStore.mobileprovision"
PROFILE_DIR="$HOME/Library/MobileDevice/Provisioning Profiles"

if [[ ! -f "$PROFILE_SRC" ]]; then
  echo "缺少描述文件: ${PROFILE_SRC}"
  exit 1
fi

mkdir -p "$PROFILE_DIR"
PLIST="${RUNNER_TEMP:-/tmp}/repo-profile.plist"
security cms -D -i "$PROFILE_SRC" > "$PLIST"
UUID="$(/usr/libexec/PlistBuddy -c 'Print UUID' "$PLIST")"
NAME="$(/usr/libexec/PlistBuddy -c 'Print Name' "$PLIST")"
cp "$PROFILE_SRC" "${PROFILE_DIR}/${UUID}.mobileprovision"

append_env() {
  local key="$1"
  local value="$2"
  local github_env="${GITHUB_ENV:-/dev/null}"
  {
    echo "${key}<<EOF"
    printf '%s\n' "$value"
    echo "EOF"
  } >> "$github_env"
}

append_env "IOS_RUNNER_PROFILE_NAME" "$NAME"
append_env "PROVISIONING_PROFILE_NAME" "$NAME"

echo "Installed repo profile: ${NAME} (${UUID})"
