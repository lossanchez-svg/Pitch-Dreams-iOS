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
        .scissorSwingNoBall
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
}
