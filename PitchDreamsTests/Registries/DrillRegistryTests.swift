import XCTest
@testable import PitchDreams

final class DrillRegistryTests: XCTestCase {

    func testAllDrillsHaveRequiredFields() {
        for drill in DrillRegistry.all {
            XCTAssertFalse(drill.id.isEmpty, "Drill id should not be empty")
            XCTAssertFalse(drill.name.isEmpty, "Drill name should not be empty for \(drill.id)")
            XCTAssertFalse(drill.category.isEmpty, "Drill category should not be empty for \(drill.id)")
            XCTAssertFalse(drill.description.isEmpty, "Drill description should not be empty for \(drill.id)")
            XCTAssertGreaterThan(drill.duration, 0, "Drill duration should be positive for \(drill.id)")
            XCTAssertGreaterThan(drill.reps, 0, "Drill reps should be positive for \(drill.id)")
            XCTAssertFalse(drill.coachTip.isEmpty, "Drill coachTip should not be empty for \(drill.id)")
            XCTAssertFalse(drill.difficulty.isEmpty, "Drill difficulty should not be empty for \(drill.id)")
            XCTAssertFalse(drill.spaceType.isEmpty, "Drill spaceType should not be empty for \(drill.id)")
        }
    }

    func testDrillsFilterBySpace() {
        let smallIndoor = DrillRegistry.drills(for: "small_indoor")
        XCTAssertFalse(smallIndoor.isEmpty, "Should have small_indoor drills")
        for drill in smallIndoor {
            XCTAssertEqual(drill.spaceType, "small_indoor")
        }
        // small_indoor should be a subset of all
        XCTAssertLessThan(smallIndoor.count, DrillRegistry.all.count)
    }

    func testNoDuplicateDrillIds() {
        let ids = DrillRegistry.all.map(\.id)
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count, "Drill IDs must be unique")
    }

    func testAllCategoriesRepresented() {
        let categories = Set(DrillRegistry.all.map(\.category))
        let expected: Set<String> = ["Ball Mastery", "Passing", "Shooting", "Dribbling", "First Touch"]
        for cat in expected {
            XCTAssertTrue(categories.contains(cat), "Missing category: \(cat)")
        }
    }

    func testDrillsFilterByCategory() {
        let passing = DrillRegistry.drills(forCategory: "Passing")
        XCTAssertFalse(passing.isEmpty)
        for drill in passing {
            XCTAssertEqual(drill.category, "Passing")
        }
    }

    func testCategoriesAreNonEmpty() {
        let categories = DrillRegistry.categories
        XCTAssertFalse(categories.isEmpty)
        for category in categories {
            XCTAssertFalse(category.isEmpty)
        }
    }
}
