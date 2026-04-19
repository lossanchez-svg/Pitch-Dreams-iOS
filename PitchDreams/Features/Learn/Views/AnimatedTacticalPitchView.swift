import SwiftUI

/// Animated tactical pitch view with per-step diagram state transitions.
/// Pitch lines rendered via Canvas; elements (players, arrows, zones) use SwiftUI overlays
/// to leverage `.animation()` and `.transition()`.
struct AnimatedTacticalPitchView: View {
    let diagram: TacticalDiagramState
    let stepIndex: Int
    /// F1 — element id to spotlight before the step animates.
    /// When set, non-matching elements dim to 15% for 1.5s with a pulse ring
    /// on the spotlighted target, then everything returns to full visibility
    /// as the main step animation plays.
    var spotlightElementId: String? = nil
    /// F1 — short caption shown during the spotlight phase only.
    /// Already age-resolved by the caller.
    var spotlightCaption: String? = nil
    /// F4 — multiplier applied to animation durations. 0.5 = half speed.
    var animationRate: Double = 1.0
    /// F5 — asset name for the child's avatar image, stage-aware. When set,
    /// the `.self_` player dot renders as this asset instead of an abstract
    /// dot. Falls back silently to the abstract dot when the asset is missing.
    var avatarAssetName: String? = nil
    var onPlayerTap: ((TacticalPlayer, CGPoint) -> Void)?
    var onArrowTap: ((TacticalArrow, CGPoint) -> Void)?
    var onZoneTap: ((TacticalZone, CGPoint) -> Void)?

    @State private var appeared = false
    @State private var spotlightActive = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Whether an element is the current spotlight target.
    private func isSpotlighted(elementId: String) -> Bool {
        spotlightActive && spotlightElementId == elementId
    }

    /// Dim factor during spotlight: full-opacity if no spotlight active,
    /// or if this element IS the spotlight. Otherwise 15%.
    private func elementOpacity(elementId: String) -> Double {
        guard spotlightActive else { return 1 }
        return spotlightElementId == elementId ? 1 : 0.15
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                // Static pitch background via Canvas
                PitchBackgroundCanvas()

                // Zones layer (behind everything)
                ForEach(diagram.zones) { zone in
                    ZoneOverlay(
                        zone: zone, size: size,
                        appeared: appeared, reduceMotion: reduceMotion,
                        animationRate: animationRate,
                        opacity: elementOpacity(elementId: zone.id),
                        isSpotlighted: isSpotlighted(elementId: zone.id)
                    )
                    .onTapGesture {
                        let pos = CGPoint(x: size.width * (zone.x + zone.w / 2) / 100,
                                          y: size.height * zone.y / 100)
                        onZoneTap?(zone, pos)
                    }
                }

                // Arrows layer
                ForEach(diagram.arrows) { arrow in
                    ArrowOverlay(
                        arrow: arrow, size: size,
                        appeared: appeared, reduceMotion: reduceMotion,
                        animationRate: animationRate,
                        opacity: elementOpacity(elementId: arrow.id),
                        isSpotlighted: isSpotlighted(elementId: arrow.id)
                    )
                    .onTapGesture {
                        let pos = CGPoint(x: size.width * (arrow.fromX + arrow.toX) / 200,
                                          y: size.height * (arrow.fromY + arrow.toY) / 200)
                        onArrowTap?(arrow, pos)
                    }
                }

                // Ball
                if let ball = diagram.ball {
                    BallDot(ball: ball, size: size, appeared: appeared, reduceMotion: reduceMotion, animationRate: animationRate)
                }

                // Players layer (on top)
                ForEach(diagram.players) { player in
                    PlayerDot(
                        player: player, size: size,
                        appeared: appeared, reduceMotion: reduceMotion,
                        avatarAssetName: avatarAssetName,
                        opacity: elementOpacity(elementId: player.id),
                        isSpotlighted: isSpotlighted(elementId: player.id)
                    ) {
                        let pos = CGPoint(x: size.width * player.x / 100,
                                          y: size.height * player.y / 100)
                        onPlayerTap?(player, pos)
                    }
                }

                // Spotlight caption (top, during spotlight phase only)
                if spotlightActive, let caption = spotlightCaption {
                    VStack {
                        Text(caption)
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.7))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(Color.dsSecondary.opacity(0.5), lineWidth: 1)
                            )
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .padding(.top, 16)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .aspectRatio(3.0 / 4.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onChange(of: stepIndex) { _ in
            resetAndPlay()
        }
        .onAppear {
            resetAndPlay()
        }
    }

