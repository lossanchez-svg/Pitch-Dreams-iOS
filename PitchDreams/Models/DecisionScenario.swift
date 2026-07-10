import Foundation

// Game Moments (PLAYER_DEVELOPMENT_PLAN.md, Phase B2).
//
// Tactical lessons teach concepts; Game Moments train the *decision*:
// a freeze-frame on the pitch, a short shot clock, tap the best option.
// Both correctness and speed count — hesitation is the thing being trained
// out. Scenarios tie back to the lesson that teaches their concept.

struct DecisionOption: Identifiable, Equatable {
    let id: String
    let label: String
    let isBest: Bool
    /// Shown after the tap — why this was (or wasn't) the ball.
    let rationale: String
    /// Age-adapted rationale (≤11). Falls back to `rationale`.
    let rationaleYoung: String?

    init(
        id: String,
        label: String,
        isBest: Bool = false,
        rationale: String,
        rationaleYoung: String? = nil
    ) {
        self.id = id
        self.label = label
        self.isBest = isBest
        self.rationale = rationale
        self.rationaleYoung = rationaleYoung
    }

    func preferredRationale(childAge: Int?) -> String {
        if let age = childAge, age <= 11, let y = rationaleYoung { return y }
        return rationale
    }
}

struct DecisionScenario: Identifiable, Equatable {
    let id: String
    /// The `AnimatedTacticalLesson` whose concept this moment trains.
    let lessonId: String
    /// One-line setup read before the clock starts.
    let situation: String
    let situationYoung: String?
    let diagram: TacticalDiagramState
    let options: [DecisionOption]
    let clockSeconds: TimeInterval

    init(
        id: String,
        lessonId: String,
        situation: String,
        situationYoung: String? = nil,
        diagram: TacticalDiagramState,
        options: [DecisionOption],
        clockSeconds: TimeInterval = 3.0
    ) {
        self.id = id
        self.lessonId = lessonId
        self.situation = situation
        self.situationYoung = situationYoung
        self.diagram = diagram
        self.options = options
        self.clockSeconds = clockSeconds
    }

    var bestOption: DecisionOption? {
        options.first(where: \.isBest)
    }

    func preferredSituation(childAge: Int?) -> String {
        if let age = childAge, age <= 11, let y = situationYoung { return y }
        return situation
    }
}

/// The outcome of one moment. `chosenOptionId == nil` means the clock ran out
/// — a miss, because in a match not deciding *is* a decision.
struct DecisionResult: Equatable {
    let scenarioId: String
    let chosenOptionId: String?
    let correct: Bool
    let reactionMs: Int
}
