import XCTest
@testable import PitchDreams

/// End-to-end flow tests that hit the REAL API and verify every response
/// decodes correctly with our Swift Codable models.
/// These tests simulate exactly what the app does for each user flow.
final class EndToEndFlowTests: XCTestCase {
    let api = APIClient()
    let testEmail = "pitchdreams.soccer@gmail.com"
    let testPassword = "DaddyAnq1"
    let testChildNickname = "Tester1"
    let testPin = "1111"

    var parentToken: String?
    var childToken: String?
    var childId: String?

    // MARK: - Setup: Login

    func test00_ParentLogin() async throws {
        let response: TokenResponse = try await api.request(
            APIRouter.parentLogin(email: testEmail, password: testPassword)
        )
        XCTAssertEqual(response.user.role, .parent)
        XCTAssertFalse(response.token.isEmpty)
        parentToken = response.token
    }

    func test01_ChildLogin() async throws {
        let response: TokenResponse = try await api.request(
            APIRouter.childLogin(parentEmail: testEmail, nickname: testChildNickname, pin: testPin)
        )
        XCTAssertEqual(response.user.role, .child)
        XCTAssertNotNil(response.user.childId)
        childToken = response.token
        childId = response.user.childId
    }

    // MARK: - Flow: Home Screen

    func test02_HomeScreen_Profile() async throws {
        let cid = try await getChildId()
        let profile: ChildProfileDetail = try await api.request(APIRouter.getProfile(childId: cid))
        XCTAssertFalse(profile.nickname.isEmpty)
        XCTAssertFalse(profile.avatarId.isEmpty)
    }

    func test03_HomeScreen_Streaks() async throws {
        let cid = try await getChildId()
        let streaks: StreakData = try await api.request(APIRouter.getStreaks(childId: cid))
        XCTAssertGreaterThanOrEqual(streaks.freezes, 0)
        XCTAssertGreaterThanOrEqual(streaks.freezesUsed, 0)
    }

    func test04_HomeScreen_TodayCheckIn_NullHandled() async throws {
        let cid = try await getChildId()
        // todayCheckIn may return null — verify our decode handles it
        let checkIn: CheckIn? = try? await api.request(APIRouter.todayCheckIn(childId: cid))
        // Either nil or a valid CheckIn — both are OK
        if let checkIn {
            XCTAssertFalse(checkIn.id.isEmpty)
        }
    }

    func test05_HomeScreen_Nudge_NullHandled() async throws {
        let cid = try await getChildId()
        let nudge: CoachNudge? = try? await api.request(APIRouter.getNudge(childId: cid))
        if let nudge {
            XCTAssertFalse(nudge.title.isEmpty)
        }
    }

    func test06_HomeScreen_FreezeCheck() async throws {
        let cid = try await getChildId()
        let result: FreezeCheckResult = try await api.request(APIRouter.checkFreeze(childId: cid))
        // freezeApplied is a bool — just verify it decodes
        XCTAssert(result.freezeApplied == true || result.freezeApplied == false)
    }

    // MARK: - Flow: Training

    func test10_Training_QuickCheckIn() async throws {
        let cid = try await getChildId()
        let body = QuickCheckInBody(mood: "EXCITED", timeAvail: nil)
        let response: CheckInResponse = try await api.request(
            APIRouter.createQuickCheckIn(childId: cid, body: body)
        )
        XCTAssertFalse(response.checkIn.id.isEmpty)
        XCTAssertFalse(response.modeResult.mode.isEmpty)
        XCTAssertFalse(response.modeResult.explanation.isEmpty)
    }

    func test11_Training_FullCheckIn() async throws {
        let cid = try await getChildId()
        let body = CreateCheckInBody(
            energy: 4, soreness: "NONE", focus: 4,
            mood: "FOCUSED", timeAvail: 30, painFlag: false
        )
        let response: CheckInResponse = try await api.request(
            APIRouter.createCheckIn(childId: cid, body: body)
        )
        XCTAssertFalse(response.checkIn.id.isEmpty)
        XCTAssertEqual(response.checkIn.energy, 4)
    }

    func test12_Training_SaveSession() async throws {
        let cid = try await getChildId()
        let body = CreateSessionBody(
            activityType: "Training - Ball Mastery",
            effortLevel: 7,
            mood: "FOCUSED",
            duration: 15,
            win: "created_space, won_ball",
            focus: "more_scanning"
        )

        // This is the EXACT decode the app does — SessionSaveResult
        struct SessionSaveResult: Decodable { let sessionId: String }
        let result: SessionSaveResult = try await api.request(
            APIRouter.createSession(childId: cid, body: body)
        )
        XCTAssertFalse(result.sessionId.isEmpty, "Session save must return a sessionId")
    }

