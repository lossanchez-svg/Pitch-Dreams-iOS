import XCTest
@testable import PitchDreams

final class APIRouterTests: XCTestCase {

    // MARK: - Path Correctness

    func testParentLoginPath() {
        let route = APIRouter.parentLogin(email: "a@b.com", password: "p")
        XCTAssertEqual(route.path, "/auth/token")
    }

    func testChildLoginPath() {
        let route = APIRouter.childLogin(parentEmail: "a@b.com", nickname: "Kid", pin: "1111")
        XCTAssertEqual(route.path, "/auth/token")
    }

    func testSignupPath() {
        let route = APIRouter.signup(email: "a@b.com", password: "p")
        XCTAssertEqual(route.path, "/auth/signup")
    }

    func testForgotPasswordPath() {
        let route = APIRouter.forgotPassword(email: "a@b.com")
        XCTAssertEqual(route.path, "/auth/forgot-password")
    }

    func testResetPasswordPath() {
        let route = APIRouter.resetPassword(token: "tok", password: "new")
        XCTAssertEqual(route.path, "/auth/reset-password")
    }

    func testListChildrenPath() {
        XCTAssertEqual(APIRouter.listChildren.path, "/parent/children")
    }

    func testCreateChildPath() {
        let body = CreateChildBody(nickname: "Kid", age: 10, position: nil, goals: nil, avatarId: "wolf", avatarColor: nil, freeTextEnabled: nil, trainingWindowStart: nil, trainingWindowEnd: nil)
        let route = APIRouter.createChild(parentId: "p1", body: body)
        XCTAssertEqual(route.path, "/parent/children")
    }

    func testAddChildPath() {
        let body = CreateChildBody(nickname: "Kid", age: 10, position: nil, goals: nil, avatarId: "wolf", avatarColor: nil, freeTextEnabled: nil, trainingWindowStart: nil, trainingWindowEnd: nil)
        let route = APIRouter.addChild(body: body)
        XCTAssertEqual(route.path, "/parent/children")
    }

    func testSetChildPinPath() {
        let route = APIRouter.setChildPin(childId: "c-123", pin: "1234")
        XCTAssertEqual(route.path, "/parent/children/c-123/pin")
    }

    func testResetChildProgressPath() {
        let route = APIRouter.resetChildProgress(childId: "c-123")
        XCTAssertEqual(route.path, "/parent/reset-progress/c-123")
    }

    func testDeleteParentAccountPath() {
        XCTAssertEqual(APIRouter.deleteParentAccount.path, "/parent/account")
    }

    func testUpdateChildPermissionsPath() {
        let perms = PermissionsUpdate(freeTextEnabled: true, voiceEnabled: true)
        let route = APIRouter.updateChildPermissions(childId: "c-123", permissions: perms)
        XCTAssertEqual(route.path, "/parent/children/c-123/permissions")
    }

    func testExportChildDataPath() {
        let route = APIRouter.exportChildData(childId: "c-123")
        XCTAssertEqual(route.path, "/parent/children/c-123/export")
    }

    func testDeleteChildPath() {
        let route = APIRouter.deleteChild(childId: "c-123")
        XCTAssertEqual(route.path, "/parent/children/c-123")
    }

    func testGetProfilePath() {
        let route = APIRouter.getProfile(childId: "c-123")
        XCTAssertEqual(route.path, "/children/c-123/profile")
    }

    func testUpdateAvatarPath() {
        let route = APIRouter.updateAvatar(childId: "c-123", avatarId: "lion")
        XCTAssertEqual(route.path, "/children/c-123/profile")
    }

    func testListSessionsPath() {
        let route = APIRouter.listSessions(childId: "c-123", limit: 20)
        XCTAssertEqual(route.path, "/children/c-123/sessions")
    }

    func testCreateSessionPath() {
        let body = CreateSessionBody(effortLevel: 5, mood: "OKAY", duration: 30)
        let route = APIRouter.createSession(childId: "c-123", body: body)
        XCTAssertEqual(route.path, "/children/c-123/sessions")
    }

