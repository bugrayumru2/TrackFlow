import AppKit
import Combine
import SwiftUI

@main
struct ModelCheck {
    @MainActor static func main() {
        NSApplication.shared.setActivationPolicy(.prohibited)
        let suite = "dev.trackflow.modelchecks." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let model = TrackFlowModel(defaults: defaults)
        var parentUpdates = 0
        let subscription = model.objectWillChange.sink { parentUpdates += 1 }
        model.visualization.isVisible = true
        for index in 0..<120 {
            model.visualization.update([CGPoint(x: Double(index) / 120, y: 0.5)], at: Double(index) / 120)
        }
        assert(parentUpdates == 0, "Contact drawing must not invalidate app/settings state")
        model.visualization.isVisible = false
        withExtendedLifetime(subscription) {}
        print("120 contact drawing updates produce zero parent-model notifications: passed.")

        let apps = NSWorkspace.shared.runningApplications.filter { $0.bundleIdentifier != nil }
        if let excluded = apps.first, let other = apps.first(where: { $0.bundleIdentifier != excluded.bundleIdentifier }) {
            model.preferences.addExclusion(id: excluded.bundleIdentifier!, name: "Excluded app")
            NSWorkspace.shared.notificationCenter.post(name: NSWorkspace.didActivateApplicationNotification,
                object: nil, userInfo: [NSWorkspace.applicationUserInfoKey: excluded])
            assert(model.suspendedForApplication == "Excluded app")
            assert(!model.isRunning)
            NSWorkspace.shared.notificationCenter.post(name: NSWorkspace.didActivateApplicationNotification,
                object: nil, userInfo: [NSWorkspace.applicationUserInfoKey: other])
            assert(model.suspendedForApplication == nil)
            model.preferences.excludedApplications = []
        } else { print("SKIP: workspace notification subcheck needs two running desktop applications.") }
        model.preferences.configuration.edgeWidth = 0.2
        assert(model.preferences.configuration.edgeWidth == 0.2)
        assert(!TrackFlowAppDelegate().applicationShouldTerminateAfterLastWindowClosed(NSApp))
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 700, height: 820),
                              styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: ContentView(model: model))
        window.close()
        assert(!model.listening)
        model.stop()
        print("Workspace exclusions, return to allowed app, settings updates and window lifecycle integration: passed.")
    }
}
