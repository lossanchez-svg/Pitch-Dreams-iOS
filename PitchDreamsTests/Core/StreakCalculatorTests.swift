import XCTest
@testable import PitchDreams

final class StreakCalculatorTests: XCTestCase {

    private let calendar = Calendar.current
    /// Fixed "now" so day-walk results are deterministic.
    private let now = ISO8601DateFormatter().date(from: "2026-07-10T15:00:00Z")!

    private func session(_ id: String, daysAgo: Int) -> SessionLog {
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return SessionLog(
            id: id, childId: "c", activityType: "SELF_TRAINING",
            effortLevel: 3, mood: nil, duration: 20,
            win: nil, focus: nil, createdAt: formatter.string(from: date)
        )
    }

    // MARK: - currentStreak

    func testRunEndingTodayCounts() {
        let sessions = [session("a", daysAgo: 0), session("b", daysAgo: 1), session("c", daysAgo: 2)]
        XCTAssertEqual(StreakCalculator.currentStreak(from: sessions, now: now), 3)
    }

    func testTodayGetsGracePass() {
        // Trained yesterday and the day before, not yet today — streak lives.
        let sessions = [session("a", daysAgo: 1), session("b", daysAgo: 2)]
        XCTAssertEqual(StreakCalculator.currentStreak(from: sessions, now: now), 2)
    }

    func testStaleRunIsNotALiveStreak() {
        // A 5-day run that ended two weeks ago is over.
        let sessions = (14..<19).map { session("s-\($0)", daysAgo: $0) }
        XCTAssertEqual(StreakCalculator.currentStreak(from: sessions, now: now), 0)
    }

    func testGapBreaksStreak() {
        // Today, yesterday, then a gap, then more days — only the live run counts.
        let sessions = [session("a", daysAgo: 0), session("b", daysAgo: 1), session("c", daysAgo: 3), session("d", daysAgo: 4)]
        XCTAssertEqual(StreakCalculator.currentStreak(from: sessions, now: now), 2)
    }

    func testMultipleSessionsSameDayCountOnce() {
        let sessions = [session("a", daysAgo: 0), session("b", daysAgo: 0), session("c", daysAgo: 1)]
        XCTAssertEqual(StreakCalculator.currentStreak(from: sessions, now: now), 2)
    }

    func testEmptySessionsIsZero() {
        XCTAssertEqual(StreakCalculator.currentStreak(from: [], now: now), 0)
        XCTAssertEqual(StreakCalculator.maxStreak(from: [], now: now), 0)
    }

    // MARK: - maxStreak

    func testMaxStreakFindsBestHistoricRun() {
        // Live 2-day run, but a 4-day run last month.
        let sessions = [session("a", daysAgo: 0), session("b", daysAgo: 1)]
            + (20..<24).map { session("s-\($0)", daysAgo: $0) }
        XCTAssertEqual(StreakCalculator.maxStreak(from: sessions, now: now), 4)
        XCTAssertEqual(StreakCalculator.currentStreak(from: sessions, now: now), 2)
    }
}
