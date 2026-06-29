#!/usr/bin/env bash
# 配置手动签名 + ExportOptions（单 App 原生 Xcode 工程，无 Flutter/Shorebird 扩展）
set -euo pipefail

: "${APPLE_TEAM_ID:?APPLE_TEAM_ID required}"
: "${BUNDLE_ID:?BUNDLE_ID required}"

IOS_RUNNER_PROFILE_NAME="${IOS_RUNNER_PROFILE_NAME:-${PROVISIONING_PROFILE_NAME:?IOS_RUNNER_PROFILE_NAME or PROVISIONING_PROFILE_NAME required}}"
PROVISIONING_PROFILE_NAME="$IOS_RUNNER_PROFILE_NAME"
export IOS_RUNNER_PROFILE_NAME PROVISIONING_PROFILE_NAME
: "${EXPORT_OPTIONS_PLIST:?EXPORT_OPTIONS_PLIST required}"

XCODE_PROJECT="${XCODE_PROJECT:-FlnutSpeakPlus.xcodeproj}"
SCHEME="${SCHEME:-FlnutSpeakPlus}"

if command -v ruby >/dev/null 2>&1; then
  gem install xcodeproj --no-document >/dev/null 2>&1 || true
fi

if ruby -e 'require "xcodeproj"' 2>/dev/null; then
  ruby <<RUBY
require "xcodeproj"

project_path = "${XCODE_PROJECT}"
profile_name = ENV.fetch("IOS_RUNNER_PROFILE_NAME")
team_id = ENV.fetch("APPLE_TEAM_ID")
bundle_id = ENV.fetch("BUNDLE_ID")

project = Xcodeproj::Project.open(project_path)
project.targets.each do |target|
  target.build_configurations.each do |config|
    next unless config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] == bundle_id
    config.build_settings["DEVELOPMENT_TEAM"] = team_id
    config.build_settings["CODE_SIGN_STYLE"] = "Manual"
    config.build_settings["CODE_SIGN_IDENTITY"] = "Apple Distribution"
    config.build_settings["PROVISIONING_PROFILE_SPECIFIER"] = profile_name
  end
end
project.save
RUBY
  echo "✅ Updated ${XCODE_PROJECT} manual signing"
else
  echo "::warning::xcodeproj gem unavailable; relying on xcodebuild signing overrides"
fi

mkdir -p "$(dirname "$EXPORT_OPTIONS_PLIST")"
cat > "$EXPORT_OPTIONS_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>app-store</string>
  <key>teamID</key>
  <string>${APPLE_TEAM_ID}</string>
  <key>signingStyle</key>
  <string>manual</string>
  <key>manageAppVersionAndBuildNumber</key>
  <false/>
  <key>uploadSymbols</key>
  <true/>
  <key>provisioningProfiles</key>
  <dict>
    <key>${BUNDLE_ID}</key>
    <string>${IOS_RUNNER_PROFILE_NAME}</string>
  </dict>
</dict>
</plist>
PLIST

echo "✅ Manual signing configured → ${EXPORT_OPTIONS_PLIST}"
