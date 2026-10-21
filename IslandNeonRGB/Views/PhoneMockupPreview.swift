import SwiftUI

/// The top of a phone, drawn to scale from a device preset, with the animated island in place.
/// Used in Settings so geometry changes can be judged against a status bar.
struct PhoneTopMockup: View {
    var preset: DevicePreset
    var config: NeonConfig
    var width: CGFloat = 300
    /// How much of the phone to show, in screen points before scaling.
    var visibleScreenHeight: Double = 150

    var body: some View {
        let scale = width / preset.screenWidth
        let screenCornerRadius = 62 * scale

        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: screenCornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.09), Color(white: 0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: screenCornerRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                )
                .frame(width: width, height: preset.screenHeight * scale)

            // Status bar stand-ins, scaled like the island.
            HStack {
                Text("9:41")
                    .font(.system(size: 17 * scale, weight: .semibold))
                Spacer()
                HStack(spacing: 5 * scale) {
                    Image(systemName: "cellularbars")
                    Image(systemName: "wifi")
                    Image(systemName: "battery.100percent")
                }
                .font(.system(size: 15 * scale, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 34 * scale)
            .padding(.top, 20 * scale)

            NeonIslandView(geometry: config.geometry, config: config, scale: scale)
                .padding(.top, config.geometry.topInset * scale)
                .offset(x: config.geometry.horizontalOffset * scale)
        }
        .frame(width: width, height: visibleScreenHeight * scale, alignment: .top)
        .clipped()
        .accessibilityHidden(true)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        PhoneTopMockup(preset: .default, config: NeonConfig())
    }
}
