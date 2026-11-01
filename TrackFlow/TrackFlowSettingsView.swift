import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct TrackFlowSettingsView: View {
    @AppStorage("trackflowLanguage") private var language = "system"
    @ObservedObject var preferences: TrackFlowPreferences
    @ObservedObject var loginItem: LoginItemController
    let showGuide: () -> Void
    @State private var availableApps: [NSRunningApplication] = []
    @State private var appError: String?

    var body: some View {
        let _ = language
        Form {
            Section(L10n.text("Language")) {
                Picker(L10n.text("Language"), selection: $language) {
                    ForEach(AppLanguage.allCases, id: \.rawValue) { option in
                        Text(option.displayName).tag(option.rawValue)
                    }
                }
                Text(L10n.text("Choose the app language. Changes apply immediately."))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section(L10n.text("Gesture regions")) {
                adjustment(L10n.text("Side edge width"), value: $preferences.configuration.edgeWidth,
                           range: 0.06...0.20, step: 0.01, percentage: true)
                adjustment(L10n.text("Slide to activate"), value: $preferences.configuration.activationDistance,
                           range: 0.01...0.10, step: 0.005, percentage: true)
                adjustment(L10n.text("Top media strip"), value: $preferences.configuration.topEdgeHeight,
                           range: 0.06...0.22, step: 0.01, percentage: true)
                adjustment(L10n.text("Wait after typing"), value: $preferences.configuration.typingCooldown,
                           range: 0.3...2.0, step: 0.1, percentage: false)
                Text(L10n.text("After activation: bottom 0%, middle 50%, top 100%. Changes apply immediately."))
                    .font(.caption).foregroundStyle(.secondary)
                Button(L10n.text("Reset gesture settings")) { preferences.configuration = .default }
            }

            Section(L10n.text("Application exceptions")) {
                Text(L10n.text("All gestures pause while one of these apps is in front. Monitoring resumes when you switch away."))
                    .font(.caption).foregroundStyle(.secondary)
                if preferences.excludedApplications.isEmpty {
                    Text(L10n.text("No excluded applications")).foregroundStyle(.secondary)
                }
                ForEach(preferences.excludedApplications) { application in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(application.name)
                            Text(application.id).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button(L10n.text("Remove")) {
                            preferences.excludedApplications.removeAll { $0.id == application.id }
                        }
                    }
                }
                HStack {
                    Menu(L10n.text("Add a running app")) {
                        ForEach(runningApps, id: \.bundleIdentifier) { app in
                            if let id = app.bundleIdentifier {
                                Button(app.localizedName ?? id) {
                                    preferences.addExclusion(id: id, name: app.localizedName ?? id)
                                }
                            }
                        }
                    }
                    Button(L10n.text("Choose application…")) { chooseApplication() }
                }
                if let appError { Text(L10n.text(appError)).font(.caption).foregroundStyle(.red) }
            }

            Section(L10n.text("Startup")) {
                Toggle(L10n.text("Launch TrackFlow at login"), isOn: Binding(
                    get: { loginItem.enabled },
                    set: { loginItem.setEnabled($0) }
                ))
                Toggle(L10n.text("Start monitoring when TrackFlow opens"), isOn: $preferences.startMonitoringOnLaunch)
                Text(L10n.text("With launch at login enabled, TrackFlow opens in the menu bar. Use Open TrackFlow to show its window. Keep the app in a stable location before enabling this."))
                    .font(.caption).foregroundStyle(.secondary)
                if loginItem.needsApproval {
                    Text(L10n.text("macOS approval is required before automatic launch can work."))
                        .font(.caption).foregroundStyle(.orange)
                    Button(L10n.text("Open Login Items settings")) { loginItem.openSystemSettings() }
                }
                if let error = loginItem.errorMessage {
                    Text(L10n.text(error)).font(.caption).foregroundStyle(.red)
                }
            }

            Section(L10n.text("Help")) {
                Button(L10n.text("Show quick-start guide"), action: showGuide)
                Text(L10n.text("TrackFlow keeps keyboard timing only, never typed text. Changing a development build can require refreshing Accessibility permissions."))
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(12)
        .onAppear {
            loginItem.refresh()
            refreshApps()
        }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didLaunchApplicationNotification)) { _ in refreshApps() }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didTerminateApplicationNotification)) { _ in refreshApps() }
    }

    private var runningApps: [NSRunningApplication] { availableApps }

    private func refreshApps() {
        availableApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular && $0.bundleIdentifier != Bundle.main.bundleIdentifier }
            .sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }
    }

    private func adjustment(_ title: String, value: Binding<Double>, range: ClosedRange<Double>,
                            step: Double, percentage: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(L10n.text(title))
                Spacer()
                Text(percentage ? String(format: "%.1f%%", locale: L10n.locale, value.wrappedValue * 100)
                     : String(format: "%.1f s", locale: L10n.locale, value.wrappedValue))
                    .monospacedDigit().foregroundStyle(.secondary)
            }
            Slider(value: value, in: range, step: step).accessibilityLabel(L10n.text(title))
        }
    }

    private func chooseApplication() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        guard panel.runModal() == .OK, let url = panel.url,
              let bundle = Bundle(url: url), let id = bundle.bundleIdentifier else { return }
        guard id != Bundle.main.bundleIdentifier else {
            appError = "TrackFlow cannot exclude itself."
            return
        }
        preferences.addExclusion(id: id, name: (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
                                 ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
                                 ?? url.deletingPathExtension().lastPathComponent)
        appError = nil
    }
}
