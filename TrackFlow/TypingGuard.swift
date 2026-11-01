import Foundation

/// Stores timing only: no key codes, characters, or typed text.
struct TypingGuard {
    static let cooldown: TimeInterval = 0.8
    var cooldownDuration = Self.cooldown
    private var lastKeyDown: TimeInterval?

    mutating func recordKeyDown(at time: TimeInterval) {
        lastKeyDown = time
    }

    func isLocked(at time: TimeInterval) -> Bool {
        guard let lastKeyDown else { return false }
        return time - lastKeyDown < cooldownDuration
    }
}
