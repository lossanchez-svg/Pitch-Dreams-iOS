import XCTest
@testable import PitchDreams

final class TechniqueAnimationTests: XCTestCase {

    // MARK: - Fixtures

    private func kf(_ t: TimeInterval,
                    ballX: Double,
                    leftX: Double,
                    rightX: Double,
                    pose: AvatarPose = .neutral,
                    caption: String? = nil,
                    voiceover: String? = nil,
                    ease: Easing = .linear) -> TechniqueKeyframe {
        TechniqueKeyframe(
            time: t,
            ball: NormPoint(x: ballX, y: 0.5),
            leftFoot:  FootState(side: .left,  position: NormPoint(x: leftX,  y: 0.9), surface: .none, isActive: false),
            rightFoot: FootState(side: .right, position: NormPoint(x: rightX, y: 0.9), surface: .none, isActive: false),
            avatarPose: pose,
            caption: caption,
            voiceover: voiceover,
            easeIn: ease
        )
    }

    private func anim(keyframes: [TechniqueKeyframe], loops: Bool = false, loopPause: TimeInterval = 0) -> TechniqueAnimation {
        TechniqueAnimation(
            assetId: "test",
            viewAngle: .profile,
            keyframes: keyframes,
            loops: loops,
            loopPauseSeconds: loopPause,
            riveAssetName: nil
        )
    }

    // MARK: - Easing curves

    func testLinearEasingIsIdentityAndClamps() {
        XCTAssertEqual(Easing.linear.apply(0.0), 0.0, accuracy: 1e-9)
        XCTAssertEqual(Easing.linear.apply(0.5), 0.5, accuracy: 1e-9)
        XCTAssertEqual(Easing.linear.apply(1.0), 1.0, accuracy: 1e-9)
        XCTAssertEqual(Easing.linear.apply(-0.4), 0.0, accuracy: 1e-9)
        XCTAssertEqual(Easing.linear.apply(1.8), 1.0, accuracy: 1e-9)
    }

    func testEaseOutAcceleratesEarlyDeceleratesLate() {
        // easeOut: 1 - (1-u)^2. At u=0.5 → 0.75.
        XCTAssertEqual(Easing.easeOut.apply(0.5), 0.75, accuracy: 1e-9)
        XCTAssertEqual(Easing.easeOut.apply(0.0), 0.0, accuracy: 1e-9)
        XCTAssertEqual(Easing.easeOut.apply(1.0), 1.0, accuracy: 1e-9)
    }

    func testEasingEndpointsAllReachZeroAndOne() {
        for easing: Easing in [.linear, .easeIn, .easeOut, .easeInOut, .spring] {
            XCTAssertEqual(easing.apply(0.0), 0.0, accuracy: 1e-9, "\(easing) at 0 should be 0")
            XCTAssertEqual(easing.apply(1.0), 1.0, accuracy: 1e-9, "\(easing) at 1 should be 1")
        }
    }

    // MARK: - NormPoint lerp

    func testNormPointLerpIsLinear() {
        let a = NormPoint(x: 0.0, y: 0.0)
        let b = NormPoint(x: 1.0, y: 1.0)
        let mid = a.lerp(to: b, t: 0.25)
        XCTAssertEqual(mid.x, 0.25, accuracy: 1e-9)
        XCTAssertEqual(mid.y, 0.25, accuracy: 1e-9)
    }

    // MARK: - Single-keyframe edge cases

    func testEmptyAnimationReturnsNeutralFrame() {
        let a = anim(keyframes: [])
        let f = a.frame(at: 1.0)
        XCTAssertEqual(f.ball, .zero)
        XCTAssertEqual(f.avatarKinematics, .neutral)
        XCTAssertNil(f.caption)
    }

    func testSingleKeyframeHoldsForever() {
        let a = anim(keyframes: [kf(0, ballX: 0.3, leftX: 0.4, rightX: 0.6, caption: "stay")])
        let f0 = a.frame(at: 0.0)
        let f99 = a.frame(at: 99.0)
        XCTAssertEqual(f0.ball.x, 0.3, accuracy: 1e-9)
        XCTAssertEqual(f99.ball.x, 0.3, accuracy: 1e-9)
        XCTAssertEqual(f99.caption, "stay")
    }

    // MARK: - Interpolation between two keyframes

