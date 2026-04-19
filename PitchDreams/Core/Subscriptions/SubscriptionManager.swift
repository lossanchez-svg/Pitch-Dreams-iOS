import Foundation
import StoreKit

/// StoreKit 2 wrapper. Responsibilities:
/// - Fetch product catalog from the App Store
/// - Handle purchase flow (init purchase → verify transaction → finish)
/// - Listen for transaction updates (renewals, revocations, refunds)
/// - Restore purchases on demand
/// - Resolve the user's highest-entitled tier and push it to `EntitlementStore`
///
/// Receipt validation strategy is **client-side only** at launch (Apple's
/// `VerificationResult` cryptographic check is sufficient for most cases).
/// Server-side receipt validation is a post-launch enhancement when the
/// web-team endpoint is ready.
@MainActor
final class SubscriptionManager: ObservableObject {
    @Published private(set) var products: [SubscriptionProduct] = []
    @Published private(set) var purchaseInFlight: Bool = false
    @Published private(set) var lastError: String?

    private let entitlementStore: EntitlementStore
    private var transactionListenerTask: Task<Void, Never>?

    init(entitlementStore: EntitlementStore) {
        self.entitlementStore = entitlementStore
        transactionListenerTask = Task.detached(priority: .background) { [weak self] in
            await self?.listenForTransactions()
        }
    }

    deinit {
        transactionListenerTask?.cancel()
    }

    // MARK: - Product catalog

    /// Fetch product metadata from the App Store. Call once at app launch
    /// (after auth) and any time the catalog may have changed.
    func loadProducts() async {
        do {
            let storeProducts = try await Product.products(for: ProductIDs.all)
            let mapped = storeProducts.compactMap(Self.map)
            self.products = mapped.sorted { $0.period == .yearly && $1.period == .monthly }
        } catch {
            lastError = "Failed to load products: \(error.localizedDescription)"
        }
    }

    // MARK: - Purchase

    /// Kick off a StoreKit purchase for the given product. On success,
    /// verifies the transaction, finishes it, and refreshes entitlements.
    func purchase(_ product: SubscriptionProduct) async -> Bool {
        guard let storeProduct = try? await Product.products(for: [product.id]).first else {
            lastError = "Product not available"
            return false
        }
        purchaseInFlight = true
        defer { purchaseInFlight = false }

        do {
            let result = try await storeProduct.purchase()
            switch result {
            case .success(let verification):
                let transaction = try Self.checkVerified(verification)
                await refreshEntitlements()
                await transaction.finish()
                // Stamp founders cohort on the very first founders purchase
                // so future renewals at the grandfathered price continue to
                // treat the user as a founder even if marketing prices change.
                if transaction.productID == ProductIDs.founders {
                    entitlementStore.markFoundersCohort()
                }
                return true
            case .userCancelled:
                return false
            case .pending:
                lastError = "Purchase pending — we'll update when it completes"
                return false
            @unknown default:
                lastError = "Unexpected purchase result"
                return false
            }
        } catch {
            lastError = "Purchase failed: \(error.localizedDescription)"
            return false
        }
    }

    /// Re-check all stored transactions and recompute the active tier.
    /// Called after purchase, on app foreground, and on "Restore Purchases".
    func refreshEntitlements() async {
        var highest: SubscriptionTier = .free
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard transaction.revocationDate == nil else { continue }
            if let exp = transaction.expirationDate, exp < .now { continue }
            guard let tier = ProductIDs.tier(for: transaction.productID) else { continue }
            if tierRank(tier) > tierRank(highest) {
                highest = tier
            }
        }
        entitlementStore.setActiveTier(highest)
    }

    /// Apple's "Restore Purchases" button hooks into this. StoreKit 2
    /// synchronizes receipts in the background on its own, so this is
    /// mostly a user-visible reassurance button.
    func restorePurchases() async {
        do {
            try await AppStore.sync()
        } catch {
            lastError = "Restore failed: \(error.localizedDescription)"
        }
        await refreshEntitlements()
    }

    // MARK: - Transaction listener

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            guard case .verified(let transaction) = result else { continue }
            await refreshEntitlements()
            await transaction.finish()
        }
    }

    // MARK: - Helpers

    private static func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw NSError(domain: "SubscriptionManager", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Transaction could not be verified"])
        case .verified(let value):
            return value
        }
    }

    private static func map(_ product: Product) -> SubscriptionProduct? {
        guard let tier = ProductIDs.tier(for: product.id) else { return nil }
        let period: SubscriptionProduct.BillingPeriod = {
            if let unit = product.subscription?.subscriptionPeriod.unit, unit == .year {
                return .yearly
            }
            return .monthly
        }()
        return SubscriptionProduct(
            id: product.id,
            tier: tier,
            displayPrice: product.displayPrice,
            period: period
        )
    }

    /// Order tiers from least to most featureful so we can pick the best
    /// if a user somehow has multiple active subscriptions (edge case —
    /// refund + repurchase, family-share overlap). Founders has the same
    /// feature set as premium so they share rank 1.
    private func tierRank(_ tier: SubscriptionTier) -> Int {
        switch tier {
        case .free:             return 0
        case .founders:         return 1
        case .premiumMonthly:   return 1
        case .premiumYearly:    return 2
        case .familyMonthly:    return 3
        case .familyYearly:     return 4
        case .club:             return 5
        }
    }
}
