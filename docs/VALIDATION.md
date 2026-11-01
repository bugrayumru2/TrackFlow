# Local publication-readiness record

Date: 2026-11-01. Toolchain: Xcode 27.2 / Swift 6.4.2 on Apple Silicon.

Passed locally:
- Clean Release build using the committed SwiftPM lock.
- Universal arm64 + x86_64 compilation and ZIP packaging.
- Shared-scheme Debug build using the documented build helper.
- Logic regression suite: typing, activation, mapping, preferences and drawing isolation.
- Workspace/window integration with isolated preferences, without starting hardware monitoring.
- 112 English/Turkish resource keys and dynamic-message fallbacks.
- App identity dev.trackflow.TrackFlow, version 0.1.0, macOS 15 deployment target.
- AppIcon, both locale bundles, Automation description, own MIT and dependency notices in the app.
- Original logo/menu assets and rendered UI previews visually inspected.
- Source staging excludes personal Xcode state, build products and matched secret/local-path patterns.
- Shell syntax and staged-diff whitespace checks.

Not yet exercised:
- First GitHub-hosted workflow execution or repository publication.
- Developer ID signing and notarization (no release credentials used).
- Clean-machine install, a real login cycle and minimum-macOS/Intel runtime acceptance.
- Physical controls after the bundle-identity change; refresh macOS permissions for this app identity.

The local unsigned ZIP is a developer artifact, not a verified public installer.
The source is prepared for review/publication independently of binary distribution.
