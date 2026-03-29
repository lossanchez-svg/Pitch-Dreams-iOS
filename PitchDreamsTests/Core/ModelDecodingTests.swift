import XCTest
@testable import PitchDreams

final class ModelDecodingTests: XCTestCase {

    private let decoder = JSONDecoder()

    private func decode<T: Decodable>(_ type: T.Type, from json: String, file: StaticString = #file, line: UInt = #line) throws -> T {
        let data = json.data(using: .utf8)!
        return try decoder.decode(type, from: data)
    }

    // MARK: - TokenResponse

    func testDecodeTokenResponse() throws {
        let json = """
        {
            "token": "eyJhbGciOiJIUzI1NiJ9.test",
            "user": {
                "id": "parent-123",
                "role": "parent",
                "email": "test@example.com",
                "name": "Test Parent",
                "childId": null,
                "parentId": null
            }
        }
        """
        let response = try decode(TokenResponse.self, from: json)
        XCTAssertFalse(response.token.isEmpty)
        XCTAssertEqual(response.user.role, .parent)
        XCTAssertEqual(response.user.id, "parent-123")
    }

    // MARK: - ChildProfileDetail

    func testDecodeChildProfileDetail() throws {
        let json = """
        {
            "nickname": "TestKid",
            "avatarId": "avatar-soccer",
            "skipAnimations": false,
            "voiceEnabled": true
        }
        """
        let profile = try decode(ChildProfileDetail.self, from: json)
        XCTAssertEqual(profile.nickname, "TestKid")
        XCTAssertEqual(profile.avatarId, "avatar-soccer")
        XCTAssertFalse(profile.skipAnimations)
        XCTAssertTrue(profile.voiceEnabled)
    }

    // MARK: - SessionLog

    func testDecodeSessionLog() throws {
        let json = """
        {
            "id": "sess-001",
            "childId": "child-456",
            "activityType": "SELF_TRAINING",
            "effortLevel": 4,
            "mood": "FOCUSED",
            "duration": 45,
            "win": "Great control",
            "focus": "Dribbling",
            "createdAt": "2026-03-28T14:30:00.000Z"
        }
        """
        let session = try decode(SessionLog.self, from: json)
        XCTAssertEqual(session.id, "sess-001")
        XCTAssertEqual(session.duration, 45)
        XCTAssertEqual(session.effortLevel, 4)
    }

    // MARK: - CheckInResponse

    func testDecodeCheckInResponse() throws {
        let json = """
        {
            "checkIn": {
                "id": "ci-001",
                "childId": "child-456",
                "energy": 7,
                "soreness": "LIGHT",
                "focus": 8,
                "mood": "FOCUSED",
                "timeAvail": 60,
                "painFlag": false,
                "mode": "NORMAL",
                "modeExplanation": "Good session ahead.",
                "qualityRating": null,
                "completed": false,
                "activityId": null,
                "createdAt": "2026-03-29T09:00:00.000Z"
            },
            "modeResult": {
                "mode": "NORMAL",
                "explanation": "Good energy for training."
            }
        }
        """
        let response = try decode(CheckInResponse.self, from: json)
        XCTAssertEqual(response.checkIn.id, "ci-001")
        XCTAssertEqual(response.modeResult.mode, "NORMAL")
        XCTAssertFalse(response.checkIn.painFlag)
    }

    // MARK: - StreakData

    func testDecodeStreakData() throws {
        let json = """
        {"freezes": 2, "freezesUsed": 0, "milestones": []}
        """
        let streak = try decode(StreakData.self, from: json)
        XCTAssertEqual(streak.freezes, 2)
        XCTAssertEqual(streak.freezesUsed, 0)
        XCTAssertTrue(streak.milestones.isEmpty)
    }

    func testDecodeStreakDataWithMilestones() throws {
        let json = """
        {"freezes": 3, "freezesUsed": 1, "milestones": [3, 7, 14]}
        """
        let streak = try decode(StreakData.self, from: json)
        XCTAssertEqual(streak.milestones, [3, 7, 14])
    }

    // MARK: - DrillStat

    func testDecodeDrillStat() throws {
        let json = """
        {
            "drillId": "ds-001",
            "drillKey": "bm-toe-taps",
            "totalAttempts": 25,
            "avgConfidence": 3.5,
            "lastAttempt": null
        }
        """
        let stat = try decode(DrillStat.self, from: json)
        XCTAssertEqual(stat.drillKey, "bm-toe-taps")
        XCTAssertEqual(stat.totalAttempts, 25)
        XCTAssertNil(stat.lastAttempt)
    }

    func testDecodeDrillStatWithLastAttempt() throws {
        let json = """
        {
            "drillId": "ds-002",
            "drillKey": "pass-wall",
            "totalAttempts": 10,
            "avgConfidence": 4.0,
            "lastAttempt": "2026-03-28T10:00:00.000Z"
        }
        """
        let stat = try decode(DrillStat.self, from: json)
        XCTAssertNotNil(stat.lastAttempt)
    }

    // MARK: - CoachNudge

