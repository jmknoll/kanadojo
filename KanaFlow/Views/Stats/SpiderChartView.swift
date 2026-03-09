import SwiftUI

/// Radar/spider chart for displaying per-metric handwriting quality scores.
struct SpiderChartView: View {
    struct Axis {
        let label: String
        let value: Double  // 0–1
    }

    let axes: [Axis]
    var size: CGFloat = 200

    var body: some View {
        Canvas { ctx, canvasSize in
            guard axes.count >= 3 else { return }
            let n = axes.count
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let radius = Double(min(canvasSize.width, canvasSize.height) / 2 - 28)
            let angleStep = 2 * Double.pi / Double(n)
            let startAngle = -Double.pi / 2  // top

            func vertex(axis: Int, fraction: Double) -> CGPoint {
                let angle = startAngle + Double(axis) * angleStep
                return CGPoint(
                    x: center.x + cos(angle) * radius * fraction,
                    y: center.y + sin(angle) * radius * fraction
                )
            }

            // Grid rings at 25%, 50%, 75%, 100%
            for level in [0.25, 0.5, 0.75, 1.0] {
                var ring = Path()
                for i in 0..<n {
                    let pt = vertex(axis: i, fraction: level)
                    i == 0 ? ring.move(to: pt) : ring.addLine(to: pt)
                }
                ring.closeSubpath()
                ctx.stroke(ring, with: .color(AppColors.border.opacity(0.6)), lineWidth: 0.5)
            }

            // Axis spokes
            for i in 0..<n {
                var spoke = Path()
                spoke.move(to: center)
                spoke.addLine(to: vertex(axis: i, fraction: 1.0))
                ctx.stroke(spoke, with: .color(AppColors.border.opacity(0.6)), lineWidth: 0.5)
            }

            // Data polygon — filled
            var data = Path()
            for (i, axis) in axes.enumerated() {
                let pt = vertex(axis: i, fraction: max(0, min(1, axis.value)))
                i == 0 ? data.move(to: pt) : data.addLine(to: pt)
            }
            data.closeSubpath()
            ctx.fill(data, with: .color(AppColors.tint.opacity(0.20)))
            ctx.stroke(data, with: .color(AppColors.tint), lineWidth: 2)

            // Labels
            for (i, axis) in axes.enumerated() {
                let angle = startAngle + Double(i) * angleStep
                let labelRadius = radius + 18
                let lx = center.x + cos(angle) * labelRadius
                let ly = center.y + sin(angle) * labelRadius

                let label = Text(axis.label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)

                ctx.draw(label, at: CGPoint(x: lx, y: ly), anchor: anchorFor(angle: angle))
            }
        }
        .frame(width: size, height: size)
    }

    /// Choose a UnitPoint anchor so labels always face outward from the centre.
    private func anchorFor(angle: Double) -> UnitPoint {
        let pi = Double.pi
        switch angle {
        case (-pi/4)..<(pi/4):   return .leading    // right side → anchor left edge
        case (pi/4)..<(3*pi/4):  return .top        // bottom → anchor top
        case (-3*pi/4)..<(-pi/4): return .bottom    // top → anchor bottom
        default:                  return .trailing   // left side → anchor right edge
        }
    }
}