    /// Per-step animation sequencing: optional spotlight phase (1.5s) → main
    /// animation. When `spotlightElementId` is nil we skip straight to the
    /// main animation so lessons without spotlights don't pay any extra time.
    private func resetAndPlay() {
        appeared = false
        spotlightActive = false

        let hasSpotlight = spotlightElementId != nil && !reduceMotion
        let spotlightDuration: Double = 1.5

        if hasSpotlight {
            // Spotlight phase: dim, then pulse, then reveal.
            withAnimation(.easeIn(duration: 0.25)) {
                spotlightActive = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + spotlightDuration) {
                withAnimation(.easeOut(duration: 0.4)) {
                    spotlightActive = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(reduceMotion ? .none : .easeOut(duration: 0.4 / animationRate)) {
                        appeared = true
                    }
                }
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(reduceMotion ? .none : .easeOut(duration: 0.4 / animationRate)) {
                    appeared = true
                }
            }
        }
    }
}

// MARK: - Pitch Background (Canvas)

private struct PitchBackgroundCanvas: View {
    var body: some View {
        Canvas { context, size in
            // Field background
            let bgRect = CGRect(origin: .zero, size: size)
            context.fill(Path(roundedRect: bgRect, cornerRadius: 12), with: .color(Color(red: 0.08, green: 0.33, blue: 0.18)))

            // Subtle grass stripes
            let stripeCount = 8
            let stripeHeight = size.height / CGFloat(stripeCount)
            for i in stride(from: 0, to: stripeCount, by: 2) {
                let rect = CGRect(x: 0, y: CGFloat(i) * stripeHeight, width: size.width, height: stripeHeight)
                context.fill(Path(rect), with: .color(.white.opacity(0.02)))
            }

            let lineColor = Color.white.opacity(0.5)
            let lineWidth: CGFloat = 1.5
            let pad: CGFloat = 12

            // Boundary
            let fieldRect = CGRect(x: pad, y: pad, width: size.width - pad * 2, height: size.height - pad * 2)
            context.stroke(Path(fieldRect), with: .color(lineColor), lineWidth: lineWidth)

            // Center line
            var centerLine = Path()
            centerLine.move(to: CGPoint(x: pad, y: size.height / 2))
            centerLine.addLine(to: CGPoint(x: size.width - pad, y: size.height / 2))
            context.stroke(centerLine, with: .color(lineColor), lineWidth: lineWidth)

            // Center circle
            let centerRadius: CGFloat = min(size.width, size.height) * 0.12
            let centerCircle = Path(ellipseIn: CGRect(
                x: size.width / 2 - centerRadius,
                y: size.height / 2 - centerRadius,
                width: centerRadius * 2,
                height: centerRadius * 2
            ))
            context.stroke(centerCircle, with: .color(lineColor), lineWidth: lineWidth)

            // Center dot
            let dotR: CGFloat = 3
            context.fill(
                Path(ellipseIn: CGRect(x: size.width / 2 - dotR, y: size.height / 2 - dotR, width: dotR * 2, height: dotR * 2)),
                with: .color(lineColor)
            )

            // Penalty areas (top and bottom)
            let penW = size.width * 0.55
            let penH = size.height * 0.18
            let topPen = CGRect(x: (size.width - penW) / 2, y: pad, width: penW, height: penH)
            context.stroke(Path(topPen), with: .color(lineColor), lineWidth: lineWidth)

            let bottomPen = CGRect(x: (size.width - penW) / 2, y: size.height - pad - penH, width: penW, height: penH)
            context.stroke(Path(bottomPen), with: .color(lineColor), lineWidth: lineWidth)

            // Goal areas
            let goalW = size.width * 0.3
            let goalH = size.height * 0.08
            let topGoal = CGRect(x: (size.width - goalW) / 2, y: pad, width: goalW, height: goalH)
            context.stroke(Path(topGoal), with: .color(lineColor), lineWidth: lineWidth)

            let bottomGoal = CGRect(x: (size.width - goalW) / 2, y: size.height - pad - goalH, width: goalW, height: goalH)
            context.stroke(Path(bottomGoal), with: .color(lineColor), lineWidth: lineWidth)
        }
    }
}

