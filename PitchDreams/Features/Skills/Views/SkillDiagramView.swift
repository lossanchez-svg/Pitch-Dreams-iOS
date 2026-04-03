import SwiftUI

/// Simplified Canvas diagrams for skill/drill concepts.
/// Maps drill categories and IDs to appropriate vector illustrations.
struct SkillDiagramView: View {
    let drillId: String
    let category: String
    var animated: Bool = false
    var isPlaying: Bool = false
    var onAnimationComplete: (() -> Void)?

    var body: some View {
        if animated, let animKey = resolveAnimationKey() {
            SkillPerformAnimationView(
                animationKey: animKey,
                isPlaying: isPlaying,
                onComplete: onAnimationComplete,
                accentColor: accentColorForCategory
            )
        } else if let diagramType = resolveDiagramType() {
            Canvas { context, size in
                switch diagramType {
                case .scanning3Point:
                    drawScanning3Point(context: context, size: size)
                case .decisionRDE:
                    drawDecisionRDE(context: context, size: size)
                case .decision2Step:
                    drawDecision2Step(context: context, size: size)
                case .decision3rdMan:
                    drawDecision3rdMan(context: context, size: size)
                case .ballMastery:
                    drawBallMastery(context: context, size: size)
                case .passing:
                    drawPassing(context: context, size: size)
                case .shooting:
                    drawShooting(context: context, size: size)
                case .dribbling:
                    drawDribbling(context: context, size: size)
                }
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Diagram Type Resolution

    private enum DiagramType {
        case scanning3Point
        case decisionRDE
        case decision2Step
        case decision3rdMan
        case ballMastery
        case passing
        case shooting
        case dribbling
    }

    private func resolveDiagramType() -> DiagramType? {
        // Map specific drill IDs to diagram types
        if drillId.contains("scan") || drillId.contains("shoulder") {
            return .scanning3Point
        }
        if drillId.contains("receive") || drillId.contains("rde") {
            return .decisionRDE
        }
        if drillId.contains("press") || drillId.contains("decision") {
            return .decision2Step
        }
        if drillId.contains("third-man") || drillId.contains("3rd") {
            return .decision3rdMan
        }

        // Fall back to category-based diagrams
        switch category {
        case "Ball Mastery": return .ballMastery
        case "Passing": return .passing
        case "Shooting": return .shooting
        case "Dribbling": return .dribbling
        case "First Touch": return .ballMastery
        default: return nil
        }
    }

    // MARK: - Animation Resolution

    private func resolveAnimationKey() -> SkillAnimationKey? {
        let key = SkillAnimationRegistry.resolve(drillId)
        return key == .generic ? nil : key
    }

    private var accentColorForCategory: Color {
        switch category {
        case "Scanning": return .cyan
        case "Decision Chain": return .purple
        case "Tempo": return .orange
        case "Ball Mastery", "Dribbling": return .green
        case "Passing": return .blue
        case "Shooting": return .red
        case "First Touch": return .teal
        case "Defending": return .yellow
        default: return .cyan
        }
    }

    // MARK: - Drawing Functions

    private let bgColor = Color(red: 0.12, green: 0.14, blue: 0.18)

    /// 3-Point Scanning: player at center with 3 scan arrows
    private func drawScanning3Point(context: GraphicsContext, size: CGSize) {
        fillBackground(context: context, size: size)
        let cx = size.width / 2
        let cy = size.height * 0.55

        // Player circle
        drawPlayer(context: context, at: CGPoint(x: cx, y: cy), color: .cyan, radius: 14)

        // Scan arrows in 3 directions
        let targets: [(CGFloat, CGFloat, String)] = [
            (cx - 60, cy - 50, "Left"),
            (cx + 60, cy - 50, "Right"),
            (cx, cy + 50, "Behind"),
        ]
        for (tx, ty, label) in targets {
            drawDashedArrow(context: context, from: CGPoint(x: cx, y: cy), to: CGPoint(x: tx, y: ty), color: .yellow)
            drawLabel(context: context, text: label, at: CGPoint(x: tx, y: ty - 12), color: .yellow)
        }

        // Title
        drawLabel(context: context, text: "3-Point Scan", at: CGPoint(x: cx, y: 16), color: .white, size: 13)
    }

    /// Receive-Decide-Execute: 3 connected nodes in a flow
    private func drawDecisionRDE(context: GraphicsContext, size: CGSize) {
        fillBackground(context: context, size: size)
        let nodeY = size.height / 2
        let spacing = size.width / 4
        let nodes: [(CGFloat, String, Color)] = [
            (spacing, "Receive", .green),
            (spacing * 2, "Decide", .orange),
            (spacing * 3, "Execute", .cyan),
        ]

        for i in 0..<nodes.count {
            let (x, label, color) = nodes[i]
            drawNode(context: context, at: CGPoint(x: x, y: nodeY), label: label, color: color)
            if i < nodes.count - 1 {
                let nextX = nodes[i + 1].0
                drawSolidArrow(context: context, from: CGPoint(x: x + 28, y: nodeY), to: CGPoint(x: nextX - 28, y: nodeY), color: .white.opacity(0.6))
            }
        }

        drawLabel(context: context, text: "Receive - Decide - Execute", at: CGPoint(x: size.width / 2, y: 16), color: .white, size: 13)
    }

    /// 2-Step Decision: decision tree with two branches
    private func drawDecision2Step(context: GraphicsContext, size: CGSize) {
        fillBackground(context: context, size: size)
        let cx = size.width / 2
        let topY: CGFloat = 50
        let midY: CGFloat = size.height / 2
        let bottomY: CGFloat = size.height - 40

        // Decision node
        drawNode(context: context, at: CGPoint(x: cx, y: topY), label: "Read", color: .purple)

        // Two branches
        drawSolidArrow(context: context, from: CGPoint(x: cx - 20, y: topY + 20), to: CGPoint(x: cx - 60, y: midY - 20), color: .white.opacity(0.5))
        drawSolidArrow(context: context, from: CGPoint(x: cx + 20, y: topY + 20), to: CGPoint(x: cx + 60, y: midY - 20), color: .white.opacity(0.5))

        drawNode(context: context, at: CGPoint(x: cx - 60, y: midY), label: "Press", color: .green)
        drawNode(context: context, at: CGPoint(x: cx + 60, y: midY), label: "Hold", color: .orange)

        // Outcomes
        drawSolidArrow(context: context, from: CGPoint(x: cx - 60, y: midY + 20), to: CGPoint(x: cx - 60, y: bottomY - 20), color: .white.opacity(0.4))
        drawSolidArrow(context: context, from: CGPoint(x: cx + 60, y: midY + 20), to: CGPoint(x: cx + 60, y: bottomY - 20), color: .white.opacity(0.4))

        drawLabel(context: context, text: "Win Ball", at: CGPoint(x: cx - 60, y: bottomY), color: .green, size: 11)
        drawLabel(context: context, text: "Stay Compact", at: CGPoint(x: cx + 60, y: bottomY), color: .orange, size: 11)

        drawLabel(context: context, text: "2-Step Decision", at: CGPoint(x: cx, y: 16), color: .white, size: 13)
    }

    /// 3rd Man Run: triangle passing pattern
    private func drawDecision3rdMan(context: GraphicsContext, size: CGSize) {
        fillBackground(context: context, size: size)
        let cx = size.width / 2

        let posA = CGPoint(x: cx, y: size.height - 50)
        let posB = CGPoint(x: cx, y: size.height / 2)
        let posC = CGPoint(x: cx - 70, y: size.height / 2 + 10)
        let target = CGPoint(x: cx - 30, y: 50)

        drawPlayer(context: context, at: posA, color: .blue, radius: 12)
        drawLabel(context: context, text: "A", at: CGPoint(x: posA.x, y: posA.y + 18), color: .white, size: 11)

        drawPlayer(context: context, at: posB, color: .blue, radius: 12)
        drawLabel(context: context, text: "B", at: CGPoint(x: posB.x, y: posB.y + 18), color: .white, size: 11)

        drawPlayer(context: context, at: posC, color: .cyan, radius: 14)
        drawLabel(context: context, text: "C (You)", at: CGPoint(x: posC.x, y: posC.y + 18), color: .cyan, size: 11)

        // A to B pass
        drawDashedArrow(context: context, from: posA, to: posB, color: .white.opacity(0.7))
        // C run
        drawSolidArrow(context: context, from: posC, to: target, color: .cyan)
        // B to C through-pass
        drawDashedArrow(context: context, from: posB, to: target, color: .white.opacity(0.7))

        drawLabel(context: context, text: "Third Man Run", at: CGPoint(x: cx, y: 16), color: .white, size: 13)
    }

    /// Ball Mastery: feet and ball with circular motion
    private func drawBallMastery(context: GraphicsContext, size: CGSize) {
        fillBackground(context: context, size: size)
        let cx = size.width / 2
        let cy = size.height / 2

        // Ball
        drawBall(context: context, at: CGPoint(x: cx, y: cy), radius: 12)

        // Circular motion arrows around ball
        let radius: CGFloat = 40
        let steps = 8
        for i in 0..<steps {
            let angle1 = CGFloat(i) / CGFloat(steps) * .pi * 2
            let angle2 = CGFloat(i + 1) / CGFloat(steps) * .pi * 2
            let from = CGPoint(x: cx + cos(angle1) * radius, y: cy + sin(angle1) * radius)
            let to = CGPoint(x: cx + cos(angle2) * radius, y: cy + sin(angle2) * radius)
            var dash = Path()
            dash.move(to: from)
            dash.addLine(to: to)
            context.stroke(dash, with: .color(.cyan.opacity(0.5)), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
        }

        // Feet indicators
        drawLabel(context: context, text: "L", at: CGPoint(x: cx - 50, y: cy), color: .white, size: 14)
        drawLabel(context: context, text: "R", at: CGPoint(x: cx + 50, y: cy), color: .white, size: 14)

        drawLabel(context: context, text: "Ball Mastery", at: CGPoint(x: cx, y: 16), color: .white, size: 13)
    }

    /// Passing: two players with a pass line between them
    private func drawPassing(context: GraphicsContext, size: CGSize) {
        fillBackground(context: context, size: size)
        let leftPt = CGPoint(x: size.width * 0.25, y: size.height / 2)
        let rightPt = CGPoint(x: size.width * 0.75, y: size.height / 2)

        drawPlayer(context: context, at: leftPt, color: .cyan, radius: 14)
        drawPlayer(context: context, at: rightPt, color: .blue, radius: 12)
        drawBall(context: context, at: CGPoint(x: size.width / 2, y: size.height / 2), radius: 8)

        drawDashedArrow(context: context, from: leftPt, to: rightPt, color: .white.opacity(0.6))

        drawLabel(context: context, text: "You", at: CGPoint(x: leftPt.x, y: leftPt.y + 22), color: .cyan, size: 11)
        drawLabel(context: context, text: "Target", at: CGPoint(x: rightPt.x, y: rightPt.y + 22), color: .blue, size: 11)
        drawLabel(context: context, text: "Passing", at: CGPoint(x: size.width / 2, y: 16), color: .white, size: 13)
    }

    /// Shooting: player, ball trajectory to goal
    private func drawShooting(context: GraphicsContext, size: CGSize) {
        fillBackground(context: context, size: size)
        let cx = size.width / 2
        let playerPt = CGPoint(x: cx, y: size.height - 50)

        // Goal
        var goal = Path()
        let goalWidth: CGFloat = 80
        let goalY: CGFloat = 35
        goal.move(to: CGPoint(x: cx - goalWidth / 2, y: goalY))
        goal.addLine(to: CGPoint(x: cx + goalWidth / 2, y: goalY))
        goal.addLine(to: CGPoint(x: cx + goalWidth / 2, y: goalY + 20))
        goal.addLine(to: CGPoint(x: cx - goalWidth / 2, y: goalY + 20))
        goal.closeSubpath()
        context.stroke(goal, with: .color(.white.opacity(0.5)), lineWidth: 2)

        drawPlayer(context: context, at: playerPt, color: .cyan, radius: 14)
        drawBall(context: context, at: CGPoint(x: cx - 5, y: size.height - 65), radius: 8)

        // Shot trajectory
        drawSolidArrow(context: context, from: CGPoint(x: cx, y: size.height - 65), to: CGPoint(x: cx, y: goalY + 20), color: .orange)

        drawLabel(context: context, text: "Shooting", at: CGPoint(x: cx, y: 16), color: .white, size: 13)
    }

    /// Dribbling: player weaving through cones
    private func drawDribbling(context: GraphicsContext, size: CGSize) {
        fillBackground(context: context, size: size)
        let cy = size.height / 2
        let startX: CGFloat = 40
        let spacing: CGFloat = (size.width - 80) / 4

        // Cones
        for i in 0..<5 {
            let x = startX + CGFloat(i) * spacing
            drawCone(context: context, at: CGPoint(x: x, y: cy))
        }

        // Weaving path
        var weave = Path()
        weave.move(to: CGPoint(x: startX - 20, y: cy + 25))
        for i in 0..<5 {
            let x = startX + CGFloat(i) * spacing
            let yOffset: CGFloat = i % 2 == 0 ? -25 : 25
            weave.addQuadCurve(
                to: CGPoint(x: x + spacing / 2, y: cy + (i % 2 == 0 ? 25 : -25)),
                control: CGPoint(x: x, y: cy + yOffset)
            )
        }
        context.stroke(weave, with: .color(.cyan.opacity(0.7)), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))

        drawPlayer(context: context, at: CGPoint(x: startX - 20, y: cy + 25), color: .cyan, radius: 10)
        drawLabel(context: context, text: "Dribbling", at: CGPoint(x: size.width / 2, y: 16), color: .white, size: 13)
    }

    // MARK: - Drawing Primitives

    private func fillBackground(context: GraphicsContext, size: CGSize) {
        let rect = CGRect(origin: .zero, size: size)
        context.fill(Path(roundedRect: rect, cornerRadius: 12), with: .color(bgColor))
    }

    private func drawPlayer(context: GraphicsContext, at point: CGPoint, color: Color, radius: CGFloat) {
        var shadow = Path()
        shadow.addEllipse(in: CGRect(x: point.x - radius + 1, y: point.y - radius + 1, width: radius * 2, height: radius * 2))
        context.fill(shadow, with: .color(.black.opacity(0.3)))

        var circle = Path()
        circle.addEllipse(in: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2))
        context.fill(circle, with: .color(color))
    }

    private func drawBall(context: GraphicsContext, at point: CGPoint, radius: CGFloat) {
        var circle = Path()
        circle.addEllipse(in: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2))
        context.fill(circle, with: .color(.orange))
    }

    private func drawNode(context: GraphicsContext, at point: CGPoint, label: String, color: Color) {
        let radius: CGFloat = 24
        var bg = Path()
        bg.addRoundedRect(in: CGRect(x: point.x - radius, y: point.y - radius / 1.5, width: radius * 2, height: radius * 1.3), cornerSize: CGSize(width: 6, height: 6))
        context.fill(bg, with: .color(color.opacity(0.2)))
        context.stroke(bg, with: .color(color.opacity(0.6)), lineWidth: 1.5)

        context.draw(
            Text(label).font(.system(size: 11, weight: .semibold)).foregroundColor(color),
            at: point,
            anchor: .center
        )
    }

    private func drawCone(context: GraphicsContext, at point: CGPoint) {
        var cone = Path()
        cone.move(to: CGPoint(x: point.x, y: point.y - 8))
        cone.addLine(to: CGPoint(x: point.x - 6, y: point.y + 6))
        cone.addLine(to: CGPoint(x: point.x + 6, y: point.y + 6))
        cone.closeSubpath()
        context.fill(cone, with: .color(.orange.opacity(0.7)))
    }

    private func drawSolidArrow(context: GraphicsContext, from: CGPoint, to: CGPoint, color: Color) {
        var line = Path()
        line.move(to: from)
        line.addLine(to: to)
        context.stroke(line, with: .color(color), lineWidth: 2)

        drawArrowHead(context: context, to: to, from: from, color: color)
    }

    private func drawDashedArrow(context: GraphicsContext, from: CGPoint, to: CGPoint, color: Color) {
        var line = Path()
        line.move(to: from)
        line.addLine(to: to)
        context.stroke(line, with: .color(color), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))

        drawArrowHead(context: context, to: to, from: from, color: color)
    }

