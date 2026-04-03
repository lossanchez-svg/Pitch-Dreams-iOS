import XCTest
@testable import PitchDreams

final class AnimatedTacticalLessonRegistryTests: XCTestCase {

    func testLessonCount() {
        XCTAssertEqual(AnimatedTacticalLessonRegistry.all.count, 10)
    }

    func testAllLessonsHaveAtLeastTwoSteps() {
        for lesson in AnimatedTacticalLessonRegistry.all {
            XCTAssertGreaterThanOrEqual(
                lesson.steps.count, 2,
                "\(lesson.id) has fewer than 2 steps"
            )
        }
    }

    func testAllLessonsHaveUniqueIDs() {
        let ids = AnimatedTacticalLessonRegistry.all.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "Duplicate lesson IDs found")
    }

    func testAllTracksRepresented() {
        let tracks = Set(AnimatedTacticalLessonRegistry.all.map(\.track))
        XCTAssertTrue(tracks.contains("scanning"), "Missing scanning track")
        XCTAssertTrue(tracks.contains("decision_chain"), "Missing decision_chain track")
        XCTAssertTrue(tracks.contains("tempo"), "Missing tempo track")
    }

    func testLookupByID() {
        let lesson = AnimatedTacticalLessonRegistry.lesson(for: "3point-scan")
        XCTAssertNotNil(lesson)
        XCTAssertEqual(lesson?.title, "3-Point Scan")
    }

    func testLookupByIDMissing() {
        XCTAssertNil(AnimatedTacticalLessonRegistry.lesson(for: "nonexistent"))
    }

    func testLessonsByTrack() {
        let scanning = AnimatedTacticalLessonRegistry.lessons(for: "scanning")
        XCTAssertGreaterThanOrEqual(scanning.count, 2, "Should have at least 2 scanning lessons")
        for lesson in scanning {
            XCTAssertEqual(lesson.track, "scanning")
        }
    }

    func testAllLessonsHaveNonEmptyDescription() {
        for lesson in AnimatedTacticalLessonRegistry.all {
            XCTAssertFalse(lesson.description.isEmpty, "\(lesson.id) has empty description")
        }
    }

    func testAllLessonsHaveDifficulty() {
        let validDifficulties: Set<String> = ["beginner", "intermediate", "advanced"]
        for lesson in AnimatedTacticalLessonRegistry.all {
            XCTAssertTrue(
                validDifficulties.contains(lesson.difficulty),
                "\(lesson.id) has invalid difficulty: \(lesson.difficulty)"
            )
        }
    }

    func testBridgeFromTacticalLessonRegistry() {
        let lesson = TacticalLessonRegistry.animatedLesson(for: "3point-scan")
        XCTAssertNotNil(lesson)
        XCTAssertEqual(lesson?.id, "3point-scan")
    }

    func testEachLessonMatchesTacticalLessonRegistryID() {
        // Every animated lesson should have a matching entry in the original registry
        for animated in AnimatedTacticalLessonRegistry.all {
            let original = TacticalLessonRegistry.lesson(for: animated.id)
            XCTAssertNotNil(original, "Animated lesson \(animated.id) has no match in TacticalLessonRegistry")
        }
    }

    func testAllLessonsHaveFiveSteps() {
        for lesson in AnimatedTacticalLessonRegistry.all {
            XCTAssertEqual(
                lesson.steps.count, 5,
                "\(lesson.id) has \(lesson.steps.count) steps, expected 5"
            )
        }
    }
}