    func testCreateQuickSessionPath() {
        let body = QuickSessionBody(type: "solo", duration: 15, effort: 5)
        let route = APIRouter.createQuickSession(childId: "c-123", body: body)
        XCTAssertEqual(route.path, "/children/c-123/sessions/quick")
    }

    func testListActivitiesPath() {
        let route = APIRouter.listActivities(childId: "c-123", limit: 10)
        XCTAssertEqual(route.path, "/children/c-123/activities")
    }

    func testCreateActivityPath() {
        let body = CreateActivityBody(activityType: "TEAM_TRAINING", durationMinutes: 90, gameIQImpact: "HIGH")
        let route = APIRouter.createActivity(childId: "c-123", body: body)
        XCTAssertEqual(route.path, "/children/c-123/activities")
    }

    func testListCheckInsPath() {
        let route = APIRouter.listCheckIns(childId: "c-123", limit: 10)
        XCTAssertEqual(route.path, "/children/c-123/check-ins")
    }

    func testCreateCheckInPath() {
        let body = CreateCheckInBody(energy: 7, soreness: "LIGHT", focus: 8, mood: "FOCUSED", timeAvail: 60, painFlag: false)
        let route = APIRouter.createCheckIn(childId: "c-123", body: body)
        XCTAssertEqual(route.path, "/children/c-123/check-ins")
    }

    func testCreateQuickCheckInPath() {
        let body = QuickCheckInBody(mood: "FOCUSED")
        let route = APIRouter.createQuickCheckIn(childId: "c-123", body: body)
        XCTAssertEqual(route.path, "/children/c-123/check-ins/quick")
    }

    func testTodayCheckInPath() {
        let route = APIRouter.todayCheckIn(childId: "c-123")
        XCTAssertEqual(route.path, "/children/c-123/check-ins/today")
    }

    func testUpdateCheckInPath() {
        let body = UpdateCheckInBody(qualityRating: 5)
        let route = APIRouter.updateCheckIn(childId: "c-123", checkInId: "ci-1", body: body)
        XCTAssertEqual(route.path, "/children/c-123/check-ins/ci-1")
    }

    func testGetTrendsPath() {
        let route = APIRouter.getTrends(childId: "c-123", weeks: 4)
        XCTAssertEqual(route.path, "/children/c-123/trends")
    }

    func testGetNudgePath() {
        let route = APIRouter.getNudge(childId: "c-123")
        XCTAssertEqual(route.path, "/children/c-123/nudge")
    }

    func testListArcsPath() {
        let route = APIRouter.listArcs(childId: "c-123")
        XCTAssertEqual(route.path, "/children/c-123/arcs")
    }

    func testActiveArcPath() {
        let route = APIRouter.activeArc(childId: "c-123")
        XCTAssertEqual(route.path, "/children/c-123/arcs/active")
    }

    func testStartArcPath() {
        let body = StartArcBody(arcId: "arc-1")
        let route = APIRouter.startArc(childId: "c-123", body: body)
        XCTAssertEqual(route.path, "/children/c-123/arcs")
    }

    func testUpdateArcStatePath() {
        let body = UpdateArcBody(action: "complete")
        let route = APIRouter.updateArcState(childId: "c-123", arcStateId: "as-1", body: body)
        XCTAssertEqual(route.path, "/children/c-123/arcs/as-1")
    }

    func testUpdateArcProgressPath() {
        let body = ArcProgressBody(sessionMode: "PEAK", sessionCompleted: true)
        let route = APIRouter.updateArcProgress(childId: "c-123", body: body)
        XCTAssertEqual(route.path, "/children/c-123/arcs/progress")
    }

    func testArcSuggestionPath() {
        let route = APIRouter.arcSuggestion(childId: "c-123")
        XCTAssertEqual(route.path, "/children/c-123/arcs/suggestion")
    }

