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

    // MARK: - Model 1 philosophy: free tier has NO paid features gated,
    // because paid features are parent-only. Kid-facing features aren't
    // in the enum at all — they can't be gated.

    func testFreeTierGrantsNoParentFeatures() {
        let store = EntitlementStore(defaults: defaults)
        for feature in Feature.allCases {
            XCTAssertFalse(store.has(feature), "Free tier should not have \(feature) — all paid features are parent-value in Model 1")
        }
    }

    func testPremiumUnlocksParentValueFeatures() {
        let store = EntitlementStore(defaults: defaults)
        store.setActiveTier(.premiumMonthly)
        XCTAssertTrue(store.has(.parentInsightsDashboard))
        XCTAssertTrue(store.has(.advancedAnalytics))
        XCTAssertTrue(store.has(.unlimitedHistory))
        XCTAssertTrue(store.has(.restDayIntelligence))
        XCTAssertTrue(store.has(.parentWeeklyInsightsEmail))
        XCTAssertTrue(store.has(.developmentProfilePDF))
        XCTAssertTrue(store.has(.prioritySupport))
        // advancedDrills is a parent-facing unlock (Model 1 framing) but lives
        // in the premium tier — verify it comes along.
        XCTAssertTrue(store.has(.advancedDrills))
        // Premium does NOT include family/club features.
        XCTAssertFalse(store.has(.familyMultiChild))
        XCTAssertFalse(store.has(.siblingLeague))
        XCTAssertFalse(store.has(.clubCoachDashboard))
    }

    func testFamilyTierExtendsPremiumWithMultiChild() {
        let store = EntitlementStore(defaults: defaults)
        store.setActiveTier(.familyYearly)
        // Inherits all premium features
        XCTAssertTrue(store.has(.parentInsightsDashboard))
        XCTAssertTrue(store.has(.advancedAnalytics))
        XCTAssertTrue(store.has(.developmentProfilePDF))
        // Plus family extras
        XCTAssertTrue(store.has(.familyMultiChild))
        XCTAssertTrue(store.has(.siblingLeague))
        // Not club though
        XCTAssertFalse(store.has(.clubCoachDashboard))
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
        store.setActiveTier(.founders)
        let foundersFeatures = store.activeTier.features
        store.setActiveTier(.premiumMonthly)
        let premiumFeatures = store.activeTier.features
        // Founders price differs ($4.99 vs $6.99 locked) but feature parity
        // with Premium is an intentional Model 1 decision — founders users
        // get the same experience, just grandfathered.
        XCTAssertEqual(foundersFeatures, premiumFeatures)
    }

    func testTierPersistsAcrossInstances() {
        let store1 = EntitlementStore(defaults: defaults)
        store1.setActiveTier(.premiumYearly)

        let store2 = EntitlementStore(defaults: defaults)
        XCTAssertEqual(store2.activeTier, .premiumYearly)
        XCTAssertTrue(store2.has(.advancedAnalytics))
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

        let store2 = EntitlementStore(defaults: defaults)
        XCTAssertEqual(store2.activeTier, .free)
        XCTAssertFalse(store2.foundersCohort)
    }

    // MARK: - Product catalog

    func testProductIDTierMapping() {
        XCTAssertEqual(ProductIDs.tier(for: ProductIDs.premiumMonthly), .premiumMonthly)
        XCTAssertEqual(ProductIDs.tier(for: ProductIDs.premiumYearly), .premiumYearly)
        XCTAssertEqual(ProductIDs.tier(for: ProductIDs.familyMonthly), .familyMonthly)
        XCTAssertEqual(ProductIDs.tier(for: ProductIDs.familyYearly), .familyYearly)
        XCTAssertEqual(ProductIDs.tier(for: ProductIDs.founders), .founders)
        XCTAssertNil(ProductIDs.tier(for: "com.unknown.product"))
    }

    func testAllConsumerFacingProductIDsIncluded() {
        // 5 consumer products: premium monthly/yearly, family monthly/yearly,
        // founders monthly. Club is B2B only and intentionally excluded.
        XCTAssertEqual(ProductIDs.all.count, 5)
        XCTAssertFalse(ProductIDs.all.contains { ProductIDs.tier(for: $0) == .club })
        XCTAssertTrue(ProductIDs.all.contains(ProductIDs.founders))
    }

    // MARK: - Pricing reference

    func testPricingReferenceMatchesDecisions() {
        // Decisions locked 2026-04-18:
        XCTAssertEqual(PricingReference.premiumMonthly, "$6.99/mo")
        XCTAssertEqual(PricingReference.premiumYearly, "$69/yr")
        XCTAssertEqual(PricingReference.familyMonthly, "$10.99/mo")
        XCTAssertEqual(PricingReference.familyYearly, "$109/yr")
        XCTAssertEqual(PricingReference.founders, "$4.99/mo")
        XCTAssertEqual(PricingReference.foundersCohortSize, 500)
    }
}