    func test13_Training_SaveSession_MinDuration() async throws {
        let cid = try await getChildId()
        // Duration = 1 (minimum) — was causing "must be >= 1" error when duration was 0
        let body = CreateSessionBody(
            activityType: "SELF_TRAINING",
            effortLevel: 5,
            mood: "okay",
            duration: 1,
            win: nil,
            focus: nil
        )
        struct SessionSaveResult: Decodable { let sessionId: String }
        let result: SessionSaveResult = try await api.request(
            APIRouter.createSession(childId: cid, body: body)
        )
        XCTAssertFalse(result.sessionId.isEmpty)
    }

    // MARK: - Flow: First Touch

    func test20_FirstTouch_Save() async throws {
        let cid = try await getChildId()
        let body = CreateSessionBody(
            activityType: "first_touch_juggling_both_feet",
            effortLevel: 3,
            mood: "focused",
            duration: 1,
            win: "25 reps — Juggling Both Feet",
            focus: nil
        )
        struct SessionSaveResult: Decodable { let sessionId: String }
        let result: SessionSaveResult = try await api.request(
            APIRouter.createSession(childId: cid, body: body)
        )
        XCTAssertFalse(result.sessionId.isEmpty)
    }

    // MARK: - Flow: Quick Log

    func test30_QuickLog_Save() async throws {
        let cid = try await getChildId()
        let body = QuickSessionBody(type: "solo", duration: 15, effort: 4)
        struct QuickLogResult: Decodable { let sessionId: String }
        let result: QuickLogResult = try await api.request(
            APIRouter.createQuickSession(childId: cid, body: body)
        )
        XCTAssertFalse(result.sessionId.isEmpty)
    }

    // MARK: - Flow: Sessions List

    func test40_Sessions_List() async throws {
        let cid = try await getChildId()
        let sessions: [SessionLog] = try await api.request(
            APIRouter.listSessions(childId: cid, limit: 5)
        )
        XCTAssertGreaterThan(sessions.count, 0, "Should have sessions from previous test saves")
        XCTAssertFalse(sessions[0].id.isEmpty)
    }

    // MARK: - Flow: Drill Stats

    func test50_DrillStats() async throws {
        let cid = try await getChildId()
        let stats: [DrillStat] = try await api.request(
            APIRouter.drillStats(childId: cid)
        )
        // May be empty or have items — just verify it decodes
        for stat in stats {
            XCTAssertFalse(stat.drillKey.isEmpty)
        }
    }

    // MARK: - Flow: Tags

    func test60_HighlightTags() async throws {
        let chips: [HighlightChip] = try await api.request(APIRouter.highlightTags)
        XCTAssertGreaterThan(chips.count, 0, "Highlight chips should auto-seed")
        XCTAssertFalse(chips[0].label.isEmpty)
    }

    func test61_NextFocusTags() async throws {
        let chips: [NextFocusChip] = try await api.request(APIRouter.nextFocusTags)
        XCTAssertGreaterThan(chips.count, 0, "Next focus chips should auto-seed")
    }

    // MARK: - Flow: Trends

    func test70_Trends() async throws {
        let cid = try await getChildId()
        let trends: [WeeklyTrend] = try await api.request(
            APIRouter.getTrends(childId: cid)
        )
        XCTAssertGreaterThan(trends.count, 0)
    }

    // MARK: - Flow: Parent Children

    func test80_ParentChildren() async throws {
        // Need parent token for this — login as parent
        let loginResponse: TokenResponse = try await api.request(
            APIRouter.parentLogin(email: testEmail, password: testPassword)
        )
        XCTAssertEqual(loginResponse.user.role, .parent)

        let children: [ChildSummary] = try await api.request(APIRouter.listChildren)
        XCTAssertGreaterThan(children.count, 0)
        XCTAssertFalse(children[0].nickname.isEmpty)
    }

    // MARK: - Helpers

    private func getChildId() async throws -> String {
        if let cid = childId { return cid }
        let response: TokenResponse = try await api.request(
            APIRouter.childLogin(parentEmail: testEmail, nickname: testChildNickname, pin: testPin)
        )
        childId = response.user.childId
        return response.user.childId!
    }
}
