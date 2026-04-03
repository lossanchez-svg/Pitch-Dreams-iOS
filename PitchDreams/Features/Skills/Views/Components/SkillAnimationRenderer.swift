import SwiftUI

/// 10 Canvas draw functions for skill performance animations.
/// All use `progress: CGFloat` (0.0-1.0) for frame interpolation.
enum SkillAnimationRenderer {

    static func draw(
        key: SkillAnimationKey,
        context: inout GraphicsContext,
        size: CGSize,
        progress: CGFloat,
        accentColor: Color
    ) {
        switch key {
        case .juggling: drawJuggling(context: &context, size: size, progress: progress, color: accentColor)
        case .dribbling: drawDribbling(context: &context, size: size, progress: progress, color: accentColor)
        case .passing: drawPassing(context: &context, size: size, progress: progress, color: accentColor)
        case .shooting: drawShooting(context: &context, size: size, progress: progress, color: accentColor)
        case .firstTouch: drawFirstTouch(context: &context, size: size, progress: progress, color: accentColor)
        case .defending: drawDefending(context: &context, size: size, progress: progress, color: accentColor)
        case .scanning: drawScanning(context: &context, size: size, progress: progress, color: accentColor)
        case .decision: drawDecision(context: &context, size: size, progress: progress, color: accentColor)
        case .tempo: drawTempo(context: &context, size: size, progress: progress, color: accentColor)
        case .generic: drawGeneric(context: &context, size: size, progress: progress, color: accentColor)
        }
    }

    // MARK: - Juggling

    private static func drawJuggling(context: inout GraphicsContext, size: CGSize, progress: CGFloat, color: Color) {
        let center = CGPoint(x: size.width / 2, y: size.height * 0.7)

        // Player figure (simple circle + body)
        drawPlayerFigure(context: &context, at: center, size: size, color: color)

        // Ball bouncing up and down in parabolic arcs
        let ballPos = BallPhysics.bounceSequence(
            start: CGPoint(x: center.x, y: center.y - 20),
            bounceCount: 3,
            progress: progress
        )
        drawBall(context: &context, at: ballPos, size: size)

        // Glow arc at ball position
        drawGlowArc(context: &context, at: ballPos, radius: 12, color: color, progress: progress)
    }

    // MARK: - Dribbling

    private static func drawDribbling(context: inout GraphicsContext, size: CGSize, progress: CGFloat, color: Color) {
        // Player moves left to right
        let playerX = size.width * (0.2 + progress * 0.6)
        let playerY = size.height * 0.6
        let playerPos = CGPoint(x: playerX, y: playerY)

        drawPlayerFigure(context: &context, at: playerPos, size: size, color: color)

        // Ball alongside, slight weave
        let weave = sin(progress * .pi * 4) * 6
        let ballPos = CGPoint(x: playerX + 12, y: playerY - 10 + weave)
        drawBall(context: &context, at: ballPos, size: size)

        // Cones to dribble through
        for i in 0..<4 {
            let coneX = size.width * (0.25 + CGFloat(i) * 0.15)
            let coneY = size.height * 0.65
            drawCone(context: &context, at: CGPoint(x: coneX, y: coneY), color: .orange.opacity(0.6))
        }
    }

    // MARK: - Passing

    private static func drawPassing(context: inout GraphicsContext, size: CGSize, progress: CGFloat, color: Color) {
        let from = CGPoint(x: size.width * 0.25, y: size.height * 0.6)
        let to = CGPoint(x: size.width * 0.75, y: size.height * 0.5)

        // Two players
        drawPlayerFigure(context: &context, at: from, size: size, color: color)
        drawPlayerFigure(context: &context, at: to, size: size, color: color.opacity(0.7))

        // Ball arcs between them
        let ballPos = BallPhysics.parabolicArc(from: from, to: to, height: 30, progress: progress)
        drawBall(context: &context, at: ballPos, size: size)

        // Impact flash at reception
        if progress > 0.85 {
            let flashProgress = (progress - 0.85) / 0.15
            drawImpactFlash(context: &context, at: to, radius: 20 * flashProgress, color: color, opacity: 1.0 - flashProgress)
        }
    }

