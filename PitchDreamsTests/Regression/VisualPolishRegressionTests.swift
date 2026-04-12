import XCTest
import SwiftUI
@testable import PitchDreams

/// Regression tests guarding the visual polish pass (Items 1-10).
/// These verify text formatting, design system tokens, shared components,
/// and ViewModel display logic introduced during the Starlight Pitch alignment.
final class VisualPolishRegressionTests: XCTestCase {

    // MARK: - Item 1: formatAPIString text cleanup

    func testFormatAPIStringUnderscores() {
        XCTAssertEqual(formatAPIString("SELF_TRAINING"), "Self Training")
    }

    func testFormatAPIStringHyphens() {
        XCTAssertEqual(formatAPIString("bm-toe-taps"), "Bm Toe Taps")
    }

    func testFormatAPIStringAlreadyClean() {
        XCTAssertEqual(formatAPIString("Passing"), "Passing")
    }

    func testFormatAPIStringMultipleUnderscores() {
        XCTAssertEqual(formatAPIString("INDOOR_LEAGUE_GAME"), "Indoor League Game")
    }

    func testFormatAPIStringEmpty() {
        XCTAssertEqual(formatAPIString(""), "")
    }

    func testFormatAPIStringSingleWord() {
        XCTAssertEqual(formatAPIString("PEAK"), "Peak")
    }

    func testFormatAPIStringMixedSeparators() {
        XCTAssertEqual(formatAPIString("some_mixed-key"), "Some Mixed Key")
    }

    // MARK: - Items 1-4: Design system token existence

    func testDesignSystemColorsExist() {
        // These compile-time checks ensure tokens weren't accidentally removed
        let _ = Color.dsCTALabel
        let _ = Color.dsAccentOrange
        let _ = Color.dsSecondary
        let _ = Color.dsTertiary
        let _ = Color.dsTertiaryContainer
        let _ = Color.dsBackground
        let _ = Color.dsSurfaceContainer
        let _ = Color.dsSurfaceContainerHighest
        let _ = Color.dsOnSurface
        let _ = Color.dsOnSurfaceVariant
        let _ = Color.dsError
        // If any of these are removed, the test won't compile
    }

    func testDesignSystemGradientsExist() {
        let _ = DSGradient.orangeAccent
        let _ = DSGradient.primaryCTA
        let _ = DSGradient.secondaryCTA
        let _ = DSGradient.parentGoldCTA
    }

    // MARK: - Item 1: DrillRegistry name lookup

    func testDrillRegistryKnownKeyResolvesName() {
        let drill = DrillRegistry.all.first(where: { $0.id == "bm-toe-taps" })
        XCTAssertNotNil(drill)
        XCTAssertEqual(drill?.name, "Toe Taps")
    }

    func testDrillRegistryAllEntriesHaveNonEmptyFields() {
        for drill in DrillRegistry.all {
            XCTAssertFalse(drill.name.isEmpty, "Drill \(drill.id) has empty name")
            XCTAssertFalse(drill.category.isEmpty, "Drill \(drill.id) has empty category")
            XCTAssertFalse(drill.coachTip.isEmpty, "Drill \(drill.id) has empty coachTip")
            XCTAssertFalse(drill.description.isEmpty, "Drill \(drill.id) has empty description")
        }
    }

    func testDrillRegistryIDsUseHyphensNotUnderscores() {
        for drill in DrillRegistry.all {
            XCTAssertFalse(drill.id.contains("_"), "Drill ID \(drill.id) should use hyphens, not underscores")
        }
    }

