import XCTest
@testable import PitchDreams

@MainActor
final class TrainingViewModelTests: XCTestCase {
    var mockAPI: MockAPIClient!
    var viewModel: TrainingViewModel!

    override func setUp() {
        mockAPI = MockAPIClient()
        viewModel = TrainingViewModel(childId: "test-child", apiClient: mockAPI)
    }

    // MARK: - Quick Check-In

    func testQuickCheckInUpdatesState() async {
        let response = TestFixtures.makeCheckInResponse(mode: "PEAK", explanation: "Great energy!")
        mockAPI.enqueue(response)

        await viewModel.quickCheckIn(mood: "EXCITED")

        XCTAssertNotNil(viewModel.checkInState)
        XCTAssertEqual(viewModel.sessionMode, "PEAK")
        XCTAssertEqual(viewModel.modeDisplayName, "Peak Day")
        XCTAssertEqual(viewModel.modeColor, "green")
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isCheckingIn)
    }

    func testQuickCheckInError() async {
        // Only a server-side rejection (4xx) surfaces as an error now;
        // network/5xx failures queue the check-in and compute a local mode.
        mockAPI.enqueueError(APIError.validation("Bad input"))

        await viewModel.quickCheckIn(mood: "FOCUSED")

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.checkInState)
        XCTAssertFalse(viewModel.isCheckingIn)
    }

    func testQuickCheckInServerErrorQueuesWithLocalMode() async {
        mockAPI.enqueueError(APIError.server("temporarily down"))

        await viewModel.quickCheckIn(mood: "FOCUSED")

        XCTAssertNil(viewModel.errorMessage)
        XCTAssertNotNil(viewModel.checkInState, "Offline check-in still produces a session mode")
        XCTAssertEqual(viewModel.sessionMode, SessionMode.normal.rawValue)
        XCTAssertFalse(viewModel.isCheckingIn)
    }

    func testQuickCheckInCallsCorrectEndpoint() async {
        mockAPI.enqueue(TestFixtures.makeCheckInResponse())

        await viewModel.quickCheckIn(mood: "OKAY")

        XCTAssertTrue(mockAPI.calledEndpoints.contains("/children/test-child/check-ins/quick"))
    }

    // MARK: - Full Check-In (trimmed: energy + mood + time + pain)

    func testFullCheckInUpdatesState() async {
        mockAPI.enqueue(TestFixtures.makeCheckInResponse(mode: "NORMAL", explanation: "Let's go."))

        await viewModel.fullCheckIn(energy: 4, mood: "FOCUSED", timeAvail: 20, painFlag: false)

        XCTAssertNotNil(viewModel.checkInState)
        XCTAssertEqual(viewModel.sessionMode, "NORMAL")
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isCheckingIn)
    }

    func testFullCheckInCallsCorrectEndpoint() async {
        mockAPI.enqueue(TestFixtures.makeCheckInResponse())

        await viewModel.fullCheckIn(energy: 3, mood: "OKAY", timeAvail: 30, painFlag: true)

        XCTAssertTrue(mockAPI.calledEndpoints.contains("/children/test-child/check-ins"))
    }

    func testFullCheckInError() async {
        mockAPI.enqueueError(APIError.validation("Bad input"))

        await viewModel.fullCheckIn(energy: 2, mood: "TIRED", timeAvail: 10, painFlag: false)

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.checkInState)
        XCTAssertFalse(viewModel.isCheckingIn)
    }

    func testFullCheckInServerErrorQueuesWithLocalMode() async {
        mockAPI.enqueueError(APIError.server("temporarily down"))

        // Low energy offline → conservative LOW_BATTERY mode locally.
        await viewModel.fullCheckIn(energy: 2, mood: "TIRED", timeAvail: 10, painFlag: false)

        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.sessionMode, SessionMode.lowBattery.rawValue)
    }

    func testOfflineCheckInPainAlwaysWinsRecovery() {
        let response = TrainingViewModel.offlineCheckInResponse(
            childId: "test-child", energy: 5, mood: "EXCITED", timeAvail: 30, painFlag: true
        )
        XCTAssertEqual(response.modeResult.mode, SessionMode.recovery.rawValue)
    }

    // MARK: - Load Today Check-In

    func testLoadTodayCheckInNilHandling() async {
        // Simulates API returning null (decoding error)
        mockAPI.enqueueError(APIError.decoding(NSError(domain: "test", code: 0)))

        await viewModel.loadTodayCheckIn()

        // Should not crash, checkInState stays nil
        XCTAssertNil(viewModel.checkInState)
    }

    func testLoadTodayCheckInPopulatesState() async {
        let checkIn = TestFixtures.makeCheckIn(mode: "LOW_BATTERY", modeExplanation: "Take it easy.")
        mockAPI.enqueue(checkIn)

        await viewModel.loadTodayCheckIn()

        XCTAssertNotNil(viewModel.checkInState)
        XCTAssertEqual(viewModel.sessionMode, "LOW_BATTERY")
        XCTAssertEqual(viewModel.modeDisplayName, "Low Battery")
    }

    // MARK: - Computed Properties

    func testModeDisplayNameDefault() {
        XCTAssertEqual(viewModel.modeDisplayName, "")
        XCTAssertEqual(viewModel.modeColor, "gray")
    }

    func testRecoveryModeDisplay() async {
        mockAPI.enqueue(TestFixtures.makeCheckInResponse(mode: "RECOVERY"))
        await viewModel.quickCheckIn(mood: "TIRED")
        XCTAssertEqual(viewModel.modeDisplayName, "Recovery")
        XCTAssertEqual(viewModel.modeColor, "purple")
    }
}
