import XCTest
@testable import PitchDreams

final class LessonRegistryTests: XCTestCase {

    func testKnownIdReturnsTitle() {
        let title = LessonRegistry.title(for: "3point-scan")
        XCTAssertEqual(title, "3-Point Scan")
    }

    func testUnknownIdReturnsFallback() {
        let title = LessonRegistry.title(for: "unknown-lesson-id")
        // Fallback replaces hyphens with spaces and capitalizes
        XCTAssertEqual(title, "Unknown Lesson Id")
    }

    func testAllKnownIdsHaveTitles() {
        for (id, expectedTitle) in LessonRegistry.titles {
            let title = LessonRegistry.title(for: id)
            XCTAssertEqual(title, expectedTitle, "Title mismatch for lesson \(id)")
            XCTAssertFalse(title.isEmpty, "Title for \(id) should not be empty")
        }
    }

    func testRegistryContainsExpectedLessons() {
        let expectedIds = [
            "3point-scan",
            "receive-decide-execute",
            "patience-in-possession",
            "check-your-shoulder",
            "press-triggers",
            "third-man-run",
            "switching-the-play",
            "blind-side-movement",
            "controlling-the-tempo",
            "breathing-under-pressure",
        ]
        for id in expectedIds {
            XCTAssertNotNil(LessonRegistry.titles[id], "Missing lesson: \(id)")
        }
    }

    func testRegistryHasTenEntries() {
        XCTAssertEqual(LessonRegistry.titles.count, 10)
    }
}
