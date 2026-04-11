import XCTest
@testable import PitchDreams

/// Tests model decoding edge cases: extra fields, missing optionals,
/// unexpected values, and malformed data that could crash in production.
final class ModelDecodingRobustnessTests: XCTestCase {

    private let decoder = JSONDecoder()

    private func decode<T: Decodable>(_ type: T.Type, from json: String, file: StaticString = #file, line: UInt = #line) throws -> T {
        let data = json.data(using: .utf8)!
        return try decoder.decode(type, from: data)
    }

    // MARK: - Extra Fields (Server adds new keys → must not crash)

    func testSessionLogIgnoresExtraFields() throws {
        let json = """
        {
            "id": "sess-extra",
            "childId": "child-1",
            "activityType": "SELF_TRAINING",
            "effortLevel": 5,
            "mood": "FOCUSED",
            "duration": 30,
            "win": null,
            "focus": null,
            "createdAt": "2026-04-01T10:00:00.000Z",
            "newFieldFromServer": "unexpected_value",
            "anotherNewField": 42
        }
        """
        let session = try decode(SessionLog.self, from: json)
        XCTAssertEqual(session.id, "sess-extra")
        XCTAssertEqual(session.duration, 30)
    }

    func testCheckInResponseIgnoresExtraFields() throws {
        let json = """
        {
            "checkIn": {
                "id": "ci-extra",
                "childId": "child-1",
                "energy": 7,
                "soreness": "LIGHT",
                "focus": 8,
                "mood": "FOCUSED",
                "timeAvail": 60,
                "painFlag": false,
                "mode": "NORMAL",
                "modeExplanation": "Good energy.",
                "qualityRating": null,
                "completed": false,
                "activityId": null,
                "createdAt": "2026-04-01T09:00:00.000Z",
                "unexpectedField": true
            },
            "modeResult": {
                "mode": "NORMAL",
                "explanation": "Train normally.",
                "confidence": 0.95
            }
        }
        """
        let response = try decode(CheckInResponse.self, from: json)
        XCTAssertEqual(response.checkIn.id, "ci-extra")
        XCTAssertEqual(response.modeResult.mode, "NORMAL")
    }

    func testWeeklyTrendIgnoresExtraFields() throws {
        let json = """
        {
            "sessionsCount": 3,
            "avgQualityRating": 4.2,
            "completionRate": 0.8,
            "hasPBMovement": true,
            "isLowEngagement": false,
            "weeksLowEngagement": 0,
            "newTrendMetric": "rising",
            "futureFlag": true
        }
        """
        let trend = try decode(WeeklyTrend.self, from: json)
        XCTAssertEqual(trend.sessionsCount, 3)
    }

    func testActivityItemIgnoresExtraFields() throws {
        let json = """
        {
            "id": "act-extra",
            "childId": "child-1",
            "activityType": "GAME",
            "durationMinutes": 90,
            "intensityRPE": 8,
            "gameIQImpact": "HIGH",
            "createdAt": "2026-04-01T16:00:00.000Z",
            "venue": "Stadium A",
            "weather": "sunny"
        }
        """
        let item = try decode(ActivityItem.self, from: json)
        XCTAssertEqual(item.activityType, "GAME")
    }

    // MARK: - All Optional Fields Null

    func testSessionLogAllOptionalsNull() throws {
        let json = """
        {
            "id": "sess-null",
            "childId": "child-1",
            "activityType": null,
            "effortLevel": null,
            "mood": null,
            "duration": null,
            "win": null,
            "focus": null,
            "createdAt": "2026-04-01T10:00:00.000Z"
        }
        """
        let session = try decode(SessionLog.self, from: json)
        XCTAssertNil(session.activityType)
        XCTAssertNil(session.effortLevel)
        XCTAssertNil(session.mood)
        XCTAssertNil(session.duration)
        XCTAssertNil(session.win)
        XCTAssertNil(session.focus)
    }