    // MARK: - Shooting

    private static func drawShooting(context: inout GraphicsContext, size: CGSize, progress: CGFloat, color: Color) {
        let playerPos = CGPoint(x: size.width * 0.35, y: size.height * 0.65)
        let goalPos = CGPoint(x: size.width * 0.8, y: size.height * 0.25)

        drawPlayerFigure(context: &context, at: playerPos, size: size, color: color)

        // Goal frame
        let goalRect = CGRect(x: size.width * 0.7, y: size.height * 0.15, width: size.width * 0.2, height: size.height * 0.25)
        context.stroke(Path(roundedRect: goalRect, cornerRadius: 2), with: .color(.white.opacity(0.5)), lineWidth: 2)

        // Ball rockets to goal
        if progress < 0.4 {
            // Wind-up phase — ball at feet
            let windupBall = CGPoint(x: playerPos.x + 10, y: playerPos.y - 8)
            drawBall(context: &context, at: windupBall, size: size)
        } else {
            let shotProgress = (progress - 0.4) / 0.6
            let ballPos = BallPhysics.parabolicArc(
                from: CGPoint(x: playerPos.x + 10, y: playerPos.y - 8),
                to: goalPos,
                height: 25,
                progress: shotProgress
            )
            drawBall(context: &context, at: ballPos, size: size)

            // Impact flash when ball reaches goal
            if shotProgress > 0.9 {
                let flashP = (shotProgress - 0.9) / 0.1
                drawImpactFlash(context: &context, at: goalPos, radius: 30 * flashP, color: .yellow, opacity: 1.0 - flashP)
            }
        }
    }

    // MARK: - First Touch

    private static func drawFirstTouch(context: inout GraphicsContext, size: CGSize, progress: CGFloat, color: Color) {
        let playerPos = CGPoint(x: size.width * 0.5, y: size.height * 0.6)
        drawPlayerFigure(context: &context, at: playerPos, size: size, color: color)

        // Ball arrives from left, player cushions
        let from = CGPoint(x: size.width * 0.1, y: size.height * 0.4)
        let receivePoint = CGPoint(x: playerPos.x - 5, y: playerPos.y - 10)

        if progress < 0.5 {
            // Ball traveling to player
            let ballPos = BallPhysics.linearTravel(from: from, to: receivePoint, progress: progress * 2)
            drawBall(context: &context, at: ballPos, size: size)
        } else {
            // Cushion — ball settles at feet with small bounce
            let settleProgress = (progress - 0.5) / 0.5
            let settle = CGPoint(x: playerPos.x + 5, y: playerPos.y - 8 - (1.0 - settleProgress) * 10)
            drawBall(context: &context, at: settle, size: size)
        }
    }

    // MARK: - Defending

    private static func drawDefending(context: inout GraphicsContext, size: CGSize, progress: CGFloat, color: Color) {
        // Lateral shuffle + interception
        let shuffleX = size.width * (0.3 + sin(progress * .pi * 2) * 0.15)
        let playerPos = CGPoint(x: shuffleX, y: size.height * 0.55)
        drawPlayerFigure(context: &context, at: playerPos, size: size, color: color)

        // Attacker with ball
        let attackerPos = CGPoint(x: size.width * 0.65, y: size.height * 0.5)
        drawPlayerFigure(context: &context, at: attackerPos, size: size, color: .orange.opacity(0.7))

        // Ball interception
        if progress > 0.7 {
            let interceptProgress = (progress - 0.7) / 0.3
            let ballPos = BallPhysics.linearTravel(
                from: CGPoint(x: attackerPos.x, y: attackerPos.y - 8),
                to: CGPoint(x: playerPos.x + 15, y: playerPos.y - 8),
                progress: interceptProgress
            )
            drawBall(context: &context, at: ballPos, size: size)

            if interceptProgress > 0.8 {
                let flashP = (interceptProgress - 0.8) / 0.2
                drawImpactFlash(context: &context, at: playerPos, radius: 20 * flashP, color: color, opacity: 1.0 - flashP)
            }
        } else {
            drawBall(context: &context, at: CGPoint(x: attackerPos.x, y: attackerPos.y - 8), size: size)
        }
    }

