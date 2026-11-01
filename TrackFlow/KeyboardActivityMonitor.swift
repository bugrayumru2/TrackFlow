import AppKit
import ApplicationServices
import Combine

@MainActor
final class KeyboardActivityMonitor: ObservableObject {
    @Published private(set) var ready = false
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var typingGuard = TypingGuard()
    private var onKeyDown: (() -> Void)?

    deinit {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
    }

    func start(requestPermission: Bool = false, onKeyDown: @escaping () -> Void) {
        self.onKeyDown = onKeyDown
        // Local observation remains useful even while global access is unavailable.
        if localMonitor == nil {
            localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                MainActor.assumeIsolated { self?.recordActivity() }
                return event
            }
        }
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: requestPermission] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        if trusted && globalMonitor == nil {
            globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] _ in
                // AppKit invokes event monitors on the main thread.
                MainActor.assumeIsolated { self?.recordActivity() }
            }
        }
        ready = trusted && globalMonitor != nil && localMonitor != nil
    }

    /// Only an observed key-down can lock the edges, and only for 800 ms.
    /// Global secure-input/permission state must never become a permanent lock.
    var allowsEdgeControl: Bool {
        !typingGuard.isLocked(at: ProcessInfo.processInfo.systemUptime)
    }

    func configure(cooldown: TimeInterval) {
        typingGuard.cooldownDuration = cooldown
    }

    func stop() {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        globalMonitor = nil
        localMonitor = nil
        onKeyDown = nil
        ready = false
    }

    private func recordActivity() {
        typingGuard.recordKeyDown(at: ProcessInfo.processInfo.systemUptime)
        onKeyDown?()
    }
}
