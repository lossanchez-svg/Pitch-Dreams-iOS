# Signature Moves — Expanded Teaching Spec

**Companion to:** `TRACK_E_STICKINESS_SPEC.md` (this doc supersedes the E2 section there)

**Critical change from original spec:** Mapping moves to generic ball-mastery drills doesn't teach anything. A kid can't learn La Croqueta by doing toe taps. This doc replaces the thin E2 implementation with a full technique-teaching system.

**Key scope change:** Launch with **5 fully-authored moves** (not 10). Quality over quantity. Release 1 new move every 3-4 weeks post-launch.

---

## Table of Contents

1. [The Teaching Stack](#the-teaching-stack)
2. [Expanded Data Model](#expanded-data-model)
3. [Launch Move Registry (5 moves, fully authored)](#launch-move-registry-5-moves-fully-authored)
    - [Scissor](#scissor)
    - [Step-Over](#step-over)
    - [Body Feint](#body-feint)
    - [La Croqueta](#la-croqueta)
    - [Elastico](#elastico)
4. [Learning-Flow UI (New Screens)](#learning-flow-ui-new-screens)
5. [Stitch Mockups Required](#stitch-mockups-required)
6. [Files to Create / Modify](#files-to-create--modify)
7. [Post-Launch Move Release Cadence](#post-launch-move-release-cadence)
8. [Content Production Estimate](#content-production-estimate)
9. [Success Criteria](#success-criteria)

---

## The Teaching Stack

A player learns a technique through five distinct phases:

| Phase | What they're doing | Example (La Croqueta) |
|-------|-------------------|-----------------------|
| 1. Watch | See it done well, multiple speeds/angles | Iniesta compilation, slow-mo breakdown |
| 2. Understand | Break down the mechanics | "Inside of one foot to inside of the other, low, single touch" |
| 3. Mimic | Practice motion, often no ball | 30 alternating inside-foot taps, no ball |
| 4. Drill with ball | Progressive, move-specific drills | Still ball push → walking → cone corridor |
| 5. Apply | Under pressure, speed, defender simulation | Timed speed corridor → imagined defender scenarios |

These collapse into **3 stages of mastery** in the app:

- **Stage 1 = Groundwork** (phases 1-3: Watch + Understand + Mimic)
- **Stage 2 = Technique** (phase 4: progressive ball drills)
- **Stage 3 = Mastery** (phase 5: pressure, speed, recording yourself)

---

## Expanded Data Model

This replaces the `MoveStage` + `DrillRegistry`-reference model in `TRACK_E_STICKINESS_SPEC.md`.

**File: `PitchDreams/Models/SignatureMove.swift`** (replace the prior definition)

```swift
import Foundation

struct SignatureMove: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let rarity: MoveRarity
    let difficulty: MoveDifficulty
    let famousFor: String
    let description: String
    let descriptionYoung: String?
    let iconSymbolName: String
    let heroDemoAsset: String?          // main teaching video/animation
    let stages: [MoveStage]              // always 3 stages — groundwork / technique / mastery
    let coachTipYoung: String            // shown at library browse
    let coachTip: String
}

enum MoveRarity: String, Codable, CaseIterable {
    case common, rare, epic, legendary

    var displayName: String { rawValue.capitalized }

    var accentColorHex: String {
        switch self {
        case .common:    return "#94A3B8"
        case .rare:      return "#46E5F8"
        case .epic:      return "#A855F7"
        case .legendary: return "#FFE9BD"
        }
    }

    /// Bonus XP awarded on final mastery of the move.
    var masteryXP: Int {
        switch self {
        case .common:    return 100
        case .rare:      return 250
        case .epic:      return 500
        case .legendary: return 1000
        }
    }

    /// XP awarded on completing an intermediate stage (1 or 2).
    var stageXP: Int {
        switch self {
        case .common:    return 25
        case .rare:      return 50
        case .epic:      return 100
        case .legendary: return 200
        }
    }
}

enum MoveDifficulty: String, Codable, CaseIterable {
    case beginner, intermediate, advanced
    var displayName: String { rawValue.capitalized }
}

enum LearningPhase: String, Codable {
    case groundwork   // Watch + mimic (no ball or still ball only)
    case technique    // With ball — progressive move-specific drills
    case mastery      // Pressure / speed / defender sim / optional self-recording

    var displayName: String {
        switch self {
        case .groundwork: return "Groundwork"
        case .technique:  return "Technique"
        case .mastery:    return "Mastery"
        }
    }

    var icon: String {
        switch self {
        case .groundwork: return "eye.fill"
        case .technique:  return "soccerball"
        case .mastery:    return "flame.fill"
        }
    }
}

struct MoveStage: Codable, Equatable {
    let order: Int                       // 1, 2, 3
    let phase: LearningPhase
    let name: String
    let description: String
    let descriptionYoung: String?
    let drills: [MoveDrill]
    let masteryCriteria: MasteryCriteria
}

struct MasteryCriteria: Codable, Equatable {
    let requiredDrillsCompleted: Int    // of the drills in this stage
    let requiredConfidence: Int          // 1-5 self-reported after stage
    let requiresVideoRecording: Bool     // typically true for final stage, optional

    /// Total reps across all drills needed for stage completion.
    let minTotalReps: Int
}

enum MoveDrillType: String, Codable {
    case watch         // Video / animation playback — no user action
    case mimic         // No ball — practice the motion itself
    case withBall      // Introduce ball, still or walking
    case challenge     // Under pressure: timed, cones, simulated defender

    var icon: String {
        switch self {
        case .watch:     return "play.rectangle.fill"
        case .mimic:     return "figure.walk.motion"
        case .withBall:  return "soccerball"
        case .challenge: return "flame.fill"
        }
    }
}

struct MoveDrill: Codable, Equatable, Identifiable {
    let id: String
    let title: String
    let type: MoveDrillType
    let instructions: String             // 12+ version
    let instructionsYoung: String?        // 8-11 version
    let setupInstructions: String?        // "Set up 3 cones 2m apart" — can be nil for no-equipment drills
    let demoVideoAsset: String?
    let diagramAnimationAsset: String?    // animated diagram fallback when no video
    let durationSeconds: Int
    let targetReps: Int
    let commonMistakes: [String]
    let commonMistakesYoung: [String]?
    let coachCues: [String]               // short prompts spoken during drill: "Low!", "Snap!"
    let coachCuesYoung: [String]?
    let enablesRecording: Bool            // the "record yourself" capstone drill
}

/// User's progress for a single move.
struct MoveProgress: Codable, Equatable {
    let moveId: String
    var currentStage: Int                // 0 = locked, 1-3 = stage in progress, 4 = mastered
    var completedDrillIds: Set<String>
    var drillReps: [String: Int]          // drillId -> reps accumulated
    var stageConfidenceRatings: [Int: Int] // stage -> 1-5 confidence
    var recordedVideoPath: String?        // optional self-recording URL
    var masteredAt: Date?
    var lastAttemptAt: Date?

    var isMastered: Bool { masteredAt != nil }
    var isLocked: Bool { currentStage == 0 }
}
```

### Persistence Update

**File: `PitchDreams/Core/Persistence/SignatureMoveStore.swift`** (replace the prior `recordStageAttempt` logic)

```swift
import Foundation

actor SignatureMoveStore {
    private let defaults = UserDefaults.standard

    func getProgress(moveId: String, childId: String) -> MoveProgress {
        guard let data = defaults.data(forKey: key(moveId: moveId, childId: childId)),
              let progress = try? JSONDecoder().decode(MoveProgress.self, from: data) else {
            return MoveProgress(
                moveId: moveId, currentStage: 1,
                completedDrillIds: [], drillReps: [:], stageConfidenceRatings: [:],
                recordedVideoPath: nil, masteredAt: nil, lastAttemptAt: nil
            )
        }
        return progress
    }

    func save(_ progress: MoveProgress, childId: String) {
        guard let data = try? JSONEncoder().encode(progress) else { return }
        defaults.set(data, forKey: key(moveId: progress.moveId, childId: childId))
    }

    /// Record reps toward a specific drill. Returns structured result for UI feedback.
    func recordDrillAttempt(
        moveId: String,
        drillId: String,
        reps: Int,
        childId: String
    ) -> DrillAttemptResult {
        guard let move = SignatureMoveRegistry.move(id: moveId) else {
            return DrillAttemptResult(drillCompleted: false, stageCanComplete: false, moveCanMaster: false)
        }
        var progress = getProgress(moveId: moveId, childId: childId)
        guard let (stage, drill) = findStageAndDrill(in: move, drillId: drillId) else {
            return DrillAttemptResult(drillCompleted: false, stageCanComplete: false, moveCanMaster: false)
        }
        guard stage.order <= progress.currentStage else {
            return DrillAttemptResult(drillCompleted: false, stageCanComplete: false, moveCanMaster: false)
        }

        let priorReps = progress.drillReps[drillId] ?? 0
        progress.drillReps[drillId] = priorReps + reps
        progress.lastAttemptAt = Date()

        let drillNowComplete = (progress.drillReps[drillId] ?? 0) >= drill.targetReps
        if drillNowComplete {
            progress.completedDrillIds.insert(drillId)
        }

        // Check if stage can complete (drill count + total reps)
        let stageCanComplete = canStageComplete(stage: stage, progress: progress)

        save(progress, childId: childId)
        return DrillAttemptResult(
            drillCompleted: drillNowComplete,
            stageCanComplete: stageCanComplete,
            moveCanMaster: false  // mastery requires confidence rating — handled separately
        )
    }

    /// Record confidence rating and advance stage if criteria met. Returns whether stage advanced
    /// and whether the move was mastered.
    func recordStageConfidence(
        moveId: String,
        stage: Int,
        confidence: Int,
        videoPath: String? = nil,
        childId: String
    ) -> StageAdvanceResult {
        guard let move = SignatureMoveRegistry.move(id: moveId) else {
            return StageAdvanceResult(stageAdvanced: false, moveMastered: false)
        }
        guard let stageDef = move.stages.first(where: { $0.order == stage }) else {
            return StageAdvanceResult(stageAdvanced: false, moveMastered: false)
        }

        var progress = getProgress(moveId: moveId, childId: childId)
        progress.stageConfidenceRatings[stage] = confidence
        if let videoPath { progress.recordedVideoPath = videoPath }

        let confidenceMet = confidence >= stageDef.masteryCriteria.requiredConfidence
        let drillsMet = canStageComplete(stage: stageDef, progress: progress)
        let videoMet = !stageDef.masteryCriteria.requiresVideoRecording || videoPath != nil

        if confidenceMet && drillsMet && videoMet {
            progress.currentStage = min(4, stage + 1)
            if progress.currentStage == 4 && progress.masteredAt == nil {
                progress.masteredAt = Date()
                save(progress, childId: childId)
                return StageAdvanceResult(stageAdvanced: true, moveMastered: true)
            }
            save(progress, childId: childId)
            return StageAdvanceResult(stageAdvanced: true, moveMastered: false)
        }

        save(progress, childId: childId)
        return StageAdvanceResult(stageAdvanced: false, moveMastered: false)
    }

    func unlockedMoves(childId: String) async -> [SignatureMove] {
        SignatureMoveRegistry.launchMoves.filter { getProgress(moveId: $0.id, childId: childId).isMastered }
    }

    func allProgress(childId: String) async -> [(move: SignatureMove, progress: MoveProgress)] {
        SignatureMoveRegistry.launchMoves.map { ($0, getProgress(moveId: $0.id, childId: childId)) }
    }

    // MARK: - Helpers

    private func findStageAndDrill(in move: SignatureMove, drillId: String) -> (MoveStage, MoveDrill)? {
        for stage in move.stages {
            if let drill = stage.drills.first(where: { $0.id == drillId }) {
                return (stage, drill)
            }
        }
        return nil
    }

    private func canStageComplete(stage: MoveStage, progress: MoveProgress) -> Bool {
        let completedInStage = stage.drills.filter { progress.completedDrillIds.contains($0.id) }
        let totalRepsInStage = stage.drills.reduce(0) { acc, drill in
            acc + (progress.drillReps[drill.id] ?? 0)
        }
        return completedInStage.count >= stage.masteryCriteria.requiredDrillsCompleted
            && totalRepsInStage >= stage.masteryCriteria.minTotalReps
    }

    private func key(moveId: String, childId: String) -> String {
        "move_progress_\(childId)_\(moveId)"
    }
}

struct DrillAttemptResult {
    let drillCompleted: Bool
    let stageCanComplete: Bool
    let moveCanMaster: Bool
}

struct StageAdvanceResult {
    let stageAdvanced: Bool
    let moveMastered: Bool
}
```

---

## Launch Move Registry (5 moves, fully authored)

**File: `PitchDreams/Models/SignatureMoveRegistry.swift`**

```swift
import Foundation

enum SignatureMoveRegistry {
    static let launchMoves: [SignatureMove] = [
        scissor,
        stepOver,
        bodyFeint,
        laCroqueta,
        elastico
    ]

    static func move(id: String) -> SignatureMove? {
        launchMoves.first { $0.id == id }
    }

    // The 5 moves defined below
}
```

---

### Scissor

```swift
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
```

---

### Step-Over

```swift
extension SignatureMoveRegistry {
    static let stepOver = SignatureMove(
        id: "move-step-over",
        name: "Step-Over",
        rarity: .common,
        difficulty: .beginner,
        famousFor: "Robinho's rhythm, Neymar's flair",
        description: "Circle your foot OVER the top of the ball (not around the outside) without touching it, then push off with the outside of the other foot.",
        descriptionYoung: "Lift one foot up and OVER the ball — don't touch it! Then push the ball with the outside of your other foot.",
        iconSymbolName: "figure.walk.motion",
        heroDemoAsset: "demo_stepover_hero",
        stages: [
            MoveStage(
                order: 1, phase: .groundwork,
                name: "Foot Over the Top",
                description: "The step-over isn't the scissor — the foot goes ABOVE the ball, not around the side. Learn this distinction.",
                descriptionYoung: "The step-over is different from a scissor — your foot goes OVER the top of the ball, like stepping over a line.",
                drills: [
                    MoveDrill(
                        id: "so-1-1", title: "Watch the Masters",
                        type: .watch,
                        instructions: "Watch Robinho's rhythm compilation and Neymar's flair compilation. Notice how the foot lifts and crosses over the top of the ball — a vertical motion, not horizontal.",
                        instructionsYoung: "Watch Robinho and Neymar! See how their foot goes UP and over the ball, like stepping over a puddle? That's the key.",
                        setupInstructions: nil,
                        demoVideoAsset: "demo_stepover_pros",
                        diagramAnimationAsset: "diagram_stepover_breakdown",
                        durationSeconds: 75,
                        targetReps: 1,
                        commonMistakes: [],
                        commonMistakesYoung: nil,
                        coachCues: ["Watch the foot lift.", "Crossing over the top.", "Not around — OVER."],
                        coachCuesYoung: ["Foot goes UP!", "Over the ball!", "Like stepping over a line!"],
                        enablesRecording: false
                    ),
                    MoveDrill(
                        id: "so-1-2", title: "The Cross Step",
                        type: .mimic,
                        instructions: "Imagine a ball. Lift right foot, circle it over the imaginary ball to the LEFT side, plant it there. Then push off your left foot to the right. Reverse and repeat. 40 reps.",
                        instructionsYoung: "Pretend a ball is there. Lift your right foot up and over the ball to the LEFT side. Plant it. Push off your left foot to go RIGHT. Switch! 40 times!",
                        setupInstructions: "1 meter of open space.",
                        demoVideoAsset: "demo_stepover_mimic",
                        diagramAnimationAsset: "diagram_stepover_feet",
                        durationSeconds: 120,
                        targetReps: 40,
                        commonMistakes: [
                            "Foot stays too low — lift it up over the ball, not past it.",
                            "Not crossing the centerline — the foot must go past where the ball would be."
                        ],
                        commonMistakesYoung: [
                            "Lift your foot HIGHER — over the ball, not next to it!",
                            "Your foot has to go to the OTHER side!"
                        ],
                        coachCues: ["Up and over.", "Cross the middle.", "Plant firm."],
                        coachCuesYoung: ["UP!", "Cross over!", "Plant!"],
                        enablesRecording: false
                    )
                ],
                masteryCriteria: MasteryCriteria(requiredDrillsCompleted: 2, requiredConfidence: 3, requiresVideoRecording: false, minTotalReps: 41)
            ),

            MoveStage(
                order: 2, phase: .technique,
                name: "With the Ball",
                description: "Now the ball is real. Start still, walk, then combine with the crucial escape push.",
                descriptionYoung: "Ball time! Still, then walking, then a real escape.",
                drills: [
                    MoveDrill(
                        id: "so-2-1", title: "Still Ball Step-Over",
                        type: .withBall,
                        instructions: "Ball stationary. Right foot lifts, crosses over the top of the ball, plants on the far side. Pause. Reset. 15 per foot.",
                        instructionsYoung: "Ball sits still. Right foot goes UP and OVER, plants on the other side. Stop, reset. 15 each side!",
                        setupInstructions: "Flat ground, you, a ball.",
                        demoVideoAsset: "demo_stepover_stillball",
                        diagramAnimationAsset: "diagram_stepover_still",
                        durationSeconds: 120,
                        targetReps: 30,
                        commonMistakes: [
                            "Touching the ball — foot must go ABOVE.",
                            "Planting too close to the ball — plant wider for balance."
                        ],
                        commonMistakesYoung: [
                            "Don't touch the ball with your foot!",
                            "Plant a little wider to stay balanced!"
                        ],
                        coachCues: ["Above the ball.", "Wide plant.", "Hover, don't touch."],
                        coachCuesYoung: ["Don't touch!", "Plant wide!", "Hover!"],
                        enablesRecording: false
                    ),
                    MoveDrill(
                        id: "so-2-2", title: "Step-Over + Outside Push",
                        type: .withBall,
                        instructions: "After the step-over, immediately push the ball with the OUTSIDE of the other foot. This is the actual escape. 25 clean combos, alternating feet.",
                        instructionsYoung: "After you step over, use the OUTSIDE of your other foot to push the ball AWAY. 25 times, switching feet!",
                        setupInstructions: "Flat ground, ball.",
                        demoVideoAsset: "demo_stepover_push",
                        diagramAnimationAsset: "diagram_stepover_combo",
                        durationSeconds: 180,
                        targetReps: 25,
                        commonMistakes: [
                            "Pushing with inside instead of outside — outside is faster and more natural after step-over.",
                            "Slow transition between step-over and push — they should feel like one motion."
                        ],
                        commonMistakesYoung: [
                            "Use the OUTSIDE of your foot to push, not the inside!",
                            "Make it ONE motion — step-over-push!"
                        ],
                        coachCues: ["Outside push.", "One motion.", "Flow through."],
                        coachCuesYoung: ["OUTSIDE!", "One motion!", "Flow!"],
                        enablesRecording: false
                    ),
                    MoveDrill(
                        id: "so-2-3", title: "Cone Step-Over",
                        type: .withBall,
                        instructions: "Approach a cone at jogging pace with the ball. Step-over 1m before the cone, exit to the opposite side with outside-foot push. 20 clean exits alternating sides.",
                        instructionsYoung: "Jog toward a cone with the ball. Do a step-over near the cone, then push the ball to the OTHER side. 20 times, switch sides!",
                        setupInstructions: "1 cone, 10m straight path.",
                        demoVideoAsset: "demo_stepover_cone",
                        diagramAnimationAsset: "diagram_stepover_cone_path",
                        durationSeconds: 180,
                        targetReps: 20,
                        commonMistakes: [
                            "Not selling the fake before the cone — defender can read you.",
                            "Straightening up during the step-over — stay low."
                        ],
                        commonMistakesYoung: [
                            "Make the fake BIG before the cone!",
                            "Stay low the whole time!"
                        ],
                        coachCues: ["Sell it.", "Stay low.", "Outside-foot exit."],
                        coachCuesYoung: ["Sell it!", "LOW!", "Outside foot!"],
                        enablesRecording: false
                    )
                ],
                masteryCriteria: MasteryCriteria(requiredDrillsCompleted: 3, requiredConfidence: 4, requiresVideoRecording: false, minTotalReps: 75)
            ),

            MoveStage(
                order: 3, phase: .mastery,
                name: "Double & Speed",
                description: "The Robinho special — double step-over — and full-speed corridor runs.",
                descriptionYoung: "Robinho's classic — TWO step-overs in a row — and going FAST!",
                drills: [
                    MoveDrill(
                        id: "so-3-1", title: "Double Step-Over",
                        type: .challenge,
                        instructions: "Two step-overs in rhythm (right, left, right, left — or reverse) before the exit push. 20 clean doubles. This is Robinho's signature.",
                        instructionsYoung: "TWO step-overs fast — right, left — then push away. 20 times! This is Robinho's trick!",
                        setupInstructions: "Open space, ball.",
                        demoVideoAsset: "demo_stepover_double",
                        diagramAnimationAsset: "diagram_stepover_double",
                        durationSeconds: 180,
                        targetReps: 20,
                        commonMistakes: [
                            "Too slow between step-overs — it should feel like a dance step, not a stop-go.",
                            "Losing balance — core engaged, knees bent."
                        ],
                        commonMistakesYoung: [
                            "Quick between the steps! Like dancing!",
                            "Core tight, knees bent — don't fall!"
                        ],
                        coachCues: ["Rhythm.", "Dance.", "Balance."],
                        coachCuesYoung: ["Dance!", "Fast feet!", "Balance!"],
                        enablesRecording: false
                    ),
                    MoveDrill(
                        id: "so-3-2", title: "Cone Corridor Speed",
                        type: .challenge,
                        instructions: "3 cones, 2m apart. Step-over past each. Complete 10 clean corridor runs in 90 seconds.",
                        instructionsYoung: "3 cones, 2m apart. Step-over past each one. 10 FULL runs in 90 seconds!",
                        setupInstructions: "3 cones, 2m apart, straight line.",
                        demoVideoAsset: "demo_stepover_speed",
                        diagramAnimationAsset: "diagram_stepover_cone_path",
                        durationSeconds: 90,
                        targetReps: 10,
                        commonMistakes: [
                            "Rushing between cones — slow before each.",
                            "Same exit direction every cone — alternate."
                        ],
                        commonMistakesYoung: [
                            "Slow down BEFORE each cone!",
                            "Switch sides — left, right, left!"
                        ],
                        coachCues: ["Slow-fake-fast.", "Alternate exits.", "Clean."],
                        coachCuesYoung: ["Slow, fake, FAST!", "Switch sides!", "Clean!"],
                        enablesRecording: false
                    ),
                    MoveDrill(
                        id: "so-3-3", title: "Record Your Best",
                        type: .challenge,
                        instructions: "Record a 10-second video of your best step-over sequence. Save to your Journey.",
                        instructionsYoung: "Film yourself! 10 seconds of your best step-overs!",
                        setupInstructions: "Phone propped up. Press record.",
                        demoVideoAsset: nil, diagramAnimationAsset: nil,
                        durationSeconds: 60, targetReps: 1,
                        commonMistakes: [], commonMistakesYoung: nil,
                        coachCues: ["One clean take."], coachCuesYoung: ["One good try!"],
                        enablesRecording: true
                    )
                ],
                masteryCriteria: MasteryCriteria(requiredDrillsCompleted: 2, requiredConfidence: 5, requiresVideoRecording: false, minTotalReps: 30)
            )
        ],
        coachTipYoung: "Your foot steps OVER the ball like a little hop — not around!",
        coachTip: "Vertical motion over the top of the ball, not the horizontal motion of a scissor. The outside-foot push is the actual escape."
    )
}
```

---

### Body Feint

```swift
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
```

---

### La Croqueta

**Note:** This is the move already detailed in the prior turn. The full content is preserved here for registry completeness. See the prior message for the fully-authored version.

```swift
extension SignatureMoveRegistry {
    static let laCroqueta: SignatureMove = {
        // Full definition as written previously — Iniesta's signature move.
        // Stage 1: The Watch + The Motion No Ball
        // Stage 2: Still Ball Push + Walking Croqueta + Cone Corridor
        // Stage 3: Speed Corridor + Defender Simulation + Record Yourself
        // Full content in prior spec authoring.
        // Rarity: .rare, Difficulty: .intermediate
        // (See the La Croqueta content from the previous reply — same structure as the other moves.)
        return laCroquetaFullDefinition
    }()
}
```

*(Implementer: paste the La Croqueta definition from the prior turn here, updating its `stages` to use the new `MoveStage`/`MoveDrill` structure. It already matches the pattern.)*

---

### Elastico

```swift
extension SignatureMoveRegistry {
    static let elastico = SignatureMove(
        id: "move-elastico",
        name: "Elastico",
        rarity: .rare,
        difficulty: .intermediate,
        famousFor: "Ronaldinho's rubber-band whip",
        description: "Push the ball sideways with the OUTSIDE of one foot, then snap it back with the INSIDE of the same foot — one fluid motion, one foot planted. Looks like a rubber band stretching and snapping.",
        descriptionYoung: "Flick the ball OUT with the side of your foot, then snap it back IN — super fast! Like a rubber band!",
        iconSymbolName: "arrow.uturn.left.circle",
        heroDemoAsset: "demo_elastico_hero",
        stages: [
            MoveStage(
                order: 1, phase: .groundwork,
                name: "The Flick Motion",
                description: "The elastico uses one foot to do two opposite things in one motion: outside-push, inside-pull. Your foot must be relaxed and mobile.",
                descriptionYoung: "The elastico is one foot doing TWO things — push out, then pull back. Your ankle has to be bendy!",
                drills: [
                    MoveDrill(
                        id: "el-1-1", title: "Watch Ronaldinho's Magic",
                        type: .watch,
                        instructions: "Watch Ronaldinho's and Denílson's elastico highlights. Pay attention: one foot, staying planted, does the whole move. Notice how the ankle flexes.",
                        instructionsYoung: "Watch Ronaldinho! Look closely — it's just ONE foot doing everything. His ankle wiggles like a noodle!",
                        setupInstructions: nil,
                        demoVideoAsset: "demo_elastico_ronaldinho",
                        diagramAnimationAsset: "diagram_elastico_breakdown",
                        durationSeconds: 90,
                        targetReps: 1,
                        commonMistakes: [], commonMistakesYoung: nil,
                        coachCues: ["One foot.", "Ankle flex.", "Outside then inside."],
                        coachCuesYoung: ["ONE foot!", "Bendy ankle!", "Out-IN!"],
                        enablesRecording: false
                    ),
                    MoveDrill(
                        id: "el-1-2", title: "Ankle Flick, No Ball",
                        type: .mimic,
                        instructions: "Stand on your left foot. Lift right foot 2 inches off the ground. Flick your right foot outside (ankle bends outward), then snap it inside (ankle rolls inward). Do 40 reps. Switch to left foot.",
                        instructionsYoung: "Stand on one foot. Lift the other just a little. Flick your ankle OUT, then IN. 40 times! Switch feet.",
                        setupInstructions: "Small space. No ball needed.",
                        demoVideoAsset: "demo_elastico_ankle",
                        diagramAnimationAsset: "diagram_elastico_ankle",
                        durationSeconds: 120,
                        targetReps: 80,
                        commonMistakes: [
                            "Using the whole leg — it's an ankle motion, not a hip motion.",
                            "Tense ankle — must be loose and springy."
                        ],
                        commonMistakesYoung: [
                            "Just your ANKLE, not your whole leg!",
                            "Keep your ankle LOOSE — no stiff!"
                        ],
                        coachCues: ["Ankle only.", "Loose.", "Fast flick."],
                        coachCuesYoung: ["ANKLE!", "Loose!", "Fast flick!"],
                        enablesRecording: false
                    )
                ],
                masteryCriteria: MasteryCriteria(requiredDrillsCompleted: 2, requiredConfidence: 3, requiresVideoRecording: false, minTotalReps: 81)
            ),

            MoveStage(
                order: 2, phase: .technique,
                name: "With the Ball",
                description: "Now add the ball. Start by mastering the outside push alone, then add the inside snap-back, then combine everything.",
                descriptionYoung: "Ball time! First learn to push OUT, then learn to pull IN, then put them together.",
                drills: [
                    MoveDrill(
                        id: "el-2-1", title: "Outside Push Only",
                        type: .withBall,
                        instructions: "Ball in front of right foot. Use ONLY outside of right foot to push ball right about 30cm. Reset. 20 reps. Switch to left foot.",
                        instructionsYoung: "Ball in front. Use the OUTSIDE (pinky-toe side) of your right foot to push the ball right. Reset. 20 times! Then left foot.",
                        setupInstructions: "Flat ground, ball.",
                        demoVideoAsset: "demo_elastico_outside",
                        diagramAnimationAsset: "diagram_elastico_outside",
                        durationSeconds: 150,
                        targetReps: 40,
                        commonMistakes: [
                            "Using toes instead of outside — must be the outside bone area.",
                            "Ball travels too far — 30cm is enough."
                        ],
                        commonMistakesYoung: [
                            "Use the outside of your foot, not your toes!",
                            "Small push — not a big kick!"
                        ],
                        coachCues: ["Outside bone.", "Short push.", "Reset."],
                        coachCuesYoung: ["Outside!", "Small push!", "Reset!"],
                        enablesRecording: false
                    ),
                    MoveDrill(
                        id: "el-2-2", title: "The Snap-Back",
                        type: .withBall,
                        instructions: "Put the ball 30cm to the right of your right foot. Snap ball back to center using the INSIDE of your right foot. 20 reps per foot.",
                        instructionsYoung: "Put the ball a little to the right. Use the INSIDE of your foot to snap it back. 20 each side!",
                        setupInstructions: "Flat ground.",
                        demoVideoAsset: "demo_elastico_inside",
                        diagramAnimationAsset: "diagram_elastico_inside",
                        durationSeconds: 150,
                        targetReps: 40,
                        commonMistakes: [
                            "Slow snap — must be sharp.",
                            "Using whole leg — foot rotation only."
                        ],
                        commonMistakesYoung: [
                            "SHARP snap-back!",
                            "Just your foot, not your leg!"
                        ],
                        coachCues: ["Sharp.", "Foot rotation.", "Snap."],
                        coachCuesYoung: ["Sharp!", "Foot twist!", "Snap!"],
                        enablesRecording: false
                    ),
                    MoveDrill(
                        id: "el-2-3", title: "Full Elastico Slow",
                        type: .withBall,
                        instructions: "Put both motions together SLOWLY. Outside-push right, then inside-snap back. All with one foot. 25 reps per foot. Slower is better while learning.",
                        instructionsYoung: "Put it together SLOW. Outside push, then inside snap. ONE foot. 25 each side. Slow is good!",
                        setupInstructions: "Flat ground.",
                        demoVideoAsset: "demo_elastico_slow",
                        diagramAnimationAsset: "diagram_elastico_combined",
                        durationSeconds: 180,
                        targetReps: 50,
                        commonMistakes: [
                            "Rushing — slow is how you learn, fast is how you show off.",
                            "Foot leaves the ground between push and snap — should stay connected."
                        ],
                        commonMistakesYoung: [
                            "SLOW! Slow is how you learn!",
                            "Keep your foot close — don't lift it up!"
                        ],
                        coachCues: ["Slow.", "Foot stays down.", "Out-in."],
                        coachCuesYoung: ["SLOW!", "Foot down!", "Out-IN!"],
                        enablesRecording: false
                    )
                ],
                masteryCriteria: MasteryCriteria(requiredDrillsCompleted: 3, requiredConfidence: 4, requiresVideoRecording: false, minTotalReps: 125)
            ),

            MoveStage(
                order: 3, phase: .mastery,
                name: "Snap at Speed",
                description: "The elastico is worthless slow — speed is the whole point. Full-game-speed execution.",
                descriptionYoung: "The elastico only works FAST. Now make it quick and sneaky!",
                drills: [
                    MoveDrill(
                        id: "el-3-1", title: "Speed Elastico",
                        type: .challenge,
                        instructions: "Full-speed elastico in place. 20 per foot as fast as you can while staying clean. Clean = outside push, ball returns, single smooth motion.",
                        instructionsYoung: "Full speed! 20 elasticos per foot, as fast as you can do them CLEAN!",
                        setupInstructions: "Open space, ball.",
                        demoVideoAsset: "demo_elastico_speed",
                        diagramAnimationAsset: nil,
                        durationSeconds: 180,
                        targetReps: 40,
                        commonMistakes: [
                            "Losing the ball at speed — slow down if you can't stay clean.",
                            "Push is too hard at speed — still needs to be controlled."
                        ],
                        commonMistakesYoung: [
                            "If you lose the ball, slow down!",
                            "Quick but CONTROLLED!"
                        ],
                        coachCues: ["Clean speed.", "Control.", "Crisp."],
                        coachCuesYoung: ["Clean fast!", "Control!", "Crisp!"],
                        enablesRecording: false
                    ),
                    MoveDrill(
                        id: "el-3-2", title: "Walking Elastico",
                        type: .challenge,
                        instructions: "Walking forward at jogging pace. Every 4 steps, execute an elastico and cut the other direction. 15 clean cuts alternating feet.",
                        instructionsYoung: "Jog forward. Every few steps, do an elastico and change direction! 15 cuts!",
                        setupInstructions: "10m straight path.",
                        demoVideoAsset: "demo_elastico_walking",
                        diagramAnimationAsset: "diagram_elastico_path",
                        durationSeconds: 180,
                        targetReps: 15,
                        commonMistakes: [
                            "Stopping to execute — must happen while moving.",
                            "Ball flies away — too much push at walking pace."
                        ],
                        commonMistakesYoung: [
                            "Don't stop to do it — KEEP MOVING!",
                            "Gentler push when walking!"
                        ],
                        coachCues: ["Keep moving.", "Smooth flow.", "Cut."],
                        coachCuesYoung: ["Keep going!", "Smooth!", "Cut!"],
                        enablesRecording: false
                    ),
                    MoveDrill(
                        id: "el-3-3", title: "Record Your Best",
                        type: .challenge,
                        instructions: "Record 10 seconds of your best elastico sequence. Save to Journey.",
                        instructionsYoung: "Film yourself! 10 seconds of elasticos!",
                        setupInstructions: "Phone propped, record.",
                        demoVideoAsset: nil, diagramAnimationAsset: nil,
                        durationSeconds: 60, targetReps: 1,
                        commonMistakes: [], commonMistakesYoung: nil,
                        coachCues: ["One clean take."], coachCuesYoung: ["One good try!"],
                        enablesRecording: true
                    )
                ],
                masteryCriteria: MasteryCriteria(requiredDrillsCompleted: 2, requiredConfidence: 5, requiresVideoRecording: false, minTotalReps: 55)
            )
        ],
        coachTipYoung: "ONE foot! Push OUT, then snap IN — like a rubber band!",
        coachTip: "Single-foot execution. Outside push then inside snap-back, no foot replant between motions. Ankle flexibility is the key."
    )
}
```

---

## Learning-Flow UI (New Screens)

The learning flow is a multi-screen experience, not a single detail page.

### Screen Flow

```
LIBRARY (grid)
    │ tap a move
    ▼
MOVE OVERVIEW
    │ tap "Begin Stage X"
    ▼
STAGE INTRO
    │ tap "Start Drill 1"
    ▼
DRILL PLAYER  ◄──┐
    │ complete reps│
    ▼             │
DRILL COMPLETE  ──┤ "Next Drill" loops back
    │ all drills done
    ▼
CONFIDENCE CHECK
    │ 3+ stars + drills met?
    ▼
STAGE COMPLETE (celebration, XP)
    │ if stage == 3 && video required/recorded
    ▼
RECORD YOURSELF (optional capstone)
    │ save recording
    ▼
MOVE MASTERED (full celebration)
    │ "Add to Player Card" CTA
    ▼
PLAYER CARD EDITOR (loadout picker)
```

### New View Files

**`PitchDreams/Features/SignatureMoves/Views/SignatureMoveOverviewView.swift`**

> **PREREQUISITE: `signature_move_overview` Stitch mockup.**

The hero entry point after tapping a move in the library.

Contents:
- Top: Large hero video/animation area (`heroDemoAsset`) with play/pause, speed toggle (1x/0.5x), loop toggle
- Title + rarity badge + difficulty tag
- "Famous for" quote with pro name
- Description (age-adapted)
- 3-stage progress stepper vertically: each stage shows icon, name, phase label, completion status, target drill count
- Current-stage CTA at bottom: "Begin Stage 1: Groundwork" (or "Continue Stage 2", or "Review & Master" if already done)
- Coach tip card below progress (age-adapted)

**`PitchDreams/Features/SignatureMoves/Views/SignatureMoveStageIntroView.swift`**

> **PREREQUISITE: `signature_move_stage_intro` Stitch mockup.**

Shown before the first drill in a stage.

Contents:
- Stage header: "Stage X: [Name]" with phase icon (eye for groundwork, ball for technique, flame for mastery)
- Stage description (age-adapted)
- List of drills in this stage as numbered cards:
  - Drill title
  - Drill type icon (watch/mimic/withBall/challenge)
  - Target reps
  - Duration
  - Completed checkmark if already done
- Primary CTA: "Start Drill 1: [title]"
- Secondary link: "Review previous stages"

**`PitchDreams/Features/SignatureMoves/Views/SignatureMoveDrillPlayerView.swift`**

> **PREREQUISITE: `signature_move_drill_player_*` Stitch mockups — 4 variants per drill type.**

The core drill execution screen. UI varies by `drill.type`:

#### Type: `.watch`
- Full-width video player with playback controls (play/pause, scrub, speed, replay)
- Coach narration overlay at bottom with drill instructions
- Coach cues appear as captions during key moments (author cues with timestamps eventually; for MVP, all cues speak evenly across duration)
- Haptic "tick" when each coach cue speaks
- "I've watched this" button appears after video ends
- Coach tip card below player

#### Type: `.mimic`
- Large animated figure or diagram demonstrating the motion (looping)
- Timer counting UP (not down — some kids are slower)
- Tap-to-count rep counter (big round button — kid taps each rep)
- Target reps shown as progress ring around counter
- Haptic metronome option (taps phone rhythmically — `.light` intensity, adjustable pace)
- Voice coach cues pipe in every 10-15 seconds from `drill.coachCuesYoung` (age-adapted), random selection
- Common mistakes card below: swipes through `drill.commonMistakes`, one at a time, every 20 seconds
- "I'm done" button (grayed until target reps hit)

#### Type: `.withBall`
- Top: Setup instructions card ("Set up 3 cones 2m apart") with a "Ready" confirmation button
- Middle: Short demo loop (if available) or animated diagram
- Bottom: Timer + rep counter (same as mimic)
- Coach cues + common mistakes rotate similarly
- "I'm done" button

#### Type: `.challenge`
- Header: challenge type indicator ("⏱️ TIMED" or "🎯 PRECISION" or "🛡️ DEFENDER SIM")
- Countdown (3...2...1...GO!) at start with haptic crescendo
- Timer counting down (or up, depending on drill)
- Rep counter
- Live cue toast system — cues from `coachCues` array fire every 10-15 seconds
- Final screen: clean-rep count, time, "Try Again" or "I'm done"
- If `enablesRecording == true`: camera capture flow (see Record Yourself screen)

**`PitchDreams/Features/SignatureMoves/Views/SignatureMoveDrillCompleteView.swift`**

> **PREREQUISITE: `signature_move_drill_complete` Stitch mockup.**

Shown after finishing a drill.

Contents:
- Big checkmark animation + haptic success
- "Drill Complete!" + drill name
- Stats: reps completed (with count-up animation), time taken
- "How did that feel?" confidence stars (1-5) — saved to progress
- If more drills in stage: "Next Drill: [title]" primary CTA
- If last drill in stage: "Complete Stage" primary CTA → proceeds to confidence check
- Secondary: "Try Again" (re-attempt current drill for more reps)

**`PitchDreams/Features/SignatureMoves/Views/SignatureMoveStageCompleteView.swift`**

> **PREREQUISITE: `signature_move_stage_complete` Stitch mockup.**

Celebration for completing a stage (not the full move).

Contents:
- Stage name with phase icon in rarity color
- "+X XP earned" with count-up
- Summary: drills completed, total reps, time invested in this stage
- Next stage preview: "Next: Stage 2 — Technique" with brief description
- Primary CTA: "Begin Stage 2" or "Finish and Return Later"
- Moderate confetti (save the big celebration for full mastery)

**`PitchDreams/Features/SignatureMoves/Views/SignatureMoveRecordSelfView.swift`**

> **PREREQUISITE: `signature_move_record_self` Stitch mockup.**

Optional capstone in the final stage.

Contents:
- Pre-record screen: "Film yourself doing [move name]. We'll save it to your Journey."
- Camera preview (rear camera default, user can flip to front)
- Countdown: 3-2-1 with haptic pulses
- Recording: 10 seconds auto-stop with progress ring
- Review: playback with "Save" / "Retake" / "Skip this" options
- Save target: `FileManager` Documents directory, path saved to `MoveProgress.recordedVideoPath`
- Privacy note: "This video stays on your device. Only you and your parents can see it."

**`PitchDreams/Features/SignatureMoves/Views/SignatureMoveUnlockedView.swift`** (already exists in prior spec)

No change — the big celebration for full mastery. Now it triggers after `SignatureMoveRecordSelfView` (if recording happened) or directly after stage 3 completion (if recording skipped).

### ViewModel Additions

**`PitchDreams/Features/SignatureMoves/ViewModels/SignatureMoveLearningViewModel.swift`** (new)

Orchestrates the learning flow across all screens:

```swift
@MainActor
final class SignatureMoveLearningViewModel: ObservableObject {
    enum FlowStep: Equatable {
        case overview
        case stageIntro(stage: Int)
        case drillPlayer(stage: Int, drillId: String)
        case drillComplete(stage: Int, drillId: String)
        case stageComplete(stage: Int)
        case recordSelf(stage: Int)
        case mastered
    }

    @Published var currentStep: FlowStep = .overview
    @Published var progress: MoveProgress
    @Published var currentDrillReps: Int = 0
    @Published var currentDrillTime: Int = 0   // seconds elapsed
    @Published var currentCue: String?
    @Published var currentMistakeIndex: Int = 0
    @Published var feverTimeActive: Bool = false

    let move: SignatureMove
    let childId: String
    let childAge: Int?
    private let store: SignatureMoveStore
    private let xpStore: XPStore
    private let voice: CoachVoiceProtocol
    private var cueTimer: Timer?
    private var mistakeTimer: Timer?

    init(
        move: SignatureMove,
        childId: String,
        childAge: Int? = nil,
        store: SignatureMoveStore = SignatureMoveStore(),
        xpStore: XPStore = XPStore(),
        voice: CoachVoiceProtocol = CoachVoice()
    ) {
        self.move = move
        self.childId = childId
        self.childAge = childAge
        self.store = store
        self.xpStore = xpStore
        self.voice = voice
        self.progress = MoveProgress(
            moveId: move.id, currentStage: 1,
            completedDrillIds: [], drillReps: [:], stageConfidenceRatings: [:],
            recordedVideoPath: nil, masteredAt: nil, lastAttemptAt: nil
        )
    }

    func load() async {
        progress = await store.getProgress(moveId: move.id, childId: childId)
    }

    private var isYoung: Bool { (childAge ?? 12) <= 11 }

    func beginStage(_ order: Int) {
        currentStep = .stageIntro(stage: order)
    }

    func startDrill(stage: Int, drillId: String) {
        currentDrillReps = 0
        currentDrillTime = 0
        currentMistakeIndex = 0
        currentStep = .drillPlayer(stage: stage, drillId: drillId)
        startCueLoop(stage: stage, drillId: drillId)
        startMistakeLoop(stage: stage, drillId: drillId)
    }

    func incrementRep() {
        currentDrillReps += 1
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    func completeDrill() async {
        cueTimer?.invalidate()
        mistakeTimer?.invalidate()
        guard case let .drillPlayer(stage, drillId) = currentStep else { return }
        let result = await store.recordDrillAttempt(
            moveId: move.id, drillId: drillId,
            reps: currentDrillReps, childId: childId
        )
        currentStep = .drillComplete(stage: stage, drillId: drillId)
    }

    func advanceStage(confidence: Int, videoPath: String? = nil) async {
        guard case let .stageComplete(stage) = currentStep else {
            // handle from drill complete when last drill
            return
        }
        let result = await store.recordStageConfidence(
            moveId: move.id, stage: stage, confidence: confidence,
            videoPath: videoPath, childId: childId
        )
        if result.moveMastered {
            // Award mastery XP
            _ = await xpStore.addXP(move.rarity.masteryXP, childId: childId)
            currentStep = .mastered
        } else if result.stageAdvanced {
            _ = await xpStore.addXP(move.rarity.stageXP, childId: childId)
            currentStep = .overview  // return to overview to begin next stage
        }
        progress = await store.getProgress(moveId: move.id, childId: childId)
    }

    private func startCueLoop(stage: Int, drillId: String) {
        guard let drill = findDrill(stage: stage, drillId: drillId) else { return }
        let cues = isYoung ? (drill.coachCuesYoung ?? drill.coachCues) : drill.coachCues
        guard !cues.isEmpty else { return }
        cueTimer = Timer.scheduledTimer(withTimeInterval: 12, repeats: true) { [weak self] _ in
            guard let self else { return }
            let cue = cues.randomElement() ?? ""
            Task { @MainActor in
                self.currentCue = cue
                self.voice.speak(cue)
            }
        }
    }

    private func startMistakeLoop(stage: Int, drillId: String) {
        guard let drill = findDrill(stage: stage, drillId: drillId) else { return }
        let mistakes = isYoung ? (drill.commonMistakesYoung ?? drill.commonMistakes) : drill.commonMistakes
        guard !mistakes.isEmpty else { return }
        mistakeTimer = Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.currentMistakeIndex = (self.currentMistakeIndex + 1) % mistakes.count
            }
        }
    }

    private func findDrill(stage: Int, drillId: String) -> MoveDrill? {
        move.stages.first(where: { $0.order == stage })?
            .drills.first(where: { $0.id == drillId })
    }

    // Helper getters for views
    func instructions(for drill: MoveDrill) -> String {
        if isYoung, let y = drill.instructionsYoung { return y }
        return drill.instructions
    }

    func currentMistake(for drill: MoveDrill) -> String? {
        let mistakes = isYoung ? (drill.commonMistakesYoung ?? drill.commonMistakes) : drill.commonMistakes
        guard !mistakes.isEmpty else { return nil }
        return mistakes[currentMistakeIndex % mistakes.count]
    }

    deinit {
        cueTimer?.invalidate()
        mistakeTimer?.invalidate()
    }
}
```

### View Coordination

**`PitchDreams/Features/SignatureMoves/Views/SignatureMoveLearningContainer.swift`** (new)

Top-level container that switches between screens based on `viewModel.currentStep`:

```swift
struct SignatureMoveLearningContainer: View {
    @StateObject var viewModel: SignatureMoveLearningViewModel

    var body: some View {
        ZStack {
            Color.dsBackground.ignoresSafeArea()
            switch viewModel.currentStep {
            case .overview:
                SignatureMoveOverviewView(viewModel: viewModel)
            case .stageIntro(let stage):
                SignatureMoveStageIntroView(viewModel: viewModel, stage: stage)
            case .drillPlayer(let stage, let drillId):
                SignatureMoveDrillPlayerView(viewModel: viewModel, stage: stage, drillId: drillId)
            case .drillComplete(let stage, let drillId):
                SignatureMoveDrillCompleteView(viewModel: viewModel, stage: stage, drillId: drillId)
            case .stageComplete(let stage):
                SignatureMoveStageCompleteView(viewModel: viewModel, stage: stage)
            case .recordSelf(let stage):
                SignatureMoveRecordSelfView(viewModel: viewModel, stage: stage)
            case .mastered:
                SignatureMoveUnlockedView(move: viewModel.move) {
                    // dismiss or nav to Player Card editor
                }
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.currentStep)
        .task { await viewModel.load() }
    }
}
```

---

## Stitch Mockups Required

Previously 6 Signature Moves mockups in the Track E spec. Updated to:

| Mockup | Priority | Screen |
|--------|----------|--------|
| `signature_moves_library` | P0 | Library grid |
| `signature_move_overview` | P0 | Move entry point with progress stepper |
| `signature_move_stage_intro` | P0 | Before-drills summary per stage |
| `signature_move_drill_player_watch` | P0 | Watch-type drill UI |
| `signature_move_drill_player_mimic` | P0 | No-ball mimic drill UI |
| `signature_move_drill_player_withBall` | P0 | With-ball drill UI |
| `signature_move_drill_player_challenge` | P0 | Challenge drill UI |
| `signature_move_drill_complete` | P0 | Post-drill confidence rating |
| `signature_move_stage_complete` | P0 | Mid-journey celebration |
| `signature_move_record_self` | P1 | Optional video capture |
| `signature_move_unlocked_celebration` | P0 | Final mastery celebration |

Total: **11 Stitch mockups** for Signature Moves (up from 6).

---

## Files to Create / Modify

### Replace in Track E spec
```
PitchDreams/Models/SignatureMove.swift                                  (expanded model)
PitchDreams/Models/SignatureMoveRegistry.swift                          (5 moves fully authored)
PitchDreams/Core/Persistence/SignatureMoveStore.swift                   (new drill/stage logic)
```

### New files
```
PitchDreams/Features/SignatureMoves/Views/
  SignatureMoveLearningContainer.swift
  SignatureMoveOverviewView.swift
  SignatureMoveStageIntroView.swift
  SignatureMoveDrillPlayerView.swift
  SignatureMoveDrillCompleteView.swift
  SignatureMoveStageCompleteView.swift
  SignatureMoveRecordSelfView.swift

PitchDreams/Features/SignatureMoves/ViewModels/
  SignatureMoveLearningViewModel.swift

PitchDreams/Features/SignatureMoves/Views/DrillPlayers/
  WatchDrillPlayerView.swift
  MimicDrillPlayerView.swift
  WithBallDrillPlayerView.swift
  ChallengeDrillPlayerView.swift
```

### Tests (updated)
```
PitchDreamsTests/Core/SignatureMoveStoreTests.swift
  + testRecordDrillAttempt_addsReps
  + testRecordDrillAttempt_drillCompleteAtTarget
  + testStageCompletesWhenDrillsAndRepsMet
  + testRecordStageConfidence_belowThreshold_doesNotAdvance
  + testRecordStageConfidence_meetsThreshold_advances
  + testFinalStageMastery_requiresVideoIfFlagSet

PitchDreamsTests/Features/SignatureMoveLearningViewModelTests.swift
  + testIncrementRep_updatesCount
  + testCompleteDrill_transitionsToDrillComplete
  + testYoungUser_getsYoungInstructions
  + testCueLoop_firesAtInterval
  + testAdvanceStage_masteryTriggersXPAward
```

---

## Post-Launch Move Release Cadence

Launch with 5 fully-authored moves. Release 1 additional move every 3-4 weeks. Full schedule:

| Release | Move | Rarity | Weeks after launch |
|---------|------|--------|--------------------|
| Launch | Scissor, Step-Over, Body Feint, La Croqueta, Elastico | common/rare | 0 |
| Release 1 | Rainbow Flick | common | +3 |
| Release 2 | Rabona | rare | +6 |
| Release 3 | Maradona Turn | epic | +10 |
| Release 4 | Zidane Roulette | epic | +14 |
| Release 5 | Scorpion Kick | legendary | +18 (seasonal event) |
| Release 6 | V-Move (Cruyff Turn) | common | +22 |
| Release 7 | Fake Shot | common | +26 |
| Release 8 | Behind-the-Leg | rare | +30 |

Each release gets:
- In-app announcement banner
- Push notification to active users
- Social post with demo clip
- First 48 hours: 2x XP bonus on that move's drills

This turns move releases into re-engagement events.

---

## Content Production Estimate

Per move, authored to La Croqueta depth:
- 8 drills written (with instructions, young variants, mistakes, cues)
- 8 demo videos OR animated diagrams
- ~24 coach cues (both age variants)
- ~15 common mistakes (both age variants)

**Production options for demo videos:**

**Option A: Animated diagrams only (MVP)** — Extend the existing `AnimatedTacticalPitchView` Canvas system with move-specific choreography. Faster to produce, lower fidelity. 2-3 hours per move for diagram animation.

**Option B: Single shoot day** — Commission a local college player or coach to demonstrate all 5 moves. Multiple angles, multiple speeds, close-ups of feet. Budget ~$500-1500 for shoot + editing. 1 shoot day yields all 40 demo clips.

**Option C: Licensed pro footage** — Expensive, slow, often rights-restricted. Defer post-launch.

**Recommendation:** Launch with Option A (animated diagrams). Replace with Option B in Month 1 post-launch.

### Content effort summary

| Task | Time |
|------|------|
| Expanded data model implementation | 1 day |
| Registry content authoring (5 moves × ~3 hours each) | 2 days |
| Animated diagrams for each drill (MVP) | 3-4 days |
| Learning flow UI implementation (8 new views) | 4-5 days |
| View model orchestration | 1 day |
| Tests | 1-2 days |
| **Total for Signature Moves deep implementation** | **~12-15 days** |

This is up from the original 5-7 day estimate. Reflects the real scope of a technique-teaching system.

**If time-constrained:** Ship 3 moves at launch (Scissor, Body Feint, La Croqueta — different rarities for variety) instead of 5. Reduces content effort to ~8-10 days.

---

## Success Criteria

### Content
- [ ] 5 moves fully authored with 8 drills each (40 total drills)
- [ ] Every drill has: instructions (standard + young), setup instructions, common mistakes (standard + young), coach cues (standard + young)
- [ ] Every drill has at least an animated diagram (video is post-launch upgrade)
- [ ] Every move has a hero demo video/animation for Overview screen

### Engine
- [ ] Expanded `MoveStage`/`MoveDrill` data model implemented
- [ ] `SignatureMoveStore` supports per-drill rep tracking and stage-completion logic
- [ ] `SignatureMoveLearningViewModel` orchestrates flow between all learning screens
- [ ] Age-adaptive content serves correct variant based on `childAge`
- [ ] Coach voice speaks cues at correct intervals with correct age variant

### UI
- [ ] All 11 Stitch mockups created and implemented
- [ ] 4 drill-type variants render correctly
- [ ] Rep counter + timer + cue toast work in all 4 types
- [ ] Record Yourself flow captures 10-sec video, saves to Documents, updates progress
- [ ] Stage completion awards correct rarity-tier XP
- [ ] Mastery celebration uses rarity-based visual treatment

### The Real Test (Usability)
- [ ] A 10-year-old test user can complete a full stage (Scissor Stage 1: Watch + Mimic) without parent intervention
- [ ] A 13-year-old test user can master at least one full move in 3 training sessions
- [ ] Test users can EXECUTE the technique in real play after mastering it in-app (the actual goal — not just completing drills, but learning the move)

The last criterion is the real one. A kid who completes all drills but still can't do a scissor in a game means the system failed. Include this in beta testing.