    private func drawArrowHead(context: GraphicsContext, to: CGPoint, from: CGPoint, color: Color) {
        let angle = atan2(to.y - from.y, to.x - from.x)
        let headLength: CGFloat = 7
        let headAngle: CGFloat = .pi / 6

        var head = Path()
        head.move(to: to)
        head.addLine(to: CGPoint(
            x: to.x - headLength * cos(angle - headAngle),
            y: to.y - headLength * sin(angle - headAngle)
        ))
        head.move(to: to)
        head.addLine(to: CGPoint(
            x: to.x - headLength * cos(angle + headAngle),
            y: to.y - headLength * sin(angle + headAngle)
        ))
        context.stroke(head, with: .color(color), lineWidth: 2)
    }

    private func drawLabel(context: GraphicsContext, text: String, at point: CGPoint, color: Color, size: CGFloat = 10) {
        context.draw(
            Text(text).font(.system(size: size, weight: .medium)).foregroundColor(color),
            at: point,
            anchor: .center
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        SkillDiagramView(drillId: "scan-practice", category: "Ball Mastery")
        SkillDiagramView(drillId: "receive-rde", category: "Passing")
        SkillDiagramView(drillId: "bm-toe-taps", category: "Ball Mastery")
        SkillDiagramView(drillId: "pass-wall", category: "Passing")
    }
    .padding()
    .background(.black)
}
