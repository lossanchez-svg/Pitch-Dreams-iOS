import SwiftUI

// MARK: - Pitch Element Types

enum PitchElementType {
    case player, opponent, teammate, ball, arrow, zone
}

struct PitchElement: Identifiable {
    let id: String
    let type: PitchElementType
    let x: CGFloat      // 0-100 percentage
    let y: CGFloat      // 0-100 percentage
    let label: String?
    let highlight: Bool
    // For arrows
    let toX: CGFloat?
    let toY: CGFloat?
    let arrowType: String?  // "pass", "run", "scan"

    init(
        id: String,
        type: PitchElementType,
        x: CGFloat,
        y: CGFloat,
        label: String? = nil,
        highlight: Bool = false,
        toX: CGFloat? = nil,
        toY: CGFloat? = nil,
        arrowType: String? = nil
    ) {
        self.id = id
        self.type = type
        self.x = x
        self.y = y
        self.label = label
        self.highlight = highlight
        self.toX = toX
        self.toY = toY
        self.arrowType = arrowType
    }
}

// MARK: - Tactical Pitch View

struct TacticalPitchView: View {
    let elements: [PitchElement]

    @State private var pulseScale: CGFloat = 1.0

    private let pitchGreen = Color(red: 0.176, green: 0.353, blue: 0.153)  // #2d5a27
    private let lineColor = Color.white.opacity(0.3)
    private let lineWidth: CGFloat = 1.5