    func testDecodeCoachNudge() throws {
        let json = """
        {
            "type": "encouragement",
            "title": "Nice streak!",
            "message": "You have trained 3 days in a row.",
            "actionLabel": "Keep Going",
            "actionValue": "training"
        }
        """
        let nudge = try decode(CoachNudge.self, from: json)
        XCTAssertEqual(nudge.type, "encouragement")
        XCTAssertEqual(nudge.title, "Nice streak!")
    }

    // MARK: - WeeklyTrend

    func testDecodeWeeklyTrend() throws {
        let json = """
        {
            "sessionsCount": 4,
            "avgQualityRating": 3.8,
            "completionRate": 0.75,
            "hasPBMovement": true,
            "isLowEngagement": false,
            "weeksLowEngagement": 0
        }
        """
        let trend = try decode(WeeklyTrend.self, from: json)
        XCTAssertEqual(trend.sessionsCount, 4)
        XCTAssertEqual(trend.completionRate, 0.75)
        XCTAssertTrue(trend.hasPBMovement)
    }

    func testDecodeWeeklyTrendNullQuality() throws {
        let json = """
        {
            "sessionsCount": 0,
            "avgQualityRating": null,
            "completionRate": 0.0,
            "hasPBMovement": false,
            "isLowEngagement": true,
            "weeksLowEngagement": 2
        }
        """
        let trend = try decode(WeeklyTrend.self, from: json)
        XCTAssertNil(trend.avgQualityRating)
        XCTAssertTrue(trend.isLowEngagement)
    }

    // MARK: - Null → Optional

    func testDecodeNullAsOptional() throws {
        let json = """
        {
            "id": "sess-x",
            "childId": "child-x",
            "activityType": null,
            "effortLevel": null,
            "mood": null,
            "duration": null,
            "win": null,
            "focus": null,
            "createdAt": "2026-03-29T12:00:00.000Z"
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

    // MARK: - ActivityItem

    func testDecodeActivityItem() throws {
        let json = """
        {
            "id": "act-001",
            "childId": "child-456",
            "activityType": "TEAM_TRAINING",
            "durationMinutes": 90,
            "intensityRPE": 7,
            "gameIQImpact": "HIGH",
            "createdAt": "2026-03-28T16:00:00.000Z"
        }
        """
        let item = try decode(ActivityItem.self, from: json)
        XCTAssertEqual(item.activityType, "TEAM_TRAINING")
        XCTAssertEqual(item.durationMinutes, 90)
        XCTAssertEqual(item.intensityRPE, 7)
    }

    func testDecodeActivityItemNullOptionals() throws {
        let json = """
        {
            "id": "act-002",
            "childId": "child-456",
            "activityType": "SELF_TRAINING",
            "durationMinutes": 30,
            "intensityRPE": null,
            "gameIQImpact": null,
            "createdAt": "2026-03-29T10:00:00.000Z"
        }
        """
        let item = try decode(ActivityItem.self, from: json)
        XCTAssertNil(item.intensityRPE)
        XCTAssertNil(item.gameIQImpact)
    }

    // MARK: - LessonProgress

    func testDecodeLessonProgress() throws {
        let json = """
        {
            "id": "lp-001",
            "childId": "child-456",
            "lessonId": "3point-scan",
            "completed": true,
            "quizScore": 4,
            "quizTotal": 5
        }
        """
        let progress = try decode(LessonProgress.self, from: json)
        XCTAssertTrue(progress.completed)
        XCTAssertEqual(progress.quizScore, 4)
    }

    // MARK: - Tags

    func testDecodeFocusTag() throws {
        let json = """
        {"id": "ft-1", "key": "passing", "category": "technical", "label": "Passing", "description": "Short passes"}
        """
        let tag = try decode(FocusTag.self, from: json)
        XCTAssertEqual(tag.key, "passing")
    }

    func testDecodeHighlightChip() throws {
        let json = """
        {"id": "hl-1", "key": "goal", "label": "Scored"}
        """
        let chip = try decode(HighlightChip.self, from: json)
        XCTAssertEqual(chip.key, "goal")
    }

    func testDecodeNextFocusChip() throws {
        let json = """
        {"id": "nf-1", "key": "weak-foot", "label": "Weak Foot"}
        """
        let chip = try decode(NextFocusChip.self, from: json)
        XCTAssertEqual(chip.key, "weak-foot")
    }

    // MARK: - Entities

    func testDecodeFacility() throws {
        let json = """
        {"id": "f-1", "name": "Soccer City", "city": "LA", "isSaved": true}
        """
        let facility = try decode(Facility.self, from: json)
        XCTAssertEqual(facility.name, "Soccer City")
        XCTAssertTrue(facility.isSaved)
    }

    func testDecodeCoach() throws {
        let json = """
        {"id": "c-1", "displayName": "Coach Lee", "isSaved": false}
        """
        let coach = try decode(Coach.self, from: json)
        XCTAssertEqual(coach.displayName, "Coach Lee")
        XCTAssertFalse(coach.isSaved)
    }

    func testDecodeProgram() throws {
        let json = """
        {"id": "p-1", "name": "Youth Academy", "type": "academy", "isSaved": true}
        """
        let program = try decode(Program.self, from: json)
        XCTAssertEqual(program.type, "academy")
    }
}
