import Foundation
import CoreGraphics
import Darwin

/// Native built-in display control. DisplayServices is a private macOS API;
/// load it optionally so missing symbols cannot prevent the app from starting.
enum BrightnessController {
    private typealias GetBrightness = @convention(c) (UInt32, UnsafeMutablePointer<Float>) -> Int32
    private typealias SetBrightness = @convention(c) (UInt32, Float) -> Int32

    private static let library = dlopen(
        "/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices",
        RTLD_LAZY | RTLD_LOCAL
    )
    private static let getBrightness: GetBrightness? = {
        guard let library, let symbol = dlsym(library, "DisplayServicesGetBrightness") else { return nil }
        return unsafeBitCast(symbol, to: GetBrightness.self)
    }()
    private static let setBrightness: SetBrightness? = {
        guard let library, let symbol = dlsym(library, "DisplayServicesSetBrightness") else { return nil }
        return unsafeBitCast(symbol, to: SetBrightness.self)
    }()

    enum Failure: Error, LocalizedError {
        case unavailable
        case readFailed
        case writeFailed

        var errorDescription: String? {
            switch self {
            case .unavailable: return "Built-in display brightness is unavailable."
            case .readFailed: return "Could not read built-in display brightness."
            case .writeFailed: return "Could not change built-in display brightness."
            }
        }
    }

    private static func builtInDisplay() throws -> CGDirectDisplayID {
        var displays = [CGDirectDisplayID](repeating: 0, count: 16)
        var count: UInt32 = 0
        guard CGGetOnlineDisplayList(UInt32(displays.count), &displays, &count) == .success,
              let display = displays.prefix(Int(count)).first(where: { CGDisplayIsBuiltin($0) != 0 }) else {
            throw Failure.unavailable
        }
        return display
    }

    static func read() throws -> Int {
        guard let getBrightness else { throw Failure.unavailable }
        let display = try builtInDisplay()
        var value: Float = 0
        guard getBrightness(display, &value) == 0, value.isFinite else { throw Failure.readFailed }
        return Int((min(1, max(0, value)) * 100).rounded())
    }

    static func set(_ percent: Int) throws {
        guard let setBrightness else { throw Failure.unavailable }
        let display = try builtInDisplay()
        let value = Float(min(100, max(0, percent))) / 100
        guard setBrightness(display, value) == 0 else { throw Failure.writeFailed }
    }
}