    func testLessonProgressNullQuizFields() throws {
        let json = """
        {
            "id": "lp-null",
            "childId": "child-1",
            "lessonId": "lesson-abc",
            "completed": false,
            "quizScore": null,
            "quizTotal": null
        }
        """
        let progress = try decode(LessonProgress.self, from: json)
        XCTAssertFalse(progress.completed)
        XCTAssertNil(progress.quizScore)
        XCTAssertNil(progress.quizTotal)
    }

    func testStreakDataWithZeroValues() throws {
        let json = """
        {"freezes": 0, "freezesUsed": 0, "milestones": []}
        """
        let streak = try decode(StreakData.self, from: json)
        XCTAssertEqual(streak.freezes, 0)
        XCTAssertTrue(streak.milestones.isEmpty)
    }

    func testCheckInNullOptionalFields() throws {
        let json = """
        {
            "id": "ci-null",
            "childId": "child-1",
            "energy": 5,
            "soreness": "NONE",
            "focus": 5,
            "mood": "OKAY",
            "timeAvail": 30,
            "painFlag": false,
            "mode": "NORMAL",
            "modeExplanation": null,
            "qualityRating": null,
            "completed": false,
            "activityId": null,
            "createdAt": "2026-04-01T09:00:00.000Z"
        }
        """
        let checkIn = try decode(CheckIn.self, from: json)
        XCTAssertNil(checkIn.modeExplanation)
        XCTAssertNil(checkIn.qualityRating)
        XCTAssertNil(checkIn.activityId)
    }

    // MARK: - Boundary Values

    func testSessionLogWithZeroDuration() throws {
        let json = """
        {
            "id": "sess-zero",
            "childId": "child-1",
            "activityType": "SELF_TRAINING",
            "effortLevel": 1,
            "mood": "TIRED",
            "duration": 0,
            "win": null,
            "focus": null,
            "createdAt": "2026-04-01T10:00:00.000Z"
        }
        """
        let session = try decode(SessionLog.self, from: json)
        XCTAssertEqual(session.duration, 0)
    }

    func testSessionLogWithLargeDuration() throws {
        let json = """
        {
            "id": "sess-big",
            "childId": "child-1",
            "activityType": "SELF_TRAINING",
            "effortLevel": 10,
            "mood": "EXCITED",
            "duration": 999,
            "win": "Everything",
            "focus": "All",
            "createdAt": "2026-04-01T10:00:00.000Z"
        }
        """
        let session = try decode(SessionLog.self, from: json)
        XCTAssertEqual(session.duration, 999)
        XCTAssertEqual(session.effortLevel, 10)
    }

    func testWeeklyTrendWithZeroCompletionRate() throws {
        let json = """
        {
            "sessionsCount": 0,
            "avgQualityRating": null,
            "completionRate": 0.0,
            "hasPBMovement": false,
            "isLowEngagement": true,
            "weeksLowEngagement": 5
        }
        """
        let trend = try decode(WeeklyTrend.self, from: json)
        XCTAssertEqual(trend.completionRate, 0.0)
        XCTAssertEqual(trend.weeksLowEngagement, 5)
    }

    func testWeeklyTrendWithPerfectCompletionRate() throws {
        let json = """
        {
            "sessionsCount": 7,
            "avgQualityRating": 5.0,
            "completionRate": 1.0,
            "hasPBMovement": true,
            "isLowEngagement": false,
            "weeksLowEngagement": 0
        }
        """
        let trend = try decode(WeeklyTrend.self, from: json)
        XCTAssertEqual(trend.completionRate, 1.0)
        XCTAssertEqual(trend.avgQualityRating, 5.0)
    }

    func testStreakDataWithLargeMilestones() throws {
        let json = """
        {"freezes": 5, "freezesUsed": 2, "milestones": [3, 7, 14, 30, 60, 100, 365]}
        """
        let streak = try decode(StreakData.self, from: json)
        XCTAssertEqual(streak.milestones.count, 7)
        XCTAssertEqual(streak.milestones.last, 365)
    }

    // MARK: - Unknown Enum Values (Server adds new types)

