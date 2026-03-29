import XCTest
@testable import PitchDreams

final class TacticalLessonRegistryTests: XCTestCase {

    func testAllTenLessonsPresent() {
        XCTAssertEqual(TacticalLessonRegistry.all.count, 10, "Expected 10 tactical lessons")
    }

    func testLookupByIdReturnsCorrectLesson() {
        let lesson = TacticalLessonRegistry.lesson(for: "3point-scan")
        XCTAssertNotNil(lesson)
        XCTAssertEqual(lesson?.title, "3-Point Scan")
    }

    func testLookupByInvalidIdReturnsNil() {
        let lesson = TacticalLessonRegistry.lesson(for: "nonexistent-lesson")
        XCTAssertNil(lesson)
    }

    func testAllLessonsHaveSteps() {
        for lesson in TacticalLessonRegistry.all {
            XCTAssertFalse(lesson.steps.isEmpty, "Lesson \(lesson.id) should have steps")
        }
    }

    func testAllLessonsHaveDescription() {
        for lesson in TacticalLessonRegistry.all {
            XCTAssertFalse(lesson.description.isEmpty, "Lesson \(lesson.id) should have a description")
        }
    }

    func testDiagramElementsHaveValidCoordinates() {
        for lesson in TacticalLessonRegistry.all {
            for element in lesson.diagram {
                XCTAssertGreaterThanOrEqual(element.x, 0, "Element \(element.id) in lesson \(lesson.id): x should be >= 0")
                XCTAssertLessThanOrEqual(element.x, 100, "Element \(element.id) in lesson \(lesson.id): x should be <= 100")
                XCTAssertGreaterThanOrEqual(element.y, 0, "Element \(element.id) in lesson \(lesson.id): y should be >= 0")
                XCTAssertLessThanOrEqual(element.y, 100, "Element \(element.id) in lesson \(lesson.id): y should be <= 100")

                if let toX = element.toX {
                    XCTAssertGreaterThanOrEqual(toX, 0, "Element \(element.id) in lesson \(lesson.id): toX should be >= 0")
                    XCTAssertLessThanOrEqual(toX, 100, "Element \(element.id) in lesson \(lesson.id): toX should be <= 100")
                }
                if let toY = element.toY {
                    XCTAssertGreaterThanOrEqual(toY, 0, "Element \(element.id) in lesson \(lesson.id): toY should be >= 0")
                    XCTAssertLessThanOrEqual(toY, 100, "Element \(element.id) in lesson \(lesson.id): toY should be <= 100")
                }
            }
        }
    }

    func testAllTracksHaveLessons() {
        for track in TacticalLessonRegistry.tracks {
            let lessons = TacticalLessonRegistry.lessons(for: track)
            XCTAssertFalse(lessons.isEmpty, "Track \(track) should have lessons")
        }
    }

    func testAllLessonsHaveReadingTime() {
        for lesson in TacticalLessonRegistry.all {
            XCTAssertGreaterThan(lesson.readingTimeMinutes, 0, "Lesson \(lesson.id) should have a positive reading time")
        }
    }

    func testAllLessonsHaveUniqueIds() {
        let ids = TacticalLessonRegistry.all.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "Lesson IDs must be unique")
    }
}
