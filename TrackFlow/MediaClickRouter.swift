import Foundation

enum SpotifyAction: String, Sendable {
    case previous, playPause, next

    nonisolated var command: String {
        switch self {
        case .previous: return "previous track"
        case .playPause: return "playpause"
        case .next: return "next track"
        }
    }

    nonisolated var title: String {
        switch self {
        case .previous: return "Previous track"
        case .playPause: return "Play / pause"
        case .next: return "Next track"
        }
    }

    nonisolated var symbol: String {
        switch self {
        case .previous: return "backward.end.fill"
        case .playPause: return "playpause.fill"
        case .next: return "forward.end.fill"
        }
    }
}

/// Fresh single-finger coordinates plus a physical mouse-down are required.
/// This is independent of the volume/brightness edge gesture recognizers.
struct MediaClickRouter {
    var configuration = GestureConfiguration.default
    private var candidate: (action: SpotifyAction, time: TimeInterval)?
    private(set) var consumingClick = false

    static func action(x: Double, y: Double, configuration: GestureConfiguration = .default) -> SpotifyAction? {
        guard x.isFinite, y.isFinite, y >= 1 - configuration.topEdgeHeight, y <= 1,
              x > configuration.edgeWidth, x < 1 - configuration.edgeWidth else { return nil }
        let segment = (x - configuration.edgeWidth) / (1 - 2 * configuration.edgeWidth)
        return segment < 1.0 / 3 ? .previous : segment < 2.0 / 3 ? .playPause : .next
    }

    mutating func update(x: Double?, y: Double?, at time: TimeInterval) {
        guard let x, let y, let action = Self.action(x: x, y: y, configuration: configuration) else {
            candidate = nil
            return
        }
        candidate = (action, time)
    }

    mutating func clearCandidate() { candidate = nil }

    mutating func mouseDown(pressure: Double, at time: TimeInterval) -> SpotifyAction? {
        guard !consumingClick, pressure.isFinite, pressure > 0,
              let candidate, time >= candidate.time, time - candidate.time <= 0.15 else { return nil }
        consumingClick = true
        return candidate.action
    }

    mutating func mouseUp() -> Bool {
        let consumed = consumingClick
        consumingClick = false
        return consumed
    }
}
