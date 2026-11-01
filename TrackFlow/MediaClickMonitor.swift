import AppKit
import ApplicationServices
import Combine

@MainActor
final class MediaClickMonitor: ObservableObject {
    @Published private(set) var ready = false
    @Published private(set) var message = "Top edge: physical click for Spotify."
    private var router = MediaClickRouter()
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private var commandTask: Task<Void, Never>?
    private var playbackObserver: NSObjectProtocol?
    private var playbackTask: Task<Void, Never>?
    private var lastPlaybackSignature: String?
    private var pendingActions: [SpotifyAction] = []

    init() {
        playbackObserver = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.spotify.client.PlaybackStateChanged"),
            object: nil, queue: .main
        ) { [weak self] notification in
            MainActor.assumeIsolated { self?.playbackChanged(notification) }
        }
    }

    deinit {
        if let playbackObserver { DistributedNotificationCenter.default().removeObserver(playbackObserver) }
        playbackTask?.cancel()
        commandTask?.cancel()
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        if let tap { CFMachPortInvalidate(tap) }
    }

    func start(requestPermission: Bool = false) {
        if tap != nil {
            ready = true
            return
        }
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: requestPermission] as CFDictionary
        guard AXIsProcessTrustedWithOptions(options) else {
            message = "Allow TrackFlow in Privacy & Security → Accessibility, then retry."
            return
        }
        let mask = (1 << CGEventType.leftMouseDown.rawValue)
            | (1 << CGEventType.leftMouseUp.rawValue)
            | (1 << CGEventType.leftMouseDragged.rawValue)
        let callback: CGEventTapCallBack = { _, type, event, userInfo in
            guard let userInfo else { return Unmanaged.passUnretained(event) }
            // The source is explicitly installed on the main run loop.
            return MainActor.assumeIsolated {
                let monitor = Unmanaged<MediaClickMonitor>.fromOpaque(userInfo).takeUnretainedValue()
                return monitor.handle(type: type, event: event)
            }
        }
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
            eventsOfInterest: CGEventMask(mask), callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ), let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
            message = "Could not enable media clicks. Check Accessibility access and retry."
            return
        }
        self.tap = tap
        self.source = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        ready = true
        message = "Spotify ready · Physical clicks on the top edge"
    }

    func configure(_ configuration: GestureConfiguration) {
        router.configuration = configuration
        router.clearCandidate()
    }

    func update(x: Double?, y: Double?) {
        router.update(x: x, y: y, at: ProcessInfo.processInfo.systemUptime)
    }

    func stop() {
        router.clearCandidate()
        playbackTask?.cancel()
        playbackTask = nil
        lastPlaybackSignature = nil
        pendingActions.removeAll()
        commandTask?.cancel()
        commandTask = nil
        // Preserve swallowing the release of a media click already in progress.
        ready = false
        if !router.consumingClick { removeTap() }
        message = "Top edge: physical click for Spotify."
    }

    private func removeTap() {
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        if let tap { CFMachPortInvalidate(tap) }
        source = nil
        tap = nil
    }

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            router.clearCandidate()
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return Unmanaged.passUnretained(event)
        }
        if type == .leftMouseUp {
            let consumed = router.mouseUp()
            if !ready { removeTap() }
            return consumed ? nil : Unmanaged.passUnretained(event)
        }
        if type == .leftMouseDragged, router.consumingClick { return nil }
        if type == .leftMouseDown, router.consumingClick { return nil }
        if type == .leftMouseDown, ready,
           let action = router.mouseDown(pressure: event.getDoubleValueField(.mouseEventPressure),
                                         at: ProcessInfo.processInfo.systemUptime) {
            // Keep AppleScript and its permission dialogs out of the event-tap callback.
            DispatchQueue.main.async { [weak self] in self?.perform(action) }
            return nil
        }
        return Unmanaged.passUnretained(event)
    }

    private func playbackChanged(_ notification: Notification) {
        guard ready, commandTask == nil,
              let name = notification.userInfo?["Name"] as? String, !name.isEmpty else { return }
        let artist = notification.userInfo?["Artist"] as? String ?? ""
        let playback = notification.userInfo?["Player State"] as? String ?? ""
        let signature = [name, artist, playback].joined(separator: "\u{1f}")
        guard signature != lastPlaybackSignature else { return }
        lastPlaybackSignature = signature
        playbackTask?.cancel()
        playbackTask = Task { @MainActor [weak self] in
            do { try await Task.sleep(for: .milliseconds(200)) } catch { return }
            let track = await Task.detached(priority: .utility) { SpotifyController.nowPlaying() }.value
            guard let self, self.ready, !Task.isCancelled else { return }
            if let track {
                LevelHUDController.shared.showMedia(
                    title: track.isPlaying ? "Now playing" : "Paused",
                    symbol: track.isPlaying ? "play.fill" : "pause.fill", nowPlaying: track)
            }
        }
    }

    private func perform(_ action: SpotifyAction) {
        guard ready, pendingActions.count < 8 else { return }
        pendingActions.append(action)
        guard commandTask == nil else { return }
        commandTask = Task { @MainActor [weak self] in
            while let self, !Task.isCancelled, !self.pendingActions.isEmpty {
                let action = self.pendingActions.removeFirst()
                let result = await Task.detached(priority: .userInitiated) {
                    let message = SpotifyController.execute(action)
                    if message == action.title {
                        try? await Task.sleep(for: .milliseconds(150))
                        return (message, SpotifyController.nowPlaying())
                    }
                    return (message, Optional<SpotifyNowPlaying>.none)
                }.value
                guard !Task.isCancelled else { return }
                self.message = result.0
                let title = action == .playPause ? result.1.map { $0.isPlaying ? "Playing" : "Paused" } ?? result.0 : result.0
                LevelHUDController.shared.showMedia(title: title, symbol: action.symbol, nowPlaying: result.1)
            }
            self?.commandTask = nil
        }
    }
}
