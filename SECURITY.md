# Security and privacy

TrackFlow is an experimental local desktop utility using Accessibility,
Automation and private macOS APIs. The current development line is 0.1.x.

Do not attach credentials, private text, raw event captures or personal logs
to public issues. Use GitHub's private vulnerability reporting if enabled.
Otherwise open a minimal issue requesting a private contact channel without
including vulnerability details or personal data.

The app records only key-down timing, stores preferences locally and requests
Spotify artwork from Spotify CDN hosts over HTTPS. It does not record typed
text or send analytics. Permission-denied states must remain visible and must
not silently widen access or permanently disable unrelated controls.

Release credentials belong in an OS keychain or protected CI secrets, never
in the source tree. Notarization, release signing and clean-machine tests are
required before advertising a binary as a verified public release.
