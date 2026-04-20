import SwiftUI

/// Canvas-based renderer for `TechniqueAnimation`. Drives a parameterized
/// kinematic figure, a ball, and two feet through interpolated keyframes.
///
/// Design notes:
/// - Pure interpolation math lives in `TechniqueAnimation.frame(at:)`.
/// - Torso/head/shoulders are driven by `AvatarKinematics` presets.
/// - Foot positions are authored per-keyframe and drive visual placement
///   directly; the figure's legs are drawn hip → knee → foot where the
///   knee is the midpoint bowed forward by the kinematic `kneeBend`.
/// - TTS fires once per keyframe boundary crossing (including loop wrap).
struct TechniqueAnimationView: View {
    let animation: TechniqueAnimation
    let coachVoice: CoachVoiceProtocol?
    let voiceoverEnabled: Bool

    @State private var isPlaying: Bool = true
    @State private var startedAt: Date = .distantPast
    @State private var accumulatedOffset: TimeInterval = 0
    @State private var lastSpokenKeyframeIndex: Int = -1
    @State private var displayedCaption: String? = nil

    init(animation: TechniqueAnimation,
         coachVoice: CoachVoiceProtocol? = nil,
         voiceoverEnabled: Bool = true) {
        self.animation = animation
        self.coachVoice = coachVoice
        self.voiceoverEnabled = voiceoverEnabled
    }

