import ActivityKit
import SwiftUI

struct LiveActivityView: View {
    @Environment(NeonSettings.self) private var settings
    @Environment(NeonActivityManager.self) private var manager

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Live Activities", value: manager.areActivitiesEnabled ? "Enabled" : "Disabled in Settings")
                    LabeledContent("Status", value: manager.isRunning ? (manager.isCycling ? "Running, cycling colours" : "Running, static colour") : "Not running")
                    if let state = manager.currentState {
                        HStack {
                            Text("Current keyline")
                            Spacer()
                            Circle()
                                .fill(state.keyline.color)
                                .frame(width: 18, height: 18)
                                .overlay(Circle().strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
                            Text("step \(state.step + 1) of \(state.stepsPerLoop)")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                    LabeledContent("Updates sent", value: "\(manager.updateCount)")
                    if let error = manager.lastError {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    if manager.isRunning {
                        Toggle("Cycle colours while app is open", isOn: cyclingBinding)
                        Button("Send one update now") {
                            manager.sendNextStep(config: settings.config)
                        }
                        Button("Stop Live Activity", role: .destructive) {
                            manager.stop()
                        }
                    } else {
                        Button("Start Live Activity") {
                            manager.start(config: settings.config)
                        }
                        .disabled(!manager.areActivitiesEnabled)
                    }
                } footer: {
                    Text("Starts a real ActivityKit Live Activity. Swipe home and look at the Dynamic Island: the compact view shows a colour dot and \"RGB\"; long-press to expand and see the keyline tint. Every \(Int(settings.config.activityUpdateInterval)) s the app sends the next colour of the \(settings.config.mode.title) loop.")
                }

                Section("What the system renders") {
                    bullet("Compact: a gradient dot on the left, \"RGB\" on the right of the cutout.")
                    bullet("Minimal: the gradient dot alone when another activity shares the island.")
                    bullet("Expanded: a static pill mockup, the elapsed timer and the current colour. `keylineTint` colours the border iOS draws around this presentation.")
                    bullet("Lock Screen: a banner with the same content.")
                }

                Section("What it cannot do") {
                    bullet("The keyline is one solid colour per update, not a gradient, and it is never animated. The colour changes only when a new update arrives.")
                    bullet("Live Activity views are static snapshots: `TimelineView`, `withAnimation` and `.animation` are ignored. The only continuous motion is the system timer text.")
                    bullet("Updates stop when this app is suspended. Background cycling would need ActivityKit push notifications from a server, and those share the same per-day budget.")
                    bullet("iOS ends every Live Activity after 8 hours.")
                    bullet("Nothing is drawn outside the island's own presentation. The pixels around the cutout stay under the foreground app's control.")
                }
            }
            .navigationTitle("Live Activity")
            .scrollContentBackground(.hidden)
            .background(Color.black.ignoresSafeArea())
        }
    }

    private var cyclingBinding: Binding<Bool> {
        Binding(
            get: { manager.isCycling },
            set: { enabled in
                if enabled {
                    manager.startCycling(config: settings.config)
                } else {
                    manager.stopCycling()
                }
            }
        )
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("•")
            Text(text)
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
}

#Preview {
    LiveActivityView()
        .environment(NeonSettings())
        .environment(NeonActivityManager())
        .preferredColorScheme(.dark)
}
