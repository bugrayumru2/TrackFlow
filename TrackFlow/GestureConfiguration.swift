import Foundation

struct GestureConfiguration: Codable, Equatable, Sendable {
    var edgeWidth = 0.12
    var activationDistance = 0.03
    var typingCooldown = 0.8
    var topEdgeHeight = 0.12
    static let `default` = GestureConfiguration()

    var normalized: Self {
        var result = self
        result.edgeWidth = Self.bound(edgeWidth, 0.06...0.20, fallback: 0.12)
        result.activationDistance = Self.bound(activationDistance, 0.01...0.10, fallback: 0.03)
        result.typingCooldown = Self.bound(typingCooldown, 0.3...2.0, fallback: 0.8)
        result.topEdgeHeight = Self.bound(topEdgeHeight, 0.06...0.22, fallback: 0.12)
        return result
    }

    private static func bound(_ value: Double, _ range: ClosedRange<Double>, fallback: Double) -> Double {
        value.isFinite ? min(range.upperBound, max(range.lowerBound, value)) : fallback
    }
}

struct ExcludedApplication: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let name: String
}