    var body: some View {
        Canvas { context, size in
            drawPitchBackground(context: context, size: size)
            drawPitchLines(context: context, size: size)
            drawElements(context: context, size: size)
        }
        .aspectRatio(3.0 / 4.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            // Pulsing rings for highlighted elements via SwiftUI overlay
            GeometryReader { geo in
                ForEach(elements.filter { $0.highlight && $0.type == .player }) { element in
                    Circle()
                        .stroke(Color.cyan.opacity(0.5), lineWidth: 2)
                        .frame(width: 30 * pulseScale, height: 30 * pulseScale)
                        .position(
                            x: element.x / 100 * geo.size.width,
                            y: element.y / 100 * geo.size.height
                        )
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulseScale = 1.5
            }
        }
    }

    // MARK: - Pitch Background

    private func drawPitchBackground(context: GraphicsContext, size: CGSize) {
        let rect = CGRect(origin: .zero, size: size)
        context.fill(Path(roundedRect: rect, cornerRadius: 12), with: .color(pitchGreen))

        // Subtle grass stripe pattern
        let stripeCount = 10
        let stripeHeight = size.height / CGFloat(stripeCount)
        for i in stride(from: 0, to: stripeCount, by: 2) {
            let stripeRect = CGRect(
                x: 0,
                y: CGFloat(i) * stripeHeight,
                width: size.width,
                height: stripeHeight
            )
            context.fill(Path(stripeRect), with: .color(Color.white.opacity(0.03)))
        }
    }

    // MARK: - Pitch Lines

    private func drawPitchLines(context: GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        let margin: CGFloat = 8
        let left = margin
        let right = w - margin
        let top = margin
        let bottom = h - margin
        let midY = h / 2

        // Outer boundary
        var boundary = Path()
        boundary.addRoundedRect(
            in: CGRect(x: left, y: top, width: right - left, height: bottom - top),
            cornerSize: CGSize(width: 4, height: 4)
        )
        context.stroke(boundary, with: .color(lineColor), lineWidth: lineWidth)

        // Center line
        var centerLine = Path()
        centerLine.move(to: CGPoint(x: left, y: midY))
        centerLine.addLine(to: CGPoint(x: right, y: midY))
        context.stroke(centerLine, with: .color(lineColor), lineWidth: lineWidth)

        // Center circle
        let centerCircleRadius = w * 0.12
        var centerCircle = Path()
        centerCircle.addEllipse(in: CGRect(
            x: w / 2 - centerCircleRadius,
            y: midY - centerCircleRadius,
            width: centerCircleRadius * 2,
            height: centerCircleRadius * 2
        ))
        context.stroke(centerCircle, with: .color(lineColor), lineWidth: lineWidth)

        // Center dot
        var centerDot = Path()
        centerDot.addEllipse(in: CGRect(x: w / 2 - 2, y: midY - 2, width: 4, height: 4))
        context.fill(centerDot, with: .color(lineColor))

        // Penalty areas
        let penaltyWidth = w * 0.55
        let penaltyHeight = h * 0.15
        let penaltyX = (w - penaltyWidth) / 2

        // Top penalty area
        var topPenalty = Path()
        topPenalty.addRect(CGRect(x: penaltyX, y: top, width: penaltyWidth, height: penaltyHeight))
        context.stroke(topPenalty, with: .color(lineColor), lineWidth: lineWidth)

        // Bottom penalty area
        var bottomPenalty = Path()
        bottomPenalty.addRect(CGRect(x: penaltyX, y: bottom - penaltyHeight, width: penaltyWidth, height: penaltyHeight))
        context.stroke(bottomPenalty, with: .color(lineColor), lineWidth: lineWidth)

        // Goal areas
        let goalWidth = w * 0.28
        let goalHeight = h * 0.06
        let goalX = (w - goalWidth) / 2

        var topGoal = Path()
        topGoal.addRect(CGRect(x: goalX, y: top, width: goalWidth, height: goalHeight))
        context.stroke(topGoal, with: .color(lineColor), lineWidth: lineWidth)

        var bottomGoal = Path()
        bottomGoal.addRect(CGRect(x: goalX, y: bottom - goalHeight, width: goalWidth, height: goalHeight))
        context.stroke(bottomGoal, with: .color(lineColor), lineWidth: lineWidth)

        // Penalty arcs
        let arcRadius = w * 0.08
        var topArc = Path()
        topArc.addArc(
            center: CGPoint(x: w / 2, y: top + penaltyHeight),
            radius: arcRadius,
            startAngle: .degrees(0),
            endAngle: .degrees(180),
            clockwise: true
        )
        context.stroke(topArc, with: .color(lineColor), lineWidth: lineWidth)

        var bottomArc = Path()
        bottomArc.addArc(
            center: CGPoint(x: w / 2, y: bottom - penaltyHeight),
            radius: arcRadius,
            startAngle: .degrees(180),
            endAngle: .degrees(360),
            clockwise: true
        )
        context.stroke(bottomArc, with: .color(lineColor), lineWidth: lineWidth)

        // Corner arcs
        let cornerRadius: CGFloat = 6
        for corner in [(left, top, 0.0, 90.0), (right, top, 90.0, 180.0),
                       (left, bottom, 270.0, 360.0), (right, bottom, 180.0, 270.0)] {
            var arc = Path()
            arc.addArc(
                center: CGPoint(x: corner.0, y: corner.1),
                radius: cornerRadius,
                startAngle: .degrees(corner.2),
                endAngle: .degrees(corner.3),
                clockwise: false
            )
            context.stroke(arc, with: .color(lineColor), lineWidth: lineWidth)
        }
    }

    // MARK: - Elements

    private func drawElements(context: GraphicsContext, size: CGSize) {
        // Draw zones first (background layer)
        for element in elements where element.type == .zone {
            drawZone(context: context, size: size, element: element)
        }

        // Draw arrows
        for element in elements where element.type == .arrow {
            drawArrow(context: context, size: size, element: element)
        }

        // Draw entities (players, opponents, teammates, ball)
        for element in elements where element.type != .arrow && element.type != .zone {
            drawEntity(context: context, size: size, element: element)
        }
    }

    private func drawEntity(context: GraphicsContext, size: CGSize, element: PitchElement) {
        let px = element.x / 100 * size.width
        let py = element.y / 100 * size.height

        let (color, radius): (Color, CGFloat) = {
            switch element.type {
            case .player: return (.cyan, 12)
            case .teammate: return (.blue, 10)
            case .opponent: return (.red, 10)
            case .ball: return (.orange, 8)
            default: return (.white, 10)
            }
        }()

        // Shadow for depth
        var shadowCircle = Path()
        shadowCircle.addEllipse(in: CGRect(
            x: px - radius + 1,
            y: py - radius + 1,
            width: radius * 2,
            height: radius * 2
        ))
        context.fill(shadowCircle, with: .color(.black.opacity(0.3)))

        // Main circle
        var circle = Path()
        circle.addEllipse(in: CGRect(
            x: px - radius,
            y: py - radius,
            width: radius * 2,
            height: radius * 2
        ))
        context.fill(circle, with: .color(color))

        // Highlight ring (static base; animated pulse done via overlay)
        if element.highlight {
            var ring = Path()
            ring.addEllipse(in: CGRect(
                x: px - radius - 3,
                y: py - radius - 3,
                width: (radius + 3) * 2,
                height: (radius + 3) * 2
            ))
            context.stroke(ring, with: .color(color.opacity(0.6)), lineWidth: 2)
        }

        // Label
        if let label = element.label {
            let labelY = py + radius + 12
            context.draw(
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white),
                at: CGPoint(x: px, y: labelY),
                anchor: .center
            )
        }
    }

