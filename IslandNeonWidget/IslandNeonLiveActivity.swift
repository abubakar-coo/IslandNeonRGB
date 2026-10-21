import ActivityKit
import SwiftUI
import WidgetKit

/// The Live Activity that appears in the Dynamic Island and on the Lock Screen.
///
/// Everything here is a static snapshot: WidgetKit renders the view once per content update
/// and ignores `withAnimation`, `.animation` and `TimelineView`. Colour movement therefore
/// comes only from the app (or a push server) sending a new `ContentState`. The system draws
/// a thin border around the expanded presentation; `keylineTint` is the one public hook that
/// colours it, and it accepts a single colour.
struct IslandNeonLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: NeonActivityAttributes.self) { context in
            LockScreenNeonView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.85))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    NeonDot(state: context.state, size: 24)
                        .padding(.leading, 6)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.attributes.startedAt, style: .timer)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(context.state.keyline.color)
                        .frame(width: 56, alignment: .trailing)
                        .padding(.trailing, 6)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.title)
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        StaticNeonPill(state: context.state)
                            .frame(width: 126, height: 37)
                        Text("Keyline tint: \(context.state.mode.title), step \(context.state.step + 1) of \(context.state.stepsPerLoop)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            } compactLeading: {
                NeonDot(state: context.state, size: 16)
            } compactTrailing: {
                Text("RGB")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(context.state.neonGradient)
            } minimal: {
                NeonDot(state: context.state, size: 16)
            }
            .keylineTint(context.state.keyline.color)
            .widgetURL(URL(string: "islandneonrgb://activity"))
        }
    }
}

// MARK: - Views

/// Lock Screen / banner presentation.
struct LockScreenNeonView: View {
    let context: ActivityViewContext<NeonActivityAttributes>

    var body: some View {
        HStack(spacing: 14) {
            StaticNeonPill(state: context.state)
                .frame(width: 92, height: 27)

            VStack(alignment: .leading, spacing: 2) {
                Text(context.attributes.title)
                    .font(.headline)
                Text("\(context.state.mode.title) keyline, step \(context.state.step + 1) of \(context.state.stepsPerLoop)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(context.attributes.startedAt, style: .timer)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(context.state.keyline.color)
                NeonDot(state: context.state, size: 14)
            }
        }
        .padding(16)
    }
}

/// A black pill with a gradient border, frozen at the current step's phase.
struct StaticNeonPill: View {
    let state: NeonActivityAttributes.ContentState

    var body: some View {
        Capsule(style: .circular)
            .fill(Color.black)
            .overlay(
                Capsule(style: .circular)
                    .strokeBorder(state.angularGradient, lineWidth: 2.5)
            )
            .shadow(color: state.keyline.color.opacity(0.7), radius: 6)
    }
}

/// Small gradient disc used in the compact and minimal presentations.
struct NeonDot: View {
    let state: NeonActivityAttributes.ContentState
    var size: CGFloat = 16

    var body: some View {
        Circle()
            .fill(state.angularGradient)
            .overlay(Circle().strokeBorder(state.keyline.color, lineWidth: 1.5))
            .frame(width: size, height: size)
    }
}

extension NeonActivityAttributes.ContentState {
    var angularGradient: AngularGradient {
        AngularGradient(
            colors: mode.gradientColors(samples: 12, brightness: brightness, phase: phase),
            center: .center,
            angle: .degrees(phase * 360)
        )
    }

    var neonGradient: LinearGradient {
        LinearGradient(
            colors: mode.gradientColors(samples: 6, brightness: brightness, phase: phase),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Previews

#Preview("Expanded", as: .dynamicIsland(.expanded), using: NeonActivityAttributes.preview) {
    IslandNeonLiveActivity()
} contentStates: {
    NeonActivityAttributes.ContentState.preview(step: 0)
    NeonActivityAttributes.ContentState.preview(step: 4, mode: .cyberpunk)
}

#Preview("Compact", as: .dynamicIsland(.compact), using: NeonActivityAttributes.preview) {
    IslandNeonLiveActivity()
} contentStates: {
    NeonActivityAttributes.ContentState.preview(step: 2)
}

#Preview("Minimal", as: .dynamicIsland(.minimal), using: NeonActivityAttributes.preview) {
    IslandNeonLiveActivity()
} contentStates: {
    NeonActivityAttributes.ContentState.preview(step: 6)
}

#Preview("Lock Screen", as: .content, using: NeonActivityAttributes.preview) {
    IslandNeonLiveActivity()
} contentStates: {
    NeonActivityAttributes.ContentState.preview(step: 0)
    NeonActivityAttributes.ContentState.preview(step: 8, mode: .sunset)
}
