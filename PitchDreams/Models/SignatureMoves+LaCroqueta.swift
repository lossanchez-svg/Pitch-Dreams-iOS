import Foundation

/// Fully-authored La Croqueta move content. Iniesta's signature — push the
/// ball from inside one foot to inside the other in a single smooth motion.
extension SignatureMoveRegistry {
    static let laCroqueta = SignatureMove(
        id: "move-la-croqueta",
        name: "La Croqueta",
        rarity: .rare,
        difficulty: .intermediate,
        famousFor: "Iniesta's disappearing act",
        description: "Push the ball from the inside of one foot to the inside of the other in a single smooth motion — low, quick, and clean. It disappears past the defender's stride.",
        descriptionYoung: "Push the ball from one foot to the other in one fast motion — like dealing cards. The defender can't catch up!",
        iconSymbolName: "arrow.left.and.right",
        heroDemoAsset: "demo_croqueta_hero",
        stages: [
            MoveStage(
                order: 1, phase: .groundwork,
                name: "Inside-Inside Feel",
                description: "La Croqueta is all about touch: the ball moves from the inside of one foot to the inside of the other with a single smooth transfer. No kick, no slam — a push.",
                descriptionYoung: "Two feet, two quick pushes — inside to inside. Smooth, not hard!",
                drills: [
                    MoveDrill(
                        id: "crq-1-1", title: "Watch Iniesta's Magic",
                        type: .watch,
                        instructions: "Watch the Iniesta compilation. Look for: how low the ball stays, how close the feet are, how the ball barely rolls between them. The move happens in a single defender stride.",
                        instructionsYoung: "Watch Iniesta! See how the ball stays LOW between his feet, and moves super fast? That's the trick.",
                        setupInstructions: nil,
                        demoVideoAsset: "demo_croqueta_iniesta",
                        diagramAnimationAsset: "diagram_croqueta_breakdown",
                        durationSeconds: 90,
                        targetReps: 1,
                        commonMistakes: [],
                        commonMistakesYoung: nil,
                        coachCues: ["Low roll.", "Feet close.", "One motion.", "Defender's stride."],
                        coachCuesYoung: ["LOW!", "Close feet!", "One motion!", "One step!"],
                        enablesRecording: false
                    ),
                    MoveDrill(
                        id: "crq-1-2", title: "Inside-Inside Taps, No Ball",
                        type: .mimic,
                        instructions: "Stand with feet shoulder-width. Tap insides of your feet together in a quick one-two pattern. Ball-side to ball-side. 60 taps at a steady rhythm.",
                        instructionsYoung: "Stand with feet apart. Tap the inside of one foot to the inside of the other — LEFT-RIGHT, LEFT-RIGHT. 60 taps!",
                        setupInstructions: "Small space. No ball needed.",
                        demoVideoAsset: "demo_croqueta_taps",
                        diagramAnimationAsset: "diagram_croqueta_feet",
                        durationSeconds: 120,
                        targetReps: 60,
                        commonMistakes: [
                            "Feet too wide — stay close so the ball won't roll far.",
                            "Slow rhythm — the croqueta is quick."
                        ],
                        commonMistakesYoung: [
                            "Keep feet close together!",
                            "QUICK taps — don't be slow!"
                        ],
                        coachCues: ["Close.", "Quick.", "Rhythm."],
                        coachCuesYoung: ["Close!", "Quick!", "Rhythm!"],
                        enablesRecording: false
                    )
                ],
                masteryCriteria: MasteryCriteria(requiredDrillsCompleted: 2, requiredConfidence: 3, requiresVideoRecording: false, minTotalReps: 61)
            ),

            MoveStage(
                order: 2, phase: .technique,
                name: "With the Ball",
                description: "Add the ball. Start with the still-ball push to learn the transfer distance, then walking, then through a corridor.",
                descriptionYoung: "Ball time! Still first, then walking, then through a tight space.",
                drills: [
                    MoveDrill(
                        id: "crq-2-1", title: "Still Ball Push",
                        type: .withBall,
                        instructions: "Ball between your feet, shoulder-width. Push with the inside of the right foot to the inside of the left (ball rolls ~30cm). Reset. 30 reps per direction.",
                        instructionsYoung: "Ball between your feet. Push it from right foot to left foot with the INSIDE of your feet. Reset. 30 each way!",
                        setupInstructions: "Flat ground, ball.",
                        demoVideoAsset: "demo_croqueta_still",
                        diagramAnimationAsset: "diagram_croqueta_still",
                        durationSeconds: 150,
                        targetReps: 60,
                        commonMistakes: [
                            "Ball travels too far — aim for 30cm, not a meter.",
                            "Using the laces or outside — must be the inside bone.",
                            "Ball bounces up — contact should be firm and low."
                        ],
                        commonMistakesYoung: [
                            "Small push! Don't kick it far!",
                            "Inside of your foot only!",
                            "Keep the ball LOW!"
                        ],
                        coachCues: ["30cm.", "Inside only.", "Low roll."],
                        coachCuesYoung: ["Small!", "Inside!", "Low!"],
                        enablesRecording: false
                    ),
                    MoveDrill(
                        id: "crq-2-2", title: "Linear Croqueta",
                        type: .withBall,
                        instructions: "Jogging forward with the ball. Every 4 strides, execute a croqueta without breaking stride. 30 reps alternating direction. The move should feel invisible in your running pattern.",
                        instructionsYoung: "Jog forward with the ball. Every few steps, do a croqueta while still moving. Don't stop!",
                        setupInstructions: "15 meters of straight open space.",
                        demoVideoAsset: "demo_croqueta_linear",
                        diagramAnimationAsset: "diagram_croqueta_path",
                        durationSeconds: 180,
                        targetReps: 30,
                        commonMistakes: [
                            "Stopping to execute — must happen while running.",
                            "Ball lifts off the ground — stay low and controlled.",
                            "Slow transfer — defenders catch slow transfers."
                        ],
                        commonMistakesYoung: [
                            "KEEP running — don't stop!",
                            "Ball stays on the ground!",
                            "Fast transfer!"
                        ],
                        coachCues: ["Stride through.", "Low and quick.", "One motion."],
                        coachCuesYoung: ["Keep moving!", "Quick!", "One!"],
                        enablesRecording: false
                    ),
                    MoveDrill(
                        id: "crq-2-3", title: "Cone Corridor",
                        type: .withBall,
                        instructions: "Set 2 cones 1m apart as a gate. Approach at jogging pace. Execute a croqueta to slip through the gate. 20 clean gate-passes, alternating which foot you start with.",
                        instructionsYoung: "2 cones, 1 meter apart — a gate! Croqueta through the middle. 20 times, switching feet!",
                        setupInstructions: "2 cones, 1m apart. 10m approach.",
                        demoVideoAsset: "demo_croqueta_gate",
                        diagramAnimationAsset: "diagram_croqueta_gate",
                        durationSeconds: 180,
                        targetReps: 20,
                        commonMistakes: [
                            "Hitting cones — tighten the transfer, stay central.",
                            "Slowing down before the gate — approach at pace."
                        ],
                        commonMistakesYoung: [
                            "Don't hit the cones!",
                            "Stay fast into the gate!"
                        ],
                        coachCues: ["Tight gap.", "Stay fast.", "Clean through."],
                        coachCuesYoung: ["Tight!", "Fast!", "Clean!"],
                        enablesRecording: false
                    )
                ],
                masteryCriteria: MasteryCriteria(requiredDrillsCompleted: 3, requiredConfidence: 4, requiresVideoRecording: false, minTotalReps: 110)
            ),

            MoveStage(
                order: 3, phase: .mastery,
                name: "In Traffic",
                description: "The croqueta's real value is escaping pressure. Execute under time pressure and through a tight corridor.",
                descriptionYoung: "Time to use it for REAL — fast and through tight spaces!",
                drills: [
                    MoveDrill(
                        id: "crq-3-1", title: "Speed Gate Run",
                        type: .challenge,
                        instructions: "3 gates in a line, 3m apart. Croqueta through each. Complete 10 clean runs in 90 seconds.",
                        instructionsYoung: "3 gates, 3m apart. Croqueta through each one. 10 full runs in 90 seconds!",
                        setupInstructions: "3 cone gates in a line, 3m apart.",
                        demoVideoAsset: "demo_croqueta_speed",
                        diagramAnimationAsset: "diagram_croqueta_speed_path",
                        durationSeconds: 90,
                        targetReps: 10,
                        commonMistakes: [
                            "Sloppy at speed — clean 8 beats messy 12.",
                            "Hesitating between gates — find the rhythm."
                        ],
                        commonMistakesYoung: [
                            "Clean beats fast-and-messy!",
                            "Keep the rhythm between gates!"
                        ],
                        coachCues: ["Clean speed.", "Rhythm.", "Ten clean."],
                        coachCuesYoung: ["Clean!", "Rhythm!", "Ten!"],
                        enablesRecording: false
                    ),
                    MoveDrill(
                        id: "crq-3-2", title: "Defender Simulation",
                        type: .challenge,
                        instructions: "Partner or parent walks toward you with arms wide. As they get within 2m, execute a croqueta past them. 15 reps — switch roles if you have a partner.",
                        instructionsYoung: "Have someone walk at you slowly with their arms open. Croqueta past them! 15 times!",
                        setupInstructions: "Partner, open space, ball.",
                        demoVideoAsset: "demo_croqueta_defender",
                        diagramAnimationAsset: nil,
                        durationSeconds: 240,
                        targetReps: 15,
                        commonMistakes: [
                            "Executing too early — wait for their stride to commit.",
                            "Executing too late — get past before they react."
                        ],
                        commonMistakesYoung: [
                            "Wait — then BURST past!",
                            "Not too early, not too late!"
                        ],
                        coachCues: ["Time it.", "Burst past.", "Don't stop."],
                        coachCuesYoung: ["Wait... GO!", "Burst!", "Keep going!"],
                        enablesRecording: false
                    ),
                    MoveDrill(
                        id: "crq-3-3", title: "Record Your Best",
                        type: .challenge,
                        instructions: "Record 10 seconds of your best croqueta sequence. Save to your Journey.",
                        instructionsYoung: "Film yourself! 10 seconds of La Croquetas!",
                        setupInstructions: "Phone propped, record.",
                        demoVideoAsset: nil, diagramAnimationAsset: nil,
                        durationSeconds: 60, targetReps: 1,
                        commonMistakes: [], commonMistakesYoung: nil,
                        coachCues: ["One clean take."], coachCuesYoung: ["One good try!"],
                        enablesRecording: true
                    )
                ],
                masteryCriteria: MasteryCriteria(requiredDrillsCompleted: 2, requiredConfidence: 5, requiresVideoRecording: false, minTotalReps: 25)
            )
        ],
        coachTipYoung: "Two touches, one smooth slide — like you're dealing cards!",
        coachTip: "Inside of one foot to inside of the other, low and quick. Defender's stride is your window."
    )
}
