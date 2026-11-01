/// Maps one deliberately activated finger in an edge strip to an absolute percentage.
struct EdgeVolumeGesture {
    enum Edge { case left, right }
    /// 3% of trackpad height: small enough to activate deliberately, above contact jitter.
    static let activationDistance = 0.03
    var configuration = GestureConfiguration.default
    let edge: Edge
    private(set) var activeFinger: Int32?
    private var startingY: Double?
    private(set) var isArmed = false

    init(edge: Edge = .right) {
        self.edge = edge
    }

    mutating func reset() {
        activeFinger = nil
        startingY = nil
        isArmed = false
    }

    mutating func process(id: Int32, x: Double, y: Double) -> Int? {
        guard x.isFinite, y.isFinite, x >= 0, x <= 1,
              (edge == .right ? x >= 1 - configuration.edgeWidth : x <= configuration.edgeWidth) else {
            reset()
            return nil
        }
        if let activeFinger, activeFinger != id {
            reset()
            return nil
        }
        let boundedY = min(1, max(0, y))
        if activeFinger == nil {
            activeFinger = id
            startingY = boundedY
            return nil
        }
        if !isArmed {
            guard let startingY, abs(boundedY - startingY) >= configuration.activationDistance else { return nil }
            isArmed = true
        }
        return Int((boundedY * 100).rounded())
    }
}