// MARK: - Player Dot

private struct PlayerDot: View {
    let player: TacticalPlayer
    let size: CGSize
    let appeared: Bool
    let reduceMotion: Bool
    let avatarAssetName: String?
    let opacity: Double
    let isSpotlighted: Bool
    let onTap: () -> Void

    @State private var pulseScale: CGFloat = 1.0

    private var position: CGPoint {
        CGPoint(x: size.width * player.x / 100, y: size.height * player.y / 100)
    }

    private var dotColor: Color {
        switch player.type {
        case .self_: return Color(red: 0.13, green: 0.83, blue: 0.93)  // cyan
        case .teammate: return Color(red: 0.64, green: 0.9, blue: 0.21)  // lime
        case .opponent: return Color(red: 0.98, green: 0.45, blue: 0.09)  // orange
        }
    }

    private var radius: CGFloat {
        player.type == .self_ ? 9 : 7
    }

    /// F5 — show avatar image only when the player is the user's self_
    /// AND an asset is provided AND the asset actually exists. Any failure
    /// falls through to the abstract dot so legacy diagrams stay intact.
    private var showsAvatarImage: Bool {
        guard player.type == .self_ else { return false }
        guard let asset = avatarAssetName, !asset.isEmpty else { return false }
        return UIImage(named: asset) != nil
    }

    var body: some View {
        ZStack {
            // Spotlight pulse ring (overrides highlight pulse when spotlighted)
            if isSpotlighted {
                Circle()
                    .stroke(Color.dsSecondary, lineWidth: 3)
                    .frame(width: (radius + 12) * 2, height: (radius + 12) * 2)
                    .scaleEffect(pulseScale)
                    .opacity(2.0 - Double(pulseScale))
            } else if player.highlight {
                Circle()
                    .stroke(dotColor.opacity(0.5), lineWidth: 2)
                    .frame(width: (radius + 6) * 2, height: (radius + 6) * 2)
                    .scaleEffect(pulseScale)
                    .opacity(2.0 - Double(pulseScale))
            }

            // Glow ring for self
            if player.type == .self_ {
                Circle()
                    .fill(dotColor.opacity(0.15))
                    .frame(width: (radius + 3) * 2, height: (radius + 3) * 2)
            }

            // Main dot — or avatar image when available for self_
            if showsAvatarImage, let asset = avatarAssetName {
                Image(asset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: radius * 4, height: radius * 4)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(dotColor, lineWidth: 2))
                    .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
            } else {
                Circle()
                    .fill(dotColor)
                    .frame(width: radius * 2, height: radius * 2)
                    .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
            }

            // Label
            if let label = player.label {
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.6), radius: 2)
                    .offset(y: -(radius + (showsAvatarImage ? 22 : 10)))
                    .opacity(appeared ? 1 : 0)
                    .animation(reduceMotion ? .none : .easeOut(duration: 0.3).delay(0.3), value: appeared)
            }
        }
        .position(position)
        .scaleEffect(appeared ? 1.0 : 0)
        .opacity(opacity)
        .animation(reduceMotion ? .none : .spring(response: 0.4, dampingFraction: 0.6), value: appeared)
        .animation(.easeInOut(duration: 0.25), value: opacity)
        .onTapGesture(perform: onTap)
        .onAppear {
            guard (player.highlight || isSpotlighted), !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.3
            }
        }
        .onChange(of: isSpotlighted) { newValue in
            guard !reduceMotion else { return }
            if newValue {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    pulseScale = 1.3
                }
            }
        }
    }
}

// MARK: - Arrow Overlay

private struct ArrowOverlay: View {
    let arrow: TacticalArrow
    let size: CGSize
    let appeared: Bool
    let reduceMotion: Bool
    let animationRate: Double
    let opacity: Double
    let isSpotlighted: Bool

    @State private var trimEnd: CGFloat = 0

    private var fromPoint: CGPoint {
        CGPoint(x: size.width * arrow.fromX / 100, y: size.height * arrow.fromY / 100)
    }

    private var toPoint: CGPoint {
        CGPoint(x: size.width * arrow.toX / 100, y: size.height * arrow.toY / 100)
    }

