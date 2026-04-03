import SwiftUI

/// Custom Shape for arrow path with arrowhead.
/// Supports `trim(from:to:)` for progressive draw-on animation.
struct AnimatedArrowShape: Shape {
    let from: CGPoint
    let to: CGPoint
    let arrowheadLength: CGFloat

    init(from: CGPoint, to: CGPoint, arrowheadLength: CGFloat = 8) {
        self.from = from
        self.to = to
        self.arrowheadLength = arrowheadLength
    }

    func path(in rect: CGRect) -> Path {
        Path { p in
            // Main line
            p.move(to: from)
            p.addLine(to: to)

            // Arrowhead
            let angle = atan2(to.y - from.y, to.x - from.x)
            let spread: CGFloat = .pi / 6  // 30 degrees

            let leftTip = CGPoint(
                x: to.x - arrowheadLength * cos(angle - spread),
                y: to.y - arrowheadLength * sin(angle - spread)
            )
            let rightTip = CGPoint(
                x: to.x - arrowheadLength * cos(angle + spread),
                y: to.y - arrowheadLength * sin(angle + spread)
            )

            p.move(to: leftTip)
            p.addLine(to: to)
            p.addLine(to: rightTip)
        }
    }
}