    func testLogDrillPath() {
        let body = LogDrillBody(drillKey: "bm-toe-taps")
        let route = APIRouter.logDrill(childId: "c-123", body: body)
        XCTAssertEqual(route.path, "/children/c-123/drills")
    }

    func testDrillStatsPath() {
        let route = APIRouter.drillStats(childId: "c-123")
        XCTAssertEqual(route.path, "/children/c-123/drills/stats")
    }

    func testLessonProgressPath() {
        let route = APIRouter.lessonProgress(childId: "c-123")
        XCTAssertEqual(route.path, "/children/c-123/lessons/progress")
    }

    func testUpdateLessonProgressPath() {
        let body = LessonProgressBody(completed: true)
        let route = APIRouter.updateLessonProgress(childId: "c-123", lessonId: "lesson-1", body: body)
        XCTAssertEqual(route.path, "/children/c-123/lessons/lesson-1/progress")
    }

    func testSubmitQuizPath() {
        let body = QuizResultBody(score: 4, total: 5)
        let route = APIRouter.submitQuiz(childId: "c-123", lessonId: "lesson-1", body: body)
        XCTAssertEqual(route.path, "/children/c-123/lessons/lesson-1/quiz")
    }

    func testGetStreaksPath() {
        let route = APIRouter.getStreaks(childId: "c-123")
        XCTAssertEqual(route.path, "/children/c-123/streaks")
    }

    func testCheckFreezePath() {
        let route = APIRouter.checkFreeze(childId: "c-123")
        XCTAssertEqual(route.path, "/children/c-123/streaks/freeze-check")
    }

    func testRecordMilestonePath() {
        let body = MilestoneBody(milestone: 7)
        let route = APIRouter.recordMilestone(childId: "c-123", body: body)
        XCTAssertEqual(route.path, "/children/c-123/streaks/milestones")
    }

    func testFocusTagsPath() {
        XCTAssertEqual(APIRouter.focusTags.path, "/tags/focus")
    }

    func testHighlightTagsPath() {
        XCTAssertEqual(APIRouter.highlightTags.path, "/tags/highlights")
    }

    func testNextFocusTagsPath() {
        XCTAssertEqual(APIRouter.nextFocusTags.path, "/tags/next-focus")
    }

    func testListFacilitiesPath() {
        XCTAssertEqual(APIRouter.listFacilities.path, "/facilities")
    }

    func testRecentFacilitiesPath() {
        let route = APIRouter.recentFacilities(limit: 5)
        XCTAssertEqual(route.path, "/facilities/recent")
    }

    func testCreateFacilityPath() {
        let body = CreateFacilityBody(name: "Field A")
        let route = APIRouter.createFacility(body: body)
        XCTAssertEqual(route.path, "/facilities")
    }

    func testListCoachesPath() {
        XCTAssertEqual(APIRouter.listCoaches.path, "/coaches")
    }

    func testCreateCoachPath() {
        let body = CreateCoachBody(displayName: "Coach Lee")
        let route = APIRouter.createCoach(body: body)
        XCTAssertEqual(route.path, "/coaches")
    }

    func testListProgramsPath() {
        XCTAssertEqual(APIRouter.listPrograms.path, "/programs")
    }

    func testCreateProgramPath() {
        let body = CreateProgramBody(name: "Academy", type: "academy")
        let route = APIRouter.createProgram(body: body)
        XCTAssertEqual(route.path, "/programs")
    }

    // MARK: - HTTP Methods

    func testAuthEndpointsArePost() {
        XCTAssertEqual(APIRouter.parentLogin(email: "", password: "").method, .post)
        XCTAssertEqual(APIRouter.childLogin(parentEmail: "", nickname: "", pin: "").method, .post)
        XCTAssertEqual(APIRouter.signup(email: "", password: "").method, .post)
        XCTAssertEqual(APIRouter.forgotPassword(email: "").method, .post)
        XCTAssertEqual(APIRouter.resetPassword(token: "", password: "").method, .post)
    }

