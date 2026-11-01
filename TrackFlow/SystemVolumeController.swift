import AppKit

/// Keeps system audio access separate from touch processing and presentation.
enum SystemVolumeController {
    static func read() -> Int {
        let script = NSAppleScript(source: "output volume of (get volume settings)")
        var error: NSDictionary?
        let result = script?.executeAndReturnError(&error)
        return error == nil ? Int(result?.int32Value ?? 50) : 50
    }

    static func set(_ value: Int) -> Bool {
        let bounded = min(100, max(0, value))
        guard let script = NSAppleScript(source: "set volume output volume \(bounded)") else {
            return false
        }
        var error: NSDictionary?
        script.executeAndReturnError(&error)
        if let error {
            print("Volume error: \(error)")
            return false
        }
        return true
    }
}
