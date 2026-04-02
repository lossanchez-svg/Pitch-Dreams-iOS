import XCTest
@testable import PitchDreams

@MainActor
final class QuickLogViewModelTests: XCTestCase {
    var mockAPI: MockAPIClient!
    var viewModel: QuickLogViewModel!

    override func setUp() {
        mockAPI = MockAPIClient()
        viewModel = QuickLogViewModel(childId: "test-child", apiClient: mockAPI)
    }

    func testSaveSuccess() async {
        mockAPI.enqueue(TestFixtures.makeSessionSaveResult())

        await viewModel.save()

        XCTAssertTrue(viewModel.saveSuccess)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isSaving)
    }

    func testSaveError() async {
        mockAPI.enqueueError(APIError.server("Failed"))

        await viewModel.save()

        XCTAssertFalse(viewModel.saveSuccess)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testTypeDisplayNames() {
        for sessionType in QuickLogViewModel.sessionTypes {
            viewModel.selectedType = sessionType.key
            XCTAssertFalse(viewModel.typeDisplayName.isEmpty, "Display name for \(sessionType.key) should not be empty")
            XCTAssertEqual(viewModel.typeDisplayName, sessionType.label)
        }
    }

    func testAllFourTypesExist() {
        XCTAssertEqual(QuickLogViewModel.sessionTypes.count, 4)
    }

    func testResetFormAfterSave() async {
        viewModel.selectedType = "game"
        viewModel.duration = 90
        viewModel.effort = 5
        mockAPI.enqueue(TestFixtures.makeSessionSaveResult())

        await viewModel.save()

        XCTAssertEqual(viewModel.selectedType, "solo")
        XCTAssertEqual(viewModel.duration, 30)
        XCTAssertEqual(viewModel.effort, 3)
    }

    func testSaveCallsCorrectEndpoint() async {
        mockAPI.enqueue(TestFixtures.makeSessionSaveResult())
        await viewModel.save()
        XCTAssertTrue(mockAPI.calledEndpoints.contains("/children/test-child/sessions/quick"))
    }
}
