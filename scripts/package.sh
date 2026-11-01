#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Builds locally only; never publishes. Signing/notarization are explicit opt-ins.
derived_data="${TRACKFLOW_DERIVED_DATA:-.build/ReleaseDerivedData}"
xcodebuild -project TrackFlow.xcodeproj -scheme TrackFlow -configuration Release   -destination 'generic/platform=macOS' -derivedDataPath "$derived_data"   -onlyUsePackageVersionsFromResolvedFile ARCHS='arm64 x86_64' ONLY_ACTIVE_ARCH=NO   CODE_SIGNING_ALLOWED=NO build
app="$derived_data/Build/Products/Release/TrackFlow.app"
python3 scripts/verify-release.py "$app" --universal
version=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$app/Contents/Info.plist")
mkdir -p dist
staging=$(mktemp -d "${TMPDIR:-/tmp}/trackflow-release.XXXXXX")
ditto "$app" "$staging/TrackFlow.app"
app="$staging/TrackFlow.app"
status=unsigned
if [ -n "${DEVELOPER_ID_APPLICATION:-}" ]; then
  while IFS= read -r -d '' framework; do
    codesign --force --options runtime --timestamp --sign "$DEVELOPER_ID_APPLICATION" "$framework"
  done < <(find "$app/Contents/Frameworks" -maxdepth 1 -name '*.framework' -print0)
  codesign --force --options runtime --timestamp --entitlements TrackFlow/TrackFlow.entitlements     --sign "$DEVELOPER_ID_APPLICATION" "$app"
  codesign --verify --deep --strict "$app"
  status=signed-unnotarized
fi
if [ -n "${NOTARY_PROFILE:-}" ]; then
  if [ "$status" = unsigned ]; then echo "Notarization requires DEVELOPER_ID_APPLICATION." >&2; exit 2; fi
  submission="$staging/submission.zip"
  ditto -c -k --sequesterRsrc --keepParent "$app" "$submission"
  xcrun notarytool submit "$submission" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$app"
  xcrun stapler validate "$app"
  status=notarized
fi
archive="$PWD/dist/TrackFlow-$version-macos-$status.zip"
ditto -c -k --sequesterRsrc --keepParent "$app" "$archive"
(cd dist && shasum -a 256 "$(basename "$archive")" > "$(basename "$archive").sha256")
echo "Created $archive"
echo "Staged app retained for review: $app"