    func testCreateEndpointsArePost() {
        let childBody = CreateChildBody(nickname: "", age: 10, position: nil, goals: nil, avatarId: "", avatarColor: nil, freeTextEnabled: nil, trainingWindowStart: nil, trainingWindowEnd: nil)
        XCTAssertEqual(APIRouter.createChild(parentId: "p", body: childBody).method, .post)
        XCTAssertEqual(APIRouter.addChild(body: childBody).method, .post)

        let sessionBody = CreateSessionBody(effortLevel: 5, mood: "OKAY", duration: 30)
        XCTAssertEqual(APIRouter.createSession(childId: "c", body: sessionBody).method, .post)

        let quickBody = QuickSessionBody(type: "solo", duration: 15, effort: 5)
        XCTAssertEqual(APIRouter.createQuickSession(childId: "c", body: quickBody).method, .post)

        let actBody = CreateActivityBody(activityType: "TEAM", durationMinutes: 90, gameIQImpact: "HIGH")
        XCTAssertEqual(APIRouter.createActivity(childId: "c", body: actBody).method, .post)

        let drillBody = LogDrillBody(drillKey: "key")
        XCTAssertEqual(APIRouter.logDrill(childId: "c", body: drillBody).method, .post)

        XCTAssertEqual(APIRouter.resetChildProgress(childId: "c").method, .post)
    }

    func testUpdateEndpointsArePatch() {
        let perms = PermissionsUpdate(freeTextEnabled: true, voiceEnabled: true)
        XCTAssertEqual(APIRouter.updateChildPermissions(childId: "c", permissions: perms).method, .patch)

        let checkInBody = UpdateCheckInBody(qualityRating: 5)
        XCTAssertEqual(APIRouter.updateCheckIn(childId: "c", checkInId: "ci", body: checkInBody).method, .patch)

        let arcBody = UpdateArcBody(action: "pause")
        XCTAssertEqual(APIRouter.updateArcState(childId: "c", arcStateId: "as", body: arcBody).method, .patch)

        XCTAssertEqual(APIRouter.updateAvatar(childId: "c", avatarId: "lion").method, .patch)
    }

    func testSetChildPinIsPut() {
        XCTAssertEqual(APIRouter.setChildPin(childId: "c", pin: "1234").method, .put)
    }

    func testDeleteEndpointsAreDelete() {
        XCTAssertEqual(APIRouter.deleteChild(childId: "c").method, .delete)
        XCTAssertEqual(APIRouter.deleteParentAccount.method, .delete)
    }

    func testGetEndpoints() {
        XCTAssertEqual(APIRouter.listChildren.method, .get)
        XCTAssertEqual(APIRouter.getProfile(childId: "c").method, .get)
        XCTAssertEqual(APIRouter.listSessions(childId: "c").method, .get)
        XCTAssertEqual(APIRouter.listActivities(childId: "c").method, .get)
        XCTAssertEqual(APIRouter.listCheckIns(childId: "c").method, .get)
        XCTAssertEqual(APIRouter.todayCheckIn(childId: "c").method, .get)
        XCTAssertEqual(APIRouter.getTrends(childId: "c").method, .get)
        XCTAssertEqual(APIRouter.getNudge(childId: "c").method, .get)
        XCTAssertEqual(APIRouter.listArcs(childId: "c").method, .get)
        XCTAssertEqual(APIRouter.activeArc(childId: "c").method, .get)
        XCTAssertEqual(APIRouter.arcSuggestion(childId: "c").method, .get)
        XCTAssertEqual(APIRouter.drillStats(childId: "c").method, .get)
        XCTAssertEqual(APIRouter.lessonProgress(childId: "c").method, .get)
        XCTAssertEqual(APIRouter.getStreaks(childId: "c").method, .get)
        XCTAssertEqual(APIRouter.focusTags.method, .get)
        XCTAssertEqual(APIRouter.highlightTags.method, .get)
        XCTAssertEqual(APIRouter.nextFocusTags.method, .get)
        XCTAssertEqual(APIRouter.listFacilities.method, .get)
        XCTAssertEqual(APIRouter.recentFacilities().method, .get)
        XCTAssertEqual(APIRouter.listCoaches.method, .get)
        XCTAssertEqual(APIRouter.listPrograms.method, .get)
        XCTAssertEqual(APIRouter.exportChildData(childId: "c").method, .get)
    }

