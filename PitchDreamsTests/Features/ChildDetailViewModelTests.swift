import XCTest
@testable import PitchDreams

@MainActor
final class ChildDetailViewModelTests: XCTestCase {
    var mockAPI: MockAPIClient!
    var viewModel: ChildDetailViewModel!

    override func setUp() {
        mockAPI = MockAPIClient()
        viewModel = ChildDetailViewModel(childId: "test-child", apiClient: mockAPI)
    }

    func testMonthlySessionCount() async {
        // Create sessions with this month's date
        let now = Date()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let thisMonthDate = formatter.string(from: now)
        let oldDate = "2025-01-15T10:00:00.000Z"

        let sessions = [
            TestFixtures.makeSessionLog(id: "s1", createdAt: thisMonthDate),
            TestFixtures.makeSessionLog(id: "s2", createdAt: thisMonthDate),
            TestFixtures.makeSessionLog(id: "s3", createdAt: oldDate),
        ]
        mockAPI.enqueue(TestFixtures.makeStreakData())
        mockAPI.enqueue(sessions)
        mockAPI.enqueue(TestFixtures.makeActivityItems(count: 0))

        await viewModel.loadData()

        XCTAssertEqual(viewModel.monthlySessionCount, 2)
    }

    func testActivityBreakdown() async {
        let activities = [
            TestFixtures.makeActivityItem(id: "a1", activityType: "SELF_TRAINING", durationMinutes: 30),
            TestFixtures.makeActivityItem(id: "a2", activityType: "SELF_TRAINING", durationMinutes: 45),
            TestFixtures.makeActivityItem(id: "a3", activityType: "TEAM_TRAINING", durationMinutes: 60),
        ]
        mockAPI.enqueue(TestFixtures.makeStreakData())
        mockAPI.enqueue([SessionLog]())
        mockAPI.enqueue(activities)

        await viewModel.loadData()

        let breakdown = viewModel.activityBreakdown
        XCTAssertFalse(breakdown.isEmpty)

        let selfTraining = breakdown.first { $0.type == "SELF_TRAINING" }
        XCTAssertNotNil(selfTraining)
        XCTAssertEqual(selfTraining?.count, 2)
        XCTAssertEqual(selfTraining?.minutes, 75)
    }

    func testAvgRPECalculation() async {
        let sessions = [
            TestFixtures.makeSessionLog(id: "s1", effortLevel: 3),
            TestFixtures.makeSessionLog(id: "s2", effortLevel: 5),
            TestFixtures.makeSessionLog(id: "s3", effortLevel: 4),
        ]
        mockAPI.enqueue(TestFixtures.makeStreakData())
        mockAPI.enqueue(sessions)
        mockAPI.enqueue([ActivityItem]())

        await viewModel.loadData()

        XCTAssertEqual(viewModel.avgRPE, 4.0)
    }

    func testAvgRPEEmpty() {
        XCTAssertEqual(viewModel.avgRPE, 0)
    }

    func testAvgGameIQ() async {
        let activities = [
            TestFixtures.makeActivityItem(id: "a1", gameIQImpact: "HIGH"),
            TestFixtures.makeActivityItem(id: "a2", gameIQImpact: "MEDIUM"),
            TestFixtures.makeActivityItem(id: "a3", gameIQImpact: "LOW"),
        ]
        mockAPI.enqueue(TestFixtures.makeStreakData())
        mockAPI.enqueue([SessionLog]())
        mockAPI.enqueue(activities)

        await viewModel.loadData()

        XCTAssertEqual(viewModel.avgGameIQ, 2.0) // (3+2+1)/3
        XCTAssertEqual(viewModel.avgGameIQLabel, "Medium")
    }

    func testFormattedTotalTime() async {
        let now = Date()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let thisMonthDate = formatter.string(from: now)

        let sessions = [
            TestFixtures.makeSessionLog(id: "s1", duration: 90, createdAt: thisMonthDate),
            TestFixtures.makeSessionLog(id: "s2", duration: 30, createdAt: thisMonthDate),
        ]
        mockAPI.enqueue(TestFixtures.makeStreakData())
        mockAPI.enqueue(sessions)
        mockAPI.enqueue([ActivityItem]())

        await viewModel.loadData()

        XCTAssertEqual(viewModel.formattedTotalTime, "2h")
    }
}
