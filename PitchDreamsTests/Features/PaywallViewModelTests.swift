import XCTest
@testable import PitchDreams

/// Covers the pure partitioning + default-selection logic on `PaywallViewModel`.
/// The StoreKit-facing `SubscriptionManager` isn't exercised here — tests use
/// the static `partitioned(products:showFounders:)` seam which is exactly
/// what the instance method delegates to.
final class PaywallViewModelTests: XCTestCase {

    // MARK: - Fixtures

    private func product(
        _ id: String,
        _ tier: SubscriptionTier,
        _ period: SubscriptionProduct.BillingPeriod,
        _ price: String
    ) -> SubscriptionProduct {
        SubscriptionProduct(id: id, tier: tier, displayPrice: price, period: period)
    }

    private var catalog: [SubscriptionProduct] {
        [
            product(ProductIDs.premiumMonthly, .premiumMonthly, .monthly, "$6.99"),
            product(ProductIDs.premiumYearly,  .premiumYearly,  .yearly,  "$69"),
            product(ProductIDs.familyMonthly,  .familyMonthly,  .monthly, "$10.99"),
            product(ProductIDs.familyYearly,   .familyYearly,   .yearly,  "$109"),
            product(ProductIDs.founders,       .founders,       .monthly, "$4.99")
        ]
    }

    // MARK: - Partition

    func testPartition_splitsByPeriod() {
        let result = PaywallViewModel.partitioned(products: catalog, showFounders: true)
        XCTAssertEqual(result.monthly.count, 3, "premium + family + founders are monthly")
        XCTAssertEqual(result.yearly.count, 2, "premium + family are yearly")
        XCTAssertTrue(result.monthly.allSatisfy { $0.period == .monthly })
        XCTAssertTrue(result.yearly.allSatisfy { $0.period == .yearly })
    }

    func testPartition_hidesFoundersWhenShowFoundersFalse() {
        let result = PaywallViewModel.partitioned(products: catalog, showFounders: false)
        XCTAssertEqual(result.monthly.count, 2, "founders is dropped, premium + family remain")
        XCTAssertFalse(result.monthly.contains { $0.tier == .founders })
        XCTAssertFalse(result.yearly.contains { $0.tier == .founders }, "founders is monthly-only anyway but make sure the filter doesn't mis-route")
    }

    func testPartition_foundersVisibleByDefault() {
        let result = PaywallViewModel.partitioned(products: catalog, showFounders: true)
        XCTAssertTrue(result.monthly.contains { $0.tier == .founders })
    }

    // MARK: - Default selection

    func testDefaultSelection_picksYearlyPremium() {
        let result = PaywallViewModel.partitioned(products: catalog, showFounders: true)
        XCTAssertEqual(result.defaultSelection?.tier, .premiumYearly, "yearly premium is the best-value pitch")
    }

    func testDefaultSelection_fallsBackToAnyYearlyWhenPremiumYearlyMissing() {
        let missingPremiumYearly = catalog.filter { $0.tier != .premiumYearly }
        let result = PaywallViewModel.partitioned(products: missingPremiumYearly, showFounders: true)
        XCTAssertEqual(result.defaultSelection?.tier, .familyYearly)
    }

    func testDefaultSelection_fallsBackToMonthlyWhenNoYearlyAvailable() {
        let onlyMonthly = catalog.filter { $0.period == .monthly }
        let result = PaywallViewModel.partitioned(products: onlyMonthly, showFounders: true)
        XCTAssertNotNil(result.defaultSelection)
        XCTAssertEqual(result.defaultSelection?.period, .monthly)
    }

    func testDefaultSelection_nilForEmptyCatalog() {
        let result = PaywallViewModel.partitioned(products: [], showFounders: true)
        XCTAssertNil(result.defaultSelection)
        XCTAssertTrue(result.monthly.isEmpty)
        XCTAssertTrue(result.yearly.isEmpty)
    }

    // MARK: - Founders flag

    func testFoundersAvailabilityIsTrueForLaunch() {
        // Until the backend exposes founders-remaining, this flag is true.
        // When wired, testing it becomes a server-stub integration concern.
        XCTAssertTrue(PaywallViewModel.isFoundersAvailable)
    }

    // MARK: - Context enumeration

    func testPaywallContext_coversAllParentTriggers() {
        // The view flipped all surfaces to parent-driven contexts under
        // Model 1. If any kid-triggered context sneaks back in via a
        // future refactor, this test calls it out.
        let parentOnly: Set<PaywallContext> = [
            .streakMilestone, .parentDashboard, .historyHorizon,
            .advancedAnalytics, .developmentReport, .addSecondChild,
            .settingsBrowse
        ]
        XCTAssertEqual(Set(PaywallContext.allCases), parentOnly)
    }
}

extension PaywallContext: CaseIterable {
    public static var allCases: [PaywallContext] {
        [.streakMilestone, .parentDashboard, .historyHorizon,
         .advancedAnalytics, .developmentReport, .addSecondChild, .settingsBrowse]
    }
}
