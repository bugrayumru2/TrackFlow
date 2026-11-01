# Contributing

Use Xcode 27+ and the shared TrackFlow scheme. Start with a focused issue or PR
that describes the user-visible problem, proposed behavior and validation.

- Keep gesture policy in small state machines and system APIs in adapters.
- Preserve app-owned monitoring lifetime when changing views.
- Do not put high-frequency contact updates on the main app model.
- Do not retain keyboard characters/key codes or add telemetry.
- Add English and Turkish keys for new app-owned strings. Keep external names verbatim.
- Run ./scripts/check.sh and a Debug build. For view/model work, also run
  localization and workspace checks documented in README.
- Explain which physical hardware/permissions were tested. Automated logic
  checks do not prove trackpad, login or Automation behavior.

Third-party source/binaries must include a compatible license and attribution.
Keep credentials, signing certificates, private logs, user preferences and
Xcode personal state out of commits.

Contributions are submitted under this repository's MIT license.
Be respectful and specific; criticize behavior and code rather than people.
