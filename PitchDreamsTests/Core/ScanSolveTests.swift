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
        XCTAssertEqual(a.callTimes, b.callTimes)
        XCTAssertEqual(a.callTimes.first, a.leadIn, "First call lands when the warm-up ends")
    }

    func testGapsWithinPaceBoundsAcrossSeeds() {
        for pace in ScanPace.allCases {
            for seed in UInt64(0)..<30 {
                let round = ScanSolveRound.generate(pace: pace, seed: seed)
                for (prev, next) in zip(round.callTimes, round.callTimes.dropFirst()) {
                    let gap = next - prev
                    XCTAssertGreaterThanOrEqual(gap, pace.minGap, "\(pace) seed \(seed)")
                    XCTAssertLessThanOrEqual(gap, pace.maxGap, "\(pace) seed \(seed)")
                }
            }
        }
    }

    func testGapsActuallyVary() {
        let round = ScanSolveRound.generate(seed: 7)
        let gaps = zip(round.callTimes, round.callTimes.dropFirst()).map { $1 - $0 }
        XCTAssertGreaterThan(Set(gaps.map { Int($0 * 1000) }).count, 1, "A metronome can be counted — gaps must jitter")
    }

    func testNoPaceGapShorterThanCallDisplay() {
        for pace in ScanPace.allCases {
            XCTAssertGreaterThanOrEqual(
                pace.minGap, ScanSolveRound.callDisplayDuration,
                "\(pace): a call must never clip the next one off the screen"
            )
        }
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
        let round = ScanSolveRound.generate(seed: 7)
        let display = ScanSolveRound.callDisplayDuration

        guard case .leadIn(let remaining) = round.moment(at: 1.0) else {
            return XCTFail("Expected lead-in at 1s")
        }
        XCTAssertEqual(remaining, round.leadIn - 1.0, accuracy: 0.001)

        // Each call shows for the display window, then back to rhythm.
        let first = round.callTimes[0]
        guard case .command(let firstIndex, _) = round.moment(at: first) else {
            return XCTFail("First call lands at its call time")
        }
        XCTAssertEqual(firstIndex, 0)
        guard case .rhythm(let next) = round.moment(at: first + display + 0.01) else {
            return XCTFail("Back to rhythm after the call display")
        }
        XCTAssertEqual(next, 1)

        // Mid-gap between calls 3 and 4 is rhythm pointing at 4.
        let midGap = (round.callTimes[3] + display + round.callTimes[4]) / 2
        guard case .rhythm(let upcoming) = round.moment(at: midGap) else {
            return XCTFail("Expected rhythm between calls")
        }
        XCTAssertEqual(upcoming, 4)

        XCTAssertEqual(round.totalDuration, round.callTimes[9] + display, accuracy: 0.001)
        guard case .command(let last, _) = round.moment(at: round.totalDuration - 0.01) else {
            return XCTFail("Last call still showing just before the end")
        }
        XCTAssertEqual(last, 9)
        guard case .finished = round.moment(at: round.totalDuration) else {
            return XCTFail("Round is over at total duration")
        }
    }

    func testPaceTiersOrderedFastToSlow() {
        XCTAssertGreaterThan(ScanPace.steady.minGap, ScanPace.quick.minGap)
        XCTAssertGreaterThan(ScanPace.quick.minGap, ScanPace.blazing.minGap)
        XCTAssertGreaterThan(ScanPace.steady.maxGap, ScanPace.quick.maxGap)
        XCTAssertGreaterThan(ScanPace.quick.maxGap, ScanPace.blazing.maxGap)
    }

    func testViewModelUsesSelectedPace() {
        let vm = makeViewModel()
        vm.pace = .blazing
        vm.start(seed: 3)
        guard let round = vm.round else { return XCTFail("No round") }
        for (prev, next) in zip(round.callTimes, round.callTimes.dropFirst()) {
            XCTAssertLessThanOrEqual(next - prev, ScanPace.blazing.maxGap)
        }
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
