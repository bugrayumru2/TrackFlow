import AppKit

@main
struct KeyboardAvailabilityChecks {
    @MainActor static func main() {
        let monitor = KeyboardActivityMonitor()
        assert(!monitor.ready)
        assert(monitor.allowsEdgeControl, "Permission state must not permanently disable side controls")
        monitor.stop()
        assert(monitor.allowsEdgeControl)
        print("Unavailable keyboard observation cannot permanently lock edges: passed.")
    }
}
