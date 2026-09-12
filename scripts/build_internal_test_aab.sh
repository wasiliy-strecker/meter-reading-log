#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "Error: $*" >&2
  exit 1
}

if [[ $# -ne 0 ]]; then
  fail "No arguments supported. Set the version in pubspec.yaml; this helper always builds store/release."
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
FLUTTER_BIN="${FLUTTER_BIN:-flutter}"
cd "$PROJECT_DIR"

command -v "$FLUTTER_BIN" >/dev/null 2>&1 || fail "Flutter not found. Set FLUTTER_BIN to its executable path."
command -v jq >/dev/null 2>&1 || fail "jq is required to verify Android build metadata."

version="$(sed -n 's/^version:[[:space:]]*//p' pubspec.yaml | tr -d '\r')"
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?\+[1-9][0-9]*$ ]]; then
  fail "pubspec.yaml needs a version such as 1.0.0+3 with an explicit positive build number."
fi
version_name="${version%%+*}"
version_code="${version##*+}"

bundle_dir="$PROJECT_DIR/build/app/outputs/bundle/storeRelease"
source_bundle="$bundle_dir/app-store-release.aab"
# Keep deliveries outside Flutter's bundle discovery directory. Otherwise
# Flutter may report an older, renamed AAB as the result of a new build.
output_dir="$PROJECT_DIR/build/releases/internal-test"
filename="zaehlerstandlog-${version_name}-build-${version_code}-internal-test.aab"
output="$output_dir/$filename"
for existing in "$output" "$bundle_dir/$filename"; do
  if [[ -e "$existing" || -L "$existing" ]]; then
    fail "Release artifact already exists: $existing. Use it for the same release; increase the build number only for a new upload. Nothing was overwritten."
  fi
done

"$FLUTTER_BIN" build appbundle --release --flavor store

metadata="$PROJECT_DIR/build/app/intermediates/merged_manifests/storeRelease/processStoreReleaseManifest/output-metadata.json"
[[ -s "$metadata" ]] || fail "Store release metadata is missing: $metadata"
if ! jq -e --arg name "$version_name" --arg code "$version_code" '
  .applicationId == "com.appfactory.meter_reading_log"
  and .variantName == "storeRelease"
  and (.elements | length) == 1
  and .elements[0].versionName == $name
  and (.elements[0].versionCode | tostring) == $code
' "$metadata" >/dev/null; then
  fail "Built package, variant, or version does not match store/release $version. No named artifact was created."
fi
[[ -s "$source_bundle" ]] || fail "Store release AAB is missing or empty: $source_bundle"

# Preserve earlier deliveries, including if another build created the file
# after the initial check. Verify that the handed-off bytes match this build.
mkdir -p "$output_dir"
cp -n "$source_bundle" "$output"
cmp -s "$source_bundle" "$output" || fail "Destination differs from this build; the existing artifact was preserved."

echo "Internal test AAB: $output"
echo "Version: $version_name (code $version_code), package: com.appfactory.meter_reading_log"
echo "Ready for manual Play Console upload. Dev and Play installations were not changed."
