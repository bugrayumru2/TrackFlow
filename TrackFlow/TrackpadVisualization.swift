import Foundation
import CoreGraphics
import Combine

/// High-frequency contact positions are observed only by the trackpad drawing.
@MainActor
final class TrackpadVisualization: ObservableObject {
    @Published private(set) var points: [CGPoint] = []
    var isVisible = false {
        didSet {
            if !isVisible && !points.isEmpty { points = [] }
        }
    }
    private var lastUpdate = -Double.infinity
    private let interval = 1.0 / 30.0

    func update(_ positions: [CGPoint], at time: TimeInterval = ProcessInfo.processInfo.systemUptime) {
        guard isVisible, positions != points else { return }
        // Clear lifted fingers immediately; otherwise cap drawing updates at 30 Hz.
        guard positions.isEmpty || time - lastUpdate >= interval else { return }
        points = positions
        lastUpdate = time
    }
}
