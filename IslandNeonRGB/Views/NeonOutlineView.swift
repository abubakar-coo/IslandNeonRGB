import SwiftUI

/// Paints a travelling multi-colour stroke around a rounded rectangle.
///
/// Colour is distributed by *perimeter distance* rather than by angle, so the rainbow
/// moves at a constant speed along the long flat edges of the pill instead of bunching
/// up at the rounded ends. Rendering uses `Canvas`: each frame strokes `segments`
/// trimmed copies of the outline path, which stays cheap at 60 fps.
struct NeonOutlineView: View {
    /// Corner radius of the stroke's centre line.
    var cornerRadius: CGFloat
    var lineWidth: CGFloat
    var mode: NeonColorMode
    /// 0...1 multiplier applied to every colour.
    var brightness: Double
    /// Position of the gradient around the loop, 0...1.
    var phase: Double
    var segments: Int = 96
    var glowRadius: CGFloat = 14
    var glowOpacity: Double = 0.85

    var body: some View {
        ZStack {
            if glowRadius > 0 && glowOpacity > 0 {
                strokeCanvas(lineWidth: lineWidth * 1.5)
                    .blur(radius: glowRadius)
                    .opacity(glowOpacity)
            }
            strokeCanvas(lineWidth: lineWidth)
        }
        .compositingGroup()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func strokeCanvas(lineWidth strokeWidth: CGFloat) -> some View {
        Canvas { context, size in
            let inset = self.lineWidth / 2
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: inset, dy: inset)
            guard rect.width > 0, rect.height > 0 else { return }

            let radius = min(cornerRadius, min(rect.width, rect.height) / 2)
            let path = Path(roundedRect: rect, cornerRadius: radius, style: .circular)

            let count = max(segments, 8)
            let step = 1.0 / Double(count)
            let overlap = step * 0.35
            let style = StrokeStyle(lineWidth: strokeWidth, lineCap: .round)

            for index in 0..<count {
                let from = Double(index) * step
                let to = min(from + step + overlap, 1)
                let sample = mode
                    .color(at: from + step / 2 - phase)
                    .scaled(brightness: brightness)
                context.stroke(path.trimmedPath(from: from, to: to), with: .color(sample.color), style: style)
            }
        }
    }
}

#Preview("Outline") {
    ZStack {
        Color.black.ignoresSafeArea()
        NeonOutlineView(cornerRadius: 40, lineWidth: 6, mode: .rainbow, brightness: 1, phase: 0.2)
            .frame(width: 260, height: 80)
    }
}
