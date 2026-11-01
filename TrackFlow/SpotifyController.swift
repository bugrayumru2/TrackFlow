import AppKit

enum SpotifyController {
    /// Only fixed commands enter this script; Spotify is never activated or launched.
    nonisolated static func execute(_ action: SpotifyAction) -> String {
        let source = """
        if application id "com.spotify.client" is not running then
            return "Open Spotify to use media controls."
        end if
        tell application id "com.spotify.client"
            \(action.command)
        end tell
        return "ok"
        """
        guard let script = NSAppleScript(source: source) else { return "Could not prepare Spotify command." }
        var error: NSDictionary?
        let result = script.executeAndReturnError(&error)
        if let error {
            if (error[NSAppleScript.errorNumber] as? NSNumber)?.intValue == -1743 {
                return "Allow TrackFlow to control Spotify in System Settings → Privacy & Security → Automation."
            }
            return "Spotify command failed. Check that Spotify is open and Automation access is allowed."
        }
        return result.stringValue == "ok" ? action.title : (result.stringValue ?? "Spotify did not respond.")
    }
    nonisolated static let nowPlayingScript = """
        if application id "com.spotify.client" is not running then return {}
        tell application id "com.spotify.client"
            if player state is stopped then return {}
            return {name of current track, artist of current track, artwork url of current track, (player state is playing)}
        end tell
        """

    nonisolated static func nowPlaying() -> SpotifyNowPlaying? {
        guard let script = NSAppleScript(source: nowPlayingScript) else { return nil }
        var error: NSDictionary?
        let result = script.executeAndReturnError(&error)
        guard error == nil, result.numberOfItems == 4,
              let title = result.atIndex(1)?.stringValue,
              let artist = result.atIndex(2)?.stringValue else { return nil }
        return SpotifyNowPlaying(title: title, artist: artist,
            artworkURL: SpotifyNowPlaying.artworkURL(from: result.atIndex(3)?.stringValue ?? ""),
            isPlaying: result.atIndex(4)?.booleanValue ?? false)
    }
}
