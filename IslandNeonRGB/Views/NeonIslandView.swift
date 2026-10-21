import SwiftUI

/// The animated Dynamic Island mockup: a black pill with a travelling RGB stroke around it.
///
/// Animation is driven by `TimelineView(.animation)` so the phase is derived from wall-clock
/// time (no accumulating state) and pauses automatically under Reduce Motion or when the
/// speed is zero.
struct NeonIslandView: View {
    var geometry: IslandGeometry
    var config: NeonConfig
    /// Multiplies every dimension; use it to enlarge the mockup in previews.
    var scale: CGFloat = 1
    /// Draw the black pill behind the stroke. Turn off to show only the outline.
    var showsPill: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var paused: Bool {
        reduceMotion || config.speed == 0
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: paused)) { context in
            let seconds = context.date.timeIntervalSinceReferenceDate
            let raw = seconds * config.speed
            NeonIslandFrame(
                geometry: geometry,
                config: config,
                scale: scale,
                showsPill: showsPill,
                phase: (config.clockwise ? raw : -raw).wrappedUnit
            )
        }
    }
}

/// A single, non-animated frame of the island at a given gradient phase.
///
/// The view's layout footprint is exactly the pill (`geometry.size * scale`); the stroke
/// and glow overhang that footprint, so positioning the view positions the pill.
struct NeonIslandFrame: View {
    var geometry: IslandGeometry
    var config: NeonConfig
    var scale: CGFloat = 1
    var showsPill: Bool = true
    var phase: Double

    var body: some View {
        let width = geometry.width * scale
        let height = geometry.height * scale
        let radius = geometry.resolvedCornerRadius * scale
        let lineWidth = config.lineWidth * scale
        let gap = config.gap * scale
        let outset = gap + lineWidth

        ZStack {
            if showsPill {
                RoundedRectangle(cornerRadius: radius, style: .circular)
                    .fill(Color.black)
                    .frame(width: width, height: height)
            }
            NeonOutlineView(
                cornerRadius: radius + gap + lineWidth / 2,
                lineWidth: lineWidth,
                mode: config.mode,
                brightness: config.brightness,
                phase: phase,
                segments: config.segments,
                glowRadius: config.glowRadius * scale,
                glowOpacity: config.glowOpacity
            )
            .frame(width: width + 2 * outset, height: height + 2 * outset)
        }
        .frame(width: width, height: height)
    }
}

#Preview("Island, 2x") {
    ZStack {
        Color.black.ignoresSafeArea()
        NeonIslandView(geometry: .iPhone16ProMax, config: NeonConfig(), scale: 2)
    }
}
