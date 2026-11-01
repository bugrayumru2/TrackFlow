import SwiftUI

/// Presentation only; monitoring and system control stay in ContentView.
struct TrackFlowDashboard: View {
    @AppStorage("trackflowLanguage") private var language = "system"
    @Binding var enabled: Bool
    let listening: Bool
    let volume: Int
    let brightness: Int?
    let brightnessError: String?
    let touchPoints: [CGPoint]
    let typingProtectionReady: Bool
    let retryTypingProtection: () -> Void
    @Binding var mediaEnabled: Bool
    let mediaReady: Bool
    let mediaMessage: String
    let retryMedia: () -> Void
    let toggleMonitoring: () -> Void

    var configuration = GestureConfiguration.default
    var suspensionReason: String? = nil
    var visualization: TrackpadVisualization? = nil

    private var isActive: Bool { listening && enabled && suspensionReason == nil }
    private var status: String {
        if let suspensionReason { return "Paused for \(suspensionReason)" }
        return !listening ? L10n.text("Not monitoring") : enabled ? L10n.text("Gestures active") : L10n.text("Gestures paused")
    }

    var body: some View {
        let _ = language
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Image("BrandMark")
                    .resizable()
                    .frame(width: 56, height: 56)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text("TrackFlow").font(.system(size: 25, weight: .bold, design: .rounded))
                    Text(L10n.text("A little less reaching. A little more flow."))
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 6) {
                    Circle().fill(isActive ? Color.green : Color.secondary)
                        .frame(width: 6, height: 6)
                    Text(L10n.text(status)).font(.caption.weight(.medium))
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(.quaternary.opacity(0.5), in: Capsule())
                .accessibilityElement(children: .combine)
            }

            VStack(spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.text("Your trackpad")).font(.headline)
                        Text(L10n.text("Slide the sides. Click the top for Spotify."))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle(L10n.text("Enable gestures"), isOn: $enabled)
                        .toggleStyle(.switch).controlSize(.small)
                }

                Group {
                    if let visualization {
                        ObservedTrackpadPreview(visualization: visualization, active: isActive,
                            mediaActive: isActive && mediaEnabled && mediaReady, configuration: configuration)
                    } else {
                        TrackpadPreview(points: touchPoints, active: isActive,
                            mediaActive: isActive && mediaEnabled && mediaReady, configuration: configuration)
                    }
                }
                .frame(height: 206)

                HStack {
                    Label(L10n.text("Brightness"), systemImage: "sun.max.fill")
                        .foregroundStyle(.orange)
                    Spacer()
                    Text(L10n.text("Slide along either edge"))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Label(L10n.text("Volume"), systemImage: "speaker.wave.2.fill")
                        .foregroundStyle(.blue)
                }
                .font(.caption.weight(.medium))
            }
            .padding(22)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(.primary.opacity(0.06)))

            HStack(spacing: 16) {
                LevelCard(title: L10n.text("Brightness"), subtitle: L10n.text("Left edge · Built-in display"),
                          symbol: "sun.max.fill", value: brightness, tint: .orange)
                LevelCard(title: L10n.text("Volume"), subtitle: L10n.text("Right edge · System audio"),
                          symbol: "speaker.wave.2.fill", value: volume, tint: .blue)
            }

            HStack(spacing: 12) {
                Image(systemName: "music.note").foregroundStyle(.green)
                VStack(alignment: .leading, spacing: 4) {
                    Toggle(L10n.text("Spotify media clicks"), isOn: $mediaEnabled)
                        .toggleStyle(.switch).controlSize(.small)
                    Text(L10n.text(mediaMessage)).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                }
                if mediaEnabled && !mediaReady {
                    Button(L10n.text("Enable access"), action: retryMedia).disabled(!listening)
                }
            }

            HStack(spacing: 8) {
                Image(systemName: !listening || typingProtectionReady ? "shield.lefthalf.filled" : "exclamationmark.shield")
                    .foregroundStyle(!listening ? Color.secondary : typingProtectionReady ? Color.green : Color.orange)
                Text(!listening ? L10n.text("Slide a little to activate either edge · Typing protection starts with monitoring")
                     : typingProtectionReady
                     ? L10n.text("Typing protection on · Slide a little to activate either edge")
                     : L10n.text("Typing protection limited · Enable Accessibility for other apps"))
                    .font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                if listening && !typingProtectionReady {
                    Button(L10n.text("Enable protection"), action: retryTypingProtection).disabled(!listening)
                }
            }

            if let brightnessError {
                Label(L10n.text(brightnessError), systemImage: "exclamationmark.circle")
                    .font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(listening ? L10n.text("Ready when you are") : L10n.text("Make your edges useful"))
                        .font(.subheadline.weight(.semibold))
                    Text(L10n.text("Bottom 0%  ·  Middle 50%  ·  Top 100%"))
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: toggleMonitoring) {
                    Label(listening ? L10n.text("Stop monitoring") : L10n.text("Start monitoring"),
                          systemImage: listening ? "stop.fill" : "play.fill")
                        .padding(.horizontal, 6).padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding(28)
        .frame(width: 680)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

private struct LevelCard: View {
    let title: String
    let subtitle: String
    let symbol: String
    let value: Int?
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 34, height: 34)
                    .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                Spacer()
                if let value {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(value)").font(.system(size: 30, weight: .semibold, design: .rounded))
                        Text("%").font(.subheadline).foregroundStyle(.secondary)
                    }
                    .monospacedDigit()
                } else {
                    Text("—").font(.title).foregroundStyle(.secondary)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.text(title)).font(.subheadline.weight(.semibold))
                Text(L10n.text(subtitle)).font(.caption).foregroundStyle(.secondary)
            }
            ProgressView(value: Double(value ?? 0), total: 100).tint(tint)
                .accessibilityLabel(L10n.text(title))
                .accessibilityValue(value.map { L10n.format("%d percent", $0) } ?? L10n.text("Unavailable"))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.primary.opacity(0.06)))
    }
}

