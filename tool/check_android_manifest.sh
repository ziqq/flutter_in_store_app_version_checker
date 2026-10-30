#!/usr/bin/env bash
set -euo pipefail

# Fails when the merged manifest of the Android example declares a
# permission that the plugin must not add to host applications.

task_repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
task_variant="${1:-debug}"
task_manifests="$task_repo/example/build/app/intermediates/merged_manifests/$task_variant"
task_forbidden=(
  "android.permission.REQUEST_INSTALL_PACKAGES"
)

task_manifest="$(find "$task_manifests" -name AndroidManifest.xml -print -quit 2>/dev/null || true)"
if [[ -z "$task_manifest" ]]; then
  echo "Merged manifest for '$task_variant' not found in $task_manifests." >&2
  echo "Build the example first: cd example && flutter build apk --$task_variant" >&2
  exit 1
fi

task_failed=0
for task_permission in "${task_forbidden[@]}"; do
  if grep -q "android:name=\"$task_permission\"" "$task_manifest"; then
    echo "Forbidden permission $task_permission found in $task_manifest." >&2
    task_failed=1
  fi
done

if [[ "$task_failed" -ne 0 ]]; then
  exit 1
fi
echo "Merged manifest has no forbidden permissions: $task_manifest"
