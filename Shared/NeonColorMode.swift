import SwiftUI

// MARK: - HSBColor

/// A colour expressed in HSB so it can be interpolated, stored in a Live Activity
/// content state (which must be `Codable`), and turned into a SwiftUI `Color`.
public struct HSBColor: Codable, Hashable, Sendable {
    /// 0...1 around the hue wheel.
    public var hue: Double
    /// 0...1.
    public var saturation: Double
    /// 0...1.
    public var brightness: Double

    public init(hue: Double, saturation: Double = 1, brightness: Double = 1) {
        self.hue = hue.wrappedUnit
        self.saturation = min(max(saturation, 0), 1)
        self.brightness = min(max(brightness, 0), 1)
    }

    public var color: Color {
        Color(hue: hue, saturation: saturation, brightness: brightness)
    }

    /// The same hue with its brightness multiplied by `factor` (0...1).
    public func scaled(brightness factor: Double) -> HSBColor {
        HSBColor(hue: hue, saturation: saturation, brightness: brightness * factor)
    }
}

public extension Double {
    /// Wraps the value into `0..<1`. Used for hue arithmetic and animation phase.
    var wrappedUnit: Double {
        let remainder = truncatingRemainder(dividingBy: 1)
        return remainder < 0 ? remainder + 1 : remainder
    }
}

// MARK: - NeonColorMode

/// A named colour loop. Each mode is a closed ring of key colours; `color(at:)`
/// interpolates between neighbours so the ring can be sampled at any position.
public enum NeonColorMode: String, CaseIterable, Codable, Identifiable, Sendable {
    case rainbow
    case neon
    case pastel
    case cyberpunk
    case sunset
    case aurora

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .rainbow: return "Rainbow"
        case .neon: return "Neon"
        case .pastel: return "Pastel"
        case .cyberpunk: return "Cyberpunk"
        case .sunset: return "Sunset"
        case .aurora: return "Aurora"
        }
    }

    public var subtitle: String {
        switch self {
        case .rainbow: return "Full spectrum, evenly spaced"
        case .neon: return "Hot pink, violet, electric blue, lime"
        case .pastel: return "Soft, desaturated spectrum"
        case .cyberpunk: return "Cyan to magenta"
        case .sunset: return "Violet, pink, red, orange, gold"
        case .aurora: return "Green, teal, blue, violet"
        }
    }

    /// Key colours in loop order. The gradient wraps from the last stop back to the first.
    public var stops: [HSBColor] {
        switch self {
        case .rainbow:
            return (0..<6).map { HSBColor(hue: Double($0) / 6) }
        case .neon:
            return [0.92, 0.78, 0.62, 0.50, 0.30, 0.15].map { HSBColor(hue: $0) }
        case .pastel:
            return (0..<6).map { HSBColor(hue: Double($0) / 6, saturation: 0.45) }
        case .cyberpunk:
            return [
                HSBColor(hue: 0.50),
                HSBColor(hue: 0.62),
                HSBColor(hue: 0.78),
                HSBColor(hue: 0.88),
                HSBColor(hue: 0.95, saturation: 0.9),
            ]
        case .sunset:
            return [
                HSBColor(hue: 0.80),
                HSBColor(hue: 0.92),
                HSBColor(hue: 0.00),
                HSBColor(hue: 0.07),
                HSBColor(hue: 0.12, saturation: 0.9),
            ]
        case .aurora:
            return [
                HSBColor(hue: 0.38),
                HSBColor(hue: 0.48),
                HSBColor(hue: 0.62),
                HSBColor(hue: 0.76, saturation: 0.85),
            ]
        }
    }

    /// The colour at position `t` (0...1, wrapping) around the loop, interpolating
    /// between neighbouring stops along the shortest path around the hue wheel.
    public func color(at t: Double) -> HSBColor {
        let stops = self.stops
        guard stops.count > 1 else { return stops.first ?? HSBColor(hue: 0) }

        let scaled = t.wrappedUnit * Double(stops.count)
        let index = Int(scaled) % stops.count
        let fraction = scaled - Double(Int(scaled))
        let a = stops[index]
        let b = stops[(index + 1) % stops.count]

        var hueDelta = b.hue - a.hue
        if hueDelta > 0.5 { hueDelta -= 1 } else if hueDelta < -0.5 { hueDelta += 1 }

        return HSBColor(
            hue: a.hue + hueDelta * fraction,
            saturation: a.saturation + (b.saturation - a.saturation) * fraction,
            brightness: a.brightness + (b.brightness - a.brightness) * fraction
        )
    }

    /// Evenly sampled SwiftUI colours with the first colour repeated at the end,
    /// so angular and linear gradients close without a seam.
    public func gradientColors(samples: Int = 24, brightness: Double = 1, phase: Double = 0) -> [Color] {
        let count = max(samples, 2)
        return (0...count).map { index in
            color(at: Double(index) / Double(count) + phase)
                .scaled(brightness: brightness)
                .color
        }
    }
}
