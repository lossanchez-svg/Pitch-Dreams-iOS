import Foundation

/// Fully-authored Body Feint move content.
extension SignatureMoveRegistry {
    static let bodyFeint = SignatureMove(
        id: "move-body-feint",
        name: "Body Feint",
        rarity: .common,
        difficulty: .beginner,
        famousFor: "Messi's invisible weapon",
        description: "No touch required. Drop your shoulder and sway your hips one direction to sell the defender, then explode the opposite way. The subtlest move in football.",
        descriptionYoung: "The sneakiest move! You don't even touch the ball — just lean your body one way to trick the defender, then go the OTHER way!",
        iconSymbolName: "arrow.triangle.swap",
        heroDemoAsset: "demo_bodyfeint_hero",
        stages: [
            MoveStage(
                order: 1, phase: .groundwork,
                name: "Selling the Lie",
                description: "The body feint works only if the fake is completely convincing. Defenders read shoulders and hips first. Learn to sell with your upper body.",
                descriptionYoung: "The trick only works if the defender BELIEVES your fake. Practice selling with your shoulders and hips.",
                drills: [
                    MoveDrill(
                        id: "bf-1-1", title: "Watch Messi's Magic",
                        type: .watch,
                        instructions: "Watch Messi's body-feint compilation. Notice he never touches the ball on the fake — it's all in the shoulder drop and hip sway. He freezes defenders without a single touch.",
                        instructionsYoung: "Watch Messi! He doesn't even TOUCH the ball. He just leans his body and the defender falls for it. Magic!",
                        setupInstructions: nil,
                        demoVideoAsset: "demo_bodyfeint_messi",
                        diagramAnimationAsset: "diagram_bodyfeint_breakdown",
                        durationSeconds: 90,
                        targetReps: 1,
                        commonMistakes: [],
                        commonMistakesYoung: nil,
                        coachCues: ["No touch on the fake.", "Shoulder drop.", "Hip swing.", "Then explode."],
                        coachCuesYoung: ["No touch!", "Shoulders!", "Hips!", "BOOM — go!"],
                        enablesRecording: false
                    ),
                    MoveDrill(
                        id: "bf-1-2", title: "Mirror Practice",
                        type: .mimic,
                        instructions: "Stand in front of a mirror. Drop your right shoulder while swinging your hip right — sell it like you're about to sprint right. Then explode left. Alternate. 50 reps. You should LOOK convincing in the mirror.",
                        instructionsYoung: "Stand in front of a mirror. Drop your shoulder and lean RIGHT like you're about to run right. Then JUMP LEFT! Alternate. 50 times. Does it look real?",
                        setupInstructions: "A mirror (bathroom, bedroom, etc.).",
                        demoVideoAsset: "demo_bodyfeint_mirror",
                        diagramAnimationAsset: "diagram_bodyfeint_bodypos",
                        durationSeconds: 150,
                        targetReps: 50,
                        commonMistakes: [
                            "Small body movements — go BIG. A tiny lean fools nobody.",
                            "Forgetting the hip — shoulders alone aren't enough, hips sell the weight transfer.",
                            "Upper body straightens before the explosion — commit until the instant you change direction."
                        ],
                        commonMistakesYoung: [
                            "Go BIG! A tiny lean doesn't fool anyone!",
                            "Don't forget your hips — they have to lean too!",
                            "Stay leaned until you JUMP the other way!"
                        ],
                        coachCues: ["Big lean.", "Hips commit.", "Hold, then explode."],
                        coachCuesYoung: ["BIG LEAN!", "HIPS!", "Hold, then BOOM!"],
                        enablesRecording: false
                    )
                ],
                masteryCriteria: MasteryCriteria(requiredDrillsCompleted: 2, requiredConfidence: 3, requiresVideoRecording: false, minTotalReps: 51)
            ),

            MoveStage(
                order: 2, phase: .technique,
                name: "With the Ball (But Don't Touch the Fake)",
                description: "Now add the ball. The discipline is hard — your instinct is to touch the ball on the fake, but the body feint works precisely because you DON'T.",
                descriptionYoung: "Now with the ball! The hard part: DON'T touch the ball when you fake — only when you escape!",
                drills: [
                    MoveDrill(
                        id: "bf-2-1", title: "Stationary Feint + Push",
                        type: .withBall,
                        instructions: "Ball in front of you, stationary. Drop shoulder and hip to the right (ball stays still). Then push the ball to the LEFT with inside-left foot. 30 reps, alternating sides.",
                        instructionsYoung: "Ball stays still. Lean your body right. Ball does NOT move! Then push it LEFT with your left foot. 30 times, switch sides!",
                        setupInstructions: "Flat ground, ball.",
                        demoVideoAsset: "demo_bodyfeint_stillball",
                        diagramAnimationAsset: "diagram_bodyfeint_still",
                        durationSeconds: 180,
                        targetReps: 30,
                        commonMistakes: [
                            "Touching the ball on the fake — hardest habit to break.",
                            "Ball-push is weak — the escape touch must be sharp."
                        ],
                        commonMistakesYoung: [
                            "DON'T touch the ball when you fake!",
                            "Push the ball FIRM when you escape!"
                        ],
                        coachCues: ["No touch on fake.", "Ball still.", "Sharp escape."],
                        coachCuesYoung: ["NO TOUCH!", "Ball still!", "SHARP push!"],
                        enablesRecording: false
                    ),
                    MoveDrill(
                        id: "bf-2-2", title: "Walking Feint + Cut",
                        type: .withBall,
                        instructions: "Walking forward with the ball. Every 3 touches, plant foot, fake with body, then cut 45° the opposite direction with the outside of the other foot. 25 cuts.",
                        instructionsYoung: "Walk forward with the ball. Every few touches: plant, fake, then cut to the other side. 25 cuts!",
                        setupInstructions: "10-meter open path.",
                        demoVideoAsset: "demo_bodyfeint_walking",
                        diagramAnimationAsset: "diagram_bodyfeint_path",
                        durationSeconds: 180,
                        targetReps: 25,
                        commonMistakes: [
                            "Cut is too gentle — 45° minimum, sharp angle.",
                            "Still looking where you're faking — look FORWARD, let body do the lie."
                        ],
                        commonMistakesYoung: [
                            "Cut SHARP — big angle!",
                            "Look forward, not at your fake!"
                        ],
                        coachCues: ["Sharp angle.", "Eyes forward.", "Commit the fake."],
                        coachCuesYoung: ["SHARP cut!", "Eyes forward!", "Commit!"],
                        enablesRecording: false
                    ),
                    MoveDrill(
                        id: "bf-2-3", title: "Cone Body Feint",
                        type: .withBall,
                        instructions: "Approach a cone. 2m before, fake right with full body. Cut left past the cone with outside-left foot. 20 clean cuts, alternating sides.",
                        instructionsYoung: "Go toward a cone. RIGHT before the cone, fake with your body. Then cut past on the OTHER side!",
                        setupInstructions: "1 cone, 10m approach.",
                        demoVideoAsset: "demo_bodyfeint_cone",
                        diagramAnimationAsset: "diagram_bodyfeint_cone",
                        durationSeconds: 180,
                        targetReps: 20,
                        commonMistakes: [
                            "Fake too early — defender (cone-as-defender) adjusts.",
                            "Body upright during the fake — must lean over."
                        ],
                        commonMistakesYoung: [
                            "Fake LATE, not early!",
                            "LEAN your body — don't stand tall!"
                        ],
                        coachCues: ["Late fake.", "Lean deep.", "Explode past."],
                        coachCuesYoung: ["LATE fake!", "LEAN!", "Explode!"],
                        enablesRecording: false
                    )
                ],
                masteryCriteria: MasteryCriteria(requiredDrillsCompleted: 3, requiredConfidence: 4, requiresVideoRecording: false, minTotalReps: 75)
            ),

            MoveStage(
                order: 3, phase: .mastery,
                name: "Read and React",
                description: "The body feint at its best is a response, not a routine. Practice reading cues and reacting instantly.",
                descriptionYoung: "Now the real thing — react to what you see, don't just do it the same every time!",
                drills: [
                    MoveDrill(
                        id: "bf-3-1", title: "Signal Reaction",
                        type: .challenge,
                        instructions: "Have someone (parent, friend) stand 5m in front of you, ball at your feet. They point left or right as you approach. You fake the OPPOSITE way of their point. 15 reps. If alone, use the app's voice prompt randomizer (shakes phone).",
                        instructionsYoung: "Have a grown-up or friend point left or right. Fake the OTHER way. 15 tries! Or ask the app to call out directions.",
                        setupInstructions: "A partner or the app's voice randomizer. 5m space.",
                        demoVideoAsset: "demo_bodyfeint_signal",
                        diagramAnimationAsset: nil,
                        durationSeconds: 240,
                        targetReps: 15,
                        commonMistakes: [
                            "Deciding before the signal — wait for the read.",
                            "Too slow to react — reaction window is under 500ms in real games."
                        ],
                        commonMistakesYoung: [
                            "Wait for the signal — don't plan ahead!",
                            "React FAST!"
                        ],
                        coachCues: ["Wait.", "Read.", "React fast."],
                        coachCuesYoung: ["Wait!", "Read!", "REACT!"],
                        enablesRecording: false
                    ),
                    MoveDrill(
                        id: "bf-3-2", title: "Feint + Combo",
                        type: .challenge,
                        instructions: "Combine the body feint with another unlocked move: feint right → La Croqueta left, or feint right → step-over left. 20 combos.",
                        instructionsYoung: "Combine the body feint with another move you know. Fake right, then La Croqueta left! 20 combos!",
                        setupInstructions: "Open space, ball.",
                        demoVideoAsset: "demo_bodyfeint_combo",
                        diagramAnimationAsset: nil,
                        durationSeconds: 240,
                        targetReps: 20,
                        commonMistakes: [
                            "Combo is too slow — both moves must flow.",
                            "Second move is weak — don't relax after the first."
                        ],
                        commonMistakesYoung: [
                            "Keep going after the feint — FLOW!",
                            "Second move needs to be strong too!"
                        ],
                        coachCues: ["Flow through.", "Both strong.", "No pause."],
                        coachCuesYoung: ["Flow!", "Both strong!", "No stop!"],
                        enablesRecording: false
                    ),
                    MoveDrill(
                        id: "bf-3-3", title: "Record Your Best",
                        type: .challenge,
                        instructions: "Record 10 seconds of your best body feint + cut. Save to Journey.",
                        instructionsYoung: "Film yourself! 10 seconds of body feints!",
                        setupInstructions: "Phone propped, record.",
                        demoVideoAsset: nil, diagramAnimationAsset: nil,
                        durationSeconds: 60, targetReps: 1,
                        commonMistakes: [], commonMistakesYoung: nil,
                        coachCues: ["One clean take."], coachCuesYoung: ["One good try!"],
                        enablesRecording: true
                    )
                ],
                masteryCriteria: MasteryCriteria(requiredDrillsCompleted: 2, requiredConfidence: 5, requiresVideoRecording: false, minTotalReps: 35)
            )
        ],
        coachTipYoung: "Lean your body one way — BIG lean! — then jump the other!",
        coachTip: "Shoulders and hips sell the lie. No ball touch on the fake — that's what makes it Messi's invisible weapon."
    )
}
