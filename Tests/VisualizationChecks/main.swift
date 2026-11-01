import Foundation
import Combine

@main
struct VisualizationChecks {
    @MainActor static func main() {
        let state = TrackpadVisualization()
        var publications = 0
        let subscription = state.$points.dropFirst().sink { _ in publications += 1 }
        for i in 0..<120 { state.update([CGPoint(x: Double(i) / 120, y: 0.5)], at: Double(i) / 120) }
        assert(publications == 0, "Hidden drawings must not publish")
        state.isVisible = true
        for i in 0..<120 { state.update([CGPoint(x: Double(i) / 120, y: 0.5)], at: Double(i) / 120) }
        assert(publications > 0 && publications <= 31, "Drawing must stay at or below 30Hz")
        let visibleUpdates = publications
        state.update([], at: 1.001)
        assert(state.points.isEmpty && publications == visibleUpdates + 1, "Lift clears immediately")
        state.update([CGPoint(x: 0.5, y: 0.5)], at: 1.1)
        let beforeIdentical = publications
        state.update([CGPoint(x: 0.5, y: 0.5)], at: 1.2)
        assert(publications == beforeIdentical)
        state.isVisible = false
        assert(state.points.isEmpty)
        let hiddenCount = publications
        state.update([CGPoint(x: 0.7, y: 0.7)], at: 2)
        assert(publications == hiddenCount)
        withExtendedLifetime(subscription) {}
        print("120 contact frames → \(visibleUpdates) drawing updates; hidden/unchanged frames publish nothing; lift clears immediately: passed.")
    }
}
