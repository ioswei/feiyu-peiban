#!/usr/bin/env bash
# 上传 TestFlight → 等待 build → 分发外部测试组（参考 ios-testflight-toolkit/lib/distribute_testflight.sh）
set -euo pipefail

: "${APP_STORE_CONNECT_API_KEY_JSON:?APP_STORE_CONNECT_API_KEY_JSON required}"
: "${BUNDLE_ID:?BUNDLE_ID required}"
: "${BUILD_NUMBER:?BUILD_NUMBER required}"

TESTFLIGHT_GROUP="${TESTFLIGHT_GROUP:-test}"
WAIT_TIMEOUT_SECONDS="${WAIT_TIMEOUT_SECONDS:-3600}"
DISTRIBUTE_EXTERNAL="${DISTRIBUTE_EXTERNAL:-true}"
NOTIFY_EXTERNAL_TESTERS="${NOTIFY_EXTERNAL_TESTERS:-true}"
SUBMIT_BETA_REVIEW="${SUBMIT_BETA_REVIEW:-true}"
CHANGELOG="${WHATS_NEW:-${CHANGELOG:-}}"

if ! command -v fastlane >/dev/null 2>&1; then
  echo "❌ 需要 fastlane: brew install fastlane" >&2
  exit 1
fi

pilot_builds_table() {
  fastlane pilot builds \
    --api_key_path "$APP_STORE_CONNECT_API_KEY_JSON" \
    --app_identifier "$BUNDLE_ID" 2>/dev/null || true
}

build_listed() {
  pilot_builds_table | grep -qw "$BUILD_NUMBER"
}

distribute_testflight_once() {
  echo "▶ 分发到外部测试组: ${TESTFLIGHT_GROUP}"
  local distribute_args=(
    --api_key_path "$APP_STORE_CONNECT_API_KEY_JSON"
    --app_identifier "$BUNDLE_ID"
    --build_number "$BUILD_NUMBER"
    --groups "$TESTFLIGHT_GROUP"
    --distribute_only true
  )
  if [[ "$DISTRIBUTE_EXTERNAL" == true ]]; then
    distribute_args+=(--distribute_external true)
  fi
  if [[ "$NOTIFY_EXTERNAL_TESTERS" == true ]]; then
    distribute_args+=(--notify_external_testers true)
  fi
  if [[ "$SUBMIT_BETA_REVIEW" == true ]]; then
    distribute_args+=(--submit_beta_review true)
  fi
  if [[ -n "$CHANGELOG" ]]; then
    distribute_args+=(--changelog "$CHANGELOG")
  fi
  distribute_args+=(--uses_non_exempt_encryption false)

  fastlane pilot distribute "${distribute_args[@]}"
}

if [[ "${DISTRIBUTE_ONLY:-false}" != true && -n "${IPA_PATH:-}" && -f "$IPA_PATH" ]]; then
  echo "▶ 上传 IPA 到 TestFlight: $IPA_PATH"
  upload_args=(
    --api_key_path "$APP_STORE_CONNECT_API_KEY_JSON"
    --ipa "$IPA_PATH"
    --skip_waiting_for_build_processing true
  )
  if [[ -n "$CHANGELOG" ]]; then
    upload_args+=(--changelog "$CHANGELOG")
  fi
  fastlane pilot upload "${upload_args[@]}"
fi

echo "▶ 等待 build ${BUILD_NUMBER} 出现在 TestFlight（最长 ${WAIT_TIMEOUT_SECONDS}s）..."
waited=0
found=false
while (( waited < WAIT_TIMEOUT_SECONDS )); do
  if build_listed; then
    found=true
    echo "✅ Build ${BUILD_NUMBER} 已出现在 TestFlight"
    break
  fi
  echo "   等待 build ${BUILD_NUMBER} 出现在 TestFlight..."
  sleep 30
  waited=$((waited + 30))
done

if [[ "$found" != true ]]; then
  echo "::error::超时：build ${BUILD_NUMBER} 尚未出现在 TestFlight" >&2
  exit 1
fi

echo "▶ 等待 build ${BUILD_NUMBER} 可分发并提交 Beta 审核（最多 600s）..."
ready_waited=0
ready=false
while (( ready_waited < 600 )); do
  if distribute_testflight_once; then
    ready=true
    break
  fi
  echo "   build 尚未就绪，30s 后重试 distribute..."
  sleep 30
  ready_waited=$((ready_waited + 30))
done

if [[ "$ready" != true ]]; then
  echo "::error::build ${BUILD_NUMBER} 已上传但 distribute/submit 失败" >&2
  exit 1
fi

echo "✅ 已分发到外部组 ${TESTFLIGHT_GROUP} 并尝试提交 Beta 审核"
