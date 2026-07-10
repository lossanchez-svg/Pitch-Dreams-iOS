import Foundation

/// Local record of Game Moments results, mirroring `PersonalBestStore`.
/// Tracks lifetime answered/correct plus the fastest *correct* reaction —
/// decision speed is the trainable metric, so only right answers count.
actor GameMomentsStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    struct Totals: Equatable {
        var answered: Int = 0
        var correct: Int = 0
        /// Fastest correct reaction in milliseconds; 0 = none yet.
        var bestReactionMs: Int = 0
    }

    func record(_ result: DecisionResult, childId: String) {
        var totals = self.totals(childId: childId)
        totals.answered += 1
        if result.correct {
            totals.correct += 1
            if totals.bestReactionMs == 0 || result.reactionMs < totals.bestReactionMs {
                totals.bestReactionMs = result.reactionMs
            }
        }
        defaults.set(totals.answered, forKey: key("answered", childId))
        defaults.set(totals.correct, forKey: key("correct", childId))
        defaults.set(totals.bestReactionMs, forKey: key("best_ms", childId))
    }

    func totals(childId: String) -> Totals {
        Totals(
            answered: defaults.integer(forKey: key("answered", childId)),
            correct: defaults.integer(forKey: key("correct", childId)),
            bestReactionMs: defaults.integer(forKey: key("best_ms", childId))
        )
    }

    private func key(_ field: String, _ childId: String) -> String {
        "game_moments_\(field)_\(childId)"
    }
}
