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
        mockAPI.enqueue(TestFixtures.makeActivityCreateResult()) // createActivity response
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

        mockAPI.enqueue(TestFixtures.makeActivityCreateResult())
        mockAPI.enqueue([ActivityItem]()) // loadRecent

        await viewModel.saveActivity()

        XCTAssertEqual(viewModel.currentStep, 0)
        XCTAssertEqual(viewModel.activityType, ActivityType.selfTraining.rawValue)
        XCTAssertEqual(viewModel.durationMinutes, 30)
    }

    // MARK: - Body wiring (regression: pickers were silently dropped)

    /// Encodes the body of the `/children/.../activities` POST that `saveActivity()` issued.
    private func savedActivityBody() throws -> [String: Any] {
        let endpoint = try XCTUnwrap(
            mockAPI.capturedEndpoints.first { $0.path.hasSuffix("/activities") && $0.method == .post },
            "No createActivity POST was captured"
        )
        let body = try XCTUnwrap(endpoint.body, "createActivity endpoint had no body")
        let data = try JSONEncoder().encode(body)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    func testSaveActivitySendsFacilityCoachProgram() async throws {
        viewModel.selectedFacilityId = "fac-1"
        viewModel.selectedCoachId = "coach-1"
        viewModel.selectedProgramId = "prog-1"

        mockAPI.enqueue(TestFixtures.makeActivityCreateResult())
        mockAPI.enqueue([ActivityItem]()) // loadRecent

        await viewModel.saveActivity()

        let json = try savedActivityBody()
        XCTAssertEqual(json["facilityId"] as? String, "fac-1")
        XCTAssertEqual(json["coachId"] as? String, "coach-1")
        XCTAssertEqual(json["programId"] as? String, "prog-1")
    }

    func testSaveActivitySendsRPEAndNotes() async throws {
        viewModel.intensityRPE = 8
        viewModel.notes = "  felt sharp today  "

        mockAPI.enqueue(TestFixtures.makeActivityCreateResult())
        mockAPI.enqueue([ActivityItem]())

        await viewModel.saveActivity()

        let json = try savedActivityBody()
        XCTAssertEqual(json["intensityRPE"] as? Int, 8)
        XCTAssertEqual(json["notes"] as? String, "felt sharp today", "notes should be trimmed")
    }

    func testSaveActivitySendsOpponentOnlyForGameType() async throws {
        viewModel.activityType = "OFFICIAL_GAME"
        viewModel.opponent = "Rival FC"

        mockAPI.enqueue(TestFixtures.makeActivityCreateResult())
        mockAPI.enqueue([ActivityItem]())

        await viewModel.saveActivity()

        let json = try savedActivityBody()
        XCTAssertEqual(json["opponentName"] as? String, "Rival FC")
    }

    func testSaveActivityOmitsEmptyOptionalFields() async throws {
        // Defaults: no facility/coach/program, non-game type, empty opponent/notes.
        viewModel.opponent = "Ignored"   // non-game type → must be dropped
        viewModel.notes = "   "          // whitespace only → must be dropped

        mockAPI.enqueue(TestFixtures.makeActivityCreateResult())
        mockAPI.enqueue([ActivityItem]())

        await viewModel.saveActivity()

        let json = try savedActivityBody()
        XCTAssertNil(json["facilityId"])
        XCTAssertNil(json["coachId"])
        XCTAssertNil(json["programId"])
        XCTAssertNil(json["opponentName"])
        XCTAssertNil(json["notes"])
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