    // MARK: - API Base Path

    func testNonV1EndpointsUseApiBase() {
        XCTAssertEqual(APIRouter.signup(email: "", password: "").apiBasePath, "/api")
        XCTAssertEqual(APIRouter.forgotPassword(email: "").apiBasePath, "/api")
        XCTAssertEqual(APIRouter.resetPassword(token: "", password: "").apiBasePath, "/api")
        let body = CreateChildBody(nickname: "", age: 10, position: nil, goals: nil, avatarId: "", avatarColor: nil, freeTextEnabled: nil, trainingWindowStart: nil, trainingWindowEnd: nil)
        XCTAssertEqual(APIRouter.createChild(parentId: "p", body: body).apiBasePath, "/api")
        XCTAssertEqual(APIRouter.addChild(body: body).apiBasePath, "/api")
        XCTAssertEqual(APIRouter.setChildPin(childId: "c", pin: "1234").apiBasePath, "/api")
    }

    func testV1EndpointsUseV1Base() {
        XCTAssertEqual(APIRouter.parentLogin(email: "", password: "").apiBasePath, "/api/v1")
        XCTAssertEqual(APIRouter.listChildren.apiBasePath, "/api/v1")
        XCTAssertEqual(APIRouter.getProfile(childId: "c").apiBasePath, "/api/v1")
        XCTAssertEqual(APIRouter.listSessions(childId: "c").apiBasePath, "/api/v1")
        XCTAssertEqual(APIRouter.getStreaks(childId: "c").apiBasePath, "/api/v1")
        XCTAssertEqual(APIRouter.focusTags.apiBasePath, "/api/v1")
    }

    // MARK: - requiresAuth

    func testPublicEndpointsDoNotRequireAuth() {
        XCTAssertFalse(APIRouter.parentLogin(email: "", password: "").requiresAuth)
        XCTAssertFalse(APIRouter.childLogin(parentEmail: "", nickname: "", pin: "").requiresAuth)
        XCTAssertFalse(APIRouter.signup(email: "", password: "").requiresAuth)
        XCTAssertFalse(APIRouter.forgotPassword(email: "").requiresAuth)
        XCTAssertFalse(APIRouter.resetPassword(token: "", password: "").requiresAuth)
        let body = CreateChildBody(nickname: "", age: 10, position: nil, goals: nil, avatarId: "", avatarColor: nil, freeTextEnabled: nil, trainingWindowStart: nil, trainingWindowEnd: nil)
        XCTAssertFalse(APIRouter.createChild(parentId: "p", body: body).requiresAuth)
    }

    func testAuthenticatedEndpointsRequireAuth() {
        XCTAssertTrue(APIRouter.listChildren.requiresAuth)
        XCTAssertTrue(APIRouter.getProfile(childId: "c").requiresAuth)
        XCTAssertTrue(APIRouter.listSessions(childId: "c").requiresAuth)
        XCTAssertTrue(APIRouter.createSession(childId: "c", body: CreateSessionBody(effortLevel: 5, mood: "OKAY", duration: 30)).requiresAuth)
        XCTAssertTrue(APIRouter.getStreaks(childId: "c").requiresAuth)
        XCTAssertTrue(APIRouter.focusTags.requiresAuth)
        XCTAssertTrue(APIRouter.listFacilities.requiresAuth)
        XCTAssertTrue(APIRouter.deleteParentAccount.requiresAuth)
        XCTAssertTrue(APIRouter.exportChildData(childId: "c").requiresAuth)
    }

