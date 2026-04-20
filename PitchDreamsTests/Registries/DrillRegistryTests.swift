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

    // MARK: - Premium gating

    func testOnlyAdvancedDrillsAreMarkedRequiresPremium() {
        // Under Model 1, the only drills gated are the advanced-difficulty
        // entries. Beginner and intermediate stay free forever.
        for drill in DrillRegistry.all where drill.requiresPremium {
            XCTAssertEqual(drill.difficulty, "advanced",
                           "Non-advanced drill \(drill.id) should not require premium")
        }
    }

    func testAtLeastFourAdvancedDrillsAreGated() {
        // Guardrail: premium tier must feel meaningfully richer — if this
        // drops below 4 the upsell value collapses, so flag it in tests.
        let gated = DrillRegistry.all.filter { $0.requiresPremium }
        XCTAssertGreaterThanOrEqual(gated.count, 4,
                                    "Premium tier should include at least 4 advanced drills")
    }

    func testFreeUsersDoNotSeePremiumDrillsInSpaceFilter() {
        for space in ["small_indoor", "large_indoor", "outdoor"] {
            let free = DrillRegistry.drills(for: space, hasPremium: false)
            for drill in free {
                XCTAssertFalse(drill.requiresPremium,
                               "Free tier surfaced gated drill \(drill.id) for space \(space)")
            }
        }
    }

    func testPremiumUsersSeeAllSpaceDrills() {
        for space in ["small_indoor", "large_indoor", "outdoor"] {
            let all = DrillRegistry.drills(for: space)
            let premium = DrillRegistry.drills(for: space, hasPremium: true)
            XCTAssertEqual(all.count, premium.count,
                           "Premium view of \(space) should include every drill")
        }
    }

    func testFreeAndPremiumListsPartitionTheSpace() {
        for space in ["small_indoor", "large_indoor", "outdoor"] {
            let free = DrillRegistry.drills(for: space, hasPremium: false)
            let gated = DrillRegistry.premiumDrills(for: space)
            let combined = Set(free.map(\.id)).union(gated.map(\.id))
            let all = Set(DrillRegistry.drills(for: space).map(\.id))
            XCTAssertEqual(combined, all,
                           "Free + premium drills should fully cover space \(space)")
            XCTAssertTrue(Set(free.map(\.id)).isDisjoint(with: gated.map(\.id)),
                          "A drill can't be both free and premium in space \(space)")
        }
    }

    func testEveryNonEmptySpaceHasFreeDrills() {
        // Model 1 safety: a free kid must not land on an empty drill list
        // for any space they can select. Every space ships with at least
        // one beginner/intermediate drill.
        for space in ["small_indoor", "large_indoor", "outdoor"] {
            let free = DrillRegistry.drills(for: space, hasPremium: false)
            XCTAssertFalse(free.isEmpty,
                           "Space \(space) must have at least one free drill")
        }
    }
}
