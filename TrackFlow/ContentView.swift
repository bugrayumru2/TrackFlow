import SwiftUI
import OpenMultitouchSupport

struct ContentView: View {
    @AppStorage("trackflowLanguage") private var language = "system"
    @AppStorage("trackflowOnboardingCompleted") private var onboardingCompleted = false
    @State private var showingGuide = false
    @ObservedObject var model: TrackFlowModel

    var body: some View {
        let _ = language
        TabView {
        ScrollView { TrackFlowDashboard(
            enabled: $model.enabled,
            listening: model.listening,
            volume: model.volume,
            brightness: model.brightness,
            brightnessError: model.brightnessError,
            touchPoints: [],
            typingProtectionReady: model.keyboardMonitor.ready,
            retryTypingProtection: { model.startTypingProtection(requestPermission: true) },
            mediaEnabled: $model.mediaEnabled,
            mediaReady: model.mediaMonitor.ready,
            mediaMessage: model.mediaMonitor.message,
            retryMedia: { model.retryMedia() },
            toggleMonitoring: { model.listening ? model.stop() : model.start() },
            configuration: model.preferences.configuration,
            suspensionReason: model.suspendedForApplication,
            visualization: model.visualization
        ) }
        .onAppear { model.visualization.isVisible = true }
        .onDisappear { model.visualization.isVisible = false }
        .tabItem { Label(L10n.text("Controls"), systemImage: "hand.draw") }
        TrackFlowSettingsView(preferences: model.preferences, loginItem: model.loginItem, showGuide: { showingGuide = true })
            .tabItem { Label(L10n.text("Settings"), systemImage: "slider.horizontal.3") }
        }
        .environment(\.locale, L10n.locale)
        .frame(width: 700, height: 820)
        .onAppear { if !onboardingCompleted { showingGuide = true } }
        .sheet(isPresented: $showingGuide) {
            OnboardingView {
                onboardingCompleted = true
                showingGuide = false
            }
        }
    }
}
