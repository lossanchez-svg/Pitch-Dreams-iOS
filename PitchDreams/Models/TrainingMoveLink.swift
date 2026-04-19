import Foundation

/// Maps regular training drills (`DrillRegistry.DrillDefinition.id`) to
/// Signature Move stages that they reinforce. Drives the ambient
/// credit-from-training wire: when a kid completes a normal session with
/// drills on this list, in-progress signature moves get a small rep bump
/// toward their current stage — never enough to replace the dedicated
/// learning flow, but enough to make training feel connected to moves.
///
/// Only authored moves (Scissor / Body Feint / La Croqueta at launch) are
/// wired. Placeholder moves pick up mappings when their content ships.
enum TrainingMoveLink {
    /// `[moveId: [stageOrder: set of training drill ids]]`.
    static let map: [String: [Int: Set<String>]] = [
        "move-scissor": [
            1: ["bm-sole-rolls", "bm-toe-taps"],         // groundwork: touch, quickness
            2: ["bm-foundation", "drib-cones"],            // technique: with-ball rhythm
            3: ["drib-1v1-moves"]                          // mastery: 1v1 at speed
        ],
        "move-body-feint": [
            1: ["bm-toe-taps"],
            2: ["drib-cones", "drib-1v1-moves"],
            3: ["drib-1v1-moves"]
        ],
        "move-la-croqueta": [
            1: ["bm-toe-taps", "bm-sole-rolls"],
            2: ["bm-foundation", "pass-wall"],
            3: ["drib-cones", "drib-1v1-moves"]
        ]
    ]

    /// Reps awarded per matching drill. Deliberately small so regular
    /// training reinforces moves but never replaces the learning flow.
    static let repsPerMatch: Int = 5

    /// For a given list of training-drill ids completed in a session,
    /// return which signature-move stages should be credited.
    /// The caller still has to know each move's current stage to decide
    /// whether to credit (we only credit the current stage).
    static func matches(trainingDrillIds: [String]) -> [(moveId: String, stage: Int)] {
        var results: [(moveId: String, stage: Int)] = []
        let ids = Set(trainingDrillIds)
        for (moveId, stageMap) in map {
            for (stage, drillIds) in stageMap where !drillIds.isDisjoint(with: ids) {
                results.append((moveId: moveId, stage: stage))
            }
        }
        return results
    }
}