    func testLinearInterpolationMidpointBallPosition() {
        let a = anim(keyframes: [
            kf(0.0, ballX: 0.0, leftX: 0.0, rightX: 0.0, ease: .linear),
            kf(2.0, ballX: 1.0, leftX: 1.0, rightX: 1.0, ease: .linear)
        ])
        let mid = a.frame(at: 1.0)
        XCTAssertEqual(mid.ball.x, 0.5, accuracy: 1e-9)
        XCTAssertEqual(mid.leftFoot.position.x, 0.5, accuracy: 1e-9)
        XCTAssertEqual(mid.rightFoot.position.x, 0.5, accuracy: 1e-9)
    }

    func testEaseOutInterpolationAtQuarterMark() {
        // easeOut at u=0.5 = 0.75 — ball should be 75% of the way at the timing midpoint.
        let a = anim(keyframes: [
            kf(0.0, ballX: 0.0, leftX: 0.0, rightX: 0.0, ease: .linear),
            kf(2.0, ballX: 1.0, leftX: 0.0, rightX: 0.0, ease: .easeOut)
        ])
        let midTiming = a.frame(at: 1.0)
        XCTAssertEqual(midTiming.ball.x, 0.75, accuracy: 1e-9)
    }

    func testCategoricalFieldsSnapToPreviousKeyframe() {
        // Caption, foot.surface, and foot.isActive should come from kA during
        // the transition — they're categorical, not interpolated.
        let a = anim(keyframes: [
            TechniqueKeyframe(
                time: 0.0,
                ball: .zero,
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 0.0, y: 0.9), surface: .inside, isActive: true),
                rightFoot: FootState(side: .right, position: NormPoint(x: 0.0, y: 0.9), surface: .none,   isActive: false),
                avatarPose: .neutral,
                caption: "first",
                voiceover: nil,
                easeIn: .linear
            ),
            TechniqueKeyframe(
                time: 2.0,
                ball: .zero,
                leftFoot:  FootState(side: .left,  position: NormPoint(x: 1.0, y: 0.9), surface: .outside, isActive: false),
                rightFoot: FootState(side: .right, position: NormPoint(x: 1.0, y: 0.9), surface: .laces,   isActive: true),
                avatarPose: .explodeLeft,
                caption: "second",
                voiceover: nil,
                easeIn: .linear
            )
        ])
        // Just past the first keyframe — categorical fields must still reflect kA.
        let f = a.frame(at: 1.0)
        XCTAssertEqual(f.caption, "first")
        XCTAssertEqual(f.leftFoot.surface, .inside)
        XCTAssertTrue(f.leftFoot.isActive)
        XCTAssertEqual(f.rightFoot.surface, .none)
        XCTAssertFalse(f.rightFoot.isActive)
        // Foot POSITIONS should interpolate, though.
        XCTAssertEqual(f.leftFoot.position.x, 0.5, accuracy: 1e-9)
    }

    func testKeyframeIndexAdvancesAcrossBoundary() {
        let a = anim(keyframes: [
            kf(0.0, ballX: 0.0, leftX: 0.0, rightX: 0.0),
            kf(1.0, ballX: 1.0, leftX: 1.0, rightX: 1.0),
            kf(2.0, ballX: 0.0, leftX: 0.0, rightX: 0.0)
        ])
        XCTAssertEqual(a.frame(at: 0.5).currentKeyframeIndex, 0)
        XCTAssertEqual(a.frame(at: 1.5).currentKeyframeIndex, 1)
    }

    // MARK: - Looping

    func testLoopingWrapsPastDuration() {
        let a = anim(
            keyframes: [
                kf(0.0, ballX: 0.0, leftX: 0.0, rightX: 0.0, caption: "A"),
                kf(1.0, ballX: 1.0, leftX: 1.0, rightX: 1.0, caption: "B")
            ],
            loops: true,
            loopPause: 0.0
        )
        // t=2.5 with cycle=1.0 → wraps to 0.5 → midpoint.
        let wrapped = a.frame(at: 2.5)
        XCTAssertEqual(wrapped.ball.x, 0.5, accuracy: 1e-9)
        XCTAssertEqual(wrapped.caption, "A")
    }

    func testLoopPauseHoldsOnLastKeyframe() {
        let a = anim(
            keyframes: [
                kf(0.0, ballX: 0.0, leftX: 0.0, rightX: 0.0, caption: "A"),
                kf(1.0, ballX: 1.0, leftX: 1.0, rightX: 1.0, caption: "B")
            ],
            loops: true,
            loopPause: 0.5
        )
        // During the pause window (duration=1.0, pause extends to 1.5),
        // playback holds on the last keyframe.
        let during = a.frame(at: 1.2)
        XCTAssertEqual(during.ball.x, 1.0, accuracy: 1e-9)
        XCTAssertEqual(during.caption, "B")
    }

    // MARK: - Duration

    func testDurationEqualsLastKeyframeTime() {
        let a = anim(keyframes: [
            kf(0.0, ballX: 0.0, leftX: 0.0, rightX: 0.0),
            kf(2.4, ballX: 1.0, leftX: 1.0, rightX: 1.0)
        ])
        XCTAssertEqual(a.duration, 2.4, accuracy: 1e-9)
    }

    // MARK: - Kinematics interpolation

    func testKinematicsTweenBetweenPoses() {
        // Going from neutral (torsoTilt 0) to leanLeft (torsoTilt -0.28).
        let a = anim(keyframes: [
            kf(0.0, ballX: 0.0, leftX: 0.0, rightX: 0.0, pose: .neutral, ease: .linear),
            kf(2.0, ballX: 0.0, leftX: 0.0, rightX: 0.0, pose: .leanLeft, ease: .linear)
        ])
        let mid = a.frame(at: 1.0)
        XCTAssertEqual(mid.avatarKinematics.torsoTilt, -0.14, accuracy: 1e-9)
    }

    // MARK: - Registry lookup

    func testRegistryResolvesScissorSwingNoBall() {
        let found = TechniqueAnimationRegistry.animation(for: "diagram_scissor_feet")
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.keyframes.count, 4)
        XCTAssertTrue(found?.loops == true)
    }

    func testRegistryReturnsNilForUnknownAsset() {
        XCTAssertNil(TechniqueAnimationRegistry.animation(for: "does_not_exist"))
    }

    func testScissorExemplarTimingsAreMonotonic() {
        guard let anim = TechniqueAnimationRegistry.animation(for: "diagram_scissor_feet") else {
            XCTFail("Registry missing scissor exemplar")
            return
        }
        for i in 1..<anim.keyframes.count {
            XCTAssertGreaterThan(
                anim.keyframes[i].time, anim.keyframes[i - 1].time,
                "Keyframe \(i) time must exceed predecessor"
            )
        }
    }

    func testScissorExemplarAllCaptionsAndVoiceoversAuthored() {
        guard let anim = TechniqueAnimationRegistry.animation(for: "diagram_scissor_feet") else {
            XCTFail("Registry missing scissor exemplar")
            return
        }
        for (i, k) in anim.keyframes.enumerated() {
            XCTAssertNotNil(k.caption, "Keyframe \(i) missing caption")
            XCTAssertNotNil(k.voiceover, "Keyframe \(i) missing voiceover")
            XCTAssertFalse(k.caption?.isEmpty ?? true)
            XCTAssertFalse(k.voiceover?.isEmpty ?? true)
        }
    }

    // MARK: - Regular drill animations

    func testRegistryResolvesRegularDrillAnimations() {
        XCTAssertNotNil(TechniqueAnimationRegistry.animation(for: "diagram_toe_taps"))
        XCTAssertNotNil(TechniqueAnimationRegistry.animation(for: "diagram_sole_rolls"))
        XCTAssertNotNil(TechniqueAnimationRegistry.animation(for: "diagram_wall_passes"))
    }

    func testAllAuthoredAnimationsAreHealthy() {
        // Cross-cutting invariants every authored animation must satisfy:
        // unique asset ids, non-empty keyframes, monotonic timings, captions
        // and voiceovers on every keyframe, positive loop pause.
        let anims = TechniqueAnimationRegistry.all
        XCTAssertFalse(anims.isEmpty)

        let assetIds = anims.map(\.assetId)
        XCTAssertEqual(Set(assetIds).count, assetIds.count,
                       "Asset ids must be unique across the registry")

        for anim in anims {
            XCTAssertFalse(anim.keyframes.isEmpty, "\(anim.assetId) has no keyframes")
            XCTAssertGreaterThan(anim.duration, 0, "\(anim.assetId) has zero duration")
            XCTAssertGreaterThanOrEqual(anim.loopPauseSeconds, 0, "\(anim.assetId) negative loop pause")

            for i in 1..<anim.keyframes.count {
                XCTAssertGreaterThan(
                    anim.keyframes[i].time, anim.keyframes[i - 1].time,
                    "\(anim.assetId) keyframe \(i) time must exceed predecessor"
                )
            }
            for (i, k) in anim.keyframes.enumerated() {
                XCTAssertNotNil(k.caption, "\(anim.assetId) keyframe \(i) missing caption")
                XCTAssertNotNil(k.voiceover, "\(anim.assetId) keyframe \(i) missing voiceover")
                XCTAssertFalse(k.caption?.isEmpty ?? true)
                XCTAssertFalse(k.voiceover?.isEmpty ?? true)
            }
        }
    }

    func testEveryTaggedDrillResolvesToAnAnimation() {
        // DrillDefinition.diagramAnimationAsset is the contract surface that
        // lets ActiveDrillView render authored animations. A tag that doesn't
        // resolve would mean a drill reference a missing registry entry.
        for drill in DrillRegistry.all {
            if let assetId = drill.diagramAnimationAsset {
                XCTAssertNotNil(
                    TechniqueAnimationRegistry.animation(for: assetId),
                    "Drill \(drill.id) references missing animation asset \(assetId)"
                )
            }
        }
    }

    // MARK: - Rive hero integration

    func testScissorHeroRegistryEntryExists() {
        // SignatureMoves+Scissor.swift pins heroDemoAsset to
        // "demo_scissor_hero". Overview view resolves that via the
        // registry. Missing registry entry would leave the overview
        // rendering the placeholder forever.
        let hero = TechniqueAnimationRegistry.animation(for: "demo_scissor_hero")
        XCTAssertNotNil(hero, "Scissor heroDemoAsset must resolve to a registry entry")
    }

    func testScissorHeroHasRiveAssetPlusCanvasFallback() {
        // Contract: any registry entry with a riveAssetName must also have
        // authored keyframes, because RiveTechniqueView.init returns nil
        // when the .riv file is missing from the bundle — the Canvas path
        // must be able to render in its place so the UI never breaks.
        guard let hero = TechniqueAnimationRegistry.animation(for: "demo_scissor_hero") else {
            XCTFail("Missing scissorHero")
            return
        }
        XCTAssertEqual(hero.riveAssetName, "scissor_hero")
        XCTAssertFalse(hero.keyframes.isEmpty, "Rive-preferred entries must still ship Canvas fallback keyframes")
    }

    func testEveryRiveBackedAnimationHasCanvasFallback() {
        // Generalized version of the Scissor-specific test: anywhere in
        // the registry. When a new Rive-backed hero lands (Body Feint,
        // La Croqueta, etc.), this guard auto-extends.
        for anim in TechniqueAnimationRegistry.all where anim.riveAssetName != nil {
            XCTAssertFalse(
                anim.keyframes.isEmpty,
                "\(anim.assetId) has riveAssetName but no keyframe fallback"
            )
        }
    }

    func testEveryFirstTouchDrillKeyResolves() {
        // FirstTouch drill keys live in FirstTouchViewModel (not in
        // DrillRegistry), and map to animations via a switch in the
        // registry. Enforce that every shipping drill key resolves to a
        // real registry entry — catches typos between the view-model's
        // keys and the switch's cases.
        let shippingKeys = FirstTouchViewModel.jugglingDrills.map(\.0)
            + FirstTouchViewModel.wallBallDrills.map(\.0)
        for key in shippingKeys {
            XCTAssertNotNil(
                TechniqueAnimationRegistry.animation(forFirstTouchDrillKey: key),
                "FirstTouch drill key '\(key)' does not resolve to an animation"
            )
        }
    }

    func testEverySignatureMoveDrillDiagramResolves() {
        // Sister invariant for MoveDrill.diagramAnimationAsset. Catches
        // typos between the signature-move authoring files and the
        // animation registry at test time.
        //
        // Scoped to fully-visualized moves only: Body Feint and La Croqueta
        // MoveDrills reference asset ids (diagram_bodyfeint_*, diagram_croqueta_*)
        // as authored-content placeholders awaiting keyframe work. Add a
        // move id to `fullyAnimatedMoveIds` once every drill in the move
        // has a registered animation — the test then enforces integrity
        // for that move automatically.
        let fullyAnimatedMoveIds: Set<String> = [
            "move-scissor",
            "move-body-feint",
            "move-la-croqueta"
        ]

        for move in SignatureMoveRegistry.launchMoves where fullyAnimatedMoveIds.contains(move.id) {
            for stage in move.stages {
                for drill in stage.drills {
                    guard let assetId = drill.diagramAnimationAsset else { continue }
                    XCTAssertNotNil(
                        TechniqueAnimationRegistry.animation(for: assetId),
                        "\(move.id) drill \(drill.id) references missing animation asset \(assetId)"
                    )
                }
            }
        }
    }
}
