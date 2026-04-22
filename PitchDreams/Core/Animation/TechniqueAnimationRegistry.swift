import Foundation

/// Resolves an asset-name string (from `MoveDrill.diagramAnimationAsset` or
/// `SignatureMove.heroDemoAsset`) to a keyframe-authored animation.
///
/// When a Rive-based animation eventually exists, we'll add a parallel
/// Rive-resolver that takes precedence via `TechniqueAnimation.riveAssetName`.
enum TechniqueAnimationRegistry {
    static func animation(for assetId: String) -> TechniqueAnimation? {
        all.first { $0.assetId == assetId }
    }

    /// Maps a `FirstTouchViewModel` drill key (e.g. "juggling_both_feet",
    /// "wall_ball_volley") to the animation that should appear above the
    /// tap counter. FirstTouch drills live outside `DrillDefinition`, so
    /// the mapping is expressed here instead of via a field on a shared
    /// model. Returns nil if no animation is authored for the key yet.
    static func animation(forFirstTouchDrillKey key: String) -> TechniqueAnimation? {
        let assetId: String?
        switch key {
        case "juggling_both_feet",
             "juggling_right_only",
             "juggling_left_only",
             "juggling_thigh":
            assetId = "diagram_juggling"
        case "wall_ball_pass":
            assetId = "diagram_wall_passes"
        case "wall_ball_one_touch":
            assetId = "diagram_wall_ball_oneTouch"
        case "wall_ball_volley":
            assetId = "diagram_wall_ball_volley"
        default:
            assetId = nil
        }
        return assetId.flatMap { animation(for: $0) }
    }

    static let all: [TechniqueAnimation] = [
        // Signature-move hero demos (Rive-preferred, Canvas fallback)
        .scissorHero,
        // Scissor — Stage 1 (groundwork)
        .scissorBreakdown,
        .scissorSwingNoBall,
        // Scissor — Stage 2 (technique)
        .scissorStillBall,
        .scissorWalking,
        .scissorConeEscape,
        // Scissor — Stage 3 (mastery)
        .scissorDouble,
        .scissorSpeedConeCorridor,
        // Body Feint — Stage 1 (groundwork)
        .bodyFeintBreakdown,
        .bodyFeintMirror,
        // Body Feint — Stage 2 (technique)
        .bodyFeintStillBall,
        .bodyFeintWalking,
        .bodyFeintConeEscape,
        // La Croqueta — Stage 1 (groundwork)
        .croquetaBreakdown,
        .croquetaInsideTaps,
        // La Croqueta — Stage 2 (technique)
        .croquetaStillBall,
        .croquetaLinear,
        .croquetaConeGate,
        // La Croqueta — Stage 3 (mastery)
        .croquetaSpeedGateRun,
        // First Touch
        .juggling,
        .wallBallOneTouch,
        .wallBallVolley,
        // Advanced drills (premium-gated)
        .dropVolleys,
        .weakFootFinishing,
        .comboMoves,
        .speedDribbleCorridor,
        // Regular drills
        .toeTaps,
        .soleRolls,
        .wallPasses,
        .foundationTouches,
        .coneWeave,
        .trianglePassing
    ]
}

// MARK: - Authored animations