    private func drawArrow(context: GraphicsContext, size: CGSize, element: PitchElement) {
        guard let toX = element.toX, let toY = element.toY else { return }

        let fromPt = CGPoint(x: element.x / 100 * size.width, y: element.y / 100 * size.height)
        let toPt = CGPoint(x: toX / 100 * size.width, y: toY / 100 * size.height)

        let arrowKind = element.arrowType ?? "pass"

        var path = Path()
        path.move(to: fromPt)
        path.addLine(to: toPt)

        let (color, style): (Color, StrokeStyle) = {
            switch arrowKind {
            case "pass":
                return (.white.opacity(0.8), StrokeStyle(lineWidth: 2, dash: [6, 4]))
            case "run":
                return (.cyan, StrokeStyle(lineWidth: 2))
            case "scan":
                return (.yellow, StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
            default:
                return (.white.opacity(0.7), StrokeStyle(lineWidth: 2))
            }
        }()

        context.stroke(path, with: .color(color), style: style)

        // Arrowhead
        let angle = atan2(toPt.y - fromPt.y, toPt.x - fromPt.x)
        let headLength: CGFloat = 8
        let headAngle: CGFloat = .pi / 6

        var head = Path()
        head.move(to: toPt)
        head.addLine(to: CGPoint(
            x: toPt.x - headLength * cos(angle - headAngle),
            y: toPt.y - headLength * sin(angle - headAngle)
        ))
        head.move(to: toPt)
        head.addLine(to: CGPoint(
            x: toPt.x - headLength * cos(angle + headAngle),
            y: toPt.y - headLength * sin(angle + headAngle)
        ))
        context.stroke(head, with: .color(color), lineWidth: 2)
    }

    private func drawZone(context: GraphicsContext, size: CGSize, element: PitchElement) {
        guard let toX = element.toX, let toY = element.toY else { return }

        let x1 = element.x / 100 * size.width
        let y1 = element.y / 100 * size.height
        let x2 = toX / 100 * size.width
        let y2 = toY / 100 * size.height

        let rect = CGRect(
            x: min(x1, x2),
            y: min(y1, y2),
            width: abs(x2 - x1),
            height: abs(y2 - y1)
        )

        let color: Color = element.highlight ? .cyan : .yellow
        var zonePath = Path()
        zonePath.addRoundedRect(in: rect, cornerSize: CGSize(width: 4, height: 4))
        context.fill(zonePath, with: .color(color.opacity(0.15)))
        context.stroke(zonePath, with: .color(color.opacity(0.4)), lineWidth: 1)

        if let label = element.label {
            context.draw(
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(color.opacity(0.8)),
                at: CGPoint(x: rect.midX, y: rect.midY),
                anchor: .center
            )
        }
    }
}

// MARK: - Preview

#Preview {
    TacticalPitchView(elements: [
        PitchElement(id: "self", type: .player, x: 50, y: 55, label: "You", highlight: true),
        PitchElement(id: "t1", type: .teammate, x: 15, y: 48, label: "LW"),
        PitchElement(id: "t2", type: .teammate, x: 56, y: 33, label: "CF"),
        PitchElement(id: "t3", type: .teammate, x: 45, y: 82, label: "CM"),
        PitchElement(id: "o1", type: .opponent, x: 38, y: 32),
        PitchElement(id: "o2", type: .opponent, x: 62, y: 32),
        PitchElement(id: "ball", type: .ball, x: 45, y: 80),
        PitchElement(id: "scan1", type: .arrow, x: 50, y: 55, toX: 30, toY: 45, arrowType: "scan"),
        PitchElement(id: "scan2", type: .arrow, x: 50, y: 55, toX: 70, toY: 45, arrowType: "scan"),
        PitchElement(id: "scan3", type: .arrow, x: 50, y: 55, toX: 50, toY: 70, arrowType: "scan"),
    ])
    .padding()
    .background(.black)
}
