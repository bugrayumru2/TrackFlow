# Architecture

TrackFlowModel is owned by MyApp, not by a window. Closing/reopening a view
does not stop monitoring. Stop/quit explicitly removes monitors and hides HUDs.

Input travels from OMSManager → pure gesture routers → system adapters.
Workspace activation and preferences determine whether controls may execute.
TypingGuard and KeyboardActivityMonitor disarm side gestures; media clicks
remain independent of the typing cooldown.

TrackpadVisualization owns high-frequency positions and is observed only by
the drawing subview. It publishes at most 30 Hz, clears lifts immediately and
does no drawing work when hidden. The app/settings model does not forward it.

SystemVolumeController, BrightnessController and SpotifyController isolate
platform access. Spotify AppleScript runs away from the main actor. Media
event callbacks enqueue work rather than performing Automation synchronously.

TrackFlowPreferences normalizes persisted values. L10n chooses cached language
bundles; AppStorage invalidates visible presentation without recreating the
monitoring model. LoginItemController registers only after an explicit toggle.

Tests are executable Swift checks, kept outside the app target. They cover
logic and selected lifecycle/notification integration; hardware input,
Accessibility, secure input, login and distribution require manual checks.
