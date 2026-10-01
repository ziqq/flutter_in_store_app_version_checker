#!/usr/bin/env bash
set -euo pipefail

task_repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
task_result="${1:?Pass the XCTest .xcresult bundle path}"
task_source="ios/flutter_in_store_app_version_checker/Sources/flutter_in_store_app_version_checker/SwiftInStoreAppVersionCheckerPlugin.swift"
mkdir -p "$task_repo/coverage"

# Export only the plugin; do not count Runner, generated registration, or Flutter.
xcrun xccov view --archive --file "$task_repo/$task_source" --json "$task_result" |
  jq -er --arg source "$task_repo/$task_source" --arg relative "$task_source" '
    .[$source] | map(select(.isExecutable)) | sort_by(.line) |
    if length == 0 then error("No Swift plugin coverage found") else
      "TN:", "SF:\($relative)",
      (.[] | "DA:\(.line),\(.executionCount)"),
      "LF:\(length)", "LH:\(map(select(.executionCount > 0)) | length)",
      "end_of_record"
    end
  ' > "$task_repo/coverage/ios.lcov.info"