    func testUnknownActivityTypeDecodesAsString() throws {
        // ActivityItem.activityType is a String, not enum — should accept anything
        let json = """
        {
            "id": "act-new",
            "childId": "child-1",
            "activityType": "SUPER_ADVANCED_TRAINING",
            "durationMinutes": 60,
            "intensityRPE": 7,
            "gameIQImpact": "EXTREME",
            "createdAt": "2026-04-01T16:00:00.000Z"
        }
        """
        let item = try decode(ActivityItem.self, from: json)
        XCTAssertEqual(item.activityType, "SUPER_ADVANCED_TRAINING")
        XCTAssertEqual(item.gameIQImpact, "EXTREME")
    }

    func testUnknownMoodStringInSessionLog() throws {
        let json = """
        {
            "id": "sess-mood",
            "childId": "child-1",
            "activityType": "SELF_TRAINING",
            "effortLevel": 5,
            "mood": "PUMPED_UP",
            "duration": 30,
            "win": null,
            "focus": null,
            "createdAt": "2026-04-01T10:00:00.000Z"
        }
        """
        // mood is String? so unknown values won't crash
        let session = try decode(SessionLog.self, from: json)
        XCTAssertEqual(session.mood, "PUMPED_UP")
    }

    func testUnknownCheckInMode() throws {
        let json = """
        {
            "id": "ci-mode",
            "childId": "child-1",
            "energy": 9,
            "soreness": "NONE",
            "focus": 9,
            "mood": "EXCITED",
            "timeAvail": 120,
            "painFlag": false,
            "mode": "SUPER_PEAK",
            "modeExplanation": "You are on fire!",
            "qualityRating": null,
            "completed": false,
            "activityId": null,
            "createdAt": "2026-04-01T09:00:00.000Z"
        }
        """
        // CheckIn.mode is String, not enum
        let checkIn = try decode(CheckIn.self, from: json)
        XCTAssertEqual(checkIn.mode, "SUPER_PEAK")
    }

    func testUnknownArcStatus() throws {
        let json = """
        {
            "id": "as-1",
            "arcId": "arc-focus",
            "status": "PAUSED_BY_PARENT",
            "dayIndex": 3,
            "sessionsCompleted": 2
        }
        """
        // ArcState.status is String, not enum
        let arc = try decode(ArcState.self, from: json)
        XCTAssertEqual(arc.status, "PAUSED_BY_PARENT")
    }

    // MARK: - TokenResponse Edge Cases

    func testTokenResponseWithNullChildId() throws {
        let json = """
        {
            "token": "jwt-abc-123",
            "user": {
                "id": "parent-99",
                "role": "parent",
                "email": "test@test.com",
                "name": "Test Parent",
                "childId": null,
                "parentId": null
            }
        }
        """
        let response = try decode(TokenResponse.self, from: json)
        XCTAssertNil(response.user.childId)
        XCTAssertEqual(response.user.role, .parent)
    }

    func testTokenResponseWithChildRole() throws {
        let json = """
        {
            "token": "jwt-child-token",
            "user": {
                "id": "child-abc",
                "role": "child",
                "email": "parent@test.com",
                "name": "KidName",
                "childId": "child-abc",
                "parentId": "parent-xyz"
            }
        }
        """
        let response = try decode(TokenResponse.self, from: json)
        XCTAssertEqual(response.user.role, .child)
        XCTAssertEqual(response.user.childId, "child-abc")
        XCTAssertEqual(response.user.parentId, "parent-xyz")
    }

    func testTokenResponseWithNullOptionals() throws {
        let json = """
        {
            "token": "jwt-minimal",
            "user": {
                "id": "user-1",
                "role": "parent",
                "email": null,
                "name": null,
                "childId": null,
                "parentId": null
            }
        }
        """
        let response = try decode(TokenResponse.self, from: json)
        XCTAssertNil(response.user.email)
        XCTAssertNil(response.user.name)
    }

    // MARK: - Malformed Data (Should throw, not crash)

    func testSessionLogMissingRequiredFieldThrows() {
        let json = """
        {
            "childId": "child-1",
            "createdAt": "2026-04-01T10:00:00.000Z"
        }
        """
        XCTAssertThrowsError(try decode(SessionLog.self, from: json))
    }

