import XCTest
@testable import PitchDreams

@MainActor
final class GameMomentsViewModelTests: XCTestCase {

    private var defaults: UserDefaults!
    private var suiteName: String!
    private let childId = "child-gm-test"

    override func setUp() {
        super.setUp()
        // Unique suite per test: the view model records results on a
        // fire-and-forget Task, so a straggler from one test must not land
        // in the next test's store.
        suiteName = "GameMomentsViewModelTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    private func fixedScenarios(_ count: Int = 2) -> [DecisionScenario] {
        Array(DecisionScenarioRegistry.all.prefix(count))
    }

    private func makeViewModel(scenarios: [DecisionScenario]? = nil) -> GameMomentsViewModel {
        GameMomentsViewModel(
            childId: childId,
            scenarios: scenarios ?? fixedScenarios(),
            store: GameMomentsStore(defaults: defaults)
        )
    }

    // MARK: - Scoring

    func testCorrectChoiceScoresCorrectWithReactionTime() {
        let vm = makeViewModel()
        let scenario = vm.scenarios[0]
        let shown = Date()

        vm.begin(now: shown)
        vm.choose(scenario.bestOption!.id, now: shown.addingTimeInterval(1.2))

        guard case .feedback(let result) = vm.phase else {
            return XCTFail("Expected feedback phase")
        }
        XCTAssertTrue(result.correct)
        XCTAssertEqual(result.reactionMs, 1200, accuracy: 5)
        XCTAssertEqual(result.scenarioId, scenario.id)
    }

    func testWrongChoiceScoresIncorrect() {
        let vm = makeViewModel()
        let scenario = vm.scenarios[0]
        let wrong = scenario.options.first(where: { !$0.isBest })!

        vm.begin(now: Date())
        vm.choose(wrong.id, now: Date())

        guard case .feedback(let result) = vm.phase else {
            return XCTFail("Expected feedback phase")
        }
        XCTAssertFalse(result.correct)
        XCTAssertEqual(result.chosenOptionId, wrong.id)
    }

    func testClockExpiryIsAMiss() {
        let vm = makeViewModel()
        vm.begin(now: Date())
        vm.timeUp()

        guard case .feedback(let result) = vm.phase else {
            return XCTFail("Expected feedback phase")
        }
        XCTAssertFalse(result.correct)
        XCTAssertNil(result.chosenOptionId)
        XCTAssertEqual(result.reactionMs, Int(vm.scenarios[0].clockSeconds * 1000))
    }

    func testChoosingTwiceOnlyCountsOnce() {
        let vm = makeViewModel()
        let scenario = vm.scenarios[0]

        vm.begin(now: Date())
        vm.choose(scenario.bestOption!.id, now: Date())
        vm.choose(scenario.options.first(where: { !$0.isBest })!.id, now: Date())
        vm.timeUp()

        XCTAssertEqual(vm.results.count, 1, "Only the first answer counts")
        XCTAssertTrue(vm.results[0].correct)
    }

    // MARK: - Round flow

    func testRoundAdvancesAndEndsInSummary() {
        let vm = makeViewModel(scenarios: fixedScenarios(2))

        vm.begin(now: Date())
        vm.choose(vm.scenarios[0].bestOption!.id, now: Date())
        vm.next(now: Date())
        XCTAssertEqual(vm.currentIndex, 1)
        guard case .deciding = vm.phase else {
            return XCTFail("Expected deciding phase for second scenario")
        }

        vm.timeUp()
        vm.next(now: Date())

        XCTAssertEqual(vm.phase, .summary)
        XCTAssertEqual(vm.results.count, 2)
        XCTAssertEqual(vm.correctCount, 1)
    }

    func testBestReactionOnlyCountsCorrectAnswers() {
        let vm = makeViewModel(scenarios: fixedScenarios(2))
        let shown = Date()

        // Fast but wrong, then slower but right.
        vm.begin(now: shown)
        vm.choose(vm.scenarios[0].options.first(where: { !$0.isBest })!.id, now: shown.addingTimeInterval(0.4))
        vm.next(now: shown)
        vm.choose(vm.scenarios[1].bestOption!.id, now: shown.addingTimeInterval(1.5))

        XCTAssertEqual(vm.bestReactionMsThisRound, 1500)
    }

    // MARK: - Persistence

    func testResultsPersistToStore() async {
        let store = GameMomentsStore(defaults: defaults)
        let vm = GameMomentsViewModel(childId: childId, scenarios: fixedScenarios(1), store: store)
        let shown = Date()

        vm.begin(now: shown)
        vm.choose(vm.scenarios[0].bestOption!.id, now: shown.addingTimeInterval(0.9))

        // The record happens on a Task; give it a beat.
        try? await Task.sleep(nanoseconds: 200_000_000)

        let totals = await store.totals(childId: childId)
        XCTAssertEqual(totals.answered, 1)
        XCTAssertEqual(totals.correct, 1)
        XCTAssertEqual(totals.bestReactionMs, 900, accuracy: 5)
    }

    func testStoreKeepsFastestCorrectReaction() async {
        let store = GameMomentsStore(defaults: defaults)
        await store.record(DecisionResult(scenarioId: "a", chosenOptionId: "x", correct: true, reactionMs: 1400), childId: childId)
        await store.record(DecisionResult(scenarioId: "b", chosenOptionId: "y", correct: true, reactionMs: 900), childId: childId)
        await store.record(DecisionResult(scenarioId: "c", chosenOptionId: nil, correct: false, reactionMs: 100), childId: childId)

        let totals = await store.totals(childId: childId)
        XCTAssertEqual(totals.answered, 3)
        XCTAssertEqual(totals.correct, 2)
        XCTAssertEqual(totals.bestReactionMs, 900, "Wrong answers must not set the reaction record")
    }
}

private func XCTAssertEqual(_ value: Int, _ expected: Int, accuracy: Int, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertLessThanOrEqual(abs(value - expected), accuracy, "\(value) not within \(accuracy) of \(expected)", file: file, line: line)
}
