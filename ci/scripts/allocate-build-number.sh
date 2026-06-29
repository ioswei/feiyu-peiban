#!/usr/bin/env bash
# 构建号从 10000 起，每次 CI 占用当前值并 +1 写入 ci/build-number.txt
set -euo pipefail

ROOT="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/../.." && pwd)}"
COUNTER_FILE="${ROOT}/ci/build-number.txt"
MIN_BUILD_NUMBER=10000

if [[ ! -f "$COUNTER_FILE" ]]; then
  echo "$MIN_BUILD_NUMBER" > "$COUNTER_FILE"
fi

BUILD_NUMBER="$(tr -d '[:space:]' < "$COUNTER_FILE")"
if ! [[ "$BUILD_NUMBER" =~ ^[0-9]+$ ]] || (( BUILD_NUMBER < MIN_BUILD_NUMBER )); then
  BUILD_NUMBER=$MIN_BUILD_NUMBER
fi

NEXT_BUILD_NUMBER=$((BUILD_NUMBER + 1))
echo "$NEXT_BUILD_NUMBER" > "$COUNTER_FILE"

export BUILD_NUMBER
if [[ -n "${GITHUB_ENV:-}" ]]; then
  echo "BUILD_NUMBER=${BUILD_NUMBER}" >> "$GITHUB_ENV"
fi

echo "Build number: ${BUILD_NUMBER} (next CI: ${NEXT_BUILD_NUMBER})"
