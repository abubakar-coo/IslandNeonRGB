import ActivityKit
import Foundation

/// Static and dynamic data for the Island Neon Live Activity.
///
/// Shared by the app target (which starts, updates and ends the activity) and the
/// widget extension (which renders it in the Dynamic Island and on the Lock Screen).
public struct NeonActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, Sendable {
        /// Colour used for `DynamicIsland.keylineTint` and every accent in this update.
        public var keyline: HSBColor
        /// Raw value of `NeonColorMode`, so the widget can render the matching gradient.
        public var modeID: String
        /// Which step of the colour loop this update represents.
        public var step: Int
        /// Number of steps that make up one full loop.
        public var stepsPerLoop: Int
        /// User brightness, 0...1.
        public var brightness: Double

        public init(keyline: HSBColor, modeID: String, step: Int, stepsPerLoop: Int, brightness: Double) {
            self.keyline = keyline
            self.modeID = modeID
            self.step = step
            self.stepsPerLoop = stepsPerLoop
            self.brightness = brightness
        }

        public var mode: NeonColorMode {
            NeonColorMode(rawValue: modeID) ?? .rainbow
        }

        /// Position of this step around the colour loop, 0...1.
        public var phase: Double {
            guard stepsPerLoop > 0 else { return 0 }
            return Double(step % stepsPerLoop) / Double(stepsPerLoop)
        }
    }

    /// Shown in the expanded presentation and on the Lock Screen.
    public var title: String
    /// Used for the elapsed-time timer, the one kind of continuous motion a Live Activity supports.
    public var startedAt: Date

    public init(title: String, startedAt: Date) {
        self.title = title
        self.startedAt = startedAt
    }
}

// MARK: - Preview helpers

public extension NeonActivityAttributes {
    static let preview = NeonActivityAttributes(title: "Island Neon", startedAt: .now)
}

public extension NeonActivityAttributes.ContentState {
    static func preview(step: Int, mode: NeonColorMode = .rainbow, stepsPerLoop: Int = 12) -> Self {
        let phase = Double(step % stepsPerLoop) / Double(stepsPerLoop)
        return Self(
            keyline: mode.color(at: phase),
            modeID: mode.rawValue,
            step: step,
            stepsPerLoop: stepsPerLoop,
            brightness: 1
        )
    }
}
