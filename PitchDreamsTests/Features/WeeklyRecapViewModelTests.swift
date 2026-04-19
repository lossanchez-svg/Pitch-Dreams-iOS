import XCTest
@testable import PitchDreams

@MainActor
final class WeeklyRecapViewModelTests: XCTestCase {
    var mockAPI: MockAPIClient!
    var xpStore: XPStore!
    var defaults: UserDefaults!
    var viewModel: WeeklyRecapViewModel!

    override func setUp() {
        mockAPI = MockAPIClient()
        defaults = UserDefaults(suiteName: "WeeklyRecapTests")!
        defaults.removePersistentDomain(forName: "WeeklyRecapTests")
        xpStore = XPStore(defaults: defaults)
        viewModel = WeeklyRecapViewModel(childId: "test-child", apiClient: mockAPI, xpStore: xpStore)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "WeeklyRecapTests")
    }

    func testLoadRecap_populatesSessionCount() async {
        // Enqueue sessions from this week
        let recentDate = ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400))
        let sessions = [
            TestFixtures.makeSessionLog(createdAt: recentDate),
            TestFixtures.makeSessionLog(createdAt: recentDate),
            TestFixtures.makeSessionLog(createdAt: recentDate),
        ]
        mockAPI.enqueue(sessions)
        mockAPI.enqueue(TestFixtures.makeChildProfileDetail())
        mockAPI.enqueue(TestFixtures.makeStreakData())

        await viewModel.loadRecap()

        XCTAssertNotNil(viewModel.recap)
        XCTAssertEqual(viewModel.recap?.sessionsCompleted, 3)
    }

    func testLoadRecap_calculatesWeeklyXP() async {
        // Add XP entries from this week
        let entry = XPEntry(amount: 100, source: "drill", date: Date())
        await xpStore.recordXPEntry(entry, childId: "test-child")
        let _ = await xpStore.addXP(100, childId: "test-child")

        mockAPI.enqueue([SessionLog]()) // empty sessions
        mockAPI.enqueue(TestFixtures.makeChildProfileDetail())
        mockAPI.enqueue(TestFixtures.makeStreakData())

        await viewModel.loadRecap()

        XCTAssertNotNil(viewModel.recap)
        XCTAssertEqual(viewModel.recap?.xpEarned, 100)
        XCTAssertEqual(viewModel.recap?.totalXP, 100)
    }

    func testLoadRecap_filtersToLastSevenDays() async {
        let recentDate = ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400))
        let oldDate = ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400 * 14))
        let sessions = [
            TestFixtures.makeSessionLog(createdAt: recentDate),
            TestFixtures.makeSessionLog(createdAt: oldDate),
        ]
        mockAPI.enqueue(sessions)
        mockAPI.enqueue(TestFixtures.makeChildProfileDetail())
        mockAPI.enqueue(TestFixtures.makeStreakData())

        await viewModel.loadRecap()

        XCTAssertEqual(viewModel.recap?.sessionsCompleted, 1) // Only the recent one
    }

    func testLoadRecap_handlesEmptyWeek() async {
        mockAPI.enqueue([SessionLog]())
        mockAPI.enqueue(TestFixtures.makeChildProfileDetail())
        mockAPI.enqueue(TestFixtures.makeStreakData())

        await viewModel.loadRecap()

        XCTAssertNotNil(viewModel.recap)
        XCTAssertEqual(viewModel.recap?.sessionsCompleted, 0)
        XCTAssertEqual(viewModel.recap?.totalMinutes, 0)
    }

    func testLoadRecap_includesAvatarId() async {
        mockAPI.enqueue([SessionLog]())
        mockAPI.enqueue(TestFixtures.makeChildProfileDetail(avatarId: "wolf"))
        mockAPI.enqueue(TestFixtures.makeStreakData())

        await viewModel.loadRecap()

        XCTAssertEqual(viewModel.recap?.avatarId, "wolf")
    }

    func testWeeklyRecap_avatarStage_derivedFromTotalXP() {
        let recap = WeeklyRecap(
            weekStarting: Date(),
            sessionsCompleted: 3,
            totalMinutes: 90,
            currentStreak: 7,
            xpEarned: 100,
            totalXP: 600,
            avatarId: "wolf",
            bestDrill: nil,
            personalBests: 0,
            improvementStat: nil
        )
        XCTAssertEqual(recap.avatarStage, .pro) // 600 >= 500
    }

    func testWeeklyRecap_formattedMinutes_showsMinutes() {
        let recap = WeeklyRecap(weekStarting: Date(), sessionsCompleted: 1, totalMinutes: 45, currentStreak: 0, xpEarned: 0, totalXP: 0, avatarId: nil, bestDrill: nil, personalBests: 0, improvementStat: nil)
        XCTAssertEqual(recap.formattedMinutes, "45 min")
    }

    func testWeeklyRecap_formattedMinutes_showsHoursAndMinutes() {
        let recap = WeeklyRecap(weekStarting: Date(), sessionsCompleted: 5, totalMinutes: 150, currentStreak: 0, xpEarned: 0, totalXP: 0, avatarId: nil, bestDrill: nil, personalBests: 0, improvementStat: nil)
        XCTAssertEqual(recap.formattedMinutes, "2h 30m")
    }

    func testWeeklyRecap_formattedMinutes_showsHoursOnly() {
        let recap = WeeklyRecap(weekStarting: Date(), sessionsCompleted: 5, totalMinutes: 120, currentStreak: 0, xpEarned: 0, totalXP: 0, avatarId: nil, bestDrill: nil, personalBests: 0, improvementStat: nil)
        XCTAssertEqual(recap.formattedMinutes, "2h")
    }

    func testWeeklyRecap_weekLabel_formatsCorrectly() {
        let calendar = Calendar.current
        let weekStart = calendar.date(from: DateComponents(year: 2026, month: 4, day: 7))!
        let recap = WeeklyRecap(weekStarting: weekStart, sessionsCompleted: 0, totalMinutes: 0, currentStreak: 0, xpEarned: 0, totalXP: 0, avatarId: nil, bestDrill: nil, personalBests: 0, improvementStat: nil)
        XCTAssertEqual(recap.weekLabel, "Apr 7 - Apr 13")
    }

    func testLoadRecap_handlesAPIError() async {
        mockAPI.enqueueError(APIError.unknown(500, "Network error"))

        await viewModel.loadRecap()

        XCTAssertNil(viewModel.recap)
        XCTAssertFalse(viewModel.isLoading)
    }
}
