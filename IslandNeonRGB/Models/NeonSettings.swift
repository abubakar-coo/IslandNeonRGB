import Foundation
import Observation

/// Everything the user can tune. Persisted as JSON in `UserDefaults`.
struct NeonConfig: Codable, Hashable {
    var mode: NeonColorMode = .rainbow

    // Animation
    /// Full colour loops per second around the perimeter. 0 freezes the gradient.
    var speed: Double = 0.35
    var clockwise: Bool = true
    /// 0.2...1. Multiplies the HSB brightness of every colour.
    var brightness: Double = 1.0

    // Stroke
    var lineWidth: Double = 3
    /// Clearance between the island edge and the inner edge of the stroke.
    var gap: Double = 0
    var glowRadius: Double = 14
    var glowOpacity: Double = 0.85
    /// Number of discrete stroke segments used to paint the perimeter gradient.
    var segments: Int = 96

    // Island geometry
    var geometry: IslandGeometry = .iPhone16ProMax
    /// When true, the geometry follows the preset detected from the screen size
    /// (only while the geometry is still a stock preset, so manual calibration is never overwritten).
    var autoDetectDevice: Bool = true
    /// Draw the black pill in immersive mode (hides tiny misalignments against the real cutout).
    var showPillInImmersiveMode: Bool = true

    // Live Activity
    /// Seconds between Live Activity colour updates while the app is in the foreground.
    var activityUpdateInterval: Double = 5
    var activityStepsPerLoop: Int = 12
}

@Observable
final class NeonSettings {
    var config: NeonConfig {
        didSet { persist() }
    }

    /// The device preset matched from the window size, if any. Not persisted.
    private(set) var detectedPreset: DevicePreset?

    @ObservationIgnored private let defaults: UserDefaults
    private static let storageKey = "IslandNeonRGB.config.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode(NeonConfig.self, from: data) {
            config = decoded
        } else {
            config = NeonConfig()
        }
    }

    func reset() {
        config = NeonConfig()
    }

    func apply(_ preset: DevicePreset) {
        config.geometry = preset.geometry
    }

    /// Whether the current geometry is still exactly one of the stock presets.
    var geometryIsStock: Bool {
        DevicePreset.all.contains { $0.geometry == config.geometry }
    }

    /// Called with the full-screen size of the window. Records the matching preset and,
    /// when auto-detect is on and the user has not calibrated manually, adopts its geometry.
    func noteScreenSize(_ size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        let match = DevicePreset.matching(screenSize: size)
        detectedPreset = match
        guard config.autoDetectDevice, let match, geometryIsStock, config.geometry != match.geometry else { return }
        config.geometry = match.geometry
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(config) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }
}
