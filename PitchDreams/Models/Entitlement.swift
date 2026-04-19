import Foundation

/// Single source of truth for what a subscriber gets. Keep this list aligned
/// with `proposals/LAUNCH_READY_PLAN.md` Track D tier structure.
///
/// Call sites should gate features with `entitlementStore.has(.featureX)` —
/// never read the raw tier directly. That way the same feature can be moved
/// between tiers without touching call sites.
enum Feature: String, CaseIterable, Codable {
    case allAvatars                 // Unlock all 7 avatars (free tier gets 1)
    case unlimitedHistory           // Session log beyond last 30 days
    case weeklyRecapExport          // Shareable recap card / sheet export
    case parentInsightsDashboard    // Parent-value features
    case advancedAnalytics          // Trends, comparisons
    case restDayIntelligence        // Rest Day surfacing + routines (B7)
    case appIconVariants            // B2
    case coachVoicePacks            // Multiple coach personalities
    case prioritySupport
    case familyMultiChild           // Up to 4 kids on one account
    case siblingLeague              // Cross-sibling family league
    case clubCoachDashboard         // Club B2B only
}

/// Buyable tiers. Product IDs are placeholders until pricing is finalized —
/// update `SubscriptionProduct.productId` when App Store Connect is set up.
enum SubscriptionTier: String, CaseIterable, Codable {
    case free
    case premiumMonthly
    case premiumYearly
    case familyMonthly
    case familyYearly
    case foundersMonthly    // Locked $4.99/mo for first N — same features as premium
    case foundersYearly     // Locked $49/yr for first N
    case club               // $299/yr per club, B2B post-launch

    var features: Set<Feature> {
        switch self {
        case .free:
            // Free-forever experience — intentionally meaningful so the app
            // stands on its own without a paywall.
            return []
        case .premiumMonthly, .premiumYearly, .foundersMonthly, .foundersYearly:
            return [
                .allAvatars, .unlimitedHistory, .weeklyRecapExport,
                .parentInsightsDashboard, .advancedAnalytics, .restDayIntelligence,
                .appIconVariants, .coachVoicePacks, .prioritySupport
            ]
        case .familyMonthly, .familyYearly:
            // Family = Premium + multi-child + sibling league
            var base = SubscriptionTier.premiumMonthly.features
            base.insert(.familyMultiChild)
            base.insert(.siblingLeague)
            return base
        case .club:
            // Club = Family + coach dashboard
            var base = SubscriptionTier.familyMonthly.features
            base.insert(.clubCoachDashboard)
            return base
        }
    }

    /// Whether this tier is a paid subscription (vs free).
    var isPaid: Bool { self != .free }

    /// Human-readable marketing label. Copy gets finalized separately.
    var displayName: String {
        switch self {
        case .free:             return "Free"
        case .premiumMonthly:   return "Premium (Monthly)"
        case .premiumYearly:    return "Premium (Yearly)"
        case .familyMonthly:    return "Family (Monthly)"
        case .familyYearly:     return "Family (Yearly)"
        case .foundersMonthly:  return "Founders (Monthly)"
        case .foundersYearly:   return "Founders (Yearly)"
        case .club:             return "Club"
        }
    }
}

/// Metadata about a StoreKit product. Kept separate from `SubscriptionTier`
/// because product IDs, display prices, and marketing copy live in App Store
/// Connect and change independently of the feature bundling logic.
struct SubscriptionProduct: Identifiable, Equatable {
    let id: String                  // StoreKit product identifier
    let tier: SubscriptionTier
    let displayPrice: String        // "$8.99" or "$69" — filled from StoreKit at runtime
    let period: BillingPeriod

    enum BillingPeriod: String {
        case monthly
        case yearly
    }
}

/// Canonical product-ID catalog. Update these to match App Store Connect
/// when products are configured. Keep IDs stable once shipped — changing
/// them orphans existing subscribers.
enum ProductIDs {
    static let premiumMonthly   = "com.pitchdreams.premium.monthly"
    static let premiumYearly    = "com.pitchdreams.premium.yearly"
    static let familyMonthly    = "com.pitchdreams.family.monthly"
    static let familyYearly     = "com.pitchdreams.family.yearly"
    static let foundersMonthly  = "com.pitchdreams.founders.monthly"
    static let foundersYearly   = "com.pitchdreams.founders.yearly"

    /// All product IDs that should be fetched from StoreKit at launch.
    /// Club tier is B2B-only and not a consumer-facing IAP.
    static let all: Set<String> = [
        premiumMonthly, premiumYearly,
        familyMonthly, familyYearly,
        foundersMonthly, foundersYearly
    ]

    /// Resolve a tier from a product ID. Returns nil for unknown / Club / free.
    static func tier(for productId: String) -> SubscriptionTier? {
        switch productId {
        case premiumMonthly:   return .premiumMonthly
        case premiumYearly:    return .premiumYearly
        case familyMonthly:    return .familyMonthly
        case familyYearly:     return .familyYearly
        case foundersMonthly:  return .foundersMonthly
        case foundersYearly:   return .foundersYearly
        default:               return nil
        }
    }
}
