import Foundation
@testable import PitchDreams

enum TestFixtures {

    // MARK: - Token Responses

    static func makeTokenResponse(
        role: UserRole = .parent,
        token: String = "test-jwt-token-abc123"
    ) -> TokenResponse {
        TokenResponse(
            token: token,
            user: makeAuthenticatedUser(role: role)
        )
    }

    // MARK: - Authenticated Users

    static func makeAuthenticatedUser(
        role: UserRole = .parent,
        id: String? = nil,
        email: String? = nil,
        name: String? = nil,
        childId: String? = nil,
        parentId: String? = nil
    ) -> AuthenticatedUser {
        switch role {
        case .parent:
            return AuthenticatedUser(
                id: id ?? "parent-abc-123",
                role: .parent,
                email: email ?? "parent@example.com",
                name: name ?? "Test Parent",
                childId: nil,
                parentId: parentId
            )
        case .child:
            return AuthenticatedUser(
                id: id ?? "child-def-456",
                role: .child,
                email: email ?? "parent@example.com",
                name: name ?? "TestKid",
                childId: childId ?? "child-def-456",
                parentId: parentId ?? "parent-abc-123"
            )
        }
    }

    // MARK: - Child Profile Detail

    static func makeChildProfileDetail(
        nickname: String = "TestKid",
        avatarId: String = "avatar-soccer",
        skipAnimations: Bool = false,
        voiceEnabled: Bool = true
    ) -> ChildProfileDetail {
        ChildProfileDetail(
            nickname: nickname,
            avatarId: avatarId,
            skipAnimations: skipAnimations,
            voiceEnabled: voiceEnabled
        )
    }

    // MARK: - Child Summary

    static func makeChildSummary(
        id: String = "child-def-456",
        nickname: String = "TestKid",
        age: Int = 12,
        position: String? = "Midfielder",
        avatarId: String? = "avatar-soccer"
    ) -> ChildSummary {
        ChildSummary(
            id: id,
            nickname: nickname,
            age: age,
            position: position,
            avatarId: avatarId
        )
    }

    // MARK: - Session Log

    static func makeSessionLog(
        id: String = "sess-001",
        childId: String = "child-def-456",
        activityType: String? = "SELF_TRAINING",
        effortLevel: Int? = 4,
        mood: String? = "FOCUSED",
        duration: Int? = 45,
        win: String? = "Great ball control today",
        focus: String? = "Dribbling",
        createdAt: String = "2026-03-28T14:30:00.000Z"
    ) -> SessionLog {
        SessionLog(
            id: id,
            childId: childId,
            activityType: activityType,
            effortLevel: effortLevel,
            mood: mood,
            duration: duration,
            win: win,
            focus: focus,
            createdAt: createdAt
        )
    }

    static func makeSessionLogs(count: Int = 5) -> [SessionLog] {
        (0..<count).map { i in
            makeSessionLog(
                id: "sess-\(i)",
                effortLevel: (i % 5) + 1,
                duration: 30 + (i * 10),
                createdAt: "2026-03-\(String(format: "%02d", 25 + (i % 5)))T14:00:00.000Z"
            )
        }
    }

    // MARK: - Check-In

    static func makeCheckIn(
        id: String = "ci-001",
        childId: String = "child-def-456",
        energy: Int = 7,
        soreness: String = "LIGHT",
        focus: Int = 8,
        mood: String = "FOCUSED",
        timeAvail: Int = 60,
        painFlag: Bool = false,
        mode: String = "NORMAL",
        modeExplanation: String? = "Good energy levels for a solid session.",
        qualityRating: Int? = nil,
        completed: Bool = false,
        activityId: String? = nil,
        createdAt: String = "2026-03-29T09:00:00.000Z"
    ) -> CheckIn {
        CheckIn(
            id: id,
            childId: childId,
            energy: energy,
            soreness: soreness,
            focus: focus,
            mood: mood,
            timeAvail: timeAvail,
            painFlag: painFlag,
            mode: mode,
            modeExplanation: modeExplanation,
            qualityRating: qualityRating,
            completed: completed,
            activityId: activityId,
            createdAt: createdAt
        )
    }

    // MARK: - Check-In Response

    static func makeCheckInResponse(
        mode: String = "NORMAL",
        explanation: String = "Good energy for a solid session."
    ) -> CheckInResponse {
        CheckInResponse(
            checkIn: makeCheckIn(mode: mode),
            modeResult: SessionModeResult(mode: mode, explanation: explanation)
        )
    }

    // MARK: - Streak Data

    static func makeStreakData(
        freezes: Int = 2,
        freezesUsed: Int = 0,
        milestones: [Int] = [3, 7]
    ) -> StreakData {
        StreakData(freezes: freezes, freezesUsed: freezesUsed, milestones: milestones)
    }

    // MARK: - Drill Stat

    static func makeDrillStat(
        drillId: String = "drill-stat-001",
        drillKey: String = "bm-toe-taps",
        totalAttempts: Int = 25,
        avgConfidence: Double = 3.5,
        lastAttempt: String? = "2026-03-28T10:00:00.000Z"
    ) -> DrillStat {
        DrillStat(
            drillId: drillId,
            drillKey: drillKey,
            totalAttempts: totalAttempts,
            avgConfidence: avgConfidence,
            lastAttempt: lastAttempt
        )
    }

