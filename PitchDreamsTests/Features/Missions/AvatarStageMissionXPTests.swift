import XCTest
@testable import PitchDreams

final class AvatarStageMissionXPTests: XCTestCase {
    // MARK: - New XP-based API

    func testRookieWithNoXP() {
        XCTAssertEqual(AvatarStage.current(forTotalXP: 0), .rookie)
    }

    func testProAt500XP() {
        XCTAssertEqual(AvatarStage.current(forTotalXP: 500), .pro)
    }

    func testLegendAt2000XP() {
        XCTAssertEqual(AvatarStage.current(forTotalXP: 2000), .legend)
    }

    func testBelowProThreshold() {
        XCTAssertEqual(AvatarStage.current(forTotalXP: 499), .rookie)
    }

    func testBetweenProAndLegend() {
        XCTAssertEqual(AvatarStage.current(forTotalXP: 1000), .pro)
    }

    func testAboveLegendThreshold() {
        XCTAssertEqual(AvatarStage.current(forTotalXP: 5000), .legend)
    }

    // MARK: - Avatar Asset Name with totalXP

    func testAvatarAssetName_usesTotalXP() {
        let name = Avatar.assetName(for: "wolf", totalXP: 600)
        XCTAssertEqual(name, "wolf_stage2") // Pro stage
    }

    func testAvatarAssetName_rookieStage() {
        let name = Avatar.assetName(for: "lion", totalXP: 100)
        XCTAssertEqual(name, "lion_stage1")
    }

    func testAvatarAssetName_legendStage() {
        let name = Avatar.assetName(for: "eagle", totalXP: 2500)
        XCTAssertEqual(name, "eagle_stage3")
    }

    // MARK: - Legacy deprecated method still works

    func testLegacyMethod_stillWorks() {
        // The deprecated method uses localMissionXP as proxy for totalXP
        // With new thresholds (500 for Pro), old XP values (50) won't trigger Pro
        let stage = AvatarStage.current(forMilestones: [], localMissionXP: 500)
        XCTAssertEqual(stage, .pro)
    }
}
