#!/usr/bin/env bash
# 选择 Xcode 26+（App Store 自 2026 起要求 iOS 26 SDK）
set -euo pipefail

select_xcode() {
  local app_path="$1"
  if [[ ! -e "$app_path" ]]; then
    return 1
  fi
  local resolved_path
  if [[ -L "$app_path" ]]; then
    resolved_path="$(readlink "$app_path")"
    if [[ "$resolved_path" != /* ]]; then
      resolved_path="/Applications/$(basename "$resolved_path")"
    fi
  else
    resolved_path="$app_path"
  fi
  sudo xcode-select -switch "$resolved_path"
  echo "Selected Xcode: $resolved_path"
  xcodebuild -version
  xcrun --sdk iphoneos --show-sdk-version
}

for candidate in \
  /Applications/Xcode_26.5.app \
  /Applications/Xcode_26.4.1.app \
  /Applications/Xcode_26.4.app \
  /Applications/Xcode_26.app \
  /Applications/Xcode.app; do
  if select_xcode "$candidate"; then
    major="$(xcrun --sdk iphoneos --show-sdk-version | cut -d. -f1)"
    if [[ "$major" -ge 26 ]]; then
      echo "TOOLCHAINS=com.apple.dt.toolchain.XcodeDefault" >> "${GITHUB_ENV:-/dev/null}"
      exit 0
    fi
  fi
done

echo "::error::未找到 Xcode 26（iOS 26 SDK）。请使用 macos-26 runner。" >&2
exit 1
