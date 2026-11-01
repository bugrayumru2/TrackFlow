import AppKit

@main
struct PreferencesChecks {
    @MainActor static func main() {
        let suite = "dev.trackflow.checks." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let preferences = TrackFlowPreferences(defaults: defaults)
        assert(preferences.configuration == .default)
        assert(!preferences.startMonitoringOnLaunch)
        preferences.configuration.edgeWidth = 0.18
        preferences.configuration.activationDistance = 0.08
        preferences.configuration.typingCooldown = 1.4
        preferences.configuration.topEdgeHeight = 0.2
        preferences.startMonitoringOnLaunch = true
        preferences.addExclusion(id: "test.editor", name: "Editor")
        preferences.addExclusion(id: "test.editor", name: "Duplicate")
        assert(preferences.excludedApplications.count == 1)
        assert(preferences.excludedName(for: "test.editor") == "Editor")
        assert(preferences.excludedName(for: "test.other") == nil)
        let restored = TrackFlowPreferences(defaults: defaults)
        assert(restored.configuration == preferences.configuration)
        assert(restored.startMonitoringOnLaunch)
        assert(restored.excludedApplications == preferences.excludedApplications)
        for edge in [EdgeVolumeGesture.Edge.left, .right] {
            var gesture = EdgeVolumeGesture(edge: edge)
            gesture.configuration = preferences.configuration
            let x = edge == .left ? 0.09 : 0.91
            assert(gesture.process(id: 1, x: x, y: 0.5) == nil)
            assert(gesture.process(id: 1, x: x, y: 0.55) == nil)
            assert(gesture.process(id: 1, x: x, y: 0.6) == 60)
            assert(gesture.process(id: 1, x: x, y: 0) == 0)
            assert(gesture.process(id: 1, x: x, y: 0.5) == 50)
            assert(gesture.process(id: 1, x: x, y: 1) == 100)
        }
        let configuration = preferences.configuration
        assert(MediaClickRouter.action(x: 0.18, y: 0.95, configuration: configuration) == nil)
        assert(MediaClickRouter.action(x: 0.25, y: 0.85, configuration: configuration) == .previous)
        assert(MediaClickRouter.action(x: 0.5, y: 0.85, configuration: configuration) == .playPause)
        assert(MediaClickRouter.action(x: 0.75, y: 0.85, configuration: configuration) == .next)
        assert(MediaClickRouter.action(x: 0.5, y: 0.79, configuration: configuration) == nil)
        var typing = TypingGuard()
        typing.cooldownDuration = 1.4
        typing.recordKeyDown(at: 10)
        assert(typing.isLocked(at: 11.3))
        assert(!typing.isLocked(at: 11.5))
        preferences.configuration.edgeWidth = .nan
        assert(preferences.configuration.edgeWidth == 0.12)
        preferences.configuration.activationDistance = 4
        assert(preferences.configuration.activationDistance == 0.1)
        assert(SpotifyNowPlaying.artworkURL(from: "https://i.scdn.co/image/example") != nil)
        assert(SpotifyNowPlaying.artworkURL(from: "file:///private/test") == nil)
        assert(SpotifyNowPlaying.artworkURL(from: "https://example.com/image") == nil)
        let spotifyAvailable = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.spotify.client") != nil
            && ProcessInfo.processInfo.environment["TRACKFLOW_TEST_WITHOUT_SPOTIFY"] != "1"
        if spotifyAvailable {
            let script = NSAppleScript(source: SpotifyController.nowPlayingScript)!
            var error: NSDictionary?
            assert(script.compileAndReturnError(&error))
            print("Spotify metadata dictionary compilation: passed.")
        } else {
            print("SKIP: Spotify metadata compilation requires the installed Spotify app.")
        }
        print("Settings persistence, validation, exclusions, dynamic routing, cooldown and artwork URL policy: passed.")
    }
}
