#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [ "$#" -ne 1 ]; then
    echo "Usage: ./scripts/check-localization.sh /path/to/TrackFlow.app"
    exit 2
fi
mkdir -p .build/checks .build/module-cache
xcrun swiftc -parse-as-library -module-cache-path .build/module-cache TrackFlow/Localization.swift Tests/LocalizationChecks/main.swift -o .build/checks/localization
.build/checks/localization "$1" Tests/LocalizationChecks/keys.json
