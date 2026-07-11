import Foundation

/// Runs a round of Game Moments: freeze-frame → shot clock → tap → feedback.
/// Timing methods take an injectable `now` so reaction scoring is testable;
/// the view drives the visible countdown and calls `timeUp()` on expiry.
@MainActor
final class GameMomentsViewModel: ObservableObject {

    enum Phase: Equatable {
        case intro
        case deciding
        case feedback(DecisionResult)
        case summary
    }

    @Published var phase: Phase = .intro
    @Published var currentIndex = 0
    @Published var results: [DecisionResult] = []
    @Published var lifetimeTotals = GameMomentsStore.Totals()

    let childId: String
    let scenarios: [DecisionScenario]
    private let store: GameMomentsStore
    private var shownAt: Date?

    init(
        childId: String,
        scenarios: [DecisionScenario] = DecisionScenarioRegistry.all.shuffled(),
        store: GameMomentsStore = GameMomentsStore()
    ) {
        self.childId = childId
        self.scenarios = scenarios
        self.store = store
    }

    var currentScenario: DecisionScenario? {
        guard scenarios.indices.contains(currentIndex) else { return nil }
        return scenarios[currentIndex]
    }

    var correctCount: Int {
        results.filter(\.correct).count
    }

    /// Fastest correct reaction this round, in ms. Nil if none were correct.
    var bestReactionMsThisRound: Int? {
        results.filter(\.correct).map(\.reactionMs).min()
    }

    func loadTotals() async {
        lifetimeTotals = await store.totals(childId: childId)
    }

    // MARK: - Round flow

    func begin(now: Date = Date()) {
        guard currentScenario != nil else {
            phase = .summary
            return
        }
        shownAt = now
        phase = .deciding
    }

    func choose(_ optionId: String, now: Date = Date()) {
        guard case .deciding = phase, let scenario = currentScenario else { return }
        let reaction = reactionMs(now: now)
        let correct = scenario.options.first(where: { $0.id == optionId })?.isBest ?? false
        finish(DecisionResult(
            scenarioId: scenario.id,
            chosenOptionId: optionId,
            correct: correct,
            reactionMs: reaction
        ))
    }

    /// Clock expiry counts as a miss — in a match, not deciding is a decision.
    func timeUp() {
        guard case .deciding = phase, let scenario = currentScenario else { return }
        finish(DecisionResult(
            scenarioId: scenario.id,
            chosenOptionId: nil,
            correct: false,
            reactionMs: Int(scenario.clockSeconds * 1000)
        ))
    }

    func next(now: Date = Date()) {
        guard case .feedback = phase else { return }
        currentIndex += 1
        if currentScenario == nil {
            phase = .summary
        } else {
            begin(now: now)
        }
    }

    // MARK: - Private

    private func finish(_ result: DecisionResult) {
        results.append(result)
        phase = .feedback(result)
        Task {
            await store.record(result, childId: childId)
            lifetimeTotals = await store.totals(childId: childId)
        }
    }

    private func reactionMs(now: Date) -> Int {
        guard let shownAt else { return 0 }
        return max(0, Int(now.timeIntervalSince(shownAt) * 1000))
    }
}
