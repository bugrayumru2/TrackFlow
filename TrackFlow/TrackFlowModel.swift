
import Combine
import OpenMultitouchSupport
import AppKit

@MainActor
final class TrackFlowModel: ObservableObject {
    @Published var enabled: Bool {
        didSet {
            defaults.set(enabled, forKey: "trackflowEnabled")
            updateEnabled()
        }
    }
    let visualization = TrackpadVisualization()
    @Published private(set) var listening = false
    private var task: Task<Void, Never>?

    @Published private(set) var volume = 50
    private var gesture = EdgeVolumeGesture()

    private var brightnessGesture = EdgeVolumeGesture(edge: .left)
    @Published private(set) var brightness: Int?
    @Published private(set) var brightnessError: String?

    @Published var mediaEnabled: Bool {
        didSet {
            defaults.set(mediaEnabled, forKey: "trackflowMediaEnabled")
            updateMediaEnabled()
        }
    }
    let keyboardMonitor = KeyboardActivityMonitor()
    let mediaMonitor = MediaClickMonitor()

    let preferences: TrackFlowPreferences
    let loginItem = LoginItemController()
    private let defaults: UserDefaults
    @Published private(set) var suspendedForApplication: String?

    var monitoringRequested: Bool { listening && enabled }

    private let manager = OMSManager.shared

    private var subscriptions = Set<AnyCancellable>()

    var isRunning: Bool { monitoringRequested && suspendedForApplication == nil }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        preferences = TrackFlowPreferences(defaults: defaults)
        enabled = defaults.object(forKey: "trackflowEnabled") as? Bool ?? true
        mediaEnabled = defaults.object(forKey: "trackflowMediaEnabled") as? Bool ?? true
        preferences.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &subscriptions)
        loginItem.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &subscriptions)
        preferences.$configuration.dropFirst()
            .sink { [weak self] configuration in self?.configure(configuration) }
            .store(in: &subscriptions)
        preferences.$excludedApplications.dropFirst()
            .sink { [weak self] applications in self?.refreshExcludedApplication(exclusions: applications) }
            .store(in: &subscriptions)
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didActivateApplicationNotification)
            .sink { [weak self] notification in
                self?.refreshExcludedApplication(
                    application: notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)
            }
            .store(in: &subscriptions)
        configure(preferences.configuration)
        refreshExcludedApplication()
        if preferences.startMonitoringOnLaunch {
            DispatchQueue.main.async { [weak self] in self?.start(requestPermission: false) }
        }
        keyboardMonitor.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &subscriptions)
        mediaMonitor.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &subscriptions)
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                self.loginItem.refresh()
                guard self.listening else { return }
                self.refreshExcludedApplication()
                self.startTypingProtection(requestPermission: false)
                self.retryMedia(requestPermission: false)
            }
            .store(in: &subscriptions)
        NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)
            .sink { [weak self] _ in self?.stop() }
            .store(in: &subscriptions)
    }

    func togglePause() {
        if monitoringRequested { stop() }
        else {
            enabled = true
            start()
        }
    }

    func retryMedia(requestPermission: Bool = true) {
        if listening && enabled && mediaEnabled && suspendedForApplication == nil {
            mediaMonitor.start(requestPermission: requestPermission)
        }
    }

    private func updateEnabled() {
        gesture.reset()
        brightnessGesture.reset()
        mediaMonitor.update(x: nil, y: nil)
        if !enabled {
            mediaMonitor.stop()
            LevelHUDController.shared.hide()
        } else {
            retryMedia()
        }
    }

    private func updateMediaEnabled() {
        if mediaEnabled { retryMedia() }
        else { mediaMonitor.stop() }
    }

    func start(requestPermission: Bool = true) {
        guard !listening else { return }

        volume = readVolume()
        do {
            brightness = try BrightnessController.read()
            brightnessError = nil
        } catch {
            brightness = nil
            brightnessError = error.localizedDescription
        }
        listening = manager.startListening()

        guard listening else { return }
        refreshExcludedApplication()
        startTypingProtection(requestPermission: requestPermission)
        retryMedia(requestPermission: requestPermission)

        task = Task { @MainActor in
            for await data in manager.touchDataStream {
                if Task.isCancelled { break }

                let active = data.filter {
                    $0.state == .touching ||
                    $0.state == .making ||
                    $0.state == .starting
                }

                if visualization.isVisible {
                    visualization.update(active.map {
                        CGPoint(x: CGFloat($0.position.x), y: CGFloat($0.position.y))
                    })
                }
                process(active)
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
        keyboardMonitor.stop()
        mediaMonitor.stop()
        LevelHUDController.shared.hide()
        manager.stopListening()
        listening = false
        visualization.update([])
        gesture.reset()
        brightnessGesture.reset()
    }

    private func process(_ touches: [OMSTouchData]) {
        if enabled, listening, suspendedForApplication == nil, mediaEnabled, touches.count == 1, let finger = touches.first {
            mediaMonitor.update(x: Double(finger.position.x), y: Double(finger.position.y))
        } else {
            mediaMonitor.update(x: nil, y: nil)
        }
        guard enabled, listening, suspendedForApplication == nil, keyboardMonitor.allowsEdgeControl, touches.count == 1,
              let finger = touches.first else {
            gesture.reset()
            brightnessGesture.reset()
            return
        }

        if let target = brightnessGesture.process(
            id: finger.id,
            x: Double(finger.position.x),
            y: Double(finger.position.y)
        ), target != brightness {
            do {
                try BrightnessController.set(target)
                brightness = target
                brightnessError = nil
                LevelHUDController.shared.show(volume: volume, brightness: brightness, active: .brightness)
            } catch {
                brightnessError = error.localizedDescription
            }
        }

        guard let target = gesture.process(
            id: finger.id,
            x: Double(finger.position.x),
            y: Double(finger.position.y)
        ), target != volume else { return }
        setVolume(target)
    }

    private func configure(_ configuration: GestureConfiguration) {
        let configuration = configuration.normalized
        gesture.configuration = configuration
        brightnessGesture.configuration = configuration
        gesture.reset()
        brightnessGesture.reset()
        keyboardMonitor.configure(cooldown: configuration.typingCooldown)
        mediaMonitor.configure(configuration)
    }

    private func refreshExcludedApplication(
        application: NSRunningApplication? = NSWorkspace.shared.frontmostApplication,
        exclusions: [ExcludedApplication]? = nil
    ) {
        let apps = exclusions ?? preferences.excludedApplications
        let name = apps.first { $0.id == application?.bundleIdentifier }?.name
        guard name != suspendedForApplication else { return }
        suspendedForApplication = name
        gesture.reset()
        brightnessGesture.reset()
        mediaMonitor.update(x: nil, y: nil)
        if name != nil {
            mediaMonitor.stop()
            LevelHUDController.shared.hide()
        } else {
            retryMedia(requestPermission: false)
        }
    }

    func startTypingProtection(requestPermission: Bool) {
        guard listening else { return }
        keyboardMonitor.start(requestPermission: requestPermission) { [weak self] in
            self?.gesture.reset()
            self?.brightnessGesture.reset()
        }
    }

    private func readVolume() -> Int {
        SystemVolumeController.read()
    }

    private func setVolume(_ value: Int) {
        if SystemVolumeController.set(value) {
            volume = value
            LevelHUDController.shared.show(volume: volume, brightness: brightness, active: .volume)
        }
    }
}
