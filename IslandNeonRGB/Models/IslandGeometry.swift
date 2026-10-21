import SwiftUI

/// Where the Dynamic Island cutout sits on screen, in points, in portrait.
///
/// Apple publishes no API that reports the island's frame, so these values are
/// calibration defaults taken from Apple's design resources for the 14/15/16 Pro
/// family (the physical sensor module is the same across those models). Every
/// value is adjustable in Settings and in the immersive alignment screen.
struct IslandGeometry: Codable, Hashable {
    /// Width of the pill.
    var width: Double
    /// Height of the pill.
    var height: Double
    /// Distance from the top edge of the screen to the top of the pill.
    var topInset: Double
    /// Fine horizontal nudge from the screen's vertical centre line.
    var horizontalOffset: Double
    /// Corner radius of the pill. `nil` means a full capsule (`height / 2`).
    var cornerRadius: Double?

    init(width: Double, height: Double, topInset: Double, horizontalOffset: Double = 0, cornerRadius: Double? = nil) {
        self.width = width
        self.height = height
        self.topInset = topInset
        self.horizontalOffset = horizontalOffset
        self.cornerRadius = cornerRadius
    }

    var resolvedCornerRadius: Double {
        min(cornerRadius ?? height / 2, height / 2)
    }

    var size: CGSize {
        CGSize(width: width, height: height)
    }

    /// Dynamic Island module shared by the iPhone 14 Pro through iPhone 16 Pro Max.
    static let proFamily = IslandGeometry(width: 126, height: 37.33, topInset: 11)

    /// Default target device for this project.
    static let iPhone16ProMax = proFamily
}

/// A known device, used to pick geometry automatically from the logical screen size.
struct DevicePreset: Identifiable, Hashable {
    let id: String
    let name: String
    /// Logical portrait screen size in points.
    let screenWidth: Double
    let screenHeight: Double
    let geometry: IslandGeometry

    static let all: [DevicePreset] = [
        DevicePreset(id: "iphone16promax", name: "iPhone 16 Pro Max", screenWidth: 440, screenHeight: 956, geometry: .proFamily),
        DevicePreset(id: "iphone16pro", name: "iPhone 16 Pro", screenWidth: 402, screenHeight: 874, geometry: .proFamily),
        DevicePreset(id: "iphone430", name: "iPhone 16 Plus / 15 Plus / 15 Pro Max / 14 Pro Max", screenWidth: 430, screenHeight: 932, geometry: .proFamily),
        DevicePreset(id: "iphone393", name: "iPhone 16 / 15 / 15 Pro / 14 Pro", screenWidth: 393, screenHeight: 852, geometry: .proFamily),
    ]

    static let `default` = all[0]

    /// Finds the preset whose logical screen size matches, tolerating rounding.
    static func matching(screenSize: CGSize) -> DevicePreset? {
        let shortSide = Double(min(screenSize.width, screenSize.height))
        let longSide = Double(max(screenSize.width, screenSize.height))
        return all.first { preset in
            abs(preset.screenWidth - shortSide) < 1.5 && abs(preset.screenHeight - longSide) < 1.5
        }
    }
}
