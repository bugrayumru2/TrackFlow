import SwiftUI
import AppKit

@main
struct MyApp: App {
    @NSApplicationDelegateAdaptor(TrackFlowAppDelegate.self) private var appDelegate
    @StateObject private var model = TrackFlowModel()

    var body: some Scene {
        Window("TrackFlow", id: "main") {
            ContentView(model: model)
        }
        .defaultLaunchBehavior(model.loginItem.enabled && UserDefaults.standard.bool(forKey: "trackflowOnboardingCompleted") ? .suppressed : .automatic)
        MenuBarExtra {
            TrackFlowMenu(model: model)
        } label: {
            Image("MenuBarIcon")
                .renderingMode(.template)
                .opacity(model.isRunning ? 1 : 0.5)
                .accessibilityLabel("TrackFlow")
        }
        .menuBarExtraStyle(.menu)
    }
}

private struct TrackFlowMenu: View {
    @AppStorage("trackflowLanguage") private var language = "system"
    @ObservedObject var model: TrackFlowModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        let _ = language
        Text(L10n.text(model.suspendedForApplication.map { "Paused for \($0)" } ?? (model.isRunning ? L10n.text("TrackFlow · Active") : L10n.text("TrackFlow · Paused"))))
        Divider()
        Button(model.monitoringRequested ? L10n.text("Pause TrackFlow") : L10n.text("Resume TrackFlow")) {
            model.togglePause()
        }
        Button(L10n.text("Open TrackFlow")) {
            openWindow(id: "main")
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
        Divider()
        Button(L10n.text("About TrackFlow")) {
            NSApplication.shared.orderFrontStandardAboutPanel(options: [
                .credits: NSAttributedString(string: L10n.text("Open source under the MIT License. See bundled license notices."))
            ])
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
        Button(L10n.text("Quit TrackFlow")) {
            model.stop()
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
