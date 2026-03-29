import XCTest
@testable import PitchDreams

/// API Contract Tests — hit the REAL API at www.pitchdreams.soccer.
/// These tests verify that the iOS models decode actual API responses without error.
/// Run these manually or in a separate CI job with test secrets.
///
/// To run only contract tests:
///   xcodebuild test -only-testing:PitchDreamsTests/APIContractTests ...
final class APIContractTests: XCTestCase {

    private let api = APIClient()
    private let childId = "cmnbsn6hv1c173623d91cb2f9"
    private let parentEmail = "pitchdreams.soccer@gmail.com"
    private let parentPassword = "DaddyAnq1"
    private let childNickname = "Tester1"
    private let childPin = "1111"

    // MARK: - Auth

    func testParentLogin() async throws {
        let response: TokenResponse = try await api.request(
            APIRouter.parentLogin(email: parentEmail, password: parentPassword)
        )
        XCTAssertEqual(response.user.role, .parent)
        XCTAssertFalse(response.token.isEmpty)
    }

    func testChildLogin() async throws {
        let response: TokenResponse = try await api.request(
            APIRouter.childLogin(parentEmail: parentEmail, nickname: childNickname, pin: childPin)
        )
        XCTAssertEqual(response.user.role, .child)
        XCTAssertNotNil(response.user.childId)
    }

    // MARK: - Child Profile

    func testGetProfile() async throws {
        // Login first
        let login: TokenResponse = try await api.request(
            APIRouter.childLogin(parentEmail: parentEmail, nickname: childNickname, pin: childPin)
        )
        XCTAssertFalse(login.token.isEmpty)

        let profile: ChildProfileDetail = try await api.request(
            APIRouter.getProfile(childId: childId)
        )
        XCTAssertFalse(profile.nickname.isEmpty)
    }

    // MARK: - Streaks

    func testGetStreaks() async throws {
        let _: TokenResponse = try await api.request(
            APIRouter.childLogin(parentEmail: parentEmail, nickname: childNickname, pin: childPin)
        )

        let streaks: StreakData = try await api.request(
            APIRouter.getStreaks(childId: childId)
        )
        XCTAssertGreaterThanOrEqual(streaks.freezes, 0)
    }

    // MARK: - Sessions

    func testListSessions() async throws {
        let _: TokenResponse = try await api.request(
            APIRouter.childLogin(parentEmail: parentEmail, nickname: childNickname, pin: childPin)
        )

        let sessions: [SessionLog] = try await api.request(
            APIRouter.listSessions(childId: childId, limit: 5)
        )
        // Just verify it decodes; may be empty for test account
        XCTAssertNotNil(sessions)
    }

    // MARK: - Drill Stats

    func testDrillStats() async throws {
        let _: TokenResponse = try await api.request(
            APIRouter.childLogin(parentEmail: parentEmail, nickname: childNickname, pin: childPin)
        )

        let stats: [DrillStat] = try await api.request(
            APIRouter.drillStats(childId: childId)
        )
        XCTAssertNotNil(stats)
    }

    // MARK: - Lesson Progress

    func testLessonProgress() async throws {
        let _: TokenResponse = try await api.request(
            APIRouter.childLogin(parentEmail: parentEmail, nickname: childNickname, pin: childPin)
        )

        let progress: [LessonProgress] = try await api.request(
            APIRouter.lessonProgress(childId: childId)
        )
        XCTAssertNotNil(progress)
    }

    // MARK: - Tags

    func testFocusTags() async throws {
        let _: TokenResponse = try await api.request(
            APIRouter.childLogin(parentEmail: parentEmail, nickname: childNickname, pin: childPin)
        )

        let tags: [FocusTag] = try await api.request(APIRouter.focusTags)
        XCTAssertFalse(tags.isEmpty, "Focus tags should not be empty")
        for tag in tags {
            XCTAssertFalse(tag.key.isEmpty)
            XCTAssertFalse(tag.label.isEmpty)
        }
    }

    func testHighlightTags() async throws {
        let _: TokenResponse = try await api.request(
            APIRouter.childLogin(parentEmail: parentEmail, nickname: childNickname, pin: childPin)
        )

        let chips: [HighlightChip] = try await api.request(APIRouter.highlightTags)
        XCTAssertNotNil(chips)
    }

    func testNextFocusTags() async throws {
        let _: TokenResponse = try await api.request(
            APIRouter.childLogin(parentEmail: parentEmail, nickname: childNickname, pin: childPin)
        )

        let chips: [NextFocusChip] = try await api.request(APIRouter.nextFocusTags)
        XCTAssertNotNil(chips)
    }

    // MARK: - Trends

    func testGetTrends() async throws {
        let _: TokenResponse = try await api.request(
            APIRouter.childLogin(parentEmail: parentEmail, nickname: childNickname, pin: childPin)
        )

        let trends: [WeeklyTrend] = try await api.request(
            APIRouter.getTrends(childId: childId, weeks: 4)
        )
        XCTAssertNotNil(trends)
    }

    // MARK: - Parent Endpoints

    func testListChildren() async throws {
        let _: TokenResponse = try await api.request(
            APIRouter.parentLogin(email: parentEmail, password: parentPassword)
        )

        let children: [ChildSummary] = try await api.request(APIRouter.listChildren)
        XCTAssertFalse(children.isEmpty, "Test parent should have at least one child")
    }
}
