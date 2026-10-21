import SwiftUI

/// Full-screen mode that draws the outline around the *real* Dynamic Island.
///
/// The app's window covers the whole screen, including the pixels around the cutout, so
/// while this app is in the foreground the outline genuinely surrounds the hardware island.
/// The moment another app comes to the front this view is gone; iOS offers no public API
/// for a third-party app to draw there otherwise (see `LimitationsView`).
struct ImmersiveIslandView: View {
    @Environment(NeonSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    @State private var controlsVisible = true
    @State private var calibrating = false

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                Color.black
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) { controlsVisible.toggle() }
                    }

                NeonIslandView(
                    geometry: settings.config.geometry,
                    config: settings.config,
                    showsPill: settings.config.showPillInImmersiveMode
                )
                .padding(.top, settings.config.geometry.topInset)
                .offset(x: settings.config.geometry.horizontalOffset)

                VStack {
                    Spacer()
                    if controlsVisible {
                        controls
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .onAppear { settings.noteScreenSize(proxy.size) }
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .preferredColorScheme(.dark)
    }

    // MARK: Controls

    private var controls: some View {
        @Bindable var settings = settings

        return VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text("Aligned to the real Dynamic Island")
                    .font(.headline)
                Text("Visible only while Island Neon is in the foreground. Tap the background to hide these controls.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if calibrating {
                VStack(spacing: 10) {
                    LabeledSlider(title: "Width", value: $settings.config.geometry.width, range: 100...150, step: 0.5) {
                        String(format: "%.1f pt", $0)
                    }
                    LabeledSlider(title: "Height", value: $settings.config.geometry.height, range: 28...48, step: 0.25) {
                        String(format: "%.2f pt", $0)
                    }
                    LabeledSlider(title: "Top inset", value: $settings.config.geometry.topInset, range: 0...24, step: 0.25) {
                        String(format: "%.2f pt", $0)
                    }
                    LabeledSlider(title: "Horizontal offset", value: $settings.config.geometry.horizontalOffset, range: -10...10, step: 0.25) {
                        String(format: "%+.2f pt", $0)
                    }
                    LabeledSlider(title: "Gap", value: $settings.config.gap, range: 0...6, step: 0.25) {
                        String(format: "%.2f pt", $0)
                    }
                    Toggle("Fill the pill black", isOn: $settings.config.showPillInImmersiveMode)
                        .font(.subheadline)

                    Button("Reset to device preset") {
                        settings.apply(settings.detectedPreset ?? .default)
                    }
                    .font(.subheadline)
                }
            }

            HStack(spacing: 12) {
                Button {
                    withAnimation(.snappy) { calibrating.toggle() }
                } label: {
                    Label(calibrating ? "Hide calibration" : "Calibrate", systemImage: "ruler")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.bottom, 44)
    }
}

#Preview {
    ImmersiveIslandView()
        .environment(NeonSettings())
}
