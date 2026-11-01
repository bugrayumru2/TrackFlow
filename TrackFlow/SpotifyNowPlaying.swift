import Foundation

struct SpotifyNowPlaying: Sendable {
    let title: String
    let artist: String
    let artworkURL: URL?
    let isPlaying: Bool

    nonisolated static func artworkURL(from value: String) -> URL? {
        guard let url = URL(string: value), url.scheme == "https", let host = url.host,
              host == "i.scdn.co" || host.hasSuffix(".scdn.co") || host.hasSuffix(".spotifycdn.com") else { return nil }
        return url
    }
}
