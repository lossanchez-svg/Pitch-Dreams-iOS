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

    static let all: [TechniqueAnimation] = [
        .scissorSwingNoBall,
        .toeTaps,
        .soleRolls,
        .wallPasses
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
