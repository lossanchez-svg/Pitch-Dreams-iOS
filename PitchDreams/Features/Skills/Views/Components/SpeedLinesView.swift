import SwiftUI

/// Canvas overlay with directional speed line streaks.
struct SpeedLinesView: View {
    let direction: SpeedLineDirection
    let color: Color
    let progress: CGFloat

    private let lineCount = 8

    var body: some View {
        Canvas { context, size in
            let fadeIn = min(1.0, progress * 3)
            let fadeOut = max(0, 1.0 - (progress - 0.7) / 0.3)
            let opacity = min(fadeIn, fadeOut)

            guard opacity > 0 else { return }

            for i in 0..<lineCount {
                let seed = CGFloat(i)
                let t = (progress + seed * 0.1).truncatingRemainder(dividingBy: 1.0)

                let lineOpacity = opacity * (0.3 + seed / CGFloat(lineCount) * 0.7)

                var start = CGPoint.zero
                var end = CGPoint.zero

                switch direction {
                case .right:
                    let y = size.height * (0.2 + seed / CGFloat(lineCount) * 0.6)
                    start = CGPoint(x: size.width * (t - 0.2), y: y)
                    end = CGPoint(x: size.width * t, y: y)
                case .left:
                    let y = size.height * (0.2 + seed / CGFloat(lineCount) * 0.6)
                    start = CGPoint(x: size.width * (1.0 - t + 0.2), y: y)
                    end = CGPoint(x: size.width * (1.0 - t), y: y)
                case .up:
                    let x = size.width * (0.3 + seed / CGFloat(lineCount) * 0.4)
                    start = CGPoint(x: x, y: size.height * (1.0 - t + 0.15))
                    end = CGPoint(x: x, y: size.height * (1.0 - t))
                case .radial:
                    let angle = CGFloat.pi * 2 * seed / CGFloat(lineCount)
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let innerR = min(size.width, size.height) * 0.2 * t
                    let outerR = innerR + min(size.width, size.height) * 0.1
                    start = CGPoint(x: center.x + cos(angle) * innerR, y: center.y + sin(angle) * innerR)
                    end = CGPoint(x: center.x + cos(angle) * outerR, y: center.y + sin(angle) * outerR)
                }

                var path = Path()
                path.move(to: start)
                path.addLine(to: end)

                context.stroke(
                    path,
                    with: .color(color.opacity(lineOpacity)),
                    lineWidth: 2
                )
            }
        }
        .allowsHitTesting(false)
    }
}
