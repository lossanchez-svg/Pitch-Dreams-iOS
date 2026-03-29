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
        mockAPI.enqueueError(APIError.server("Server down"))

        await viewModel.quickCheckIn(mood: "FOCUSED")

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.checkInState)
        XCTAssertFalse(viewModel.isCheckingIn)
    }

    func testQuickCheckInCallsCorrectEndpoint() async {
        mockAPI.enqueue(TestFixtures.makeCheckInResponse())

        await viewModel.quickCheckIn(mood: "OKAY")

        XCTAssertTrue(mockAPI.calledEndpoints.contains("/children/test-child/check-ins/quick"))
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
