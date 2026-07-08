import XCTest
@testable import PitchDreams

@MainActor
final class ConfidenceViewModelTests: XCTestCase {

    private var defaults: UserDefaults!
    private var mockAPI: MockAPIClient!
    private let childId = "child-confidence-test"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "ConfidenceViewModelTests")!
        defaults.removePersistentDomain(forName: "ConfidenceViewModelTests")
        mockAPI = MockAPIClient()
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "ConfidenceViewModelTests")
        super.tearDown()
    }

    private func makeViewModel() -> ConfidenceViewModel {
        ConfidenceViewModel(
            childId: childId,
            apiClient: mockAPI,
            moveStore: SignatureMoveStore(defaults: defaults),
            pbStore: PersonalBestStore(defaults: defaults)
        )
    }

    private func seedMasteredMove(_ moveId: String) {
        var progress = MoveProgress.initial(for: moveId)
        progress.currentStage = 4
        progress.masteredAt = Date()
        let data = try! JSONEncoder().encode(progress)
        defaults.set(data, forKey: "move_progress_\(childId)_\(moveId)")
    }

    private func sessionLog(_ id: String) -> SessionLog {
        SessionLog(
            id: id, childId: childId, activityType: "SELF_TRAINING",
            effortLevel: 5, mood: "GOOD", duration: 20,
            win: nil, focus: nil, createdAt: "2026-07-01T10:00:00Z"
        )
    }

    // MARK: - Assembly

    func testAssemblesMasteryStreakAndVolumeLines() async {
        let move = SignatureMoveRegistry.launchMoves.first!
        seedMasteredMove(move.id)
        _ = await PersonalBestStore(defaults: defaults)
            .checkAndUpdate(metric: "juggling_both_feet", value: 47, childId: childId)

        mockAPI.enqueue(StreakData(freezes: 1, freezesUsed: 0, milestones: [7, 14]))
        mockAPI.enqueue((0..<12).map { sessionLog("s-\($0)") })

        let vm = makeViewModel()
        await vm.load()

        XCTAssertEqual(vm.snapshot.masteredMoveNames, [move.name])
        XCTAssertEqual(vm.snapshot.currentStreak, 14)
        XCTAssertEqual(vm.snapshot.totalSessions, 12)
        XCTAssertFalse(vm.snapshot.sessionCountIsFloor)

        let lines = vm.snapshot.evidenceLines
        XCTAssertTrue(lines.contains(where: { $0.kind == .mastery && $0.text.contains(move.name) }))
        XCTAssertTrue(lines.contains(where: { $0.kind == .record && $0.text.contains("47") }))
        XCTAssertTrue(lines.contains(where: { $0.kind == .consistency && $0.text.contains("14") }))
        XCTAssertTrue(lines.contains(where: { $0.kind == .volume && $0.text.contains("12") }))
    }

    func testNewPlayerGetsEncouragingNonEmptySnapshot() async {
        // No local progress, and the API fails — worst case for a new player.
        mockAPI.enqueueError(APIError.network(URLError(.notConnectedToInternet)))
        mockAPI.enqueueError(APIError.network(URLError(.notConnectedToInternet)))

        let vm = makeViewModel()
        await vm.load()

        let lines = vm.snapshot.evidenceLines
        XCTAssertFalse(lines.isEmpty, "Evidence bank must never render empty")
        XCTAssertEqual(lines.first?.kind, .starter)
    }

    func testShortStreakAndLowVolumeAreOmitted() async {
        mockAPI.enqueue(StreakData(freezes: 0, freezesUsed: 0, milestones: [1]))
        mockAPI.enqueue([sessionLog("s-1")])

        let vm = makeViewModel()
        await vm.load()

        let lines = vm.snapshot.evidenceLines
        XCTAssertFalse(lines.contains(where: { $0.kind == .consistency }),
                       "A 1-day streak isn't evidence yet")
        XCTAssertFalse(lines.contains(where: { $0.kind == .volume }),
                       "One session isn't a volume brag yet")
    }

    func testSessionCapProducesFloorCopy() async {
        mockAPI.enqueue(StreakData(freezes: 0, freezesUsed: 0, milestones: []))
        mockAPI.enqueue((0..<ConfidenceViewModel.sessionFetchLimit).map { sessionLog("s-\($0)") })

        let vm = makeViewModel()
        await vm.load()

        XCTAssertTrue(vm.snapshot.sessionCountIsFloor)
        XCTAssertTrue(vm.snapshot.evidenceLines.contains(where: {
            $0.kind == .volume && $0.text.contains("+")
        }))
    }

    func testLoadDoesNotMutateStoredProgress() async {
        let move = SignatureMoveRegistry.launchMoves.first!
        seedMasteredMove(move.id)
        let before = defaults.data(forKey: "move_progress_\(childId)_\(move.id)")

        mockAPI.enqueue(StreakData(freezes: 0, freezesUsed: 0, milestones: []))
        mockAPI.enqueue([SessionLog]())

        let vm = makeViewModel()
        await vm.load()

        let after = defaults.data(forKey: "move_progress_\(childId)_\(move.id)")
        XCTAssertEqual(before, after, "Evidence bank must be read-only")
    }

    // MARK: - Name joining

    func testJoinNamesGrammar() {
        XCTAssertEqual(ConfidenceSnapshot.joinNames(["Scissor"]), "Scissor")
        XCTAssertEqual(ConfidenceSnapshot.joinNames(["Scissor", "Body Feint"]), "Scissor and Body Feint")
        XCTAssertEqual(
            ConfidenceSnapshot.joinNames(["Scissor", "Body Feint", "La Croqueta"]),
            "Scissor, Body Feint, and La Croqueta"
        )
    }
}
