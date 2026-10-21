import SwiftUI

enum AppTab: String, Hashable {
    case neon, activity, settings, limits
}

struct ContentView: View {
    @Environment(NeonSettings.self) private var settings
    @State private var selectedTab: AppTab = .neon

    var body: some View {
        TabView(selection: $selectedTab) {
            NeonHomeView()
                .tabItem { Label("Neon", systemImage: "sparkles") }
                .tag(AppTab.neon)

            LiveActivityView()
                .tabItem { Label("Live Activity", systemImage: "bolt.horizontal.circle") }
                .tag(AppTab.activity)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "slider.horizontal.3") }
                .tag(AppTab.settings)

            LimitationsView()
                .tabItem { Label("Limits", systemImage: "info.circle") }
                .tag(AppTab.limits)
        }
        .tint(.white)
        .background {
            // Reads the full window size once so geometry can follow the detected device.
            GeometryReader { proxy in
                Color.clear
                    .onAppear { settings.noteScreenSize(proxy.size) }
                    .onChange(of: proxy.size) { _, size in settings.noteScreenSize(size) }
            }
            .ignoresSafeArea()
        }
        .onOpenURL { url in
            // The Live Activity's widgetURL opens this tab.
            if url.scheme == "islandneonrgb" {
                selectedTab = .activity
            }
        }
    }
}

// MARK: - Home

struct NeonHomeView: View {
    @Environment(NeonSettings.self) private var settings
    @State private var showsImmersive = false

    var body: some View {
        @Bindable var settings = settings

        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    heroCard
                    ModePicker(selection: $settings.config.mode)

                    Button {
                        showsImmersive = true
                    } label: {
                        Label("Align to the real Dynamic Island", systemImage: "iphone.gen3")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(settings.config.mode.color(at: 0).color)

                    Text("Immersive mode draws the outline around the real cutout. It is visible only while this app is in the foreground; iOS has no public API to draw there over other apps.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    quickControls
                }
                .padding()
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Island Neon")
            .fullScreenCover(isPresented: $showsImmersive) {
                ImmersiveIslandView()
            }
        }
    }

    private var heroCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.11), Color(white: 0.03)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )

            VStack(spacing: 28) {
                NeonIslandView(geometry: settings.config.geometry, config: settings.config, scale: 2.2)
                    .padding(.top, 36)

                VStack(spacing: 4) {
                    Text(settings.config.mode.title)
                        .font(.title3.weight(.semibold))
                    Text(settings.config.mode.subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 20)
            }
        }
        .frame(height: 260)
    }

    private var quickControls: some View {
        @Bindable var settings = settings
        return VStack(spacing: 16) {
            LabeledSlider(title: "Speed", value: $settings.config.speed, range: 0...2, step: 0.05) {
                String(format: "%.2f loops/s", $0)
            }
            LabeledSlider(title: "Brightness", value: $settings.config.brightness, range: 0.2...1, step: 0.05) {
                String(format: "%.0f%%", $0 * 100)
            }
            LabeledSlider(title: "Glow", value: $settings.config.glowRadius, range: 0...30, step: 1) {
                String(format: "%.0f pt", $0)
            }
        }
        .padding()
        .background(Color(white: 0.07), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

// MARK: - Shared controls

/// A slider with a title and a formatted readout of its value.
struct LabeledSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let format: (Double) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text(format(value))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .font(.subheadline)
            Slider(value: $value, in: range, step: step)
        }
    }
}

/// Horizontal strip of colour-mode chips, each previewing its gradient on a tiny island.
struct ModePicker: View {
    @Binding var selection: NeonColorMode

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(NeonColorMode.allCases) { mode in
                    ModeChip(mode: mode, isSelected: mode == selection)
                        .onTapGesture {
                            withAnimation(.snappy) { selection = mode }
                        }
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
        }
    }
}

private struct ModeChip: View {
    let mode: NeonColorMode
    let isSelected: Bool

    var body: some View {
        var chipConfig = NeonConfig()
        chipConfig.mode = mode
        chipConfig.glowRadius = 6
        chipConfig.lineWidth = 2.5

        return VStack(spacing: 10) {
            NeonIslandFrame(geometry: .iPhone16ProMax, config: chipConfig, scale: 0.55, phase: 0)
                .padding(.top, 8)
            Text(mode.title)
                .font(.caption.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .primary : .secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(white: isSelected ? 0.14 : 0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(isSelected ? mode.color(at: 0).color.opacity(0.9) : Color.clear, lineWidth: 1.5)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(mode.title)
        .accessibilityAddTraits(traits)
    }

    private var traits: AccessibilityTraits {
        var traits: AccessibilityTraits = .isButton
        if isSelected {
            traits.insert(.isSelected)
        }
        return traits
    }
}

#Preview {
    ContentView()
        .environment(NeonSettings())
        .environment(NeonActivityManager())
        .preferredColorScheme(.dark)
}
