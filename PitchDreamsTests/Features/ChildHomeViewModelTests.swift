import XCTest
@testable import PitchDreams

@MainActor
final class ChildHomeViewModelTests: XCTestCase {
    var mockAPI: MockAPIClient!
    var viewModel: ChildHomeViewModel!

    override func setUp() {
        mockAPI = MockAPIClient()
        viewModel = ChildHomeViewModel(childId: "test-child", apiClient: mockAPI)
    }

    func testLoadDataPopulatesProfile() async {
        mockAPI.enqueue(TestFixtures.makeChildProfileDetail())
        mockAPI.enqueue(TestFixtures.makeStreakData())
        mockAPI.enqueueError(APIError.decoding(NSError(domain: "test", code: 0))) // null checkIn
        mockAPI.enqueueError(APIError.decoding(NSError(domain: "test", code: 0))) // null nudge
        mockAPI.enqueue(TestFixtures.makeFreezeCheckResult()) // freeze check

        await viewModel.loadData()

        XCTAssertNotNil(viewModel.profile)
        XCTAssertEqual(viewModel.profile?.nickname, "TestKid")
        XCTAssertNotNil(viewModel.streakData)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testGreetingBasedOnTime() {
        let greeting = viewModel.greeting
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            XCTAssertTrue(greeting.contains("morning"))
        } else if hour < 17 {
            XCTAssertTrue(greeting.contains("afternoon"))
        } else {
            XCTAssertTrue(greeting.contains("evening"))
        }
    }

    func testNullCheckInHandled() async {
        mockAPI.enqueue(TestFixtures.makeChildProfileDetail())
        mockAPI.enqueue(TestFixtures.makeStreakData())
        mockAPI.enqueueError(APIError.notFound("Not found")) // null checkIn
        mockAPI.enqueueError(APIError.notFound("Not found")) // null nudge
        mockAPI.enqueue(TestFixtures.makeFreezeCheckResult())

        await viewModel.loadData()

        // Should not crash
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.todayCheckIn)
        XCTAssertNil(viewModel.nudge)
        XCTAssertFalse(viewModel.hasCheckedInToday)
    }

    func testStreakCount() async {
        mockAPI.enqueue(TestFixtures.makeChildProfileDetail())
        mockAPI.enqueue(TestFixtures.makeStreakData(milestones: [3, 7, 14]))
        mockAPI.enqueueError(APIError.notFound("Not found")) // null checkIn
        mockAPI.enqueueError(APIError.notFound("Not found")) // null nudge
        mockAPI.enqueue(TestFixtures.makeFreezeCheckResult())

        await viewModel.loadData()

        XCTAssertEqual(viewModel.streakCount, 14)
        XCTAssertEqual(viewModel.freezeCount, 2)
    }

    func testHasCheckedInTodayWhenCheckInExists() async {
        mockAPI.enqueue(TestFixtures.makeChildProfileDetail())
        mockAPI.enqueue(TestFixtures.makeStreakData())
        mockAPI.enqueue(TestFixtures.makeCheckIn())
        mockAPI.enqueue(TestFixtures.makeCoachNudge())
        mockAPI.enqueue(TestFixtures.makeFreezeCheckResult())

        await viewModel.loadData()

        XCTAssertTrue(viewModel.hasCheckedInToday)
    }
}
