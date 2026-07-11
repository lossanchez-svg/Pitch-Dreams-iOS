import XCTest
@testable import PitchDreams

@MainActor
final class MatchModeTests: XCTestCase {

    private var defaults: UserDefaults!
    private var suiteName: String!
    private let childId = "child-match-test"

    override func setUp() {
        super.setUp()
        suiteName = "MatchModeTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    private func makeStore() -> MatchStore {
        MatchStore(defaults: defaults)
    }

    // MARK: - Store

    func testPrepRoundTrips() async {
        let store = makeStore()
        let prep = MatchPrep(
            processGoal: MatchPresets.processGoals[0],
            powerCue: MatchPresets.powerCues[1],
            preppedAt: Date()
        )

        await store.savePrep(prep, childId: childId)
        let loaded = await store.latestPrep(childId: childId)

        XCTAssertEqual(loaded?.processGoal, prep.processGoal)
        XCTAssertEqual(loaded?.powerCue, prep.powerCue)
    }

    func testNoPrepReturnsNil() async {
        let loaded = await makeStore().latestPrep(childId: childId)
        XCTAssertNil(loaded)
    }

    func testBravePlaysOnlyCountWhenBraveThingBanked() async {
        let store = makeStore()

        await store.recordReflection(
            MatchReflection(braveThingTried: "Took my defender on 1v1", effortLevel: 4, decisionImProudOf: nil, reflectedAt: Date()),
            childId: childId
        )
        await store.recordReflection(
            MatchReflection(braveThingTried: nil, effortLevel: 2, decisionImProudOf: "Stayed patient when it was blocked", reflectedAt: Date()),
            childId: childId
        )

        let brave = await store.bravePlays(childId: childId)
        let reflected = await store.matchesReflected(childId: childId)
        XCTAssertEqual(brave, 1, "Only reflections with a brave thing feed the flywheel")
        XCTAssertEqual(reflected, 2, "But every reflection counts as a reflected match")
    }

    // MARK: - View model

    func testPrepRequiresAGoal() async {
        let vm = MatchModeViewModel(childId: childId, store: makeStore())
        XCTAssertFalse(vm.canSavePrep)

        await vm.savePrep()
        XCTAssertNil(vm.savedPrep, "Prep without a process goal must not save")

        vm.selectedGoal = MatchPresets.processGoals[2]
        XCTAssertTrue(vm.canSavePrep)
        await vm.savePrep()
        XCTAssertEqual(vm.savedPrep?.processGoal, MatchPresets.processGoals[2])
    }

    func testReflectionSavesOnceAndUpdatesBraveCount() async {
        let store = makeStore()
        let vm = MatchModeViewModel(childId: childId, store: store)
        vm.effortLevel = 5
        vm.braveThingTried = MatchPresets.braveThings[0]

        await vm.saveReflection()
        XCTAssertTrue(vm.reflectionSaved)
        XCTAssertEqual(vm.bravePlays, 1)

        // Double-save guard
        await vm.saveReflection()
        let brave = await store.bravePlays(childId: childId)
        XCTAssertEqual(brave, 1, "Saving twice must not double-count bravery")
    }

    func testLoadRestoresPrepAndBraveCount() async {
        let store = makeStore()
        await store.savePrep(
            MatchPrep(processGoal: "Scan before every touch", powerCue: "Next ball", preppedAt: Date()),
            childId: childId
        )
        await store.recordReflection(
            MatchReflection(braveThingTried: "Shot when I had the chance", effortLevel: 3, decisionImProudOf: nil, reflectedAt: Date()),
            childId: childId
        )

        let vm = MatchModeViewModel(childId: childId, store: store)
        await vm.load()

        XCTAssertEqual(vm.savedPrep?.processGoal, "Scan before every touch")
        XCTAssertEqual(vm.bravePlays, 1)
    }

    // MARK: - Presets

    func testPresetsAreTapReadyAndProcessFocused() {
        XCTAssertGreaterThanOrEqual(MatchPresets.processGoals.count, 4)
        XCTAssertGreaterThanOrEqual(MatchPresets.powerCues.count, 3)
        XCTAssertGreaterThanOrEqual(MatchPresets.braveThings.count, 4)
        XCTAssertGreaterThanOrEqual(MatchPresets.proudDecisions.count, 3)

        // The whole point: reflection prompts must never be about outcomes.
        // ("after a mistake" is fine — that's process framing; scorelines aren't.)
        let banned = ["scored", "won", "lost", "conceded", "the score"]
        for option in MatchPresets.braveThings + MatchPresets.proudDecisions {
            for word in banned {
                XCTAssertFalse(
                    option.lowercased().contains(word),
                    "'\(option)' smells like an outcome prompt, not a process prompt"
                )
            }
        }
    }
}
