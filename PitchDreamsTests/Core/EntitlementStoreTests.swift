import XCTest
@testable import PitchDreams

@MainActor
final class EntitlementStoreTests: XCTestCase {
    private var suiteName: String = ""
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "EntitlementStoreTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testDefaultsToFreeTier() {
        let store = EntitlementStore(defaults: defaults)
        XCTAssertEqual(store.activeTier, .free)
        XCTAssertFalse(store.isPaid)
    }

    func testFreeTierHasNoFeatures() {
        let store = EntitlementStore(defaults: defaults)
        for feature in Feature.allCases {
            XCTAssertFalse(store.has(feature), "Free tier should not have \(feature)")
        }
    }

    func testPremiumMonthlyUnlocksCoreFeatures() {
        let store = EntitlementStore(defaults: defaults)
        store.setActiveTier(.premiumMonthly)
        XCTAssertTrue(store.has(.allAvatars))
        XCTAssertTrue(store.has(.weeklyRecapExport))
        XCTAssertTrue(store.has(.parentInsightsDashboard))
        XCTAssertTrue(store.has(.coachVoicePacks))
        XCTAssertFalse(store.has(.familyMultiChild))
        XCTAssertFalse(store.has(.clubCoachDashboard))
    }

    func testFamilyTierIncludesPremiumPlusFamily() {
        let store = EntitlementStore(defaults: defaults)
        store.setActiveTier(.familyYearly)
        // Inherits all premium features
        XCTAssertTrue(store.has(.allAvatars))
        XCTAssertTrue(store.has(.weeklyRecapExport))
        // Plus family extras
        XCTAssertTrue(store.has(.familyMultiChild))
        XCTAssertTrue(store.has(.siblingLeague))
    }

    func testClubTierIsSuperset() {
        let store = EntitlementStore(defaults: defaults)
        store.setActiveTier(.club)
        for feature in Feature.allCases {
            XCTAssertTrue(store.has(feature), "Club should have \(feature)")
        }
    }

    func testFoundersMatchesPremiumFeatures() {
        let store = EntitlementStore(defaults: defaults)
        store.setActiveTier(.foundersMonthly)
        // Founders price differs but the feature set is identical to premium.
        let foundersFeatures = store.activeTier.features
        store.setActiveTier(.premiumMonthly)
        let premiumFeatures = store.activeTier.features
        XCTAssertEqual(foundersFeatures, premiumFeatures)
    }

    func testTierPersistsAcrossInstances() {
        let store1 = EntitlementStore(defaults: defaults)
        store1.setActiveTier(.premiumYearly)

        let store2 = EntitlementStore(defaults: defaults)
        XCTAssertEqual(store2.activeTier, .premiumYearly)
        XCTAssertTrue(store2.has(.allAvatars))
    }

    func testFoundersCohortStickyAcrossInstances() {
        let store1 = EntitlementStore(defaults: defaults)
        store1.markFoundersCohort()

        let store2 = EntitlementStore(defaults: defaults)
        XCTAssertTrue(store2.foundersCohort)
    }

    func testResetClearsTierAndCohort() {
        let store = EntitlementStore(defaults: defaults)
        store.setActiveTier(.familyYearly)
        store.markFoundersCohort()
        store.reset()
        XCTAssertEqual(store.activeTier, .free)
        XCTAssertFalse(store.foundersCohort)

        // Second instance should also see the reset.
        let store2 = EntitlementStore(defaults: defaults)
        XCTAssertEqual(store2.activeTier, .free)
        XCTAssertFalse(store2.foundersCohort)
    }

    func testProductIDTierMapping() {
        XCTAssertEqual(ProductIDs.tier(for: ProductIDs.premiumMonthly), .premiumMonthly)
        XCTAssertEqual(ProductIDs.tier(for: ProductIDs.premiumYearly), .premiumYearly)
        XCTAssertEqual(ProductIDs.tier(for: ProductIDs.familyMonthly), .familyMonthly)
        XCTAssertEqual(ProductIDs.tier(for: ProductIDs.familyYearly), .familyYearly)
        XCTAssertEqual(ProductIDs.tier(for: ProductIDs.foundersMonthly), .foundersMonthly)
        XCTAssertEqual(ProductIDs.tier(for: ProductIDs.foundersYearly), .foundersYearly)
        XCTAssertNil(ProductIDs.tier(for: "com.unknown.product"))
    }

    func testAllConsumerFacingProductIDsIncluded() {
        // Club is B2B only and should NOT be in the consumer catalog.
        XCTAssertEqual(ProductIDs.all.count, 6)
        XCTAssertFalse(ProductIDs.all.contains { ProductIDs.tier(for: $0) == .club })
    }
}