    func testDrillRegistryIDsAreUnique() {
        let ids = DrillRegistry.all.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "Drill IDs must be unique")
    }

    // MARK: - Item 9: ActivityType display names

    func testAllActivityTypesHaveCleanDisplayNames() {
        for type in ActivityType.allCases {
            XCTAssertFalse(type.displayName.isEmpty, "\(type.rawValue) should have a display name")
            XCTAssertFalse(type.displayName.contains("_"), "\(type.rawValue) display name should not contain underscores")
        }
    }

    func testFormatAPIStringFallbackForUnknownActivityType() {
        // When ActivityType enum doesn't match, formatAPIString is the fallback
        let formatted = formatAPIString("PICKUP_GAME")
        XCTAssertEqual(formatted, "Pickup Game")
        XCTAssertFalse(formatted.contains("_"))
    }

    // MARK: - Item 1: ProgressViewModel chip parsing

    @MainActor
    func testParseChipsJSONArray() {
        let vm = ProgressViewModel(childId: "test", apiClient: MockAPIClient())
        let result = vm.parseChips("[\"fast_paced\",\"good_positioning\"]")
        XCTAssertEqual(result, ["fast_paced", "good_positioning"])
    }

    @MainActor
    func testParseChipsCommaSeparated() {
        let vm = ProgressViewModel(childId: "test", apiClient: MockAPIClient())
        let result = vm.parseChips("dribbling, passing, shooting")
        XCTAssertEqual(result, ["dribbling", "passing", "shooting"])
    }

    @MainActor
    func testParseChipsNilReturnsEmpty() {
        let vm = ProgressViewModel(childId: "test", apiClient: MockAPIClient())
        XCTAssertTrue(vm.parseChips(nil).isEmpty)
    }

    @MainActor
    func testParseChipsEmptyReturnsEmpty() {
        let vm = ProgressViewModel(childId: "test", apiClient: MockAPIClient())
        XCTAssertTrue(vm.parseChips("").isEmpty)
    }

    // MARK: - Item 5: Shared components instantiation

    func testHeroGlowViewDefaults() {
        let glow = HeroGlowView()
        XCTAssertEqual(glow.height, 120)
    }

    func testHeroGlowViewCustomParams() {
        let glow = HeroGlowView(color: .dsSecondary, height: 200)
        XCTAssertEqual(glow.height, 200)
    }

    func testSectionHeaderViewStoresTitle() {
        let header = SectionHeaderView("YOUR DRILLS")
        XCTAssertEqual(header.title, "YOUR DRILLS")
    }

    func testEmptyStateViewStoresAllParams() {
        let empty = EmptyStateView(icon: "star.circle", title: "No Data", subtitle: "Try again later")
        XCTAssertEqual(empty.icon, "star.circle")
        XCTAssertEqual(empty.title, "No Data")
        XCTAssertEqual(empty.subtitle, "Try again later")
    }

    func testStatCardViewStoresAllParams() {
        let card = StatCardView(title: "Streak", value: "7", unit: "days", icon: "flame.fill", color: .dsAccentOrange)
        XCTAssertEqual(card.title, "Streak")
        XCTAssertEqual(card.value, "7")
        XCTAssertEqual(card.unit, "days")
        XCTAssertEqual(card.icon, "flame.fill")
    }

    func testStatCardViewDefaultUnit() {
        let card = StatCardView(title: "Time", value: "2h", icon: "clock.fill")
        XCTAssertEqual(card.unit, "", "Default unit should be empty string")
    }

    func testErrorBannerViewDefaults() {
        let banner = ErrorBannerView(message: "Something went wrong")
        XCTAssertEqual(banner.message, "Something went wrong")
        XCTAssertTrue(banner.showRetryHint, "showRetryHint should default to true")
    }

    func testErrorBannerViewCustomRetryHint() {
        let banner = ErrorBannerView(message: "Error", showRetryHint: false)
        XCTAssertFalse(banner.showRetryHint)
    }

    // MARK: - Item 10: SkillsViewModel error cleared on retry

    @MainActor
    func testSkillsViewModelClearsErrorOnRetry() async {
        let mock = MockAPIClient()
        let vm = SkillsViewModel(childId: "test", apiClient: mock)

        // First call fails
        mock.enqueueError(APIError.server("Network error"))
        await vm.loadStats()
        XCTAssertNotNil(vm.errorMessage, "Error should be set after failure")

        // Second call succeeds
        mock.enqueue(TestFixtures.makeDrillStats(count: 2))
        await vm.loadStats()
        XCTAssertNil(vm.errorMessage, "Error should be cleared on successful retry")
        XCTAssertEqual(vm.drillStats.count, 2)
    }

    // MARK: - Item 5: ProgressViewModel formattedTotalTime

    @MainActor
    func testFormattedTotalTimeZero() {
        let vm = ProgressViewModel(childId: "test", apiClient: MockAPIClient())
        // No sessions loaded, totalMinutes is 0
        XCTAssertEqual(vm.formattedTotalTime, "0m")
    }

    @MainActor
    func testFormattedTotalTimeMinutesOnly() async {
        let mock = MockAPIClient()
        let vm = ProgressViewModel(childId: "test", apiClient: mock)

        mock.enqueue(TestFixtures.makeStreakData())
        mock.enqueue([TestFixtures.makeSessionLog(id: "s1", duration: 45)])
        mock.enqueue([WeeklyTrend]())

        await vm.loadData()

        XCTAssertEqual(vm.formattedTotalTime, "45m")
    }

    @MainActor
    func testFormattedTotalTimeExactHour() async {
        let mock = MockAPIClient()
        let vm = ProgressViewModel(childId: "test", apiClient: mock)

        mock.enqueue(TestFixtures.makeStreakData())
        mock.enqueue([TestFixtures.makeSessionLog(id: "s1", duration: 60)])
        mock.enqueue([WeeklyTrend]())

        await vm.loadData()

        XCTAssertEqual(vm.formattedTotalTime, "1h")
    }

    @MainActor
    func testFormattedTotalTimeHoursAndMinutes() async {
        let mock = MockAPIClient()
        let vm = ProgressViewModel(childId: "test", apiClient: mock)

        mock.enqueue(TestFixtures.makeStreakData())
        mock.enqueue([
            TestFixtures.makeSessionLog(id: "s1", duration: 90),
            TestFixtures.makeSessionLog(id: "s2", duration: 45),
        ])
        mock.enqueue([WeeklyTrend]())

        await vm.loadData()

        XCTAssertEqual(vm.formattedTotalTime, "2h 15m")
    }

    // MARK: - Item 1: SessionLog activity type formatting

    func testKnownActivityTypeFormatsCleanly() {
        let type = ActivityType(rawValue: "SELF_TRAINING")
        XCTAssertNotNil(type)
        XCTAssertEqual(type?.displayName, "Self Training")
    }

    func testUnknownActivityTypeFallsBackToFormatAPIString() {
        // When rawValue doesn't match any case, formatAPIString handles it
        let type = ActivityType(rawValue: "PICKUP_GAME")
        XCTAssertNil(type, "PICKUP_GAME should not match any enum case")
        XCTAssertEqual(formatAPIString("PICKUP_GAME"), "Pickup Game")
    }

    func testActivityTypeDisplayNamesNeverContainUnderscores() {
        for type in ActivityType.allCases {
            XCTAssertFalse(
                type.displayName.contains("_"),
                "\(type.rawValue).displayName '\(type.displayName)' must not contain underscores"
            )
        }
    }

    // MARK: - Item 3: DrillRegistry completeness for SkillDiagramView

    func testAllDrillCategoriesAreMapped() {
        let categories = Set(DrillRegistry.all.map(\.category))
        // SkillDiagramView and DrillDetailView use category for icon/color switching
        for category in categories {
            XCTAssertFalse(category.isEmpty, "Category should not be empty")
        }
        // At minimum these categories should exist for icon mapping
        XCTAssertTrue(categories.contains("Ball Mastery"))
        XCTAssertTrue(categories.contains("Passing"))
    }

    func testAllDrillDifficultiesAreValid() {
        let validDifficulties = Set(["beginner", "intermediate", "advanced"])
        for drill in DrillRegistry.all {
            XCTAssertTrue(
                validDifficulties.contains(drill.difficulty),
                "Drill \(drill.id) has invalid difficulty: \(drill.difficulty)"
            )
        }
    }

    func testAllDrillSpaceTypesFormatCleanly() {
        for drill in DrillRegistry.all {
            let formatted = formatAPIString(drill.spaceType)
            XCTAssertFalse(formatted.contains("_"), "Formatted space type '\(formatted)' must not contain underscores")
            XCTAssertFalse(formatted.isEmpty, "Formatted space type should not be empty for \(drill.id)")
        }
    }
}