    var body: some View {
        VStack(spacing: 12) {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isPlaying)) { context in
                let elapsed = isPlaying
                    ? accumulatedOffset + context.date.timeIntervalSince(startedAt)
                    : accumulatedOffset
                let frame = animation.frame(at: max(0, elapsed))

                diagramCanvas(frame: frame)
                    .onChange(of: frame.currentKeyframeIndex) { newIndex in
                        handleKeyframeCrossing(to: newIndex)
                    }
                    .onChange(of: frame.caption ?? "") { _ in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            displayedCaption = frame.caption
                        }
                    }
            }
            .frame(height: 240)
            .background(diagramBackground)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            .overlay(alignment: .topTrailing) { viewAngleBadge }
            .overlay(alignment: .bottomLeading) { playPauseButton }

            captionStrip
        }
        .onAppear {
            startedAt = Date()
            accumulatedOffset = 0
            lastSpokenKeyframeIndex = -1
            displayedCaption = animation.keyframes.first?.caption
        }
        .onDisappear {
            // Stop any in-flight speech when the view leaves screen so the
            // coach voice doesn't trail into the next surface.
            coachVoice?.stop()
        }
    }

    // MARK: - Canvas

    private func diagramCanvas(frame: InterpolatedFrame) -> some View {
        Canvas { context, size in
            drawPitchGuides(context: &context, size: size)
            drawAvatar(frame: frame, context: &context, size: size)
            drawFoot(frame.leftFoot,  context: &context, size: size)
            drawFoot(frame.rightFoot, context: &context, size: size)
            drawBall(frame.ball, context: &context, size: size)
        }
    }

    private var diagramBackground: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#0F1F32"), Color(hex: "#06293A")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var viewAngleBadge: some View {
        Text(animation.viewAngle == .profile ? "SIDE VIEW" : "TOP DOWN")
            .font(.system(size: 9, weight: .heavy, design: .rounded))
            .tracking(1.5)
            .foregroundStyle(Color.dsSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.5))
            .clipShape(Capsule())
            .padding(10)
    }

    private var playPauseButton: some View {
        Button {
            togglePlay()
        } label: {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(Color(hex: "#06293A"))
                .frame(width: 32, height: 32)
                .background(Color.dsSecondary)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .padding(10)
        .accessibilityLabel(isPlaying ? "Pause animation" : "Play animation")
    }

    // MARK: - Caption

    @ViewBuilder
    private var captionStrip: some View {
        let text = displayedCaption ?? animation.keyframes.first?.caption ?? ""
        HStack {
            Text(text)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.dsOnSurface)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.dsSurfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
    }

    // MARK: - Drawing primitives

    private func drawPitchGuides(context: inout GraphicsContext, size: CGSize) {
        // Subtle horizon line at y=0.70 so the profile view reads as "ground".
        if animation.viewAngle == .profile {
            let y = 0.70 * size.height
            let line = Path { p in
                p.move(to: CGPoint(x: 0, y: y))
                p.addLine(to: CGPoint(x: size.width, y: y))
            }
            context.stroke(
                line,
                with: .color(Color.white.opacity(0.06)),
                style: StrokeStyle(lineWidth: 1, dash: [4, 6])
            )
        }
    }

    private func drawAvatar(frame: InterpolatedFrame, context: inout GraphicsContext, size: CGSize) {
        let kin = frame.avatarKinematics
        let hip = CGPoint(x: kin.centerOfMass.x * size.width,
                          y: kin.centerOfMass.y * size.height)

        // Torso vector (from hip upward, rotated by torsoTilt).
        // All trig uses Double explicitly — mixing CGFloat * Double with sin/
        // cos overloads was ambiguous on iOS 26 SDK (ambiguous-use error).
        let torsoTilt = kin.torsoTilt
        let torsoLen: Double = Double(size.height) * 0.22
        let torsoEnd = CGPoint(
            x: hip.x + CGFloat(sin(torsoTilt) * torsoLen),
            y: hip.y - CGFloat(cos(torsoTilt) * torsoLen)
        )

        // Torso stroke.
        var torso = Path()
        torso.move(to: hip)
        torso.addLine(to: torsoEnd)
        context.stroke(torso, with: .color(Color.dsOnSurface.opacity(0.92)), style: StrokeStyle(lineWidth: 10, lineCap: .round))

        // Shoulders — perpendicular to torso, offset by shoulderTilt.
        let shoulderHalfWidth: Double = Double(size.width) * 0.055
        let perpAngle = torsoTilt + kin.shoulderTilt * 0.3
        let shoulderDx = CGFloat(cos(perpAngle) * shoulderHalfWidth)
        let shoulderDy = CGFloat(sin(perpAngle) * shoulderHalfWidth)
        var shoulders = Path()
        shoulders.move(to: CGPoint(x: torsoEnd.x - shoulderDx, y: torsoEnd.y - shoulderDy))
        shoulders.addLine(to: CGPoint(x: torsoEnd.x + shoulderDx, y: torsoEnd.y + shoulderDy))
        context.stroke(shoulders, with: .color(Color.dsOnSurface.opacity(0.85)), style: StrokeStyle(lineWidth: 6, lineCap: .round))

        // Head — above torso, slight lean offset.
        let headRadius: Double = Double(size.height) * 0.045
        let headCenter = CGPoint(
            x: torsoEnd.x + CGFloat(sin(torsoTilt) * headRadius * 0.8),
            y: torsoEnd.y - CGFloat(cos(torsoTilt) * headRadius * 1.4)
        )
        let headR = CGFloat(headRadius)
        context.fill(
            Path(ellipseIn: CGRect(
                x: headCenter.x - headR, y: headCenter.y - headR,
                width: headR * 2, height: headR * 2
            )),
            with: .color(Color.dsOnSurface.opacity(0.92))
        )

        // Legs — hip → knee → foot. Knee is midpoint bowed forward by kneeBend.
        drawLeg(from: hip,
                to: CGPoint(x: frame.leftFoot.position.x * size.width,
                            y: frame.leftFoot.position.y * size.height),
                kneeBend: kin.leftKneeBend,
                context: &context)
        drawLeg(from: hip,
                to: CGPoint(x: frame.rightFoot.position.x * size.width,
                            y: frame.rightFoot.position.y * size.height),
                kneeBend: kin.rightKneeBend,
                context: &context)

        // Hip joint dot.
        let hipDot: CGFloat = 6
        context.fill(
            Path(ellipseIn: CGRect(x: hip.x - hipDot, y: hip.y - hipDot, width: hipDot * 2, height: hipDot * 2)),
            with: .color(Color.dsAccentOrange)
        )
    }

    private func drawLeg(from hip: CGPoint, to foot: CGPoint, kneeBend: Double, context: inout GraphicsContext) {
        // Midpoint plus a forward (downward-forward) bow proportional to bend.
        let mid = CGPoint(x: (hip.x + foot.x) / 2, y: (hip.y + foot.y) / 2)
        let dx = foot.x - hip.x
        let dy = foot.y - hip.y
        // Perpendicular vector pointing "forward" of the leg (in 2D profile,
        // that means slightly toward the viewer — positive x side for the
        // right leg, mirrored for the left is handled by the knee offset).
        let len = max(1, hypot(dx, dy))
        let nx = -dy / len
        let ny =  dx / len
        let bow = CGFloat(kneeBend) * 28
        let knee = CGPoint(x: mid.x + nx * bow, y: mid.y + ny * bow)

        var path = Path()
        path.move(to: hip)
        path.addLine(to: knee)
        path.addLine(to: foot)
        context.stroke(path, with: .color(Color.dsOnSurface.opacity(0.80)), style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
    }

    private func drawFoot(_ foot: FootState, context: inout GraphicsContext, size: CGSize) {
        let p = CGPoint(x: foot.position.x * size.width, y: foot.position.y * size.height)
        let radius: CGFloat = 11
        let footRect = CGRect(x: p.x - radius, y: p.y - radius, width: radius * 2, height: radius * 2)

        // Base foot.
        context.fill(
            Path(ellipseIn: footRect),
            with: .color(Color.dsOnSurface.opacity(0.92))
        )

        // Active-foot ring + surface color.
        if foot.isActive {
            let ringRadius = radius + 6
            let ringRect = CGRect(x: p.x - ringRadius, y: p.y - ringRadius,
                                  width: ringRadius * 2, height: ringRadius * 2)
            context.stroke(
                Path(ellipseIn: ringRect),
                with: .color(surfaceColor(foot.surface)),
                style: StrokeStyle(lineWidth: 3)
            )
        }
    }

    private func drawBall(_ ball: NormPoint, context: inout GraphicsContext, size: CGSize) {
        let p = CGPoint(x: ball.x * size.width, y: ball.y * size.height)
        let r: CGFloat = 10
        let rect = CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)
        context.fill(
            Path(ellipseIn: rect),
            with: .color(Color.dsAccentOrange)
        )
        context.stroke(
            Path(ellipseIn: rect),
            with: .color(Color.black.opacity(0.5)),
            style: StrokeStyle(lineWidth: 1.5)
        )
    }

    private func surfaceColor(_ surface: FootSurface) -> Color {
        switch surface {
        case .none:    return .clear
        case .inside:  return Color(hex: "#46E5F8")
        case .outside: return Color(hex: "#A855F7")
        case .laces:   return Color.dsAccentOrange
        case .sole:    return Color(hex: "#FFE9BD")
        case .heel:    return Color(hex: "#F87171")
        }
    }

    // MARK: - Playback control

    private func togglePlay() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if isPlaying {
            accumulatedOffset += Date().timeIntervalSince(startedAt)
            isPlaying = false
        } else {
            startedAt = Date()
            isPlaying = true
        }
    }

    // MARK: - TTS coupling

    private func handleKeyframeCrossing(to newIndex: Int) {
        guard newIndex != lastSpokenKeyframeIndex else { return }
        lastSpokenKeyframeIndex = newIndex
        guard voiceoverEnabled,
              let coachVoice,
              let voiceover = animation.keyframes[safe: newIndex]?.voiceover,
              !voiceover.isEmpty else { return }
        coachVoice.speak(voiceover, personality: "manager", rate: 1.0)
    }
}

// MARK: - Utilities

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#if DEBUG
#Preview("Scissor: Swing (No Ball)") {
    ZStack {
        Color.dsBackground.ignoresSafeArea()
        TechniqueAnimationView(
            animation: .scissorSwingNoBall,
            coachVoice: nil,
            voiceoverEnabled: false
        )
        .padding()
    }
}
#endif
