# Release preparation

## Source release

1. Run the documented checks and Debug/Release builds.
2. Confirm both locale resources, original icon, license notices and shared scheme.
3. Inspect git diff and tracked files. No personal Xcode state or credentials.
4. Update CHANGELOG and the marketing/build versions in project.xcproj.
5. Create a repository under your own GitHub account; review visibility and
   license before the first push. The tools here never create a repository.
6. Commit, push and wait for the first hosted CI run. A local pass does not
   prove hosted CI execution.
7. Tag only after checks and manual acceptance are complete.

## Local artifact

~~~sh
./scripts/package.sh
~~~

This builds arm64 + x86_64 and creates an explicitly **unsigned** ZIP and SHA-256
file under dist/. It is a local developer artifact, not a Gatekeeper-approved
installer. The staged app remains in a printed temporary directory for review.
Do not label an unsigned archive as a signed/notarized release.

## Signed and notarized distribution

Obtain your own Apple Developer ID Application certificate and store
notarization credentials in an OS keychain profile using Apple's documented
notarytool workflow. Do not commit credentials or ask contributors to share them.

The packaging script accepts these explicit opt-ins:

~~~sh
DEVELOPER_ID_APPLICATION='Developer ID Application: Your certificate name' \
NOTARY_PROFILE='your-keychain-profile' ./scripts/package.sh
~~~

It signs the embedded framework and app, submits the ZIP, staples and validates
the ticket, then produces a notarized archive. This path needs real credentials
and has not been exercised as part of the unsigned local source preparation.
Never bypass Gatekeeper in install instructions.

## Manual acceptance before public binaries

- Clean machine: install, Accessibility and Spotify Automation prompts.
- Absolute 0/50/100 controls; activation, typing, multi-finger and edge exit.
- Spotify click consumption and title/art feedback, including denied access.
- Menu bar lifetime, pause/resume, close/reopen and quit.
- Language change, saved settings, exclusions and manual pause interactions.
- Optional login item approval and a real logout/login cycle.
- Apple Silicon, Intel and minimum macOS runtime testing as claimed.
- Verify signatures, Gatekeeper assessment and stapled notarization ticket.
- Include MIT and dependency licenses with the distributed app.

Only publish binaries that have passed the appropriate signing and acceptance
steps. Source publication can happen independently of binary distribution.
