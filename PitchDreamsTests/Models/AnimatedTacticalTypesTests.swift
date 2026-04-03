import XCTest
@testable import PitchDreams

final class AnimatedTacticalTypesTests: XCTestCase {

    // MARK: - TacticalPlayer

    func testPlayerCoordinatesInRange() {
        let lessons = AnimatedTacticalLessonRegistry.all
        for lesson in lessons {
            for (stepIndex, step) in lesson.steps.enumerated() {
                for player in step.diagram.players {
                    XCTAssertTrue(
                        player.x >= 0 && player.x <= 100,
                        "Player \(player.id) x=\(player.x) out of 0-100 in \(lesson.id) step \(stepIndex)"
                    )
                    XCTAssertTrue(
                        player.y >= 0 && player.y <= 100,
                        "Player \(player.id) y=\(player.y) out of 0-100 in \(lesson.id) step \(stepIndex)"
                    )
                }
            }
        }
    }

    func testArrowCoordinatesInRange() {
        let lessons = AnimatedTacticalLessonRegistry.all
        for lesson in lessons {
            for (stepIndex, step) in lesson.steps.enumerated() {
                for arrow in step.diagram.arrows {
                    XCTAssertTrue(
                        arrow.fromX >= 0 && arrow.fromX <= 100,
                        "Arrow \(arrow.id) fromX=\(arrow.fromX) out of range in \(lesson.id) step \(stepIndex)"
                    )
                    XCTAssertTrue(
                        arrow.toX >= 0 && arrow.toX <= 100,
                        "Arrow \(arrow.id) toX=\(arrow.toX) out of range in \(lesson.id) step \(stepIndex)"
                    )
                    XCTAssertTrue(
                        arrow.fromY >= 0 && arrow.fromY <= 100,
                        "Arrow \(arrow.id) fromY=\(arrow.fromY) out of range in \(lesson.id) step \(stepIndex)"
                    )
                    XCTAssertTrue(
                        arrow.toY >= 0 && arrow.toY <= 100,
                        "Arrow \(arrow.id) toY=\(arrow.toY) out of range in \(lesson.id) step \(stepIndex)"
                    )
                }
            }
        }
    }

    func testZoneCoordinatesInRange() {
        let lessons = AnimatedTacticalLessonRegistry.all
        for lesson in lessons {
            for (stepIndex, step) in lesson.steps.enumerated() {
                for zone in step.diagram.zones {
                    XCTAssertTrue(
                        zone.x >= 0 && zone.x <= 100,
                        "Zone \(zone.id) x=\(zone.x) out of range in \(lesson.id) step \(stepIndex)"
                    )
                    XCTAssertTrue(
                        zone.y >= 0 && zone.y <= 100,
                        "Zone \(zone.id) y=\(zone.y) out of range in \(lesson.id) step \(stepIndex)"
                    )
                    XCTAssertTrue(
                        zone.w > 0,
                        "Zone \(zone.id) has zero width in \(lesson.id) step \(stepIndex)"
                    )
                    XCTAssertTrue(
                        zone.h > 0,
                        "Zone \(zone.id) has zero height in \(lesson.id) step \(stepIndex)"
                    )
                }
            }
        }
    }

    func testStepDurationsPositive() {
        for lesson in AnimatedTacticalLessonRegistry.all {
            for (stepIndex, step) in lesson.steps.enumerated() {
                XCTAssertGreaterThan(
                    step.duration, 0,
                    "Step \(stepIndex) in \(lesson.id) has non-positive duration"
                )
            }
        }
    }

    func testNarrationsNonEmpty() {
        for lesson in AnimatedTacticalLessonRegistry.all {
            for (stepIndex, step) in lesson.steps.enumerated() {
                XCTAssertFalse(
                    step.narration.isEmpty,
                    "Step \(stepIndex) in \(lesson.id) has empty narration"
                )
            }
        }
    }

    func testDiagramHasAtLeastOnePlayer() {
        for lesson in AnimatedTacticalLessonRegistry.all {
            for (stepIndex, step) in lesson.steps.enumerated() {
                XCTAssertFalse(
                    step.diagram.players.isEmpty,
                    "Step \(stepIndex) in \(lesson.id) has no players"
                )
            }
        }
    }

    func testBallPositionInRange() {
        for lesson in AnimatedTacticalLessonRegistry.all {
            for (stepIndex, step) in lesson.steps.enumerated() {
                if let ball = step.diagram.ball {
                    XCTAssertTrue(
                        ball.x >= 0 && ball.x <= 100,
                        "Ball x=\(ball.x) out of range in \(lesson.id) step \(stepIndex)"
                    )
                    XCTAssertTrue(
                        ball.y >= 0 && ball.y <= 100,
                        "Ball y=\(ball.y) out of range in \(lesson.id) step \(stepIndex)"
                    )
                }
            }
        }
    }

    func testArrowDelaysNonNegative() {
        for lesson in AnimatedTacticalLessonRegistry.all {
            for (stepIndex, step) in lesson.steps.enumerated() {
                for arrow in step.diagram.arrows {
                    XCTAssertGreaterThanOrEqual(
                        arrow.delay, 0,
                        "Arrow \(arrow.id) delay=\(arrow.delay) is negative in \(lesson.id) step \(stepIndex)"
                    )
                }
            }
        }
    }
}
