import XCTest
@testable import PitchDreams

final class XPCalculatorTests: XCTestCase {

    // MARK: - XP for Session

    func testXPForSession_minimumIs10() {
        let xp = XPCalculator.xpForSession(duration: 0, effortLevel: nil, activityType: nil)
        XCTAssertGreaterThanOrEqual(xp, 10)
    }

    func testXPForSession_scalesWithDuration() {
        let short = XPCalculator.xpForSession(duration: 10, effortLevel: nil, activityType: nil)
        let long = XPCalculator.xpForSession(duration: 30, effortLevel: nil, activityType: nil)
        XCTAssertGreaterThan(long, short)
    }

    func testXPForSession_effortBonus() {
        let low = XPCalculator.xpForSession(duration: 15, effortLevel: 3, activityType: nil)
        let high = XPCalculator.xpForSession(duration: 15, effortLevel: 8, activityType: nil)
        XCTAssertGreaterThan(high, low)
    }

    func testXPForSession_activityTypeBonus() {
        let drill = XPCalculator.xpForSession(duration: 15, effortLevel: 5, activityType: "drill")
        let game = XPCalculator.xpForSession(duration: 15, effortLevel: 5, activityType: "game")
        XCTAssertGreaterThan(game, drill) // game gives 25, drill gives 15
    }

    // MARK: - Avatar Stage for XP

    func testAvatarStageForXP_startsAtRookie() {
        XCTAssertEqual(XPCalculator.avatarStageForXP(0), .rookie)
    }

    func testAvatarStageForXP_proAt500() {
        XCTAssertEqual(XPCalculator.avatarStageForXP(500), .pro)
    }

    func testAvatarStageForXP_legendAt2000() {
        XCTAssertEqual(XPCalculator.avatarStageForXP(2000), .legend)
    }

    func testAvatarStageForXP_belowPro() {
        XCTAssertEqual(XPCalculator.avatarStageForXP(499), .rookie)
    }

    func testAvatarStageForXP_belowLegend() {
        XCTAssertEqual(XPCalculator.avatarStageForXP(1999), .pro)
    }

    func testAvatarStageForXP_aboveLegend() {
        XCTAssertEqual(XPCalculator.avatarStageForXP(5000), .legend)
    }

    // MARK: - Progress to Next Stage

    func testProgressToNextStage_halfwayToPro() {
        let result = XPCalculator.progressToNextStage(250)
        XCTAssertEqual(result.progress, 0.5, accuracy: 0.01)
        XCTAssertEqual(result.xpInStage, 250)
        XCTAssertEqual(result.xpNeeded, 500)
    }

    func testProgressToNextStage_legendIsMaxed() {
        let result = XPCalculator.progressToNextStage(3000)
        XCTAssertEqual(result.progress, 1.0)
        XCTAssertEqual(result.xpInStage, 0)
        XCTAssertEqual(result.xpNeeded, 0)
    }

    func testProgressToNextStage_zeroXP() {
        let result = XPCalculator.progressToNextStage(0)
        XCTAssertEqual(result.progress, 0.0)
        XCTAssertEqual(result.xpNeeded, 500)
    }

    func testProgressToNextStage_proToLegend() {
        let result = XPCalculator.progressToNextStage(1250)
        XCTAssertEqual(result.progress, 0.5, accuracy: 0.01)
        XCTAssertEqual(result.xpInStage, 750)
        XCTAssertEqual(result.xpNeeded, 1500)
    }

    // MARK: - Streak Milestones

    func testXPForStreakMilestone_7days() {
        XCTAssertEqual(XPCalculator.xpForStreakMilestone(7), 50)
    }

    func testXPForStreakMilestone_14days() {
        XCTAssertEqual(XPCalculator.xpForStreakMilestone(14), 100)
    }

    func testXPForStreakMilestone_30days() {
        XCTAssertEqual(XPCalculator.xpForStreakMilestone(30), 250)
    }

    func testXPForStreakMilestone_100days() {
        XCTAssertEqual(XPCalculator.xpForStreakMilestone(100), 1000)
    }

    func testXPForStreakMilestone_unknownMilestone() {
        XCTAssertEqual(XPCalculator.xpForStreakMilestone(50), 25)
    }

    // MARK: - XP for Personal Best

    func testXPForPersonalBest() {
        XCTAssertEqual(XPCalculator.xpForPersonalBest, 25)
    }
}
