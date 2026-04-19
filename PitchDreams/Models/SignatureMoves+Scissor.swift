import Foundation

/// Fully-authored Scissor move content. Lives in its own file to keep the
/// registry manageable as more moves ship.
extension SignatureMoveRegistry {
    static let scissor = SignatureMove(
        id: "move-scissor",
        name: "Scissor",
        rarity: .common,
        difficulty: .beginner,
        famousFor: "Cristiano Ronaldo's go-to",
        description: "Sweep one foot around the outside of the ball to sell the defender, then explode off the planted foot in the opposite direction.",
        descriptionYoung: "Swing one foot around the ball (don't touch it!), then push off the other foot the OTHER way to escape.",
        iconSymbolName: "scissors",
        heroDemoAsset: "demo_scissor_hero",
        stages: [
            MoveStage(
                order: 1, phase: .groundwork,
                name: "The Fake",
                description: "Before adding the ball, learn the leg motion. The scissor is about selling the fake with your whole body.",
                descriptionYoung: "Before the ball, practice the leg swing. Make your fake look real!",
                drills: [
                    MoveDrill(
                        id: "scis-1-1", title: "Watch the Masters",
                        type: .watch,
                        instructions: "Watch Ronaldo, Robinho, and Bale execute the scissor at different speeds. Notice how their planted foot absorbs the lean while the fake foot circles outside the ball.",
                        instructionsYoung: "Watch these pros! See how their body leans one way with the fake, then they jump the OTHER way? That's the trick!",
                        setupInstructions: nil,
                        demoVideoAsset: "demo_scissor_pros",
                        diagramAnimationAsset: "diagram_scissor_breakdown",
                        durationSeconds: 75,
                        targetReps: 1,
                        commonMistakes: [],
                        commonMistakesYoung: nil,
                        coachCues: ["Watch the plant foot.", "See the hip swivel.", "Notice the explosion the other way."],
                        coachCuesYoung: ["Look at their plant foot!", "Watch the hips!", "Boom — they go the OTHER way!"],
                        enablesRecording: false
                    ),
                    MoveDrill(
                        id: "scis-1-2", title: "The Swing, No Ball",
                        type: .mimic,
                        instructions: "Stand with your feet shoulder-width. Imagine a ball on the ground. Swing your right foot OUTSIDE the imaginary ball in a circular motion, plant it, then explode left off your left foot. Alternate feet. 40 total reps.",
                        instructionsYoung: "Pretend a ball is in front of you. Swing your right foot around the outside of it — don't touch! — then jump to the LEFT with your other foot. Now do the other side!",
                        setupInstructions: "1 meter of open floor space.",
                        demoVideoAsset: "demo_scissor_mimic",
                        diagramAnimationAsset: "diagram_scissor_feet",
                        durationSeconds: 120,
                        targetReps: 40,
                        commonMistakes: [
                            "Swinging too small — the fake must be BIG to sell.",
                            "Not leaning with the fake — your shoulders should go with the foot.",
                            "Forgetting to explode the other way — the whole point is the direction change."
                        ],
                        commonMistakesYoung: [
                            "Make the fake BIG! Small fakes don't fool anyone.",
                            "Lean your whole body with the foot — sell it!",
                            "Don't forget to JUMP the other way — that's the escape!"
                        ],
                        coachCues: ["Big swing.", "Lean into it.", "Explode opposite."],
                        coachCuesYoung: ["BIG swing!", "Lean your body!", "Jump the other way!"],
                        enablesRecording: false
                    )
                ],
                masteryCriteria: MasteryCriteria(requiredDrillsCompleted: 2, requiredConfidence: 3, requiresVideoRecording: false, minTotalReps: 41)
            ),

            MoveStage(
                order: 2, phase: .technique,
                name: "With the Ball",
                description: "Now add the ball. Start with a single scissor from stationary, then walking, then past a cone — each drill adds speed and complexity.",
                descriptionYoung: "Now with the ball! Start slow, then walk, then use a cone.",
                drills: [
                    MoveDrill(
                        id: "scis-2-1", title: "Still Ball Scissor",
                        type: .withBall,
                        instructions: "Ball in front of you. Swing right foot outside-around the ball, plant, push off with inside of left foot. Reset. 15 reps per foot.",
                        instructionsYoung: "Ball in front. Swing your right foot around the ball (don't touch!), plant it, then push the ball away with the inside of your LEFT foot. Switch feet. 15 each side.",
                        setupInstructions: "Flat ground. You and a ball.",
                        demoVideoAsset: "demo_scissor_stillball",
                        diagramAnimationAsset: "diagram_scissor_still",
                        durationSeconds: 120,
                        targetReps: 30,
                        commonMistakes: [
                            "Touching the ball on the swing — the fake foot must NOT touch it.",
                            "Plant foot too far away — stay close to accelerate.",
                            "Forgetting to use the other foot to push the ball — the scissor alone isn't the escape."
                        ],
                        commonMistakesYoung: [
                            "Don't touch the ball with the fake foot!",
                            "Stay close to the ball when you plant.",
                            "Remember: the OTHER foot pushes the ball away!"
                        ],
                        coachCues: ["Don't touch.", "Plant close.", "Push with inside."],
                        coachCuesYoung: ["Don't touch!", "Plant close!", "Other foot pushes!"],
                        enablesRecording: false
                    ),
                    MoveDrill(
                        id: "scis-2-2", title: "Walking Scissor",
                        type: .withBall,
                        instructions: "Walking slowly with the ball. Every 3 touches, execute a scissor and change direction 30°. 25 clean scissors.",
                        instructionsYoung: "Walk slowly with the ball. Every few touches, do a scissor and change direction a little. 25 in a row!",
                        setupInstructions: "10 meters of open space.",
                        demoVideoAsset: "demo_scissor_walking",
                        diagramAnimationAsset: "diagram_scissor_path",
                        durationSeconds: 180,
                        targetReps: 25,
                        commonMistakes: [
                            "Losing the ball when changing direction — stay connected.",
                            "Scissoring at random intervals — develop rhythm."
                        ],
                        commonMistakesYoung: [
                            "Keep the ball close when you change direction!",
                            "Find a rhythm: walk walk walk scissor, walk walk walk scissor."
                        ],
                        coachCues: ["Rhythm.", "Stay connected.", "Change direction."],
                        coachCuesYoung: ["Rhythm!", "Ball close!", "New direction!"],
                        enablesRecording: false
                    ),
                    MoveDrill(
                        id: "scis-2-3", title: "Cone Escape",
                        type: .withBall,
                        instructions: "Place 1 cone. Approach at jogging pace, execute scissor 1m before cone, accelerate past it. 20 clean escapes, alternating which side you escape to.",
                        instructionsYoung: "Put down one cone. Jog toward it with the ball. Do a scissor RIGHT BEFORE the cone, then zoom past. 20 times, switching sides!",
                        setupInstructions: "1 cone in a 10m straight line path.",
                        demoVideoAsset: "demo_scissor_cone",
                        diagramAnimationAsset: "diagram_scissor_cone_escape",
                        durationSeconds: 180,
                        targetReps: 20,
                        commonMistakes: [
                            "Scissoring too early — the cone-as-defender can adjust.",
                            "Not accelerating after — the fake means nothing without the burst."
                        ],
                        commonMistakesYoung: [
                            "Scissor CLOSE to the cone, not way early!",
                            "BURST after the fake — go fast!"
                        ],
                        coachCues: ["Close to the cone.", "Explode after.", "Don't slow down."],
                        coachCuesYoung: ["Close to the cone!", "BURST!", "Don't stop!"],
                        enablesRecording: false
                    )
                ],
                masteryCriteria: MasteryCriteria(requiredDrillsCompleted: 3, requiredConfidence: 4, requiresVideoRecording: false, minTotalReps: 75)
            ),

            MoveStage(
                order: 3, phase: .mastery,
                name: "Sell It at Speed",
                description: "Full-speed execution and double-scissor combos. A scissor without speed is just a wiggle — a scissor WITH speed beats defenders.",
                descriptionYoung: "Time to go FAST! Real scissors happen at real speed.",
                drills: [
                    MoveDrill(
                        id: "scis-3-1", title: "Double Scissor",
                        type: .challenge,
                        instructions: "Two scissors in sequence (right foot then left foot) before pushing the ball. 20 clean doubles. Harder to sell — defender expects one, you give two.",
                        instructionsYoung: "Try TWO scissors in a row, right then left, then push the ball away. 20 of these — this really fools defenders!",
                        setupInstructions: "Open space, ball, you.",
                        demoVideoAsset: "demo_scissor_double",
                        diagramAnimationAsset: "diagram_scissor_double",
                        durationSeconds: 180,
                        targetReps: 20,
                        commonMistakes: [
                            "Too slow between scissors — pace them like a drumroll.",
                            "Losing balance — stay low throughout."
                        ],
                        commonMistakesYoung: [
                            "Fast between the scissors! One-two!",
                            "Stay low — don't wobble!"
                        ],
                        coachCues: ["One-two.", "Quick.", "Stay low."],
                        coachCuesYoung: ["ONE-TWO!", "Quick!", "Low!"],
                        enablesRecording: false
                    ),
                    MoveDrill(
                        id: "scis-3-2", title: "Speed Cone Corridor",
                        type: .challenge,
                        instructions: "3 cones, 2m apart. Scissor past each. Complete 10 clean runs in 90 seconds. Clean run = scissor + direction change + control maintained.",
                        instructionsYoung: "3 cones, 2m apart. Scissor past each one. 10 full runs in 90 seconds — FAST AND CLEAN!",
                        setupInstructions: "3 cones in a line, 2m apart.",
                        demoVideoAsset: "demo_scissor_speed",
                        diagramAnimationAsset: "diagram_scissor_cone_path",
                        durationSeconds: 90,
                        targetReps: 10,
                        commonMistakes: [
                            "Sloppy at speed — a clean 8 beats a messy 12.",
                            "Same-side scissor every time — alternate."
                        ],
                        commonMistakesYoung: [
                            "Clean is better than messy-fast!",
                            "Switch sides each cone!"
                        ],
                        coachCues: ["Clean at speed.", "Alternate.", "Ten of them."],
                        coachCuesYoung: ["Clean!", "Switch sides!", "Ten total!"],
                        enablesRecording: false
                    ),
                    MoveDrill(
                        id: "scis-3-3", title: "Record Your Best",
                        type: .challenge,
                        instructions: "Record a 10-second video of your best scissor sequence. Save to your Journey. Compare to the pro footage. You've earned this.",
                        instructionsYoung: "Film yourself! 10 seconds of your best scissors. Save it — and feel proud!",
                        setupInstructions: "Phone propped up. Camera on. Press record.",
                        demoVideoAsset: nil,
                        diagramAnimationAsset: nil,
                        durationSeconds: 60,
                        targetReps: 1,
                        commonMistakes: [],
                        commonMistakesYoung: nil,
                        coachCues: ["You've got this.", "One clean take."],
                        coachCuesYoung: ["You can do it!", "One great take!"],
                        enablesRecording: true
                    )
                ],
                masteryCriteria: MasteryCriteria(requiredDrillsCompleted: 2, requiredConfidence: 5, requiresVideoRecording: false, minTotalReps: 30)
            )
        ],
        coachTipYoung: "Foot swings around, body leans, then BOOM — jump the other way!",
        coachTip: "The fake is sold by the lean, not the foot. Your shoulders and hips go with the swing, then explode opposite."
    )
}
