#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
configuration="${1:-Debug}"
derived_data="${2:-.build/DerivedData}"
case "$configuration" in Debug|Release) ;; *) echo "Expected Debug or Release" >&2; exit 2;; esac
xcodebuild -project TrackFlow.xcodeproj -scheme TrackFlow -configuration "$configuration"   -destination 'platform=macOS' -derivedDataPath "$derived_data"   -onlyUsePackageVersionsFromResolvedFile CODE_SIGNING_ALLOWED=NO build
