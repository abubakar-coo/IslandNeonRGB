import SwiftUI

struct SettingsView: View {
    @Environment(NeonSettings.self) private var settings
    @State private var confirmReset = false

    var body: some View {
        @Bindable var settings = settings

        NavigationStack {
            Form {
                Section {
                    PhoneTopMockup(preset: settings.detectedPreset ?? .default, config: settings.config)
                        .frame(maxWidth: .infinity)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.black)
                }

                Section("Colour mode") {
                    ModePicker(selection: $settings.config.mode)
                        .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                }

                Section("Animation") {
                    LabeledSlider(title: "Speed", value: $settings.config.speed, range: 0...2, step: 0.05) {
                        $0 == 0 ? "Frozen" : String(format: "%.2f loops/s", $0)
                    }
                    Toggle("Clockwise", isOn: $settings.config.clockwise)
                    LabeledSlider(title: "Brightness", value: $settings.config.brightness, range: 0.2...1, step: 0.05) {
                        String(format: "%.0f%%", $0 * 100)
                    }
                }

                Section("Stroke and glow") {
                    LabeledSlider(title: "Line width", value: $settings.config.lineWidth, range: 1...8, step: 0.5) {
                        String(format: "%.1f pt", $0)
                    }
                    LabeledSlider(title: "Gap from island", value: $settings.config.gap, range: 0...6, step: 0.25) {
                        String(format: "%.2f pt", $0)
                    }
                    LabeledSlider(title: "Glow radius", value: $settings.config.glowRadius, range: 0...30, step: 1) {
                        String(format: "%.0f pt", $0)
                    }
                    LabeledSlider(title: "Glow intensity", value: $settings.config.glowOpacity, range: 0...1, step: 0.05) {
                        String(format: "%.0f%%", $0 * 100)
                    }
                    Stepper(value: $settings.config.segments, in: 24...192, step: 24) {
                        LabeledContent("Gradient segments", value: "\(settings.config.segments)")
                    }
                }

                Section {
                    Toggle("Auto-detect device", isOn: $settings.config.autoDetectDevice)
                    LabeledContent("Detected", value: settings.detectedPreset?.name ?? "Unknown screen size")
                    Menu {
                        ForEach(DevicePreset.all) { preset in
                            Button(preset.name) { settings.apply(preset) }
                        }
                    } label: {
                        LabeledContent("Apply preset", value: settings.geometryIsStock ? "Stock" : "Custom")
                    }

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
                    Toggle("Full capsule corners", isOn: capsuleBinding)
                    if settings.config.geometry.cornerRadius != nil {
                        LabeledSlider(title: "Corner radius", value: cornerRadiusBinding, range: 4...24, step: 0.5) {
                            String(format: "%.1f pt", $0)
                        }
                    }
                } header: {
                    Text("Island geometry")
                } footer: {
                    Text("Apple provides no API for the cutout's frame. These defaults come from Apple's design resources for the 14/15/16 Pro family; use \"Align to the real Dynamic Island\" on the Neon tab to fine-tune on your device.")
                }

                Section {
                    LabeledSlider(title: "Update interval", value: $settings.config.activityUpdateInterval, range: 2...30, step: 1) {
                        String(format: "%.0f s", $0)
                    }
                    Stepper(value: $settings.config.activityStepsPerLoop, in: 4...36, step: 2) {
                        LabeledContent("Steps per colour loop", value: "\(settings.config.activityStepsPerLoop)")
                    }
                } header: {
                    Text("Live Activity")
                } footer: {
                    Text("Each update sends a new keyline colour to the Live Activity. Updates are budgeted by iOS and only run while this app is in the foreground.")
                }

                Section {
                    Button("Reset all settings", role: .destructive) { confirmReset = true }
                }
            }
            .navigationTitle("Settings")
            .scrollContentBackground(.hidden)
            .background(Color.black.ignoresSafeArea())
            .confirmationDialog("Reset all settings?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Reset", role: .destructive) { settings.reset() }
            }
        }
    }

    private var capsuleBinding: Binding<Bool> {
        Binding(
            get: { settings.config.geometry.cornerRadius == nil },
            set: { isCapsule in
                settings.config.geometry.cornerRadius = isCapsule ? nil : settings.config.geometry.height / 2
            }
        )
    }

    private var cornerRadiusBinding: Binding<Double> {
        Binding(
            get: { settings.config.geometry.resolvedCornerRadius },
            set: { settings.config.geometry.cornerRadius = $0 }
        )
    }
}

#Preview {
    SettingsView()
        .environment(NeonSettings())
        .preferredColorScheme(.dark)
}
