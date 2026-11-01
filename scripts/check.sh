#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build/checks .build/module-cache
base=(xcrun swiftc -module-cache-path .build/module-cache)
config=TrackFlow/GestureConfiguration.swift

"${base[@]}" "$config" TrackFlow/TypingGuard.swift TrackFlow/EdgeVolumeGesture.swift Tests/EdgeProtectionChecks/main.swift -o .build/checks/edges
.build/checks/edges
"${base[@]}" "$config" TrackFlow/MediaClickRouter.swift TrackFlow/EdgeVolumeGesture.swift Tests/MediaClickChecks/main.swift -o .build/checks/media
.build/checks/media
"${base[@]}" -parse-as-library TrackFlow/TypingGuard.swift TrackFlow/KeyboardActivityMonitor.swift Tests/KeyboardAvailabilityChecks/main.swift -o .build/checks/keyboard
.build/checks/keyboard
"${base[@]}" -parse-as-library "$config" TrackFlow/TrackFlowPreferences.swift TrackFlow/EdgeVolumeGesture.swift TrackFlow/TypingGuard.swift TrackFlow/MediaClickRouter.swift TrackFlow/SpotifyController.swift TrackFlow/SpotifyNowPlaying.swift Tests/PreferencesChecks/main.swift -o .build/checks/preferences
.build/checks/preferences

"${base[@]}" -parse-as-library TrackFlow/TrackpadVisualization.swift Tests/VisualizationChecks/main.swift -o .build/checks/visualization
.build/checks/visualization
