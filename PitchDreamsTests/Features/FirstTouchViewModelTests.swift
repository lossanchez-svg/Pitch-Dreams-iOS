import XCTest
@testable import PitchDreams

@MainActor
final class FirstTouchViewModelTests: XCTestCase {
    var mockAPI: MockAPIClient!
    var viewModel: FirstTouchViewModel!

    override func setUp() {
        mockAPI = MockAPIClient()
        viewModel = FirstTouchViewModel(childId: "test-child", apiClient: mockAPI)
    }

    func testStartDrillSetsActiveKey() {
        viewModel.startDrill("juggling_both_feet")
        XCTAssertEqual(viewModel.activeDrillKey, "juggling_both_feet")
        XCTAssertEqual(viewModel.activeCount, 0)
        XCTAssertFalse(viewModel.saveSuccess)
    }

    func testIncrementCount() {
        viewModel.startDrill("juggling_both_feet")
        viewModel.incrementCount()
        viewModel.incrementCount()
        viewModel.incrementCount()
        XCTAssertEqual(viewModel.activeCount, 3)
    }

    func testSaveDrillCallsAPI() async {
        viewModel.startDrill("wall_ball_pass")
        viewModel.incrementCount()
        viewModel.incrementCount()

        // saveDrill() calls createSession, which decodes SessionSaveResult { sessionId }
        mockAPI.enqueue(TestFixtures.makeSessionSaveResult())

        await viewModel.saveDrill()

        XCTAssertTrue(viewModel.saveSuccess)
        XCTAssertNil(viewModel.activeDrillKey) // Cleared after save
        XCTAssertTrue(mockAPI.calledEndpoints.contains("/children/test-child/sessions"))
    }

    func testSaveDrillWithoutActiveKeyDoesNothing() async {
        await viewModel.saveDrill()
        XCTAssertTrue(mockAPI.calledEndpoints.isEmpty)
    }

    func testCancelDrill() {
        viewModel.startDrill("juggling_both_feet")
        viewModel.incrementCount()
        viewModel.cancelDrill()
        XCTAssertNil(viewModel.activeDrillKey)
        XCTAssertEqual(viewModel.activeCount, 0)
    }

    func testLoadStats() async {
        let stats = TestFixtures.makeDrillStats(count: 2)
        mockAPI.enqueue(stats)

        await viewModel.loadStats()

        XCTAssertEqual(viewModel.drillStats.count, 2)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testJugglingDrillsConstant() {
        XCTAssertFalse(FirstTouchViewModel.jugglingDrills.isEmpty)
        for (key, label) in FirstTouchViewModel.jugglingDrills {
            XCTAssertFalse(key.isEmpty)
            XCTAssertFalse(label.isEmpty)
        }
    }

    func testWallBallDrillsConstant() {
        XCTAssertFalse(FirstTouchViewModel.wallBallDrills.isEmpty)
        for (key, label) in FirstTouchViewModel.wallBallDrills {
            XCTAssertFalse(key.isEmpty)
            XCTAssertFalse(label.isEmpty)
        }
    }
}
