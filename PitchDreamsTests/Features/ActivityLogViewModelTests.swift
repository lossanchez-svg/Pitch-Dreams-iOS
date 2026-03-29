import XCTest
@testable import PitchDreams

@MainActor
final class ActivityLogViewModelTests: XCTestCase {
    var mockAPI: MockAPIClient!
    var viewModel: ActivityLogViewModel!

    override func setUp() {
        mockAPI = MockAPIClient()
        viewModel = ActivityLogViewModel(childId: "test-child", apiClient: mockAPI)
    }

    func testSaveActivitySuccess() async {
        // saveActivity calls createActivity then loadRecent
        let savedItem = TestFixtures.makeActivityItem()
        mockAPI.enqueue(savedItem) // createActivity response
        mockAPI.enqueue([TestFixtures.makeActivityItem()]) // loadRecent response

        await viewModel.saveActivity()

        XCTAssertTrue(viewModel.saveSuccess)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isSaving)
    }

    func testSaveActivityError() async {
        mockAPI.enqueueError(APIError.server("Failed"))

        await viewModel.saveActivity()

        XCTAssertFalse(viewModel.saveSuccess)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testLoadRecentPopulatesList() async {
        let items = TestFixtures.makeActivityItems(count: 3)
        mockAPI.enqueue(items)

        await viewModel.loadRecent()

        XCTAssertEqual(viewModel.recentActivities.count, 3)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadRecentError() async {
        mockAPI.enqueueError(APIError.network(URLError(.notConnectedToInternet)))

        await viewModel.loadRecent()

        XCTAssertTrue(viewModel.recentActivities.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testResetFormAfterSave() async {
        viewModel.activityType = "OFFICIAL_GAME"
        viewModel.durationMinutes = 90
        viewModel.currentStep = 2

        mockAPI.enqueue(TestFixtures.makeActivityItem())
        mockAPI.enqueue([ActivityItem]()) // loadRecent

        await viewModel.saveActivity()

        XCTAssertEqual(viewModel.currentStep, 0)
        XCTAssertEqual(viewModel.activityType, ActivityType.selfTraining.rawValue)
        XCTAssertEqual(viewModel.durationMinutes, 30)
    }

    func testStepNavigation() {
        XCTAssertEqual(viewModel.currentStep, 0)
        viewModel.nextStep()
        XCTAssertEqual(viewModel.currentStep, 1)
        viewModel.nextStep()
        XCTAssertEqual(viewModel.currentStep, 2)
        viewModel.previousStep()
        XCTAssertEqual(viewModel.currentStep, 1)
        viewModel.previousStep()
        XCTAssertEqual(viewModel.currentStep, 0)
        viewModel.previousStep()
        XCTAssertEqual(viewModel.currentStep, 0) // Does not go below 0
    }

    func testIsGameType() {
        viewModel.activityType = "OFFICIAL_GAME"
        XCTAssertTrue(viewModel.isGameType)

        viewModel.activityType = "SELF_TRAINING"
        XCTAssertFalse(viewModel.isGameType)
    }
}
