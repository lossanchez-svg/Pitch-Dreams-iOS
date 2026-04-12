import XCTest
@testable import PitchDreams

final class AvatarStageMissionXPTests: XCTestCase {
    func testRookieWithNoProgress() {
        XCTAssertEqual(AvatarStage.current(forMilestones: []), .rookie)
    }

    func testXP50PromotesToPro() {
        XCTAssertEqual(AvatarStage.current(forMilestones: [], localMissionXP: 50), .pro)
    }

    func testXP200PromotesToLegend() {
        XCTAssertEqual(AvatarStage.current(forMilestones: [], localMissionXP: 200), .legend)
    }

    func testStreakStageTakesPrecedenceWhenHigher() {
        let stage = AvatarStage.current(forMilestones: [30], localMissionXP: 50)
        XCTAssertEqual(stage, .legend) // streak legend wins over XP pro
    }

    func testXPStageTakesPrecedenceWhenHigher() {
        let stage = AvatarStage.current(forMilestones: [7], localMissionXP: 200)
        XCTAssertEqual(stage, .legend) // XP legend wins over streak pro
    }

    func testPartialXPStaysAtCurrentStreakStage() {
        let stage = AvatarStage.current(forMilestones: [7], localMissionXP: 30)
        XCTAssertEqual(stage, .pro)
    }
}
