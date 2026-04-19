import Foundation

/// One of the app's collectible + teachable signature moves. Each move is
/// a full technique-teaching journey with three stages of mastery — not a
/// drill-completion checkbox.
///
/// Authored in `SignatureMoveRegistry`; progress tracked in
/// `SignatureMoveStore`. View flow is orchestrated by
/// `SignatureMoveLearningViewModel`.
struct SignatureMove: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let rarity: MoveRarity
    let difficulty: MoveDifficulty
    let famousFor: String
    let description: String
    let descriptionYoung: String?
    let iconSymbolName: String
    let heroDemoAsset: String?           // main teaching video/animation
    let stages: [MoveStage]              // always 3 stages — groundwork / technique / mastery
    let coachTipYoung: String
    let coachTip: String
}

enum MoveRarity: String, Codable, CaseIterable, Identifiable {
    case common
    case rare
    case epic
    case legendary

    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }

    var accentColorHex: String {
        switch self {
        case .common:    return "#94A3B8"  // slate
        case .rare:      return "#46E5F8"  // cyan
        case .epic:      return "#A855F7"  // purple
        case .legendary: return "#FFE9BD"  // gold
        }
    }

    /// Bonus XP for full mastery (all 3 stages complete).
    var masteryXP: Int {
        switch self {
        case .common:    return 100
        case .rare:      return 250
        case .epic:      return 500
        case .legendary: return 1000
        }
    }

    /// Bonus XP awarded on completing a non-final stage (1 or 2).
    var stageXP: Int {
        switch self {
        case .common:    return 25
        case .rare:      return 50
        case .epic:      return 100
        case .legendary: return 200
        }
    }
}

enum MoveDifficulty: String, Codable, CaseIterable, Identifiable {
    case beginner, intermediate, advanced
    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
}

// MARK: - Stages

enum LearningPhase: String, Codable {
    case groundwork   // Watch + mimic (no ball or still ball only)
    case technique    // With ball — progressive move-specific drills
    case mastery      // Pressure / speed / defender sim / optional recording

    var displayName: String {
        switch self {
        case .groundwork: return "Groundwork"
        case .technique:  return "Technique"
        case .mastery:    return "Mastery"
        }
    }

    /// SF Symbol name for the phase icon.
    var iconSymbol: String {
        switch self {
        case .groundwork: return "eye.fill"
        case .technique:  return "soccerball"
        case .mastery:    return "flame.fill"
        }
    }
}

struct MoveStage: Codable, Equatable, Identifiable {
    let order: Int                       // 1, 2, 3
    let phase: LearningPhase
    let name: String
    let description: String
    let descriptionYoung: String?
    let drills: [MoveDrill]
    let masteryCriteria: MasteryCriteria

    var id: Int { order }
}

struct MasteryCriteria: Codable, Equatable {
    let requiredDrillsCompleted: Int
    let requiredConfidence: Int          // 1-5 self-reported after stage
    let requiresVideoRecording: Bool
    let minTotalReps: Int
}

enum MoveDrillType: String, Codable {
    case watch         // Video / animation playback — no user action
    case mimic         // No ball — practice the motion itself
    case withBall      // Introduce ball, still or walking
    case challenge     // Under pressure: timed, cones, simulated defender

    var iconSymbol: String {
        switch self {
        case .watch:     return "play.rectangle.fill"
        case .mimic:     return "figure.walk.motion"
        case .withBall:  return "soccerball"
        case .challenge: return "flame.fill"
        }
    }

    var displayName: String {
        switch self {
        case .watch:     return "Watch"
        case .mimic:     return "Mimic"
        case .withBall:  return "With Ball"
        case .challenge: return "Challenge"
        }
    }
}

struct MoveDrill: Codable, Equatable, Identifiable {
    let id: String
    let title: String
    let type: MoveDrillType
    let instructions: String             // 12+ version
    let instructionsYoung: String?        // 8-11 version
    let setupInstructions: String?        // "Set up 3 cones 2m apart" — nil for no equipment
    let demoVideoAsset: String?
    let diagramAnimationAsset: String?
    let durationSeconds: Int
    let targetReps: Int
    let commonMistakes: [String]
    let commonMistakesYoung: [String]?
    let coachCues: [String]               // prompts during drill: "Low!", "Snap!"
    let coachCuesYoung: [String]?
    let enablesRecording: Bool            // the "record yourself" capstone
}

// MARK: - Progress

/// A user's progress on a single move. One `MoveProgress` record per
/// (childId, moveId) pair, persisted in `SignatureMoveStore`.
struct MoveProgress: Codable, Equatable {
    let moveId: String
    var currentStage: Int                 // 0 = locked, 1-3 = stage in progress, 4 = mastered
    var completedDrillIds: Set<String>
    var drillReps: [String: Int]           // drillId -> cumulative reps
    var stageConfidenceRatings: [Int: Int] // stage -> 1-5 confidence
    var recordedVideoPath: String?
    var masteredAt: Date?
    var lastAttemptAt: Date?

    var isMastered: Bool { masteredAt != nil }
    var isLocked: Bool { currentStage == 0 }

    static func initial(for moveId: String) -> MoveProgress {
        MoveProgress(
            moveId: moveId,
            currentStage: 1,
            completedDrillIds: [],
            drillReps: [:],
            stageConfidenceRatings: [:],
            recordedVideoPath: nil,
            masteredAt: nil,
            lastAttemptAt: nil
        )
    }
}

// MARK: - Store result types

struct DrillAttemptResult: Equatable {
    let drillCompleted: Bool
    let stageCanComplete: Bool
}

struct StageAdvanceResult: Equatable {
    let stageAdvanced: Bool
    let moveMastered: Bool
}
