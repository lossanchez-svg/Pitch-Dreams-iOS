import XCTest
@testable import PitchDreams

@MainActor
final class ProgressViewModelTests: XCTestCase {
    var mockAPI: MockAPIClient!
    var viewModel: ProgressViewModel!

    override func setUp() {
        mockAPI = MockAPIClient()
        viewModel = ProgressViewModel(childId: "test-child", apiClient: mockAPI)
    }

    func testLoadDataFetchesAll() async {
        mockAPI.enqueue(TestFixtures.makeStreakData())
        mockAPI.enqueue(TestFixtures.makeSessionLogs(count: 5))
        mockAPI.enqueue([TestFixtures.makeWeeklyTrend()])

        await viewModel.loadData()

        XCTAssertNotNil(viewModel.streakData)
        XCTAssertEqual(viewModel.sessions.count, 5)
        XCTAssertNotNil(viewModel.trends)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testTotalMinutesCalculation() async {
        let sessions = [
            TestFixtures.makeSessionLog(id: "s1", duration: 30),
            TestFixtures.makeSessionLog(id: "s2", duration: 45),
            TestFixtures.makeSessionLog(id: "s3", duration: 60),
        ]
        mockAPI.enqueue(TestFixtures.makeStreakData())
        mockAPI.enqueue(sessions)
        mockAPI.enqueue([TestFixtures.makeWeeklyTrend()])

        await viewModel.loadData()

        XCTAssertEqual(viewModel.totalMinutes, 135)
        XCTAssertEqual(viewModel.formattedTotalTime, "2h 15m")
    }

    func testTotalMinutesWithNilDurations() async {
        let sessions = [
            TestFixtures.makeSessionLog(id: "s1", duration: 30),
            TestFixtures.makeSessionLog(id: "s2", duration: nil),
        ]
        mockAPI.enqueue(TestFixtures.makeStreakData())
        mockAPI.enqueue(sessions)
        mockAPI.enqueue([TestFixtures.makeWeeklyTrend()])

        await viewModel.loadData()

        XCTAssertEqual(viewModel.totalMinutes, 30)
    }

    func testAverageEffort() async {
        let sessions = [
            TestFixtures.makeSessionLog(id: "s1", effortLevel: 3),
            TestFixtures.makeSessionLog(id: "s2", effortLevel: 5),
        ]
        mockAPI.enqueue(TestFixtures.makeStreakData())
        mockAPI.enqueue(sessions)
        mockAPI.enqueue([TestFixtures.makeWeeklyTrend()])

        await viewModel.loadData()

        XCTAssertEqual(viewModel.averageEffort, 4.0)
    }

    func testEmptySessionsComputedProperties() {
        XCTAssertEqual(viewModel.totalSessions, 0)
        XCTAssertEqual(viewModel.totalMinutes, 0)
        XCTAssertEqual(viewModel.averageEffort, 0)
        XCTAssertEqual(viewModel.currentStreak, 0)
        XCTAssertEqual(viewModel.maxStreak, 0)
    }

    func testFreezesAvailable() async {
        mockAPI.enqueue(TestFixtures.makeStreakData(freezes: 3))
        mockAPI.enqueue([SessionLog]())
        mockAPI.enqueue([WeeklyTrend]())

        await viewModel.loadData()

        XCTAssertEqual(viewModel.freezesAvailable, 3)
    }

    func testMilestonesAchieved() async {
        mockAPI.enqueue(TestFixtures.makeStreakData(milestones: [3, 7, 14]))
        mockAPI.enqueue([SessionLog]())
        mockAPI.enqueue([WeeklyTrend]())

        await viewModel.loadData()

        XCTAssertEqual(viewModel.milestonesAchieved, [3, 7, 14])
    }
}
