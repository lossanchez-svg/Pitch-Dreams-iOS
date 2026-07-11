import XCTest
@testable import PitchDreams

@MainActor
final class CreativityTests: XCTestCase {

    private var defaults: UserDefaults!
    private var suiteName: String!
    private var mockAPI: MockAPIClient!
    private let childId = "child-creativity-test"

    override func setUp() {
        super.setUp()
        suiteName = "CreativityTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        mockAPI = MockAPIClient()
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    private func makeViewModel() -> CreativityViewModel {
        CreativityViewModel(
            childId: childId,
            apiClient: mockAPI,
            store: CreativityStore(defaults: defaults),
            xpStore: XPStore(defaults: defaults)
        )
    }

    // MARK: - Registry

    func testRegistryIntegrity() {
        let all = CreativityChallengeRegistry.all
        XCTAssertGreaterThanOrEqual(all.count, 8)
        XCTAssertEqual(all.map(\.id).count, Set(all.map(\.id)).count, "Duplicate challenge ids")

        for challenge in all {
            XCTAssertFalse(challenge.title.isEmpty)
            XCTAssertFalse(challenge.prompt.isEmpty)
            XCTAssertFalse(challenge.unit.isEmpty)
            XCTAssertTrue(
                (3...10).contains(challenge.varietyTarget),
                "\(challenge.id): target \(challenge.varietyTarget) is out of the doable range"
            )
        }

        XCTAssertTrue(all.contains(where: \.isInvention), "The lab needs an invention challenge")
    }

    func testYoungPromptResolution() {
        for challenge in CreativityChallengeRegistry.all {
            XCTAssertEqual(challenge.preferredPrompt(childAge: 9), challenge.promptYoung ?? challenge.prompt)
            XCTAssertEqual(challenge.preferredPrompt(childAge: 15), challenge.prompt)
        }
    }

    func testMoveNameCombination() {
        XCTAssertEqual(MoveNameParts.combined("Thunder", "Chop"), "Thunder Chop")
        XCTAssertFalse(MoveNameParts.first.isEmpty)
        XCTAssertFalse(MoveNameParts.second.isEmpty)
    }

    // MARK: - Store

    func testStoreRoundTrips() async {
        let store = CreativityStore(defaults: defaults)
        await store.recordCompletion(challengeId: "cone-five-ways", childId: childId)
        await store.recordCompletion(challengeId: "cone-five-ways", childId: childId)

        let count = await store.completions(challengeId: "cone-five-ways", childId: childId)
        let total = await store.totalCompletions(childId: childId)
        XCTAssertEqual(count, 2)
        XCTAssertEqual(total, 2)
    }

    func testInventedMovesDeduplicate() async {
        let store = CreativityStore(defaults: defaults)
        await store.saveInventedMove("Thunder Chop", childId: childId)
        await store.saveInventedMove("Thunder Chop", childId: childId)
        await store.saveInventedMove("Silky Roll", childId: childId)

        let moves = await store.inventedMoves(childId: childId)
        XCTAssertEqual(moves, ["Thunder Chop", "Silky Roll"])
    }

    // MARK: - View model

    func testVarietyCountCapsAtTarget() {
        let vm = makeViewModel()
        let challenge = CreativityChallengeRegistry.challenge(for: "four-escapes")!
        vm.begin(challenge)

        for _ in 0..<10 { vm.countNewWay() }

        XCTAssertEqual(vm.varietyCount, 4, "Repetition beyond the target scores nothing")
        XCTAssertTrue(vm.targetReached)
    }

    func testCompleteRequiresTarget() async {
        let vm = makeViewModel()
        vm.begin(CreativityChallengeRegistry.all[0])
        vm.countNewWay()

        await vm.complete()

        XCTAssertFalse(vm.challengeComplete)
        XCTAssertTrue(mockAPI.calledEndpoints.isEmpty)
    }

    func testCompleteSavesAndRecords() async {
        mockAPI.enqueue(TestFixtures.makeSessionSaveResult())
        let vm = makeViewModel()
        let challenge = CreativityChallengeRegistry.challenge(for: "weak-foot-moves")!
        vm.begin(challenge)
        for _ in 0..<challenge.varietyTarget { vm.countNewWay() }

        await vm.complete()

        XCTAssertTrue(vm.challengeComplete)
        XCTAssertGreaterThan(vm.xpEarned, 0)
        XCTAssertEqual(vm.completions[challenge.id], 1)
        XCTAssertTrue(mockAPI.calledEndpoints.contains("/children/\(childId)/sessions"))
    }

    func testInventedMoveOnlySavesForInventionChallenge() async {
        mockAPI.enqueue(TestFixtures.makeSessionSaveResult())
        let vm = makeViewModel()
        let regular = CreativityChallengeRegistry.challenge(for: "cone-five-ways")!
        vm.begin(regular)
        for _ in 0..<regular.varietyTarget { vm.countNewWay() }
        await vm.complete()

        vm.namePartA = "Thunder"
        vm.namePartB = "Chop"
        await vm.saveInventedMove()

        XCTAssertTrue(vm.inventedMoves.isEmpty, "Only invention challenges name moves")
    }

    func testInventionFlowSavesTheName() async {
        mockAPI.enqueue(TestFixtures.makeSessionSaveResult())
        let vm = makeViewModel()
        let invention = CreativityChallengeRegistry.all.first(where: \.isInvention)!
        vm.begin(invention)
        for _ in 0..<invention.varietyTarget { vm.countNewWay() }
        await vm.complete()

        vm.namePartA = "Phantom"
        vm.namePartB = "Spin"
        XCTAssertEqual(vm.proposedMoveName, "Phantom Spin")
        await vm.saveInventedMove()

        XCTAssertEqual(vm.inventedMoves, ["Phantom Spin"])
    }
}
