import XCTest
@testable import PitchDreams

@MainActor
final class ScanSolveTests: XCTestCase {

    private var defaults: UserDefaults!
    private var suiteName: String!
    private var mockAPI: MockAPIClient!
    private let childId = "child-scan-test"

    override func setUp() {
        super.setUp()
        suiteName = "ScanSolveTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        mockAPI = MockAPIClient()
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    private func makeViewModel() -> ScanSolveViewModel {
        ScanSolveViewModel(
            childId: childId,
            apiClient: mockAPI,
            xpStore: XPStore(defaults: defaults),
            pbStore: PersonalBestStore(defaults: defaults)
        )
    }

    // MARK: - Round model

    func testSameSeedSameRound() {
        let a = ScanSolveRound.generate(seed: 42)
        let b = ScanSolveRound.generate(seed: 42)
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.commands.count, ScanSolveRound.defaultCount)
    }

    func testNoConsecutiveRepeats() {
        for seed in UInt64(0)..<50 {
            let round = ScanSolveRound.generate(seed: seed)
            for (prev, next) in zip(round.commands, round.commands.dropFirst()) {
                XCTAssertNotEqual(prev, next, "seed \(seed): a repeated call teaches nothing")
            }
        }
    }

    func testMomentTimeline() {
        let round = ScanSolveRound.generate(seed: 7)  // leadIn 3, interval 4, 10 commands

        guard case .leadIn(let remaining) = round.moment(at: 1.0) else {
            return XCTFail("Expected lead-in at 1s")
        }
        XCTAssertEqual(remaining, 2.0, accuracy: 0.001)

        guard case .command(let first, _) = round.moment(at: 3.0) else {
            return XCTFail("First call lands when the lead-in ends")
        }
        XCTAssertEqual(first, 0)

        guard case .command(let last, _) = round.moment(at: 3.0 + 9 * 4 + 3.9) else {
            return XCTFail("Last call still active just before the end")
        }
        XCTAssertEqual(last, 9)

        XCTAssertEqual(round.totalDuration, 43.0)
        guard case .finished = round.moment(at: round.totalDuration) else {
            return XCTFail("Round is over at total duration")
        }
    }

    func testPaceTiersOrderedAndDefaultMatches() {
        XCTAssertGreaterThan(ScanPace.steady.interval, ScanPace.quick.interval)
        XCTAssertGreaterThan(ScanPace.quick.interval, ScanPace.blazing.interval)
        XCTAssertEqual(ScanSolveRound.defaultInterval, ScanSolveRound.defaultPace.interval)
    }

    func testViewModelUsesSelectedPace() {
        let vm = makeViewModel()
        vm.pace = .blazing
        vm.start(seed: 3)
        XCTAssertEqual(vm.round?.interval, ScanPace.blazing.interval)
    }

    // MARK: - View model flow

    func testRoundFlowToReport() {
        let vm = makeViewModel()
        XCTAssertEqual(vm.phase, .intro)

        vm.start(seed: 1)
        XCTAssertEqual(vm.phase, .playing)
        XCTAssertEqual(vm.round?.commands.count, 10)

        vm.finishRound()
        XCTAssertEqual(vm.phase, .report)
    }

    func testSaveClampsCleanCountAndSetsPB() async {
        mockAPI.enqueue(TestFixtures.makeSessionSaveResult())
        let vm = makeViewModel()
        vm.start(seed: 1)
        vm.finishRound()
        vm.cleanCount = 99  // over the command count

        await vm.save()

        XCTAssertEqual(vm.phase, .done)
        XCTAssertTrue(vm.isNewPersonalBest, "First round is always a PB")
        XCTAssertEqual(vm.bestClean, 10, "Clean count is clamped to the number of calls")
        XCTAssertGreaterThan(vm.xpEarned, 0)
        XCTAssertTrue(mockAPI.calledEndpoints.contains("/children/\(childId)/sessions"))
    }

    func testSaveRequiresReportPhase() async {
        let vm = makeViewModel()
        vm.start(seed: 1)

        await vm.save()  // still .playing

        XCTAssertEqual(vm.phase, .playing)
        XCTAssertTrue(mockAPI.calledEndpoints.isEmpty)
    }

    func testLowerRoundIsNotAPB() async {
        let pbStore = PersonalBestStore(defaults: defaults)
        _ = await pbStore.checkAndUpdate(metric: ScanSolveViewModel.pbMetric, value: 8, childId: childId)

        mockAPI.enqueue(TestFixtures.makeSessionSaveResult())
        let vm = makeViewModel()
        vm.start(seed: 1)
        vm.finishRound()
        vm.cleanCount = 5

        await vm.save()

        XCTAssertEqual(vm.phase, .done)
        XCTAssertFalse(vm.isNewPersonalBest)
    }

    func testSaveErrorStaysOnReport() async {
        mockAPI.enqueueError(APIError.server("down"))
        let vm = makeViewModel()
        vm.start(seed: 1)
        vm.finishRound()
        vm.cleanCount = 6

        await vm.save()

        XCTAssertEqual(vm.phase, .report, "A failed save must not eat the round")
        XCTAssertNotNil(vm.errorMessage)
    }
}
