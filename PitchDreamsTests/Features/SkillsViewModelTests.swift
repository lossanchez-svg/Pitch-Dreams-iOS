import XCTest
@testable import PitchDreams

@MainActor
final class SkillsViewModelTests: XCTestCase {
    var mockAPI: MockAPIClient!
    var viewModel: SkillsViewModel!

    override func setUp() {
        mockAPI = MockAPIClient()
        viewModel = SkillsViewModel(childId: "test-child", apiClient: mockAPI)
    }

    func testLoadStatsPopulatesList() async {
        let stats = TestFixtures.makeDrillStats(count: 3)
        mockAPI.enqueue(stats)

        await viewModel.loadStats()

        XCTAssertEqual(viewModel.drillStats.count, 3)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadStatsError() async {
        mockAPI.enqueueError(APIError.server("Failed"))

        await viewModel.loadStats()

        XCTAssertTrue(viewModel.drillStats.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testLogDrillSuccess() async {
        let drillResult = TestFixtures.makeLogDrillResult()
        mockAPI.enqueue(drillResult) // logDrill response
        mockAPI.enqueue(TestFixtures.makeDrillStats(count: 1)) // reload stats

        await viewModel.logDrill(drillKey: "bm-toe-taps", confidence: 4)

        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.drillStats.count, 1)
    }

    func testLogDrillError() async {
        mockAPI.enqueueError(APIError.server("Failed"))

        await viewModel.logDrill(drillKey: "bm-toe-taps", confidence: 3)

        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testLogDrillCallsCorrectEndpoint() async {
        mockAPI.enqueue(TestFixtures.makeLogDrillResult())
        mockAPI.enqueue([DrillStat]())

        await viewModel.logDrill(drillKey: "pass-wall", confidence: 5)

        XCTAssertTrue(mockAPI.calledEndpoints.contains("/children/test-child/drills"))
    }
}