    func testTokenResponseMissingTokenThrows() {
        let json = """
        {
            "user": {
                "id": "user-1",
                "role": "parent",
                "email": null,
                "name": null,
                "childId": null,
                "parentId": null
            }
        }
        """
        XCTAssertThrowsError(try decode(TokenResponse.self, from: json))
    }

    func testTokenResponseMissingUserThrows() {
        let json = """
        {"token": "jwt-no-user"}
        """
        XCTAssertThrowsError(try decode(TokenResponse.self, from: json))
    }

    func testInvalidJsonThrows() {
        let json = "not valid json at all"
        XCTAssertThrowsError(try decode(SessionLog.self, from: json))
    }

    func testEmptyJsonObjectThrows() {
        let json = "{}"
        XCTAssertThrowsError(try decode(SessionLog.self, from: json))
        XCTAssertThrowsError(try decode(TokenResponse.self, from: json))
        XCTAssertThrowsError(try decode(CheckIn.self, from: json))
    }

    // MARK: - ChildSummary Edge Cases

    func testChildSummaryNullOptionals() throws {
        let json = """
        {
            "id": "child-1",
            "nickname": "TestKid",
            "age": 8,
            "position": null,
            "avatarId": null
        }
        """
        let child = try decode(ChildSummary.self, from: json)
        XCTAssertEqual(child.age, 8)
        XCTAssertNil(child.position)
        XCTAssertNil(child.avatarId)
    }

    func testChildSummaryBoundaryAge() throws {
        let json = """
        {"id": "child-min", "nickname": "Young", "age": 8, "position": null, "avatarId": null}
        """
        let child = try decode(ChildSummary.self, from: json)
        XCTAssertEqual(child.age, 8)
    }

    // MARK: - DrillStat Edge Cases

    func testDrillStatZeroAttempts() throws {
        let json = """
        {
            "drillId": "ds-zero",
            "drillKey": "bm-toe-taps",
            "totalAttempts": 0,
            "avgConfidence": 0.0,
            "lastAttempt": null
        }
        """
        let stat = try decode(DrillStat.self, from: json)
        XCTAssertEqual(stat.totalAttempts, 0)
        XCTAssertEqual(stat.avgConfidence, 0.0)
    }

    func testDrillStatHighConfidence() throws {
        let json = """
        {
            "drillId": "ds-high",
            "drillKey": "pass-wall",
            "totalAttempts": 500,
            "avgConfidence": 5.0,
            "lastAttempt": "2026-04-10T10:00:00.000Z"
        }
        """
        let stat = try decode(DrillStat.self, from: json)
        XCTAssertEqual(stat.totalAttempts, 500)
        XCTAssertEqual(stat.avgConfidence, 5.0)
    }

    // MARK: - CoachNudge Edge Cases

    func testCoachNudgeWithAllFields() throws {
        let json = """
        {
            "type": "challenge",
            "title": "Try Something New",
            "message": "You haven't tried wall passes in a while.",
            "actionLabel": "Start Drill",
            "actionValue": "bm-wall-pass"
        }
        """
        let nudge = try decode(CoachNudge.self, from: json)
        XCTAssertEqual(nudge.type, "challenge")
        XCTAssertEqual(nudge.actionValue, "bm-wall-pass")
    }

    // MARK: - Array Decoding

    func testEmptyArrayDecodes() throws {
        let json = "[]"
        let sessions = try decode([SessionLog].self, from: json)
        XCTAssertTrue(sessions.isEmpty)

        let trends = try decode([WeeklyTrend].self, from: json)
        XCTAssertTrue(trends.isEmpty)
    }

    func testLargeArrayDecodes() throws {
        // Simulate 50 sessions
        var items: [String] = []
        for i in 0..<50 {
            items.append("""
            {"id":"s-\(i)","childId":"c","activityType":"SELF_TRAINING","effortLevel":\(i % 10 + 1),"mood":"OKAY","duration":\(i * 5 + 10),"win":null,"focus":null,"createdAt":"2026-04-01T10:00:00.000Z"}
            """)
        }
        let json = "[\(items.joined(separator: ","))]"
        let sessions = try decode([SessionLog].self, from: json)
        XCTAssertEqual(sessions.count, 50)
    }
}