    static func makeDrillStats(count: Int = 3) -> [DrillStat] {
        let keys = ["bm-toe-taps", "bm-sole-rolls", "pass-wall", "drib-cones", "ft-juggling"]
        return (0..<count).map { i in
            makeDrillStat(
                drillId: "drill-stat-\(i)",
                drillKey: keys[i % keys.count],
                totalAttempts: 10 + (i * 5),
                avgConfidence: Double(2 + i)
            )
        }
    }

    // MARK: - Lesson Progress

    static func makeLessonProgress(
        id: String = "lp-001",
        childId: String = "child-def-456",
        lessonId: String = "3point-scan",
        completed: Bool = true,
        quizScore: Int? = 4,
        quizTotal: Int? = 5
    ) -> LessonProgress {
        LessonProgress(
            id: id,
            childId: childId,
            lessonId: lessonId,
            completed: completed,
            quizScore: quizScore,
            quizTotal: quizTotal
        )
    }

    // MARK: - Activity Item

    static func makeActivityItem(
        id: String = "act-001",
        childId: String = "child-def-456",
        activityType: String = "SELF_TRAINING",
        durationMinutes: Int = 45,
        intensityRPE: Int? = 6,
        gameIQImpact: String? = "MEDIUM",
        createdAt: String = "2026-03-28T16:00:00.000Z"
    ) -> ActivityItem {
        ActivityItem(
            id: id,
            childId: childId,
            activityType: activityType,
            durationMinutes: durationMinutes,
            intensityRPE: intensityRPE,
            gameIQImpact: gameIQImpact,
            createdAt: createdAt
        )
    }

    static func makeActivityItems(count: Int = 3) -> [ActivityItem] {
        let types = ["SELF_TRAINING", "TEAM_TRAINING", "OFFICIAL_GAME"]
        return (0..<count).map { i in
            makeActivityItem(
                id: "act-\(i)",
                activityType: types[i % types.count],
                durationMinutes: 30 + (i * 15)
            )
        }
    }

    // MARK: - Coach Nudge

    static func makeCoachNudge(
        type: String = "encouragement",
        title: String = "Keep it up!",
        message: String = "You have been training consistently this week.",
        actionLabel: String = "Start Training",
        actionValue: String? = "training"
    ) -> CoachNudge {
        CoachNudge(
            type: type,
            title: title,
            message: message,
            actionLabel: actionLabel,
            actionValue: actionValue
        )
    }

    // MARK: - Weekly Trend

    static func makeWeeklyTrend(
        sessionsCount: Int = 4,
        avgQualityRating: Double? = 3.8,
        completionRate: Double = 0.75,
        hasPBMovement: Bool = true,
        isLowEngagement: Bool = false,
        weeksLowEngagement: Int = 0
    ) -> WeeklyTrend {
        WeeklyTrend(
            sessionsCount: sessionsCount,
            avgQualityRating: avgQualityRating,
            completionRate: completionRate,
            hasPBMovement: hasPBMovement,
            isLowEngagement: isLowEngagement,
            weeksLowEngagement: weeksLowEngagement
        )
    }

    // MARK: - Tags

    static func makeFocusTag(
        id: String = "ft-001",
        key: String = "passing",
        category: String = "technical",
        label: String = "Passing",
        description: String? = "Short and long passing drills"
    ) -> FocusTag {
        FocusTag(id: id, key: key, category: category, label: label, description: description)
    }

    static func makeHighlightChip(
        id: String = "hl-001",
        key: String = "goal-scored",
        label: String = "Scored a goal"
    ) -> HighlightChip {
        HighlightChip(id: id, key: key, label: label)
    }

    static func makeNextFocusChip(
        id: String = "nf-001",
        key: String = "weak-foot",
        label: String = "Weak foot work"
    ) -> NextFocusChip {
        NextFocusChip(id: id, key: key, label: label)
    }

    // MARK: - Facility / Coach / Program

    static func makeFacility(
        id: String = "fac-001",
        name: String = "Soccer City",
        city: String? = "Los Angeles",
        isSaved: Bool = true
    ) -> Facility {
        Facility(id: id, name: name, city: city, isSaved: isSaved)
    }

    static func makeCoach(
        id: String = "coach-001",
        displayName: String = "Coach Martinez",
        isSaved: Bool = true
    ) -> Coach {
        Coach(id: id, displayName: displayName, isSaved: isSaved)
    }

    static func makeProgram(
        id: String = "prog-001",
        name: String = "Youth Academy",
        type: String = "academy",
        isSaved: Bool = true
    ) -> Program {
        Program(id: id, name: name, type: type, isSaved: isSaved)
    }

    // MARK: - Freeze / Milestone Results

    static func makeFreezeCheckResult(
        freezeApplied: Bool = false,
        freezesRemaining: Int = 2
    ) -> FreezeCheckResult {
        FreezeCheckResult(freezeApplied: freezeApplied, freezesRemaining: freezesRemaining)
    }

    static func makeLogDrillResult(logId: String = "log-001") -> LogDrillResult {
        LogDrillResult(logId: logId)
    }

    static func makeSessionSaveResult(sessionId: String = "sess-001") -> SessionSaveResult {
        SessionSaveResult(sessionId: sessionId)
    }

    static func makeLessonProgressResult(progressId: String = "lpr-001") -> LessonProgressResult {
        LessonProgressResult(progressId: progressId)
    }

    static func makeSignupResponse(
        success: Bool = true,
        parentId: String = "parent-new-001"
    ) -> SignupResponse {
        SignupResponse(success: success, parentId: parentId)
    }

    static func makeCreateChildResponse(
        success: Bool = true,
        childId: String = "child-new-001"
    ) -> CreateChildResponse {
        CreateChildResponse(success: success, childId: childId)
    }
}
