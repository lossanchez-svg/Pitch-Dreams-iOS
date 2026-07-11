import XCTest
@testable import PitchDreams

final class DecisionScenarioRegistryTests: XCTestCase {

    func testRegistryIsNotEmpty() {
        XCTAssertGreaterThanOrEqual(DecisionScenarioRegistry.all.count, 8)
    }

    func testEveryScenarioHasExactlyOneBestOption() {
        for scenario in DecisionScenarioRegistry.all {
            let bestCount = scenario.options.filter(\.isBest).count
            XCTAssertEqual(bestCount, 1, "\(scenario.id) must have exactly one best option, has \(bestCount)")
        }
    }

    func testEveryScenarioHasAtLeastThreeOptions() {
        for scenario in DecisionScenarioRegistry.all {
            XCTAssertGreaterThanOrEqual(scenario.options.count, 3, "\(scenario.id) needs real distractors")
        }
    }

    func testEveryScenarioMapsToARealLesson() {
        for scenario in DecisionScenarioRegistry.all {
            XCTAssertNotNil(
                AnimatedTacticalLessonRegistry.lesson(for: scenario.lessonId),
                "\(scenario.id) references unknown lesson '\(scenario.lessonId)'"
            )
        }
    }

    func testEveryScenarioHasADrawableFreezeFrame() {
        for scenario in DecisionScenarioRegistry.all {
            XCTAssertFalse(scenario.diagram.players.isEmpty, "\(scenario.id) has an empty pitch")
            XCTAssertTrue(
                scenario.diagram.players.contains(where: { $0.type == .self_ }),
                "\(scenario.id) must show the kid on the pitch"
            )
            XCTAssertNotNil(scenario.diagram.ball, "\(scenario.id) has no ball")
        }
    }

    func testScenarioIdsAreUnique() {
        let ids = DecisionScenarioRegistry.all.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "Duplicate scenario ids")
    }

    func testEveryOptionHasARationale() {
        for scenario in DecisionScenarioRegistry.all {
            for option in scenario.options {
                XCTAssertFalse(option.rationale.isEmpty, "\(scenario.id)/\(option.id) has no rationale")
            }
        }
    }

    func testClockIsShortEnoughToTrainSpeed() {
        for scenario in DecisionScenarioRegistry.all {
            XCTAssertLessThanOrEqual(scenario.clockSeconds, 5, "\(scenario.id): a long clock trains hesitation")
            XCTAssertGreaterThanOrEqual(scenario.clockSeconds, 2, "\(scenario.id): too short to even read")
        }
    }

    func testYoungVariantsWhereProvidedAreNonEmpty() {
        for scenario in DecisionScenarioRegistry.all {
            if let young = scenario.situationYoung {
                XCTAssertFalse(young.isEmpty)
            }
            XCTAssertEqual(scenario.preferredSituation(childAge: 9), scenario.situationYoung ?? scenario.situation)
            XCTAssertEqual(scenario.preferredSituation(childAge: 15), scenario.situation)
        }
    }
}
