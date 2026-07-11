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
            pbStore: PersonalBestStore(defaults: defaults),
            matchStore: MatchStore(defaults: defaults)
        )
    }

    private func seedMasteredMove(_ moveId: String) {
        var progress = MoveProgress.initial(for: moveId)
        progress.currentStage = 4
        progress.masteredAt = Date()
        let data = try! JSONEncoder().encode(progress)
        defaults.set(data, forKey: "move_progress_\(childId)_\(moveId)")
    }

    private func sessionLog(_ id: String, daysAgo: Int = 30) -> SessionLog {
        SessionLog(
            id: id, childId: childId, activityType: "SELF_TRAINING",
            effortLevel: 5, mood: "GOOD", duration: 20,
            win: nil, focus: nil, createdAt: iso(daysAgo: daysAgo)
        )
    }

    /// ISO timestamp `daysAgo` days before now — streaks are computed against
    /// the real clock, so streak fixtures must be relative, not fixed dates.
    private func iso(daysAgo: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }

    // MARK: - Assembly

    func testAssemblesMasteryStreakAndVolumeLines() async {
        let move = SignatureMoveRegistry.launchMoves.first!
        seedMasteredMove(move.id)
        _ = await PersonalBestStore(defaults: defaults)
            .checkAndUpdate(metric: "juggling_both_feet", value: 47, childId: childId)

        // 12 sessions, the last four on a live 4-day run ending today.
        let sessions = (0..<8).map { sessionLog("old-\($0)", daysAgo: 30 + $0 * 3) }
            + (0..<4).map { sessionLog("run-\($0)", daysAgo: $0) }
        mockAPI.enqueue(sessions)

        let vm = makeViewModel()
        await vm.load()

        XCTAssertEqual(vm.snapshot.masteredMoveNames, [move.name])
        XCTAssertEqual(vm.snapshot.currentStreak, 4)
        XCTAssertEqual(vm.snapshot.totalSessions, 12)
        XCTAssertFalse(vm.snapshot.sessionCountIsFloor)

        let lines = vm.snapshot.evidenceLines
        XCTAssertTrue(lines.contains(where: { $0.kind == .mastery && $0.text.contains(move.name) }))
        XCTAssertTrue(lines.contains(where: { $0.kind == .record && $0.text.contains("47") }))
        XCTAssertTrue(lines.contains(where: { $0.kind == .consistency && $0.text.contains("4") }))
        XCTAssertTrue(lines.contains(where: { $0.kind == .volume && $0.text.contains("12") }))
    }

    func testStreakComesFromSessionsNotMilestoneBadges() async {
        // Regression: currentStreak was read from StreakData.milestones.max(),
        // which is an earned badge, not the live streak. A kid with an old
        // 14-day badge and no recent sessions has a streak of zero.
        mockAPI.enqueue((0..<6).map { sessionLog("stale-\($0)", daysAgo: 20 + $0) })

        let vm = makeViewModel()
        await vm.load()

        XCTAssertEqual(vm.snapshot.currentStreak, 0)
        XCTAssertFalse(vm.snapshot.evidenceLines.contains(where: { $0.kind == .consistency }))
    }

    func testNewPlayerGetsEncouragingNonEmptySnapshot() async {
        // No local progress, and the API fails — worst case for a new player.
        mockAPI.enqueueError(APIError.network(URLError(.notConnectedToInternet)))

        let vm = makeViewModel()
        await vm.load()

        let lines = vm.snapshot.evidenceLines
        XCTAssertFalse(lines.isEmpty, "Evidence bank must never render empty")
        XCTAssertEqual(lines.first?.kind, .starter)
    }

    func testShortStreakAndLowVolumeAreOmitted() async {
        mockAPI.enqueue([sessionLog("s-1", daysAgo: 0)])

        let vm = makeViewModel()
        await vm.load()

        let lines = vm.snapshot.evidenceLines
        XCTAssertFalse(lines.contains(where: { $0.kind == .consistency }),
                       "A 1-day streak isn't evidence yet")
        XCTAssertFalse(lines.contains(where: { $0.kind == .volume }),
                       "One session isn't a volume brag yet")
    }

    func testSessionCapProducesFloorCopy() async {
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

        mockAPI.enqueue([SessionLog]())

        let vm = makeViewModel()
        await vm.load()

        let after = defaults.data(forKey: "move_progress_\(childId)_\(move.id)")
        XCTAssertEqual(before, after, "Evidence bank must be read-only")
    }

    // MARK: - Courage flywheel (Match Mode, B3)

    func testBravePlaysProduceCourageLine() async {
        let store = MatchStore(defaults: defaults)
        await store.recordReflection(
            MatchReflection(braveThingTried: "Took my defender on 1v1", effortLevel: 4, decisionImProudOf: nil, reflectedAt: Date()),
            childId: childId
        )
        await store.recordReflection(
            MatchReflection(braveThingTried: "Tried my signature move", effortLevel: 3, decisionImProudOf: nil, reflectedAt: Date()),
            childId: childId
        )
        mockAPI.enqueue([SessionLog]())

        let vm = makeViewModel()
        await vm.load()

        XCTAssertEqual(vm.snapshot.bravePlaysLogged, 2)
        XCTAssertTrue(vm.snapshot.evidenceLines.contains(where: {
            $0.kind == .courage && $0.text.contains("2")
        }))
    }

    func testNoBravePlaysMeansNoCourageLine() async {
        mockAPI.enqueue([SessionLog]())

        let vm = makeViewModel()
        await vm.load()

        XCTAssertEqual(vm.snapshot.bravePlaysLogged, 0)
        XCTAssertFalse(vm.snapshot.evidenceLines.contains(where: { $0.kind == .courage }))
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