    // MARK: - Query Items

    func testListSessionsQueryLimit() {
        let route = APIRouter.listSessions(childId: "c", limit: 50)
        XCTAssertEqual(route.queryItems?.first?.name, "limit")
        XCTAssertEqual(route.queryItems?.first?.value, "50")
    }

    func testListActivitiesQueryLimit() {
        let route = APIRouter.listActivities(childId: "c", limit: 25)
        XCTAssertEqual(route.queryItems?.first?.name, "limit")
        XCTAssertEqual(route.queryItems?.first?.value, "25")
    }

    func testListCheckInsQueryLimit() {
        let route = APIRouter.listCheckIns(childId: "c", limit: 5)
        XCTAssertEqual(route.queryItems?.first?.name, "limit")
        XCTAssertEqual(route.queryItems?.first?.value, "5")
    }

    func testGetTrendsQueryWeeks() {
        let route = APIRouter.getTrends(childId: "c", weeks: 8)
        XCTAssertEqual(route.queryItems?.first?.name, "weeks")
        XCTAssertEqual(route.queryItems?.first?.value, "8")
    }

    func testRecentFacilitiesQueryLimit() {
        let route = APIRouter.recentFacilities(limit: 10)
        XCTAssertEqual(route.queryItems?.first?.name, "limit")
        XCTAssertEqual(route.queryItems?.first?.value, "10")
    }

    func testEndpointsWithNoQueryItems() {
        XCTAssertNil(APIRouter.parentLogin(email: "", password: "").queryItems)
        XCTAssertNil(APIRouter.getProfile(childId: "c").queryItems)
        XCTAssertNil(APIRouter.focusTags.queryItems)
        XCTAssertNil(APIRouter.listFacilities.queryItems)
    }

    // MARK: - Body Presence

    func testGetEndpointsHaveNoBody() {
        XCTAssertNil(APIRouter.listChildren.body)
        XCTAssertNil(APIRouter.getProfile(childId: "c").body)
        XCTAssertNil(APIRouter.listSessions(childId: "c").body)
        XCTAssertNil(APIRouter.getStreaks(childId: "c").body)
        XCTAssertNil(APIRouter.focusTags.body)
        XCTAssertNil(APIRouter.listFacilities.body)
        XCTAssertNil(APIRouter.drillStats(childId: "c").body)
    }

    func testPostEndpointsHaveBody() {
        XCTAssertNotNil(APIRouter.parentLogin(email: "a@b.com", password: "p").body)
        XCTAssertNotNil(APIRouter.childLogin(parentEmail: "a@b.com", nickname: "K", pin: "1111").body)
        XCTAssertNotNil(APIRouter.signup(email: "a@b.com", password: "p").body)
        XCTAssertNotNil(APIRouter.forgotPassword(email: "a@b.com").body)

        let sessionBody = CreateSessionBody(effortLevel: 5, mood: "OKAY", duration: 30)
        XCTAssertNotNil(APIRouter.createSession(childId: "c", body: sessionBody).body)

        let drillBody = LogDrillBody(drillKey: "key")
        XCTAssertNotNil(APIRouter.logDrill(childId: "c", body: drillBody).body)
    }

    // MARK: - Child ID Substitution

    func testChildIdSubstitutedInPaths() {
        let childId = "child-xyz-789"
        XCTAssertTrue(APIRouter.getProfile(childId: childId).path.contains(childId))
        XCTAssertTrue(APIRouter.listSessions(childId: childId).path.contains(childId))
        XCTAssertTrue(APIRouter.getStreaks(childId: childId).path.contains(childId))
        XCTAssertTrue(APIRouter.drillStats(childId: childId).path.contains(childId))
        XCTAssertTrue(APIRouter.lessonProgress(childId: childId).path.contains(childId))
    }
}
