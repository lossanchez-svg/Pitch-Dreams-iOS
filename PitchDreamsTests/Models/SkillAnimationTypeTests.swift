import XCTest
@testable import PitchDreams

final class SkillAnimationTypeTests: XCTestCase {

    func testAllKeysHaveConfigs() {
        for key in SkillAnimationKey.allCases {
            let config = SkillAnimationRegistry.config(for: key)
            XCTAssertFalse(config.displayName.isEmpty, "\(key) has empty displayName")
            XCTAssertFalse(config.description.isEmpty, "\(key) has empty description")
        }
    }

    func testAllConfigsHavePositiveDuration() {
        for key in SkillAnimationKey.allCases {
            let config = SkillAnimationRegistry.config(for: key)
            XCTAssertGreaterThan(
                config.durationSeconds, 0,
                "\(key) has non-positive duration"
            )
        }
    }

    func testCaseIterableCount() {
        XCTAssertEqual(SkillAnimationKey.allCases.count, 10)
    }

    func testShowsBallFalseForScanningAndDecision() {
        let scanConfig = SkillAnimationRegistry.config(for: .scanning)
        XCTAssertFalse(scanConfig.showsBall)

        let decisionConfig = SkillAnimationRegistry.config(for: .decision)
        XCTAssertFalse(decisionConfig.showsBall)
    }

    func testHasImpactFlashForShootingDefendingPassing() {
        XCTAssertTrue(SkillAnimationRegistry.config(for: .shooting).hasImpactFlash)
        XCTAssertTrue(SkillAnimationRegistry.config(for: .defending).hasImpactFlash)
        XCTAssertTrue(SkillAnimationRegistry.config(for: .passing).hasImpactFlash)
    }

    func testResolveDirectMatch() {
        XCTAssertEqual(SkillAnimationRegistry.resolve("juggling"), .juggling)
        XCTAssertEqual(SkillAnimationRegistry.resolve("shooting"), .shooting)
    }

    func testResolveTrackPrefix() {
        XCTAssertEqual(SkillAnimationRegistry.resolve("scanning.3point_scan"), .scanning)
        XCTAssertEqual(SkillAnimationRegistry.resolve("tempo.breathing_rhythm"), .tempo)
    }

    func testResolveFallsBackToGeneric() {
        XCTAssertEqual(SkillAnimationRegistry.resolve("unknown_skill"), .generic)
    }

    func testResolveKnownMappings() {
        XCTAssertEqual(SkillAnimationRegistry.resolve("ball_mastery"), .dribbling)
        XCTAssertEqual(SkillAnimationRegistry.resolve("receiving"), .firstTouch)
        XCTAssertEqual(SkillAnimationRegistry.resolve("tackling"), .defending)
    }

    func testSpeedLineDirections() {
        XCTAssertEqual(SkillAnimationRegistry.config(for: .scanning).speedLineDirection, .radial)
        XCTAssertEqual(SkillAnimationRegistry.config(for: .decision).speedLineDirection, .radial)
        XCTAssertEqual(SkillAnimationRegistry.config(for: .shooting).speedLineDirection, .right)
        XCTAssertEqual(SkillAnimationRegistry.config(for: .juggling).speedLineDirection, .up)
    }
}