private struct ObservedTrackpadPreview: View {
    @ObservedObject var visualization: TrackpadVisualization
    let active: Bool
    let mediaActive: Bool
    let configuration: GestureConfiguration

    var body: some View {
        TrackpadPreview(points: visualization.points, active: active,
                        mediaActive: mediaActive, configuration: configuration)
    }
}

private struct TrackpadPreview: View {
    let points: [CGPoint]
    let active: Bool
    let mediaActive: Bool
    let configuration: GestureConfiguration

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(.primary.opacity(0.025))
                HStack(spacing: 0) {
                    edge(color: .orange, symbol: "sun.max.fill")
                        .frame(width: geometry.size.width * configuration.edgeWidth)
                    Spacer(minLength: 0)
                    edge(color: .blue, symbol: "speaker.wave.2.fill")
                        .frame(width: geometry.size.width * configuration.edgeWidth)
                }
                VStack {
                    HStack(spacing: 0) {
                        mediaZone("backward.end.fill", title: L10n.text("Previous"))
                        mediaZone("playpause.fill", title: L10n.text("Play / pause"))
                        mediaZone("forward.end.fill", title: L10n.text("Next"))
                    }
                    .frame(height: geometry.size.height * configuration.topEdgeHeight)
                    .padding(.horizontal, geometry.size.width * configuration.edgeWidth)
                    Spacer(minLength: 0)
                }
                VStack(spacing: 10) {
                    Image(systemName: "hand.point.up")
                        .font(.system(size: 27, weight: .light))
                    Text(active ? L10n.text("Find your flow") : L10n.text("Your shortcuts start here"))
                        .font(.subheadline.weight(.medium))
                    Text(L10n.text("Move up to increase · down to decrease"))
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

                ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                    Circle()
                        .fill(.white)
                        .frame(width: 13, height: 13)
                        .padding(7)
                        .background(Color.accentColor.opacity(0.25), in: Circle())
                        .overlay(Circle().strokeBorder(Color.accentColor.opacity(0.6)))
                        .position(x: point.x * geometry.size.width,
                                  y: (1 - point.y) * geometry.size.height)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.primary.opacity(0.1)))
        }
        .accessibilityLabel(L10n.text("Trackpad: left edge brightness, right edge volume. Top edge: previous, play or pause, next."))
    }

    private func mediaZone(_ symbol: String, title: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 11, weight: .semibold))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundStyle(.green)
            .background(.green.opacity(mediaActive ? 0.12 : 0.04))
            .overlay(alignment: .trailing) { Rectangle().fill(.green.opacity(0.15)).frame(width: 1) }
            .accessibilityLabel(L10n.text(title))
    }

    private func edge(color: Color, symbol: String) -> some View {
        VStack {
            Text("100").font(.system(size: 10, weight: .medium, design: .rounded))
            Spacer()
            Image(systemName: symbol).font(.system(size: 15, weight: .medium))
            Spacer()
            Text("0").font(.system(size: 10, weight: .medium, design: .rounded))
        }
        .foregroundStyle(color)
        .padding(.vertical, 15)
        .frame(maxWidth: .infinity)
        .background(color.opacity(active ? 0.13 : 0.06))
    }
}
