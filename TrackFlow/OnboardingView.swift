import SwiftUI
import AppKit
import ApplicationServices

struct OnboardingView: View {
    @AppStorage("trackflowLanguage") private var language = "system"
    let finish: () -> Void
    @State private var page = 0
    @State private var trusted = AXIsProcessTrusted()

    init(initialPage: Int = 0, finish: @escaping () -> Void) {
        self.finish = finish
        _page = State(initialValue: min(2, max(0, initialPage)))
    }

    private let titles = ["Meet your trackpad shortcuts", "Keep every gesture intentional", "Make TrackFlow yours"]
    private let symbols = ["hand.draw.fill", "shield.lefthalf.filled", "slider.horizontal.3"]

    var body: some View {
        let _ = language
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                Text("TRACKFLOW").font(.caption.weight(.bold)).tracking(2).foregroundStyle(.secondary)
                Spacer()
                Text("\(page + 1) / 3").font(.caption).foregroundStyle(.secondary)
            }
            Image(systemName: symbols[page]).font(.system(size: 40)).foregroundStyle(.blue)
            Text(L10n.text(titles[page])).font(.system(size: 26, weight: .bold, design: .rounded))
            Group {
                if page == 0 {
                    instruction("sun.max.fill", L10n.text("Left edge"), L10n.text("Slide for brightness."))
                    instruction("speaker.wave.2.fill", L10n.text("Right edge"), L10n.text("Slide for volume. Bottom 0%, middle 50%, top 100%."))
                    instruction("playpause.fill", L10n.text("Top edge"), L10n.text("Physically click: previous, play/pause, next in Spotify."))
                } else if page == 1 {
                    instruction("keyboard", L10n.text("Typing protection"), L10n.text("Side controls wait 800 ms after typing, then require a short slide."))
                    instruction("checkmark.shield", L10n.text("Accessibility access"), L10n.text("Required for global typing protection and physical media clicks. Spotify also asks for Automation access on first use."))
                    Button(trusted ? L10n.text("Accessibility allowed — check again") : L10n.text("Request Accessibility access")) {
                        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
                        trusted = AXIsProcessTrustedWithOptions(options)
                    }
                    Button(L10n.text("Open Accessibility settings")) {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    Text(L10n.text("You can finish now and grant access later. Spotify must be open for media controls."))
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    instruction("slider.horizontal.3", L10n.text("Settings"), L10n.text("Adjust gesture areas and typing delay; exclude games and creative apps."))
                    instruction("menubar.rectangle", L10n.text("Keep it nearby"), L10n.text("Closing the window keeps TrackFlow in the menu bar. Pause, resume or quit there."))
                    instruction("power", L10n.text("Choose your startup"), L10n.text("Launch at login and automatic monitoring are optional in Settings."))
                }
            }
            Spacer(minLength: 0)
            HStack {
                if page > 0 { Button(L10n.text("Back")) { page -= 1 } }
                Button(L10n.text("Skip guide"), action: finish).foregroundStyle(.secondary)
                Spacer()
                Button(page == 2 ? L10n.text("Get started") : L10n.text("Continue")) {
                    if page < 2 { page += 1 } else { finish() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(32)
        .frame(width: 540, height: 530)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func instruction(_ icon: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon).foregroundStyle(.blue).frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.text(title)).font(.subheadline.weight(.semibold))
                Text(L10n.text(detail)).font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
