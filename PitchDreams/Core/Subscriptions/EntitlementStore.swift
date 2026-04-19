import Foundation
import Combine

/// Observable, cached entitlement state. ViewModels and Views observe this
/// via `@EnvironmentObject` or `@ObservedObject` and gate features with
/// `has(.featureX)`.
///
/// **Source of truth:** `SubscriptionManager` writes the active tier here
/// whenever StoreKit transactions update. On cold launch, we restore the
/// last-known tier from UserDefaults so the UI renders correctly BEFORE
/// StoreKit finishes validating (avoids a brief free-tier flash on every
/// paid user's cold launch).
@MainActor
final class EntitlementStore: ObservableObject {
    @Published private(set) var activeTier: SubscriptionTier
    @Published private(set) var foundersCohort: Bool

    private let defaults: UserDefaults
    private let activeTierKey = "com.pitchdreams.subscription.activeTier"
    private let foundersCohortKey = "com.pitchdreams.subscription.foundersCohort"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let raw = defaults.string(forKey: activeTierKey),
           let tier = SubscriptionTier(rawValue: raw) {
            self.activeTier = tier
        } else {
            self.activeTier = .free
        }
        self.foundersCohort = defaults.bool(forKey: foundersCohortKey)
    }

    /// Primary feature-gate check. Call sites:
    /// `if entitlementStore.has(.weeklyRecapExport) { … }`
    func has(_ feature: Feature) -> Bool {
        activeTier.features.contains(feature)
    }

    /// Whether the user is on any paid tier (any premium / family / founders).
    var isPaid: Bool { activeTier.isPaid }

    /// Update the active tier. Called by `SubscriptionManager` when StoreKit
    /// transactions resolve. Persists so the next cold launch starts in the
    /// right state before the async StoreKit handshake completes.
    func setActiveTier(_ tier: SubscriptionTier) {
        activeTier = tier
        defaults.set(tier.rawValue, forKey: activeTierKey)
    }

    /// Mark the user as part of the founders cohort. Set once at first
    /// founders purchase and sticky forever — founders pricing is locked
    /// for the lifetime of the subscription per the plan.
    func markFoundersCohort() {
        foundersCohort = true
        defaults.set(true, forKey: foundersCohortKey)
    }

    /// Reset — used on logout/account switch and in tests.
    func reset() {
        activeTier = .free
        foundersCohort = false
        defaults.removeObject(forKey: activeTierKey)
        defaults.removeObject(forKey: foundersCohortKey)
    }
}