    // MARK: - Scanning

    private static func drawScanning(context: inout GraphicsContext, size: CGSize, progress: CGFloat, color: Color) {
        let center = CGPoint(x: size.width / 2, y: size.height * 0.55)
        drawPlayerFigure(context: &context, at: center, size: size, color: color)

        // Rotating scan arrows from player
        let arrowCount = 6
        for i in 0..<arrowCount {
            let baseAngle = CGFloat.pi * 2 * CGFloat(i) / CGFloat(arrowCount)
            let rotatedAngle = baseAngle + progress * .pi * 2
            let length: CGFloat = 40 + CGFloat(i % 3) * 10

            let end = CGPoint(
                x: center.x + cos(rotatedAngle) * length,
                y: center.y + sin(rotatedAngle) * length
            )

            var path = Path()
            path.move(to: center)
            path.addLine(to: end)

            let arrowOpacity = 0.3 + (sin(progress * .pi * 4 + CGFloat(i)) + 1) / 2 * 0.5
            context.stroke(
                path,
                with: .color(color.opacity(arrowOpacity)),
                style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])
            )
        }
    }

    // MARK: - Decision

    private static func drawDecision(context: inout GraphicsContext, size: CGSize, progress: CGFloat, color: Color) {
        let center = CGPoint(x: size.width * 0.35, y: size.height * 0.55)
        drawPlayerFigure(context: &context, at: center, size: size, color: color)

        // Branching arrows — decision tree
        let options: [(CGPoint, String)] = [
            (CGPoint(x: size.width * 0.7, y: size.height * 0.3), "A"),
            (CGPoint(x: size.width * 0.75, y: size.height * 0.55), "B"),
            (CGPoint(x: size.width * 0.65, y: size.height * 0.75), "C"),
        ]

        for (i, (target, label)) in options.enumerated() {
            let delay = CGFloat(i) * 0.15
            let arrowProgress = max(0, min(1, (progress - delay) / 0.5))

            if arrowProgress > 0 {
                let end = BallPhysics.linearTravel(from: center, to: target, progress: arrowProgress)
                var path = Path()
                path.move(to: center)
                path.addLine(to: end)

                let isChosen = i == 0 && progress > 0.7
                let opacity = isChosen ? 1.0 : 0.4
                context.stroke(path, with: .color(color.opacity(opacity)), style: StrokeStyle(lineWidth: isChosen ? 2.5 : 1.5, dash: [6, 3]))

                if arrowProgress > 0.8 {
                    context.draw(
                        Text(label).font(.system(size: 10, weight: .bold)).foregroundColor(.white),
                        at: target
                    )
                }
            }
        }
    }

    // MARK: - Tempo

    private static func drawTempo(context: inout GraphicsContext, size: CGSize, progress: CGFloat, color: Color) {
        let center = CGPoint(x: size.width / 2, y: size.height * 0.6)
        drawPlayerFigure(context: &context, at: center, size: size, color: color)

        // Metronome pulse — concentric rings
        let ringCount = 3
        for i in 0..<ringCount {
            let phase = (progress + CGFloat(i) * 0.33).truncatingRemainder(dividingBy: 1.0)
            let radius = 15 + phase * 50
            let opacity = max(0, 1.0 - phase)

            let ring = Path(ellipseIn: CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            ))
            context.stroke(ring, with: .color(color.opacity(opacity * 0.6)), lineWidth: 2)
        }

        // Ball with rhythm
        let ballBob = sin(progress * .pi * 6) * 5
        drawBall(context: &context, at: CGPoint(x: center.x + 15, y: center.y - 10 + ballBob), size: size)
    }

    // MARK: - Generic

    private static func drawGeneric(context: inout GraphicsContext, size: CGSize, progress: CGFloat, color: Color) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)

        // Simple pulse/glow
        let pulseRadius = 20 + sin(progress * .pi * 2) * 15
        let glow = Path(ellipseIn: CGRect(
            x: center.x - pulseRadius,
            y: center.y - pulseRadius,
            width: pulseRadius * 2,
            height: pulseRadius * 2
        ))
        context.fill(glow, with: .color(color.opacity(0.2)))
        context.stroke(glow, with: .color(color.opacity(0.5)), lineWidth: 2)

        drawBall(context: &context, at: center, size: size)
    }

    // MARK: - Shared Helpers

    private static func drawPlayerFigure(context: inout GraphicsContext, at point: CGPoint, size: CGSize, color: Color) {
        // Head
        let headRadius: CGFloat = 6
        context.fill(
            Path(ellipseIn: CGRect(x: point.x - headRadius, y: point.y - 28, width: headRadius * 2, height: headRadius * 2)),
            with: .color(color)
        )
        // Body line
        var body = Path()
        body.move(to: CGPoint(x: point.x, y: point.y - 16))
        body.addLine(to: CGPoint(x: point.x, y: point.y))
        context.stroke(body, with: .color(color), lineWidth: 2.5)

        // Arms
        var arms = Path()
        arms.move(to: CGPoint(x: point.x - 8, y: point.y - 12))
        arms.addLine(to: CGPoint(x: point.x + 8, y: point.y - 12))
        context.stroke(arms, with: .color(color), lineWidth: 2)

        // Legs
        var leftLeg = Path()
        leftLeg.move(to: CGPoint(x: point.x, y: point.y))
        leftLeg.addLine(to: CGPoint(x: point.x - 6, y: point.y + 12))
        context.stroke(leftLeg, with: .color(color), lineWidth: 2)

        var rightLeg = Path()
        rightLeg.move(to: CGPoint(x: point.x, y: point.y))
        rightLeg.addLine(to: CGPoint(x: point.x + 6, y: point.y + 12))
        context.stroke(rightLeg, with: .color(color), lineWidth: 2)
    }

    private static func drawBall(context: inout GraphicsContext, at point: CGPoint, size: CGSize) {
        let r: CGFloat = 5
        // Shadow
        context.fill(
            Path(ellipseIn: CGRect(x: point.x - r, y: point.y - r + 1, width: r * 2, height: r * 2)),
            with: .color(.black.opacity(0.3))
        )
        // Ball
        context.fill(
            Path(ellipseIn: CGRect(x: point.x - r, y: point.y - r, width: r * 2, height: r * 2)),
            with: .color(.white)
        )
        context.stroke(
            Path(ellipseIn: CGRect(x: point.x - r, y: point.y - r, width: r * 2, height: r * 2)),
            with: .color(.gray.opacity(0.4)),
            lineWidth: 0.5
        )
    }

    private static func drawCone(context: inout GraphicsContext, at point: CGPoint, color: Color) {
        var path = Path()
        path.move(to: CGPoint(x: point.x, y: point.y - 8))
        path.addLine(to: CGPoint(x: point.x - 5, y: point.y))
        path.addLine(to: CGPoint(x: point.x + 5, y: point.y))
        path.closeSubpath()
        context.fill(path, with: .color(color))
    }

    private static func drawGlowArc(context: inout GraphicsContext, at point: CGPoint, radius: CGFloat, color: Color, progress: CGFloat) {
        let arc = Path { p in
            p.addArc(
                center: point,
                radius: radius,
                startAngle: .degrees(-90),
                endAngle: .degrees(-90 + 360 * Double(progress)),
                clockwise: false
            )
        }
        context.stroke(arc, with: .color(color.opacity(0.4)), lineWidth: 2)
    }

    private static func drawImpactFlash(context: inout GraphicsContext, at point: CGPoint, radius: CGFloat, color: Color, opacity: Double) {
        let flash = Path(ellipseIn: CGRect(
            x: point.x - radius,
            y: point.y - radius,
            width: radius * 2,
            height: radius * 2
        ))
        context.fill(flash, with: .color(color.opacity(opacity * 0.5)))
    }
}
