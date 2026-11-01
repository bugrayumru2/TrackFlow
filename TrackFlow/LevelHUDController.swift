import AppKit
import SwiftUI
import Combine

enum LevelHUDKind {
    case volume, brightness
}

@MainActor
final class LevelHUDState: ObservableObject {
    @Published var nowPlaying: SpotifyNowPlaying?
    @Published var mediaTitle: String?
    @Published var mediaSymbol = "playpause.fill"
    @Published var volume = 0
    @Published var brightness: Int?
    @Published var active: LevelHUDKind = .volume
}

/// One reusable, click-through panel. It never becomes the key window.
@MainActor
final class LevelHUDController {
    static let shared = LevelHUDController()

    private let state = LevelHUDState()
    private var panel: LevelHUDPanel?
    private var dismissal: Task<Void, Never>?
    private var generation = 0

    func show(volume: Int, brightness: Int?, active: LevelHUDKind) {
        state.nowPlaying = nil
        state.mediaTitle = nil
        state.volume = min(100, max(0, volume))
        state.brightness = brightness.map { min(100, max(0, $0)) }
        state.active = active

        present()
    }

    func showMedia(title: String, symbol: String, nowPlaying: SpotifyNowPlaying? = nil) {
        state.nowPlaying = nowPlaying
        state.mediaTitle = title
        state.mediaSymbol = symbol
        present()
    }

    private func present() {
        generation += 1
        dismissal?.cancel()
        let panel = panel ?? makePanel()
        // Use the display under the pointer, falling back to the main display.
        if let screen = NSScreen.screens.first(where: {
            NSMouseInRect(NSEvent.mouseLocation, $0.frame, false)
        }) ?? NSScreen.main {
            let area = screen.visibleFrame
            panel.setFrameOrigin(NSPoint(
                x: area.midX - panel.frame.width / 2,
                y: area.minY + 24
            ))
        }

        panel.alphaValue = 1
        panel.orderFrontRegardless()

        let currentGeneration = generation
        dismissal = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(for: .milliseconds(1300))
            } catch { return }
            guard let self, !Task.isCancelled,
                  self.generation == currentGeneration else { return }
            panel.orderOut(nil)
        }
    }

    func hide() {
        generation += 1
        dismissal?.cancel()
        dismissal = nil
        panel?.orderOut(nil)
    }

    private func makePanel() -> LevelHUDPanel {
        let panel = LevelHUDPanel(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 124),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = true
        panel.isReleasedWhenClosed = false
        panel.contentView = NSHostingView(rootView: LevelHUDView(state: state))
        self.panel = panel
        return panel
    }
}

private final class LevelHUDPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

struct LevelHUDView: View {
    @AppStorage("trackflowLanguage") private var language = "system"
    @ObservedObject var state: LevelHUDState

    var body: some View {
        let _ = language
        VStack(spacing: 15) {
            if let track = state.nowPlaying {
                HStack(spacing: 12) {
                    AsyncImage(url: track.artworkURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Image(systemName: "music.note").font(.title2)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(.green.opacity(0.12))
                    }
                    .frame(width: 54, height: 54)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    VStack(alignment: .leading, spacing: 5) {
                        Text(L10n.text(state.mediaTitle ?? "Spotify")).font(.caption2.weight(.medium)).foregroundStyle(.green)
                        Text(track.title).font(.system(size: 13, weight: .semibold)).lineLimit(1)
                        Text(track.artist).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }
            } else if let title = state.mediaTitle {
                Image(systemName: state.mediaSymbol)
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundStyle(.green)
                Text(L10n.text(title))
                    .font(.system(size: 12, weight: .medium))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            } else {
            row(L10n.text("Volume"), symbol: state.volume == 0 ? "speaker.slash.fill" : "speaker.wave.2.fill",
                value: state.volume, color: .blue, active: state.active == .volume)
            row(L10n.text("Brightness"), symbol: "sun.max.fill",
                value: state.brightness, color: .orange, active: state.active == .brightness)
            }
        }
        .padding(.horizontal, 19)
        .padding(.vertical, 18)
        .frame(width: 280, height: 124)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(.white.opacity(0.14)))
    }

    private func row(_ title: String, symbol: String, value: Int?,
                     color: Color, active: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(active ? color : .secondary)
                .frame(width: 24)
            VStack(spacing: 6) {
                HStack {
                    Text(L10n.text(title)).font(.system(size: 11, weight: .semibold))
                    Spacer()
                    Text(value.map { "\($0)%" } ?? "—")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                }
                GeometryReader { geo in
                    Capsule().fill(.primary.opacity(0.1))
                        .overlay(alignment: .leading) {
                            Capsule().fill(active ? color : Color.secondary.opacity(0.5))
                                .frame(width: geo.size.width * Double(value ?? 0) / 100)
                        }
                }
                .frame(height: 4)
            }
            .foregroundStyle(active ? .primary : .secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.text(title))
        .accessibilityValue(value.map { L10n.format("%d percent", $0) } ?? L10n.text("Unavailable"))
    }
}