extension TechniqueAnimation {
    /// Exemplar: Scissor Stage 1 Groundwork drill "The Swing, No Ball" (scis-1-2).
    /// Four keyframes, profile view, loops with a 0.6s pause so captions settle.
    ///
    /// Authoring notes:
    /// - Coord origin top-left. Player faces the camera; bottom of frame is
    ///   toward the viewer. Plant foot sits around y=0.90.
    /// - Imaginary ball rests at (0.50, 0.70) for the first 3 frames — the
    ///   whole point of "no ball" is the ball stays put while the foot sweeps.
    /// - Final frame pushes the ball left to show the escape after the plant.
    static let scissorSwingNoBall = TechniqueAnimation(
        assetId: "diagram_scissor_feet",
        viewAngle: .profile,
        keyframes: [
            TechniqueKeyframe(
                time: 0.0,
                ball: NormPoint(x: 0.50, y: 0.70),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.42, y: 0.92), surface: .none, isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.58, y: 0.92), surface: .none, isActive: false),
                avatarPose: .neutral,
                caption: "Ball in front. Feet shoulder-width.",
                voiceover: "Start with the ball in front. Feet shoulder-width.",
                easeIn: .linear
            ),
            TechniqueKeyframe(
                time: 0.8,
                ball: NormPoint(x: 0.50, y: 0.70),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.42, y: 0.92), surface: .inside,  isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.78, y: 0.55), surface: .outside, isActive: true),
                avatarPose: .leanLeft,
                caption: "Swing your right foot AROUND the ball.",
                voiceover: "Swing your right foot around the ball. Don't touch it.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 1.4,
                ball: NormPoint(x: 0.50, y: 0.70),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.42, y: 0.92), surface: .inside,  isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.62, y: 0.90), surface: .inside,  isActive: true),
                avatarPose: .plantLeft,
                caption: "Plant close. Don't touch the ball.",
                voiceover: "Plant close. Stay low.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 2.4,
                ball: NormPoint(x: 0.30, y: 0.65),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.25, y: 0.85), surface: .inside, isActive: true),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.55, y: 0.80), surface: .none,   isActive: false),
                avatarPose: .explodeLeft,
                caption: "Explode OPPOSITE off the plant.",
                voiceover: "Explode opposite off the plant foot.",
                easeIn: .spring
            )
        ],
        loops: true,
        loopPauseSeconds: 0.6,
        riveAssetName: nil
    )

    // MARK: Regular drills

    /// Toe Taps — alternate feet tapping the top of a stationary ball.
    /// Ball drawn slightly raised so the tapping foot reading "up to the
    /// ball" makes sense in 2D profile.
    static let toeTaps = TechniqueAnimation(
        assetId: "diagram_toe_taps",
        viewAngle: .profile,
        keyframes: [
            TechniqueKeyframe(
                time: 0.0,
                ball: NormPoint(x: 0.50, y: 0.78),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.42, y: 0.92), surface: .none, isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.58, y: 0.92), surface: .none, isActive: false),
                avatarPose: .neutral,
                caption: "Start balanced. Eyes up.",
                voiceover: "Start balanced. Eyes up.",
                easeIn: .linear
            ),
            TechniqueKeyframe(
                time: 0.5,
                ball: NormPoint(x: 0.50, y: 0.78),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.42, y: 0.92), surface: .none, isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.50, y: 0.76), surface: .sole, isActive: true),
                avatarPose: .plantLeft,
                caption: "Right foot taps the top.",
                voiceover: "Right foot, tap the top.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 1.0,
                ball: NormPoint(x: 0.50, y: 0.78),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.50, y: 0.76), surface: .sole, isActive: true),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.58, y: 0.92), surface: .none, isActive: false),
                avatarPose: .plantRight,
                caption: "Switch. Left foot taps.",
                voiceover: "Switch. Left foot.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 1.5,
                ball: NormPoint(x: 0.50, y: 0.78),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.42, y: 0.92), surface: .none, isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.58, y: 0.92), surface: .none, isActive: false),
                avatarPose: .neutral,
                caption: "Small touches. Keep eyes up.",
                voiceover: "Small touches. Keep eyes up.",
                easeIn: .easeInOut
            )
        ],
        loops: true,
        loopPauseSeconds: 0.3,
        riveAssetName: nil
    )

    /// Sole Rolls — one foot's sole rolls the ball left↔right, then switch
    /// feet. Two oscillations per foot, then swap.
    static let soleRolls = TechniqueAnimation(
        assetId: "diagram_sole_rolls",
        viewAngle: .profile,
        keyframes: [
            TechniqueKeyframe(
                time: 0.0,
                ball: NormPoint(x: 0.60, y: 0.80),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.40, y: 0.92), surface: .none, isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.60, y: 0.78), surface: .sole, isActive: true),
                avatarPose: .crouched,
                caption: "Sole on top of the ball.",
                voiceover: "Sole on top of the ball.",
                easeIn: .linear
            ),
            TechniqueKeyframe(
                time: 0.8,
                ball: NormPoint(x: 0.38, y: 0.80),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.30, y: 0.92), surface: .none, isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.38, y: 0.78), surface: .sole, isActive: true),
                avatarPose: .crouched,
                caption: "Roll left under the sole.",
                voiceover: "Roll it left.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 1.6,
                ball: NormPoint(x: 0.60, y: 0.80),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.40, y: 0.92), surface: .none, isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.60, y: 0.78), surface: .sole, isActive: true),
                avatarPose: .crouched,
                caption: "Roll back. Stay low.",
                voiceover: "Roll it back. Stay low.",
                easeIn: .easeInOut
            ),
            TechniqueKeyframe(
                time: 2.4,
                ball: NormPoint(x: 0.40, y: 0.80),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.40, y: 0.78), surface: .sole, isActive: true),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.60, y: 0.92), surface: .none, isActive: false),
                avatarPose: .crouched,
                caption: "Switch to the other foot.",
                voiceover: "Switch feet.",
                easeIn: .easeInOut
            )
        ],
        loops: true,
        loopPauseSeconds: 0.3,
        riveAssetName: nil
    )

    // MARK: Hero demos (Rive-preferred)

    /// Scissor hero demo. The `riveAssetName` resolves to `scissor_hero.riv`
    /// in `Bundle.main` when one is shipped; until then the keyframe
    /// fallback (same content as `scissorStillBall`) renders via
    /// `TechniqueAnimationView`'s Canvas path, so the overview screen
    /// never shows a broken state.
    ///
    /// First real `.riv` file lands in a follow-up PR once authored in the
    /// Rive editor and dropped into `PitchDreams/Resources/`.
    static let scissorHero = TechniqueAnimation(
        assetId: "demo_scissor_hero",
        viewAngle: .profile,
        keyframes: scissorStillBall.keyframes,
        loops: true,
        loopPauseSeconds: 0.5,
        riveAssetName: "scissor_hero"
    )

    // MARK: Scissor — Stage 1 (groundwork)

    /// Scissor Breakdown — slow, analytical replay framing (as if pausing
    /// pro footage). Same motion as scissorSwingNoBall but stretched out
    /// with observation-style captions ("notice the lean", "see the
    /// plant") to match the "Watch the Masters" drill type.
    static let scissorBreakdown = TechniqueAnimation(
        assetId: "diagram_scissor_breakdown",
        viewAngle: .profile,
        keyframes: [
            TechniqueKeyframe(
                time: 0.0,
                ball: NormPoint(x: 0.50, y: 0.78),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.42, y: 0.92), surface: .none, isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.58, y: 0.92), surface: .none, isActive: false),
                avatarPose: .neutral,
                caption: "Watch the whole body, not just the foot.",
                voiceover: "Watch the whole body, not just the foot.",
                easeIn: .linear
            ),
            TechniqueKeyframe(
                time: 1.0,
                ball: NormPoint(x: 0.50, y: 0.78),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.42, y: 0.92), surface: .none,    isActive: true),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.78, y: 0.60), surface: .outside, isActive: true),
                avatarPose: .leanLeft,
                caption: "Right foot sweeps OUTSIDE the ball.",
                voiceover: "See how the right foot sweeps outside the ball.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 2.0,
                ball: NormPoint(x: 0.50, y: 0.78),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.42, y: 0.92), surface: .inside, isActive: true),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.62, y: 0.90), surface: .none,   isActive: false),
                avatarPose: .plantLeft,
                caption: "Plant close — shoulders lean with the fake.",
                voiceover: "Plant close. Shoulders lean with the fake.",
                easeIn: .easeInOut
            ),
            TechniqueKeyframe(
                time: 3.0,
                ball: NormPoint(x: 0.50, y: 0.78),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.28, y: 0.86), surface: .inside, isActive: true),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.55, y: 0.82), surface: .none,   isActive: false),
                avatarPose: .explodeLeft,
                caption: "Explosion OPPOSITE — that's the escape.",
                voiceover: "Explosion opposite. That is the escape.",
                easeIn: .easeInOut
            )
        ],
        loops: true,
        loopPauseSeconds: 0.8,
        riveAssetName: nil
    )

    // MARK: Scissor — Stage 2 (technique, with ball)

    /// Still Ball Scissor — the canonical move. Ball stationary, right
    /// foot sweeps outside, plant close, LEFT foot pushes the ball with
    /// inside. The "escape push with the other foot" is the missing piece
    /// most kids skip, so it gets its own keyframe and voiceover.
    static let scissorStillBall = TechniqueAnimation(
        assetId: "diagram_scissor_still",
        viewAngle: .profile,
        keyframes: [
            TechniqueKeyframe(
                time: 0.0,
                ball: NormPoint(x: 0.50, y: 0.78),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.42, y: 0.92), surface: .none, isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.58, y: 0.92), surface: .none, isActive: false),
                avatarPose: .neutral,
                caption: "Ball in front. Stay close to it.",
                voiceover: "Ball in front. Stay close.",
                easeIn: .linear
            ),
            TechniqueKeyframe(
                time: 0.7,
                ball: NormPoint(x: 0.50, y: 0.78),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.40, y: 0.92), surface: .none,    isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.78, y: 0.60), surface: .outside, isActive: true),
                avatarPose: .leanLeft,
                caption: "Sweep OUTSIDE — don't touch the ball.",
                voiceover: "Sweep outside. Don't touch the ball.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 1.3,
                ball: NormPoint(x: 0.50, y: 0.78),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.40, y: 0.92), surface: .none,   isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.62, y: 0.90), surface: .inside, isActive: true),
                avatarPose: .plantLeft,
                caption: "Plant right foot close to the ball.",
                voiceover: "Plant close.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 2.0,
                ball: NormPoint(x: 0.22, y: 0.80),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.30, y: 0.84), surface: .inside, isActive: true),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.58, y: 0.88), surface: .none,   isActive: false),
                avatarPose: .explodeLeft,
                caption: "LEFT foot inside — push the ball away.",
                voiceover: "Left foot pushes the ball away.",
                easeIn: .spring
            )
        ],
        loops: true,
        loopPauseSeconds: 0.5,
        riveAssetName: nil
    )

    /// Walking Scissor — walking with ball, scissor every ~3 touches.
    /// Shown as: ball drifts forward → scissor interrupts → direction
    /// change pushes ball sideways → resumes forward.
    static let scissorWalking = TechniqueAnimation(
        assetId: "diagram_scissor_path",
        viewAngle: .profile,
        keyframes: [
            TechniqueKeyframe(
                time: 0.0,
                ball: NormPoint(x: 0.22, y: 0.82),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.18, y: 0.92), surface: .inside, isActive: true),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.28, y: 0.90), surface: .none,   isActive: false),
                avatarPose: .plantRight,
                caption: "Walk — small inside touches.",
                voiceover: "Walk with small inside touches.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 0.8,
                ball: NormPoint(x: 0.45, y: 0.82),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.40, y: 0.92), surface: .none,    isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.70, y: 0.62), surface: .outside, isActive: true),
                avatarPose: .leanLeft,
                caption: "Scissor mid-walk — sweep outside.",
                voiceover: "Scissor mid-walk.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 1.5,
                ball: NormPoint(x: 0.48, y: 0.82),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.40, y: 0.92), surface: .none,   isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.52, y: 0.90), surface: .inside, isActive: true),
                avatarPose: .plantLeft,
                caption: "Plant — ready to change direction.",
                voiceover: "Plant. Change direction.",
                easeIn: .easeInOut
            ),
            TechniqueKeyframe(
                time: 2.2,
                ball: NormPoint(x: 0.28, y: 0.76),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.34, y: 0.82), surface: .inside, isActive: true),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.52, y: 0.88), surface: .none,   isActive: false),
                avatarPose: .explodeLeft,
                caption: "Push 30° off-line — stay connected.",
                voiceover: "Push off-line. Stay connected to the ball.",
                easeIn: .spring
            )
        ],
        loops: true,
        loopPauseSeconds: 0.4,
        riveAssetName: nil
    )

    /// Cone Escape — approach implied cone, scissor right before it,
    /// explode past. Cone position read from the lean direction in the
    /// final keyframe (left of frame = "past the cone on the left").
    static let scissorConeEscape = TechniqueAnimation(
        assetId: "diagram_scissor_cone_escape",
        viewAngle: .profile,
        keyframes: [
            TechniqueKeyframe(
                time: 0.0,
                ball: NormPoint(x: 0.30, y: 0.82),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.26, y: 0.92), surface: .inside, isActive: true),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.34, y: 0.90), surface: .none,   isActive: false),
                avatarPose: .plantRight,
                caption: "Jog toward the cone.",
                voiceover: "Jog toward the cone.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 0.7,
                ball: NormPoint(x: 0.55, y: 0.82),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.48, y: 0.92), surface: .none,    isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.80, y: 0.60), surface: .outside, isActive: true),
                avatarPose: .leanLeft,
                caption: "Scissor RIGHT BEFORE the cone.",
                voiceover: "Scissor right before the cone.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 1.3,
                ball: NormPoint(x: 0.55, y: 0.82),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.48, y: 0.92), surface: .none,   isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.60, y: 0.90), surface: .inside, isActive: true),
                avatarPose: .plantLeft,
                caption: "Plant. Coil for the burst.",
                voiceover: "Plant and coil.",
                easeIn: .easeInOut
            ),
            TechniqueKeyframe(
                time: 2.0,
                ball: NormPoint(x: 0.20, y: 0.74),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.28, y: 0.80), surface: .inside, isActive: true),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.50, y: 0.88), surface: .none,   isActive: false),
                avatarPose: .explodeLeft,
                caption: "BURST past the cone — don't slow down.",
                voiceover: "Burst past. Don't slow down.",
                easeIn: .spring
            )
        ],
        loops: true,
        loopPauseSeconds: 0.5,
        riveAssetName: nil
    )

    // MARK: Scissor — Stage 3 (mastery)

    /// Double Scissor — two scissors in sequence (right foot → left foot)
    /// before the ball is pushed. Faster tempo than single-scissor drills
    /// so the rhythm reads as "one-two" rather than two separate moves.
    static let scissorDouble = TechniqueAnimation(
        assetId: "diagram_scissor_double",
        viewAngle: .profile,
        keyframes: [
            TechniqueKeyframe(
                time: 0.0,
                ball: NormPoint(x: 0.50, y: 0.80),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.42, y: 0.92), surface: .none, isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.58, y: 0.92), surface: .none, isActive: false),
                avatarPose: .crouched,
                caption: "Low stance. Stay balanced.",
                voiceover: "Stay low.",
                easeIn: .linear
            ),
            TechniqueKeyframe(
                time: 0.5,
                ball: NormPoint(x: 0.50, y: 0.80),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.40, y: 0.92), surface: .none,    isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.78, y: 0.62), surface: .outside, isActive: true),
                avatarPose: .leanLeft,
                caption: "Scissor ONE — right foot.",
                voiceover: "One!",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 1.0,
                ball: NormPoint(x: 0.50, y: 0.80),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.22, y: 0.62), surface: .outside, isActive: true),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.58, y: 0.90), surface: .none,    isActive: false),
                avatarPose: .leanRight,
                caption: "Scissor TWO — left foot.",
                voiceover: "Two!",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 1.6,
                ball: NormPoint(x: 0.78, y: 0.76),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.46, y: 0.90), surface: .none,   isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.68, y: 0.82), surface: .inside, isActive: true),
                avatarPose: .explodeRight,
                caption: "NOW push — right foot inside.",
                voiceover: "Now push!",
                easeIn: .spring
            )
        ],
        loops: true,
        loopPauseSeconds: 0.4,
        riveAssetName: nil
    )

    /// Speed Cone Corridor — scissor past cone 1, burst, scissor past
    /// cone 2. Fastest Scissor animation — tempo reads as "scissor-burst,
    /// scissor-burst" to match the 10-runs-in-90s drill target.
    static let scissorSpeedConeCorridor = TechniqueAnimation(
        assetId: "diagram_scissor_cone_path",
        viewAngle: .profile,
        keyframes: [
            TechniqueKeyframe(
                time: 0.0,
                ball: NormPoint(x: 0.22, y: 0.82),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.18, y: 0.92), surface: .none,    isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.70, y: 0.62), surface: .outside, isActive: true),
                avatarPose: .leanLeft,
                caption: "Scissor cone 1.",
                voiceover: "Cone one.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 0.5,
                ball: NormPoint(x: 0.38, y: 0.76),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.32, y: 0.84), surface: .inside, isActive: true),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.48, y: 0.90), surface: .none,   isActive: false),
                avatarPose: .explodeLeft,
                caption: "Burst past.",
                voiceover: "Burst.",
                easeIn: .spring
            ),
            TechniqueKeyframe(
                time: 1.0,
                ball: NormPoint(x: 0.60, y: 0.82),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.20, y: 0.62), surface: .outside, isActive: true),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.58, y: 0.90), surface: .none,    isActive: false),
                avatarPose: .leanRight,
                caption: "Scissor cone 2 — alternate feet.",
                voiceover: "Cone two.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 1.5,
                ball: NormPoint(x: 0.80, y: 0.74),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.52, y: 0.88), surface: .none,   isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.68, y: 0.82), surface: .inside, isActive: true),
                avatarPose: .explodeRight,
                caption: "Clean beats fast — but both is the goal.",
                voiceover: "Clean beats fast.",
                easeIn: .spring
            )
        ],
        loops: true,
        loopPauseSeconds: 0.3,
        riveAssetName: nil
    )

    // MARK: Body Feint — Stage 1 (groundwork)

    /// Body Feint Breakdown — slow analytical replay framing. Same basic
    /// lean-hold-explode pattern as bodyFeintMirror but stretched, with
    /// observation-style captions for the "watch Messi" drill.
    ///
    /// Distinctive Body Feint visual contract: the ball stays stationary
    /// through the fake keyframes — feet DON'T move around it. Only on the
    /// escape keyframe does anything touch the ball.
    static let bodyFeintBreakdown = TechniqueAnimation(
        assetId: "diagram_bodyfeint_breakdown",
        viewAngle: .profile,
        keyframes: [
            TechniqueKeyframe(
                time: 0.0,
                ball: NormPoint(x: 0.50, y: 0.80),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.42, y: 0.92), surface: .none, isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.58, y: 0.92), surface: .none, isActive: false),
                avatarPose: .neutral,
                caption: "Watch the shoulders and hips — no ball touch.",
                voiceover: "Watch the shoulders and hips. No ball touch.",
                easeIn: .linear
            ),
            TechniqueKeyframe(
                time: 1.2,
                ball: NormPoint(x: 0.50, y: 0.80),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.42, y: 0.92), surface: .none, isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.58, y: 0.92), surface: .none, isActive: false),
                avatarPose: .leanRight,
                caption: "Drop right shoulder — hips lean right.",
                voiceover: "Drop the right shoulder. Hips lean right.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 2.2,
                ball: NormPoint(x: 0.50, y: 0.80),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.42, y: 0.92), surface: .none, isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.58, y: 0.92), surface: .none, isActive: false),
                avatarPose: .leanRight,
                caption: "Hold the lie — defender commits.",
                voiceover: "Hold the lie. Defender commits.",
                easeIn: .easeInOut
            ),
            TechniqueKeyframe(
                time: 3.0,
                ball: NormPoint(x: 0.26, y: 0.78),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.30, y: 0.84), surface: .inside, isActive: true),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.54, y: 0.88), surface: .none,   isActive: false),
                avatarPose: .explodeLeft,
                caption: "Ball goes LEFT — the fake is paid off.",
                voiceover: "Ball goes left. The fake is paid off.",
                easeIn: .spring
            )
        ],
        loops: true,
        loopPauseSeconds: 0.8,
        riveAssetName: nil
    )

    /// Mirror Practice — no ball. Alternates lean-right-then-explode-left
    /// with lean-left-then-explode-right so the kid sees both directions.
    static let bodyFeintMirror = TechniqueAnimation(
        assetId: "diagram_bodyfeint_bodypos",
        viewAngle: .profile,
        keyframes: [
            TechniqueKeyframe(
                time: 0.0,
                ball: NormPoint(x: 0.50, y: 0.80),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.42, y: 0.92), surface: .none, isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.58, y: 0.92), surface: .none, isActive: false),
                avatarPose: .neutral,
                caption: "Mirror practice — no ball.",
                voiceover: "No ball. Just the body.",
                easeIn: .linear
            ),
            TechniqueKeyframe(
                time: 0.6,
                ball: NormPoint(x: 0.50, y: 0.80),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.42, y: 0.92), surface: .none, isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.58, y: 0.92), surface: .none, isActive: false),
                avatarPose: .leanRight,
                caption: "BIG lean right — shoulders and hips.",
                voiceover: "Big lean right.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 1.1,
                ball: NormPoint(x: 0.50, y: 0.80),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.42, y: 0.92), surface: .none, isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.58, y: 0.92), surface: .none, isActive: false),
                avatarPose: .explodeLeft,
                caption: "Explode LEFT off the plant.",
                voiceover: "Explode left.",
                easeIn: .spring
            ),
            TechniqueKeyframe(
                time: 1.6,
                ball: NormPoint(x: 0.50, y: 0.80),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.42, y: 0.92), surface: .none, isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.58, y: 0.92), surface: .none, isActive: false),
                avatarPose: .leanLeft,
                caption: "Now the other side — lean LEFT.",
                voiceover: "Now the other side.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 2.1,
                ball: NormPoint(x: 0.50, y: 0.80),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.42, y: 0.92), surface: .none, isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.58, y: 0.92), surface: .none, isActive: false),
                avatarPose: .explodeRight,
                caption: "Explode RIGHT. Alternate each rep.",
                voiceover: "Explode right.",
                easeIn: .spring
            )
        ],
        loops: true,
        loopPauseSeconds: 0.4,
        riveAssetName: nil
    )

    // MARK: Body Feint — Stage 2 (technique, with ball)

    /// Stationary Feint + Push — the canonical move with a ball. Lean
    /// sells the fake without touching the ball, then the opposite foot
    /// pushes the ball the OTHER way.
    static let bodyFeintStillBall = TechniqueAnimation(
        assetId: "diagram_bodyfeint_still",
        viewAngle: .profile,
        keyframes: [
            TechniqueKeyframe(
                time: 0.0,
                ball: NormPoint(x: 0.50, y: 0.80),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.42, y: 0.92), surface: .none, isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.58, y: 0.92), surface: .none, isActive: false),
                avatarPose: .neutral,
                caption: "Ball stays still throughout the fake.",
                voiceover: "Ball stays still through the fake.",
                easeIn: .linear
            ),
            TechniqueKeyframe(
                time: 0.7,
                ball: NormPoint(x: 0.50, y: 0.80),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.42, y: 0.92), surface: .none, isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.58, y: 0.92), surface: .none, isActive: false),
                avatarPose: .leanRight,
                caption: "Lean right — NO ball touch.",
                voiceover: "Lean right. No ball touch.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 1.3,
                ball: NormPoint(x: 0.50, y: 0.80),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.42, y: 0.92), surface: .none, isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.58, y: 0.92), surface: .none, isActive: false),
                avatarPose: .leanRight,
                caption: "Hold the lean — sell the lie.",
                voiceover: "Sell the lie.",
                easeIn: .easeInOut
            ),
            TechniqueKeyframe(
                time: 2.2,
                ball: NormPoint(x: 0.22, y: 0.78),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.28, y: 0.84), surface: .inside, isActive: true),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.54, y: 0.88), surface: .none,   isActive: false),
                avatarPose: .explodeLeft,
                caption: "Push LEFT with inside-left — sharp.",
                voiceover: "Push left with the inside of the left foot.",
                easeIn: .spring
            )
        ],
        loops: true,
        loopPauseSeconds: 0.5,
        riveAssetName: nil
    )

    /// Walking Feint + Cut — walking forward with ball, every few touches
    /// plant → fake with body → cut 45° opposite with outside of foot.
    /// Ball drifts forward during walking keyframes, then sharply left
    /// on the cut.
    static let bodyFeintWalking = TechniqueAnimation(
        assetId: "diagram_bodyfeint_path",
        viewAngle: .profile,
        keyframes: [
            TechniqueKeyframe(
                time: 0.0,
                ball: NormPoint(x: 0.22, y: 0.82),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.18, y: 0.92), surface: .inside, isActive: true),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.28, y: 0.90), surface: .none,   isActive: false),
                avatarPose: .plantRight,
                caption: "Walking touches — eyes forward.",
                voiceover: "Walking. Eyes forward.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 0.8,
                ball: NormPoint(x: 0.50, y: 0.82),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.44, y: 0.92), surface: .none,   isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.58, y: 0.90), surface: .inside, isActive: true),
                avatarPose: .plantLeft,
                caption: "Plant — prepare the fake.",
                voiceover: "Plant and prepare.",
                easeIn: .easeInOut
            ),
            TechniqueKeyframe(
                time: 1.5,
                ball: NormPoint(x: 0.52, y: 0.82),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.44, y: 0.92), surface: .none, isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.58, y: 0.90), surface: .none, isActive: false),
                avatarPose: .leanRight,
                caption: "Fake RIGHT — ball doesn't move.",
                voiceover: "Fake right. Ball doesn't move.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 2.3,
                ball: NormPoint(x: 0.22, y: 0.72),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.32, y: 0.82), surface: .outside, isActive: true),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.54, y: 0.88), surface: .none,    isActive: false),
                avatarPose: .explodeLeft,
                caption: "Cut 45° with outside-left — sharp angle.",
                voiceover: "Cut sharp with the outside of the left foot.",
                easeIn: .spring
            )
        ],
        loops: true,
        loopPauseSeconds: 0.4,
        riveAssetName: nil
    )

    /// Cone Body Feint — approach a cone, fake LATE (right before the
    /// cone), cut past on the opposite side. Late fake is the key teaching
    /// beat — defenders adjust to early fakes.
    static let bodyFeintConeEscape = TechniqueAnimation(
        assetId: "diagram_bodyfeint_cone",
        viewAngle: .profile,
        keyframes: [
            TechniqueKeyframe(
                time: 0.0,
                ball: NormPoint(x: 0.30, y: 0.82),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.26, y: 0.92), surface: .inside, isActive: true),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.34, y: 0.90), surface: .none,   isActive: false),
                avatarPose: .plantRight,
                caption: "Jog toward the cone — ball close.",
                voiceover: "Jog. Ball close.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 0.7,
                ball: NormPoint(x: 0.58, y: 0.82),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.50, y: 0.92), surface: .none, isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.62, y: 0.90), surface: .none, isActive: false),
                avatarPose: .leanRight,
                caption: "LATE fake — right before the cone.",
                voiceover: "Late fake. Right before the cone.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 1.3,
                ball: NormPoint(x: 0.58, y: 0.82),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.50, y: 0.92), surface: .none, isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.62, y: 0.90), surface: .none, isActive: false),
                avatarPose: .leanRight,
                caption: "Lean deep — don't stand tall.",
                voiceover: "Lean deep.",
                easeIn: .easeInOut
            ),
            TechniqueKeyframe(
                time: 2.2,
                ball: NormPoint(x: 0.22, y: 0.72),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.30, y: 0.80), surface: .outside, isActive: true),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.52, y: 0.88), surface: .none,    isActive: false),
                avatarPose: .explodeLeft,
                caption: "Explode past on the OTHER side.",
                voiceover: "Explode past on the other side.",
                easeIn: .spring
            )
        ],
        loops: true,
        loopPauseSeconds: 0.5,
        riveAssetName: nil
    )

    // MARK: La Croqueta — Stage 1 (groundwork)

    /// La Croqueta Breakdown — slow analytical "watch Iniesta" replay.
    /// Teaches the three core mechanics: feet close, ball low, one-motion
    /// inside-inside transfer that happens in a single defender stride.
    ///
    /// Distinctive Croqueta visual contract: ball y stays at ≈0.86
    /// (literally "on the ground") through the transfer, moves only ~15%
    /// of frame width between the two feet, and never leaves the
    /// inside-foot-to-inside-foot track.
    static let croquetaBreakdown = TechniqueAnimation(
        assetId: "diagram_croqueta_breakdown",
        viewAngle: .profile,
        keyframes: [
            TechniqueKeyframe(
                time: 0.0,
                ball: NormPoint(x: 0.56, y: 0.86),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.44, y: 0.90), surface: .none,   isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.58, y: 0.88), surface: .inside, isActive: true),
                avatarPose: .crouched,
                caption: "Ball at inside of right — feet close.",
                voiceover: "Ball at the inside of the right foot. Feet close.",
                easeIn: .linear
            ),
            TechniqueKeyframe(
                time: 1.0,
                ball: NormPoint(x: 0.50, y: 0.86),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.44, y: 0.90), surface: .none,    isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.58, y: 0.88), surface: .inside,  isActive: true),
                avatarPose: .crouched,
                caption: "Push with the inside — stay LOW.",
                voiceover: "Push with the inside. Stay low.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 2.0,
                ball: NormPoint(x: 0.44, y: 0.86),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.42, y: 0.88), surface: .inside, isActive: true),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.58, y: 0.90), surface: .none,   isActive: false),
                avatarPose: .crouched,
                caption: "Inside of left catches it — same motion.",
                voiceover: "Inside of the left catches it.",
                easeIn: .easeInOut
            ),
            TechniqueKeyframe(
                time: 2.8,
                ball: NormPoint(x: 0.28, y: 0.84),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.36, y: 0.88), surface: .inside, isActive: true),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.58, y: 0.90), surface: .none,   isActive: false),
                avatarPose: .explodeLeft,
                caption: "Happens in ONE defender stride.",
                voiceover: "Happens in one defender stride.",
                easeIn: .easeOut
            )
        ],
        loops: true,
        loopPauseSeconds: 0.8,
        riveAssetName: nil
    )

    /// Inside-Inside Taps — no ball. Mirrors the rhythm of the actual
    /// move. Feet stay close and the "active" highlight bounces between
    /// them in quick one-two pattern.
    static let croquetaInsideTaps = TechniqueAnimation(
        assetId: "diagram_croqueta_feet",
        viewAngle: .profile,
        keyframes: [
            TechniqueKeyframe(
                time: 0.0,
                ball: NormPoint(x: 0.50, y: 0.95),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.44, y: 0.90), surface: .none, isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.56, y: 0.90), surface: .none, isActive: false),
                avatarPose: .crouched,
                caption: "No ball — just the rhythm.",
                voiceover: "No ball. Just the rhythm.",
                easeIn: .linear
            ),
            TechniqueKeyframe(
                time: 0.35,
                ball: NormPoint(x: 0.50, y: 0.95),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.44, y: 0.90), surface: .none,   isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.52, y: 0.88), surface: .inside, isActive: true),
                avatarPose: .crouched,
                caption: "Right inside tap.",
                voiceover: "Right.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 0.7,
                ball: NormPoint(x: 0.50, y: 0.95),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.48, y: 0.88), surface: .inside, isActive: true),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.56, y: 0.90), surface: .none,   isActive: false),
                avatarPose: .crouched,
                caption: "Left inside tap.",
                voiceover: "Left.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 1.05,
                ball: NormPoint(x: 0.50, y: 0.95),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.44, y: 0.90), surface: .none,   isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.52, y: 0.88), surface: .inside, isActive: true),
                avatarPose: .crouched,
                caption: "Keep the rhythm — close, quick.",
                voiceover: "Close. Quick.",
                easeIn: .easeOut
            )
        ],
        loops: true,
        loopPauseSeconds: 0.2,
        riveAssetName: nil
    )

    // MARK: La Croqueta — Stage 2 (technique, with ball)

    /// Still Ball Push — canonical. Ball starts between feet, transfers
    /// right→left via inside surfaces, then a reset pause before looping.
    /// 30cm transfer distance is encoded as a ~12% horizontal ball move.
    static let croquetaStillBall = TechniqueAnimation(
        assetId: "diagram_croqueta_still",
        viewAngle: .profile,
        keyframes: [
            TechniqueKeyframe(
                time: 0.0,
                ball: NormPoint(x: 0.56, y: 0.86),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.44, y: 0.90), surface: .none,   isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.58, y: 0.88), surface: .inside, isActive: true),
                avatarPose: .crouched,
                caption: "Ball at inside of right foot.",
                voiceover: "Ball at inside of right.",
                easeIn: .linear
            ),
            TechniqueKeyframe(
                time: 0.5,
                ball: NormPoint(x: 0.50, y: 0.86),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.44, y: 0.90), surface: .none,   isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.56, y: 0.88), surface: .inside, isActive: true),
                avatarPose: .crouched,
                caption: "Firm push — 30cm, not a kick.",
                voiceover: "Firm push. Thirty centimeters.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 1.0,
                ball: NormPoint(x: 0.44, y: 0.86),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.42, y: 0.88), surface: .inside, isActive: true),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.58, y: 0.90), surface: .none,   isActive: false),
                avatarPose: .crouched,
                caption: "Inside of left stops it — LOW.",
                voiceover: "Inside of left stops it.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 2.0,
                ball: NormPoint(x: 0.56, y: 0.86),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.44, y: 0.90), surface: .none,   isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.58, y: 0.88), surface: .inside, isActive: true),
                avatarPose: .crouched,
                caption: "Reset. Now do it the other way.",
                voiceover: "Reset. Other direction next.",
                easeIn: .easeInOut
            )
        ],
        loops: true,
        loopPauseSeconds: 0.3,
        riveAssetName: nil
    )

    /// Linear Croqueta — jogging forward, croqueta happens mid-stride
    /// without breaking rhythm. Ball drifts forward during jog keyframes,
    /// transfers horizontally on the croqueta keyframe, keeps moving
    /// forward after.
    static let croquetaLinear = TechniqueAnimation(
        assetId: "diagram_croqueta_path",
        viewAngle: .profile,
        keyframes: [
            TechniqueKeyframe(
                time: 0.0,
                ball: NormPoint(x: 0.22, y: 0.86),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.18, y: 0.90), surface: .none,   isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.26, y: 0.88), surface: .inside, isActive: true),
                avatarPose: .plantLeft,
                caption: "Jogging — right-inside touches.",
                voiceover: "Jogging. Right inside touches.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 0.7,
                ball: NormPoint(x: 0.48, y: 0.86),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.44, y: 0.90), surface: .none,   isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.52, y: 0.88), surface: .inside, isActive: true),
                avatarPose: .crouched,
                caption: "Mid-stride — push inside.",
                voiceover: "Mid-stride. Push inside.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 1.2,
                ball: NormPoint(x: 0.42, y: 0.86),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.40, y: 0.88), surface: .inside, isActive: true),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.54, y: 0.90), surface: .none,   isActive: false),
                avatarPose: .crouched,
                caption: "Left inside catches — stride unbroken.",
                voiceover: "Left inside catches. Stride unbroken.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 2.0,
                ball: NormPoint(x: 0.70, y: 0.84),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.54, y: 0.88), surface: .inside, isActive: true),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.66, y: 0.90), surface: .none,   isActive: false),
                avatarPose: .explodeRight,
                caption: "Keep running — the move was invisible.",
                voiceover: "Keep running. The move was invisible.",
                easeIn: .spring
            )
        ],
        loops: true,
        loopPauseSeconds: 0.4,
        riveAssetName: nil
    )

    /// Cone Gate — approach a 1m cone gate, croqueta slips the ball
    /// through, player bursts past. Ball passes through the implied gate
    /// on the transfer keyframe.
    static let croquetaConeGate = TechniqueAnimation(
        assetId: "diagram_croqueta_gate",
        viewAngle: .profile,
        keyframes: [
            TechniqueKeyframe(
                time: 0.0,
                ball: NormPoint(x: 0.28, y: 0.86),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.24, y: 0.90), surface: .none,   isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.32, y: 0.88), surface: .inside, isActive: true),
                avatarPose: .plantLeft,
                caption: "Approach the gate at pace.",
                voiceover: "Approach the gate.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 0.6,
                ball: NormPoint(x: 0.52, y: 0.86),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.46, y: 0.88), surface: .inside, isActive: true),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.56, y: 0.90), surface: .none,   isActive: false),
                avatarPose: .crouched,
                caption: "Croqueta through the gate — tight.",
                voiceover: "Croqueta through the gate.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 1.2,
                ball: NormPoint(x: 0.60, y: 0.86),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.54, y: 0.90), surface: .none,   isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.62, y: 0.88), surface: .inside, isActive: true),
                avatarPose: .crouched,
                caption: "Ball on the other side — keep low.",
                voiceover: "Ball on the other side.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 2.0,
                ball: NormPoint(x: 0.82, y: 0.82),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.66, y: 0.88), surface: .none,   isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.74, y: 0.86), surface: .inside, isActive: true),
                avatarPose: .explodeRight,
                caption: "Burst past — don't slow down.",
                voiceover: "Burst past.",
                easeIn: .spring
            )
        ],
        loops: true,
        loopPauseSeconds: 0.4,
        riveAssetName: nil
    )

    // MARK: La Croqueta — Stage 3 (mastery)

    /// Speed Gate Run — fastest Croqueta. Scissor-style short loop where
    /// two rapid croquetas chain into a single run through imagined gates.
    /// Tempo chosen so viewers feel "gate-gate-gate" pacing.
    static let croquetaSpeedGateRun = TechniqueAnimation(
        assetId: "diagram_croqueta_speed_path",
        viewAngle: .profile,
        keyframes: [
            TechniqueKeyframe(
                time: 0.0,
                ball: NormPoint(x: 0.22, y: 0.86),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.18, y: 0.90), surface: .none,   isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.26, y: 0.88), surface: .inside, isActive: true),
                avatarPose: .crouched,
                caption: "Gate 1 — croqueta through.",
                voiceover: "Gate one.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 0.4,
                ball: NormPoint(x: 0.38, y: 0.86),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.34, y: 0.88), surface: .inside, isActive: true),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.44, y: 0.90), surface: .none,   isActive: false),
                avatarPose: .crouched,
                caption: "Through 1. Rhythm.",
                voiceover: "Through.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 0.9,
                ball: NormPoint(x: 0.62, y: 0.86),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.56, y: 0.90), surface: .none,   isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.64, y: 0.88), surface: .inside, isActive: true),
                avatarPose: .crouched,
                caption: "Gate 2 — clean beats fast.",
                voiceover: "Gate two. Clean beats fast.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 1.4,
                ball: NormPoint(x: 0.82, y: 0.84),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.64, y: 0.88), surface: .inside, isActive: true),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.74, y: 0.90), surface: .none,   isActive: false),
                avatarPose: .explodeRight,
                caption: "Through 2 — keep rhythm to 3.",
                voiceover: "Keep rhythm.",
                easeIn: .spring
            )
        ],
        loops: true,
        loopPauseSeconds: 0.3,
        riveAssetName: nil
    )

    // MARK: First Touch

    /// Juggling — ball floats near center, alternating feet tap it up.
    /// Ball y oscillates between ~0.55 (rising) and ~0.75 (at foot for
    /// contact) so the viewer reads vertical rhythm, not foot movement.
    static let juggling = TechniqueAnimation(
        assetId: "diagram_juggling",
        viewAngle: .profile,
        keyframes: [
            TechniqueKeyframe(
                time: 0.0,
                ball: NormPoint(x: 0.50, y: 0.55),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.42, y: 0.92), surface: .none, isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.58, y: 0.92), surface: .none, isActive: false),
                avatarPose: .neutral,
                caption: "Eyes on the ball — light touches.",
                voiceover: "Eyes on the ball. Light touches.",
                easeIn: .easeInOut
            ),
            TechniqueKeyframe(
                time: 0.4,
                ball: NormPoint(x: 0.50, y: 0.75),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.42, y: 0.92), surface: .none,  isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.50, y: 0.75), surface: .laces, isActive: true),
                avatarPose: .plantLeft,
                caption: "Right foot — laces up.",
                voiceover: "Right.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 0.8,
                ball: NormPoint(x: 0.50, y: 0.55),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.42, y: 0.92), surface: .none, isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.58, y: 0.92), surface: .none, isActive: false),
                avatarPose: .neutral,
                caption: "Ball rises — reset.",
                voiceover: "Up.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 1.2,
                ball: NormPoint(x: 0.50, y: 0.75),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.50, y: 0.75), surface: .laces, isActive: true),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.58, y: 0.92), surface: .none,  isActive: false),
                avatarPose: .plantRight,
                caption: "Left foot — laces up.",
                voiceover: "Left.",
                easeIn: .easeOut
            )
        ],
        loops: true,
        loopPauseSeconds: 0.2,
        riveAssetName: nil
    )

    /// Wall Ball One Touch — no control step: ball arrives, foot strikes
    /// back in one motion. Shorter loop + faster tempo than the basic
    /// Wall Passes animation so the "one touch" rule reads through pacing.
    static let wallBallOneTouch = TechniqueAnimation(
        assetId: "diagram_wall_ball_oneTouch",
        viewAngle: .profile,
        keyframes: [
            TechniqueKeyframe(
                time: 0.0,
                ball: NormPoint(x: 0.80, y: 0.82),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.28, y: 0.92), surface: .inside, isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.40, y: 0.90), surface: .none,   isActive: false),
                avatarPose: .crouched,
                caption: "Ball returning — no control step.",
                voiceover: "Ball returning.",
                easeIn: .linear
            ),
            TechniqueKeyframe(
                time: 0.5,
                ball: NormPoint(x: 0.42, y: 0.82),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.28, y: 0.92), surface: .inside, isActive: true),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.40, y: 0.90), surface: .none,   isActive: false),
                avatarPose: .leanRight,
                caption: "Meet and strike in one motion.",
                voiceover: "Meet and strike.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 1.1,
                ball: NormPoint(x: 0.82, y: 0.74),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.40, y: 0.84), surface: .inside, isActive: true),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.36, y: 0.90), surface: .none,   isActive: false),
                avatarPose: .leanRight,
                caption: "Back to the wall — firm pace.",
                voiceover: "Back to the wall.",
                easeIn: .spring
            )
        ],
        loops: true,
        loopPauseSeconds: 0.3,
        riveAssetName: nil
    )

    /// Wall Ball Volley — ball falls from above (dropped), foot meets it
    /// with laces mid-height, rises toward wall. Teaches ankle-lock and
    /// timing the contact point.
    static let wallBallVolley = TechniqueAnimation(
        assetId: "diagram_wall_ball_volley",
        viewAngle: .profile,
        keyframes: [
            TechniqueKeyframe(
                time: 0.0,
                ball: NormPoint(x: 0.36, y: 0.20),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.32, y: 0.92), surface: .none, isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.44, y: 0.92), surface: .none, isActive: false),
                avatarPose: .neutral,
                caption: "Drop the ball from your hands.",
                voiceover: "Drop the ball.",
                easeIn: .linear
            ),
            TechniqueKeyframe(
                time: 0.6,
                ball: NormPoint(x: 0.36, y: 0.68),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.32, y: 0.92), surface: .none, isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.44, y: 0.92), surface: .none, isActive: false),
                avatarPose: .crouched,
                caption: "Watch the ball onto your foot.",
                voiceover: "Watch the ball.",
                easeIn: .easeIn
            ),
            TechniqueKeyframe(
                time: 0.9,
                ball: NormPoint(x: 0.42, y: 0.74),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.32, y: 0.92), surface: .none,  isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.44, y: 0.74), surface: .laces, isActive: true),
                avatarPose: .plantLeft,
                caption: "Ankle LOCKED — laces contact.",
                voiceover: "Ankle locked. Laces.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 1.5,
                ball: NormPoint(x: 0.86, y: 0.40),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.32, y: 0.92), surface: .none,  isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.52, y: 0.80), surface: .laces, isActive: true),
                avatarPose: .leanRight,
                caption: "Follow through — eyes at the target.",
                voiceover: "Follow through.",
                easeIn: .spring
            )
        ],
        loops: true,
        loopPauseSeconds: 0.5,
        riveAssetName: nil
    )

    // MARK: Advanced drills (premium-gated)

    /// Drop Volleys — drop ball from hands, volley at goal. Shares the
    /// fall→contact→follow-through rhythm with the wall-ball volley but
    /// scaled for a goal-side setup (more lateral distance on the strike).
    static let dropVolleys = TechniqueAnimation(
        assetId: "diagram_shoot_volleys",
        viewAngle: .profile,
        keyframes: [
            TechniqueKeyframe(
                time: 0.0,
                ball: NormPoint(x: 0.36, y: 0.20),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.32, y: 0.92), surface: .none, isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.44, y: 0.92), surface: .none, isActive: false),
                avatarPose: .neutral,
                caption: "Drop — don't toss — from your hands.",
                voiceover: "Drop. Don't toss.",
                easeIn: .linear
            ),
            TechniqueKeyframe(
                time: 0.7,
                ball: NormPoint(x: 0.38, y: 0.70),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.30, y: 0.92), surface: .none, isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.46, y: 0.90), surface: .none, isActive: false),
                avatarPose: .crouched,
                caption: "Watch the ball onto the foot.",
                voiceover: "Watch the ball onto the foot.",
                easeIn: .easeIn
            ),
            TechniqueKeyframe(
                time: 1.0,
                ball: NormPoint(x: 0.46, y: 0.76),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.30, y: 0.92), surface: .none,  isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.50, y: 0.76), surface: .laces, isActive: true),
                avatarPose: .plantLeft,
                caption: "LOCK the ankle — clean laces contact.",
                voiceover: "Lock the ankle.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 1.6,
                ball: NormPoint(x: 0.92, y: 0.50),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.32, y: 0.92), surface: .none,  isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.60, y: 0.78), surface: .laces, isActive: true),
                avatarPose: .explodeRight,
                caption: "Follow through — strike at goal.",
                voiceover: "Follow through.",
                easeIn: .spring
            )
        ],
        loops: true,
        loopPauseSeconds: 0.6,
        riveAssetName: nil
    )

    /// Weak Foot Finishing — placed finish from the edge of the box.
    /// Ball stationary at planted-foot side; weak foot swings and strikes
    /// with inside-placement (not power). Teaches the discipline of
    /// accuracy over force on the non-dominant side.
    static let weakFootFinishing = TechniqueAnimation(
        assetId: "diagram_shoot_weak_foot",
        viewAngle: .profile,
        keyframes: [
            TechniqueKeyframe(
                time: 0.0,
                ball: NormPoint(x: 0.48, y: 0.86),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.32, y: 0.92), surface: .none,  isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.58, y: 0.90), surface: .inside, isActive: false),
                avatarPose: .crouched,
                caption: "Plant foot BESIDE the ball.",
                voiceover: "Plant beside the ball.",
                easeIn: .linear
            ),
            TechniqueKeyframe(
                time: 0.7,
                ball: NormPoint(x: 0.48, y: 0.86),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.24, y: 0.80), surface: .none,   isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.58, y: 0.90), surface: .inside, isActive: false),
                avatarPose: .leanRight,
                caption: "Weak foot draws back — eyes on target.",
                voiceover: "Draw back. Eyes on target.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 1.2,
                ball: NormPoint(x: 0.52, y: 0.86),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.48, y: 0.86), surface: .inside, isActive: true),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.58, y: 0.90), surface: .none,   isActive: false),
                avatarPose: .leanLeft,
                caption: "PLACE with inside — accuracy, not power.",
                voiceover: "Place with the inside.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 1.8,
                ball: NormPoint(x: 0.92, y: 0.76),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.56, y: 0.84), surface: .inside, isActive: true),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.60, y: 0.88), surface: .none,   isActive: false),
                avatarPose: .leanLeft,
                caption: "Follow through across your body.",
                voiceover: "Follow through across the body.",
                easeIn: .easeOut
            )
        ],
        loops: true,
        loopPauseSeconds: 0.6,
        riveAssetName: nil
    )

    /// Combo Moves — chain a scissor into an opposite-direction cut. The
    /// first move must be sold or the second has nothing to break from.
    /// Five keyframes so viewers feel the two moves as a single sequence,
    /// not two separate drills.
    static let comboMoves = TechniqueAnimation(
        assetId: "diagram_drib_1v1_combo",
        viewAngle: .profile,
        keyframes: [
            TechniqueKeyframe(
                time: 0.0,
                ball: NormPoint(x: 0.50, y: 0.82),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.42, y: 0.92), surface: .none, isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.58, y: 0.92), surface: .none, isActive: false),
                avatarPose: .crouched,
                caption: "Two moves, one sequence.",
                voiceover: "Two moves. One sequence.",
                easeIn: .linear
            ),
            TechniqueKeyframe(
                time: 0.6,
                ball: NormPoint(x: 0.50, y: 0.82),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.40, y: 0.92), surface: .none,    isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.78, y: 0.60), surface: .outside, isActive: true),
                avatarPose: .leanLeft,
                caption: "Scissor — commit to the fake.",
                voiceover: "Scissor. Commit.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 1.1,
                ball: NormPoint(x: 0.50, y: 0.82),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.40, y: 0.92), surface: .none,   isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.60, y: 0.90), surface: .inside, isActive: true),
                avatarPose: .plantLeft,
                caption: "Plant — now break the OTHER way.",
                voiceover: "Plant. Break the other way.",
                easeIn: .easeInOut
            ),
            TechniqueKeyframe(
                time: 1.6,
                ball: NormPoint(x: 0.28, y: 0.78),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.34, y: 0.84), surface: .outside, isActive: true),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.56, y: 0.90), surface: .none,    isActive: false),
                avatarPose: .explodeLeft,
                caption: "Cut sharp — outside-left.",
                voiceover: "Cut sharp.",
                easeIn: .spring
            ),
            TechniqueKeyframe(
                time: 2.2,
                ball: NormPoint(x: 0.12, y: 0.72),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.20, y: 0.80), surface: .inside, isActive: true),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.48, y: 0.90), surface: .none,   isActive: false),
                avatarPose: .explodeLeft,
                caption: "Both moves strong — no relaxing.",
                voiceover: "Both moves strong.",
                easeIn: .spring
            )
        ],
        loops: true,
        loopPauseSeconds: 0.5,
        riveAssetName: nil
    )

    /// Speed Dribble Corridor — ball weaves at top speed between implied
    /// parallel cone lines 1.5m apart (encoded as limited y oscillation
    /// on ball between 0.80 and 0.88). Feet alternate quickly; no side
    /// moves — just close touches at pace.
    static let speedDribbleCorridor = TechniqueAnimation(
        assetId: "diagram_drib_speed_corridor",
        viewAngle: .profile,
        keyframes: [
            TechniqueKeyframe(
                time: 0.0,
                ball: NormPoint(x: 0.20, y: 0.84),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.18, y: 0.92), surface: .none,   isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.22, y: 0.84), surface: .inside, isActive: true),
                avatarPose: .explodeRight,
                caption: "Close touches at pace.",
                voiceover: "Close touches at pace.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 0.4,
                ball: NormPoint(x: 0.38, y: 0.88),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.36, y: 0.86), surface: .inside, isActive: true),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.42, y: 0.92), surface: .none,   isActive: false),
                avatarPose: .explodeRight,
                caption: "Stay INSIDE the corridor.",
                voiceover: "Stay inside the corridor.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 0.8,
                ball: NormPoint(x: 0.56, y: 0.80),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.50, y: 0.92), surface: .none,   isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.58, y: 0.82), surface: .inside, isActive: true),
                avatarPose: .explodeRight,
                caption: "Alternate feet each touch.",
                voiceover: "Alternate feet.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 1.2,
                ball: NormPoint(x: 0.78, y: 0.86),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.70, y: 0.86), surface: .inside, isActive: true),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.76, y: 0.92), surface: .none,   isActive: false),
                avatarPose: .explodeRight,
                caption: "Eyes UP when you can.",
                voiceover: "Eyes up when you can.",
                easeIn: .easeOut
            )
        ],
        loops: true,
        loopPauseSeconds: 0.2,
        riveAssetName: nil
    )

    /// Foundation Touches — inside → outside → sole sequence on the right
    /// foot, with a neutral reset hinting at "now the other foot." The
    /// ball drifts slightly with each touch surface to read the motion.
    static let foundationTouches = TechniqueAnimation(
        assetId: "diagram_foundation_touches",
        viewAngle: .profile,
        keyframes: [
            TechniqueKeyframe(
                time: 0.0,
                ball: NormPoint(x: 0.50, y: 0.80),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.40, y: 0.92), surface: .none, isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.60, y: 0.92), surface: .none, isActive: false),
                avatarPose: .crouched,
                caption: "Inside — outside — sole.",
                voiceover: "Inside, outside, sole.",
                easeIn: .linear
            ),
            TechniqueKeyframe(
                time: 0.5,
                ball: NormPoint(x: 0.56, y: 0.80),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.40, y: 0.92), surface: .none,   isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.52, y: 0.82), surface: .inside, isActive: true),
                avatarPose: .plantLeft,
                caption: "Inside of the right foot.",
                voiceover: "Inside.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 1.0,
                ball: NormPoint(x: 0.48, y: 0.80),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.40, y: 0.92), surface: .none,    isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.58, y: 0.82), surface: .outside, isActive: true),
                avatarPose: .plantLeft,
                caption: "Outside of the right foot.",
                voiceover: "Outside.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 1.5,
                ball: NormPoint(x: 0.50, y: 0.80),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.40, y: 0.92), surface: .none, isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.50, y: 0.78), surface: .sole, isActive: true),
                avatarPose: .plantLeft,
                caption: "Sole on top.",
                voiceover: "Sole.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 2.0,
                ball: NormPoint(x: 0.50, y: 0.80),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.40, y: 0.92), surface: .none, isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.60, y: 0.92), surface: .none, isActive: false),
                avatarPose: .crouched,
                caption: "Now switch to the other foot.",
                voiceover: "Now the other foot.",
                easeIn: .easeInOut
            )
        ],
        loops: true,
        loopPauseSeconds: 0.4,
        riveAssetName: nil
    )

    /// Cone Weave — ball zig-zags rightward as feet alternate inside/
    /// outside touches, finishing with a lean-right explode past the last
    /// (off-screen) cone.
    static let coneWeave = TechniqueAnimation(
        assetId: "diagram_cone_weave",
        viewAngle: .profile,
        keyframes: [
            TechniqueKeyframe(
                time: 0.0,
                ball: NormPoint(x: 0.22, y: 0.82),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.32, y: 0.92), surface: .none, isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.24, y: 0.82), surface: .inside, isActive: true),
                avatarPose: .plantLeft,
                caption: "Inside touch — push right.",
                voiceover: "Inside touch. Push right.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 0.7,
                ball: NormPoint(x: 0.42, y: 0.82),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.40, y: 0.82), surface: .outside, isActive: true),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.50, y: 0.92), surface: .none,    isActive: false),
                avatarPose: .plantRight,
                caption: "Outside of the left foot.",
                voiceover: "Outside of the left.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 1.4,
                ball: NormPoint(x: 0.62, y: 0.82),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.52, y: 0.92), surface: .none,   isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.60, y: 0.82), surface: .inside, isActive: true),
                avatarPose: .plantLeft,
                caption: "Back to inside right.",
                voiceover: "Inside right.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 2.1,
                ball: NormPoint(x: 0.82, y: 0.78),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.60, y: 0.88), surface: .none, isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.70, y: 0.80), surface: .laces, isActive: true),
                avatarPose: .explodeRight,
                caption: "Explode past the last cone.",
                voiceover: "Explode past the last cone.",
                easeIn: .spring
            )
        ],
        loops: true,
        loopPauseSeconds: 0.5,
        riveAssetName: nil
    )

    /// Triangle Passing — ball travels between three implied cone
    /// positions. Body opens to the next target before the ball arrives;
    /// each pass uses the inside of the foot.
    static let trianglePassing = TechniqueAnimation(
        assetId: "diagram_triangle_passing",
        viewAngle: .profile,
        keyframes: [
            TechniqueKeyframe(
                time: 0.0,
                ball: NormPoint(x: 0.30, y: 0.84),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.26, y: 0.92), surface: .none,   isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.36, y: 0.90), surface: .inside, isActive: false),
                avatarPose: .plantLeft,
                caption: "Plant beside the ball.",
                voiceover: "Plant beside the ball.",
                easeIn: .linear
            ),
            TechniqueKeyframe(
                time: 0.6,
                ball: NormPoint(x: 0.82, y: 0.74),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.26, y: 0.92), surface: .none,    isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.40, y: 0.82), surface: .inside,  isActive: true),
                avatarPose: .leanRight,
                caption: "Pass to cone 1 — inside of the foot.",
                voiceover: "Pass with the inside of the foot.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 1.2,
                ball: NormPoint(x: 0.52, y: 0.82),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.38, y: 0.92), surface: .none, isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.50, y: 0.90), surface: .none, isActive: false),
                avatarPose: .neutral,
                caption: "Open your body to cone 2.",
                voiceover: "Open your body to the next cone.",
                easeIn: .easeInOut
            ),
            TechniqueKeyframe(
                time: 1.8,
                ball: NormPoint(x: 0.20, y: 0.74),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.60, y: 0.82), surface: .inside, isActive: true),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.56, y: 0.92), surface: .none,   isActive: false),
                avatarPose: .leanLeft,
                caption: "Pass to cone 2. First touch sets the next.",
                voiceover: "Pass to cone two.",
                easeIn: .easeOut
            )
        ],
        loops: true,
        loopPauseSeconds: 0.5,
        riveAssetName: nil
    )

    /// Wall Passes — player on the left, wall implied at frame-right edge.
    /// Ball cycles: plant → strike → return → control. Renders as a
    /// rhythmic loop the kid can match their own reps to.
    static let wallPasses = TechniqueAnimation(
        assetId: "diagram_wall_passes",
        viewAngle: .profile,
        keyframes: [
            TechniqueKeyframe(
                time: 0.0,
                ball: NormPoint(x: 0.32, y: 0.84),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.28, y: 0.92), surface: .inside, isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.40, y: 0.90), surface: .none,   isActive: false),
                avatarPose: .plantRight,
                caption: "Plant beside the ball.",
                voiceover: "Plant foot beside the ball.",
                easeIn: .linear
            ),
            TechniqueKeyframe(
                time: 0.5,
                ball: NormPoint(x: 0.78, y: 0.78),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.40, y: 0.82), surface: .inside, isActive: true),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.36, y: 0.90), surface: .none,   isActive: false),
                avatarPose: .leanRight,
                caption: "Strike with the inside.",
                voiceover: "Strike with the inside of the foot.",
                easeIn: .easeOut
            ),
            TechniqueKeyframe(
                time: 1.1,
                ball: NormPoint(x: 0.55, y: 0.80),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.30, y: 0.92), surface: .none, isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.40, y: 0.90), surface: .none, isActive: false),
                avatarPose: .neutral,
                caption: "Wait for the return.",
                voiceover: "Wait for the return.",
                easeIn: .easeInOut
            ),
            TechniqueKeyframe(
                time: 1.6,
                ball: NormPoint(x: 0.34, y: 0.84),
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.28, y: 0.92), surface: .none,   isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.40, y: 0.84), surface: .inside, isActive: true),
                avatarPose: .plantLeft,
                caption: "Cushion with a soft touch.",
                voiceover: "Cushion with a soft touch.",
                easeIn: .easeOut
            )
        ],
        loops: true,
        loopPauseSeconds: 0.4,
        riveAssetName: nil
    )
}
