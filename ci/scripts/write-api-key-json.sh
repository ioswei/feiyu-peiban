#!/usr/bin/env bash
set -euo pipefail

: "${ASC_KEY_ID:?ASC_KEY_ID is required}"
: "${ASC_ISSUER_ID:?ASC_ISSUER_ID is required}"
: "${ASC_KEY_PATH:?ASC_KEY_PATH is required}"

JSON_PATH="${RUNNER_TEMP:-/tmp}/asc_api_key.json"

ruby -rjson -e '
  data = {
    key_id: ENV.fetch("ASC_KEY_ID"),
    issuer_id: ENV.fetch("ASC_ISSUER_ID"),
    key: File.read(ENV.fetch("ASC_KEY_PATH")),
    duration: 1200,
    in_house: false
  }
  File.write(ARGV[0], JSON.pretty_generate(data))
' "$JSON_PATH"

echo "APP_STORE_CONNECT_API_KEY_JSON=${JSON_PATH}" >> "${GITHUB_ENV:-/dev/null}"
echo "Prepared App Store Connect API key JSON at ${JSON_PATH}"