    private var arrowColor: Color {
        switch arrow.type {
        case .pass: return .white
        case .run: return Color(red: 0.64, green: 0.9, blue: 0.21)  // lime
        case .scan: return Color(red: 0.13, green: 0.83, blue: 0.93)  // cyan
        case .space: return Color(red: 0.98, green: 0.8, blue: 0.08)  // yellow
        }
    }

    private var isDashed: Bool {
        arrow.type == .scan || arrow.type == .space
    }

    var body: some View {
        ZStack {
            AnimatedArrowShape(from: fromPoint, to: toPoint)
                .trim(from: 0, to: trimEnd)
                .stroke(
                    arrowColor,
                    style: StrokeStyle(
                        lineWidth: isSpotlighted ? 3 : 2,
                        lineCap: .round,
                        lineJoin: .round,
                        dash: isDashed ? [6, 4] : []
                    )
                )

            // Label at midpoint
            if let label = arrow.label {
                Text(label)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.7), radius: 2)
                    .position(
                        x: (fromPoint.x + toPoint.x) / 2 + 8,
                        y: (fromPoint.y + toPoint.y) / 2 - 6
                    )
                    .opacity(trimEnd > 0.8 ? 1 : 0)
                    .animation(reduceMotion ? .none : .easeOut(duration: 0.3), value: trimEnd)
            }
        }
        .opacity(opacity)
        .animation(.easeInOut(duration: 0.25), value: opacity)
        .onChange(of: appeared) { isAppeared in
            if isAppeared {
                let delay = reduceMotion ? 0 : (arrow.delay / animationRate)
                withAnimation(reduceMotion ? .none : .easeOut(duration: 0.6 / animationRate).delay(delay)) {
                    trimEnd = 1.0
                }
            } else {
                trimEnd = 0
            }
        }
    }
}

// MARK: - Zone Overlay

private struct ZoneOverlay: View {
    let zone: TacticalZone
    let size: CGSize
    let appeared: Bool
    let reduceMotion: Bool
    let animationRate: Double
    let opacity: Double
    let isSpotlighted: Bool

    private var rect: CGRect {
        CGRect(
            x: size.width * zone.x / 100,
            y: size.height * zone.y / 100,
            width: size.width * zone.w / 100,
            height: size.height * zone.h / 100
        )
    }

    private var fillColor: Color {
        switch zone.type {
        case .space: return Color(red: 0.64, green: 0.9, blue: 0.21)
        case .danger: return Color(red: 0.94, green: 0.27, blue: 0.27)
        case .opportunity: return Color(red: 0.13, green: 0.83, blue: 0.93)
        }
    }

    private var strokeColor: Color {
        fillColor
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(fillColor.opacity(0.12))
                .frame(width: rect.width, height: rect.height)

            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    isSpotlighted ? Color.dsSecondary : strokeColor.opacity(0.4),
                    style: StrokeStyle(lineWidth: isSpotlighted ? 2 : 1, dash: [4, 3])
                )
                .frame(width: rect.width, height: rect.height)

            if let label = zone.label {
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.5), radius: 1)
            }
        }
        .position(x: rect.midX, y: rect.midY)
        .scaleEffect(appeared ? 1.0 : 0.8)
        .opacity(appeared ? opacity : 0)
        .animation(reduceMotion ? .none : .easeOut(duration: 0.5 / animationRate), value: appeared)
        .animation(.easeInOut(duration: 0.25), value: opacity)
    }
}

// MARK: - Ball Dot

private struct BallDot: View {
    let ball: BallPosition
    let size: CGSize
    let appeared: Bool
    let reduceMotion: Bool
    let animationRate: Double

    private var position: CGPoint {
        CGPoint(x: size.width * ball.x / 100, y: size.height * ball.y / 100)
    }

    var body: some View {
        ZStack {
            // Shadow
            Circle()
                .fill(Color.black.opacity(0.4))
                .frame(width: 12, height: 12)
                .offset(y: 1)

            // Ball
            Circle()
                .fill(.white)
                .frame(width: 10, height: 10)
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                )
        }
        .position(position)
        .scaleEffect(appeared ? 1.0 : 0)
        .animation(reduceMotion ? .none : .spring(response: 0.3 / animationRate, dampingFraction: 0.5), value: appeared)
    }
}
