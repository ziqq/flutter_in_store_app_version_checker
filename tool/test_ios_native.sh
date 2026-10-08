#!/usr/bin/env bash
set -euo pipefail

task_repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
task_simulator="${IOS_SIMULATOR_ID:?Set IOS_SIMULATOR_ID to a dedicated test simulator; active simulators are never selected automatically}"

mkdir -p "$task_repo/example/build"
task_results="$(mktemp -d "$task_repo/example/build/native-ios-results-XXXXXX")"
xcodebuild test \
  -workspace "$task_repo/example/ios/Runner.xcworkspace" \
  -scheme Runner -configuration Debug \
  -destination "platform=iOS Simulator,id=$task_simulator" \
  -derivedDataPath "$task_repo/example/build/native-ios" \
  -resultBundlePath "$task_results/Tests.xcresult" \
  -enableCodeCoverage YES -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=NO

bash "$task_repo/tool/export_ios_coverage.sh" "$task_results/Tests.xcresult"
