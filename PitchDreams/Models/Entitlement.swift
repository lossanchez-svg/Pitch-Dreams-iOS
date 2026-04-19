import Foundation

/// Single source of truth for what a subscriber gets. Keep this list aligned
/// with `proposals/LAUNCH_READY_PLAN.md` Track D tier structure.
///
/// **Monetization model: Model 1 — "Free for the kid, paid for the parent."**
/// All kid-facing features (avatars, weekly recap sharing, coach voice packs,
/// app icons) stay on the free tier forever. Paid tiers unlock PARENT-value
/// features only — analytics, notifications, PDF reports, multi-kid support.
/// This is the core differentiator vs conventional freemium apps.
///
/// Call sites should gate features with `entitlementStore.has(.featureX)` —
/// never read the raw tier directly. That way a feature can be moved between
/// tiers without touching call sites.
enum Feature: String, CaseIterable, Codable {
    // MARK: - Parent-value features (PAID)

    /// Parent Insights Dashboard — the core parent-facing premium surface.
    /// Includes training summaries, trend charts, milestone notifications.
    case parentInsightsDashboard

    /// Deep analytics — month-over-month trends, skill breakdowns,
    /// comparisons against age-group benchmarks.
    case advancedAnalytics

    /// Unlimited training history (free tier caps at last 30 days).
    case unlimitedHistory

    /// Rest Day intelligence — detects high soreness / low mood and
    /// surfaces gentler routines with parent notifications. Behavioral
    /// differentiation that parents pay for.
    case restDayIntelligence

    /// Weekly parent insights email — off-app engagement channel.
    case parentWeeklyInsightsEmail

    /// Development Profile PDF — shareable report for coaches, grandparents,
    /// college applications. Seasonal snapshot.
    case developmentProfilePDF

    /// Priority support channel.
    case prioritySupport

    // MARK: - Family tier additions (PAID)

    /// Up to 4 children on one account with a unified parent dashboard.
    case familyMultiChild

    /// Cross-sibling "family league" — gentle competition between siblings.
    case siblingLeague

    // MARK: - Club B2B (POST-LAUNCH)

    /// Coach dashboard for clubs — tracks player consistency, flags
    /// underperformers, club-branded app experience.
    case clubCoachDashboard
}

/// Buyable tiers. Product IDs are placeholders until App Store Connect is
/// configured — update `ProductIDs` when the products are live. Keep IDs
/// stable once shipped; changing them orphans existing subscribers.
enum SubscriptionTier: String, CaseIterable, Codable {
    case free
    case premiumMonthly     // $6.99/mo — parent-value features for 1 kid
    case premiumYearly      // $69/yr
    case familyMonthly      // $10.99/mo — parent-value features for up to 4 kids
    case familyYearly       // $109/yr
    case founders           // $4.99/mo locked forever, first 500 users only — same features as premium
    case club               // $299/yr per club, B2B post-launch

    var features: Set<Feature> {
        switch self {
        case .free:
            // Free-forever experience. Kid gets EVERYTHING — avatars, recap
            // sharing, coach voices, signature moves, mystery box, IRL pitch.
            // Parent gets basic stats for 1 kid (last 30 days). No kid-
            // facing feature is gated under Model 1.
            return []
        case .premiumMonthly, .premiumYearly, .founders:
            return [
                .parentInsightsDashboard,
                .advancedAnalytics,
                .unlimitedHistory,
                .restDayIntelligence,
                .parentWeeklyInsightsEmail,
                .developmentProfilePDF,
                .prioritySupport
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
        case .founders:         return "Founders (Monthly)"
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
    let displayPrice: String        // "$6.99" or "$69" — filled from StoreKit at runtime
    let period: BillingPeriod

    enum BillingPeriod: String {
        case monthly
        case yearly
    }
}

/// Canonical product-ID catalog. Update these to match App Store Connect
/// when products are configured. Keep IDs stable once shipped — changing
/// them orphans existing subscribers.
///
/// Founders is monthly-only by design — it's a promotional lock-in, not a
/// tier variant. Yearly founders would over-complicate the pitch.
enum ProductIDs {
    static let premiumMonthly   = "com.pitchdreams.premium.monthly"
    static let premiumYearly    = "com.pitchdreams.premium.yearly"
    static let familyMonthly    = "com.pitchdreams.family.monthly"
    static let familyYearly     = "com.pitchdreams.family.yearly"
    static let founders         = "com.pitchdreams.founders.monthly"

    /// All product IDs that should be fetched from StoreKit at launch.
    /// Club tier is B2B-only and not a consumer-facing IAP.
    static let all: Set<String> = [
        premiumMonthly, premiumYearly,
        familyMonthly, familyYearly,
        founders
    ]

    /// Resolve a tier from a product ID. Returns nil for unknown / Club / free.
    static func tier(for productId: String) -> SubscriptionTier? {
        switch productId {
        case premiumMonthly:   return .premiumMonthly
        case premiumYearly:    return .premiumYearly
        case familyMonthly:    return .familyMonthly
        case familyYearly:     return .familyYearly
        case founders:         return .founders
        default:               return nil
        }
    }
}

/// Canonical pricing reference. Hard-coded copies of the prices configured
/// in App Store Connect — use only for UI messaging pre-StoreKit-load (the
/// paywall replaces these with live `displayPrice` from StoreKit once the
/// catalog loads). Update whenever App Store Connect changes.
///
/// Source of truth is App Store Connect, not this file. Pricing decisions
/// (as of 2026-04-18):
/// - Premium $6.99/mo or $69/yr
/// - Family $10.99/mo or $109/yr (up to 4 kids)
/// - Founders $4.99/mo, first 500 subscribers lock in forever
/// - Club $299/yr per club, post-launch only
enum PricingReference {
    static let premiumMonthly = "$6.99/mo"
    static let premiumYearly  = "$69/yr"
    static let familyMonthly  = "$10.99/mo"
    static let familyYearly   = "$109/yr"
    static let founders       = "$4.99/mo"
    static let club           = "$299/yr"

    /// Post-Model 1 philosophy: $69/yr = 18% off monthly ($6.99 × 12 = $83.88).
    /// Family yearly = 17% off.
    static let yearlyDiscountMessaging = "Save 17% with yearly"

    /// Founders cohort cap. Server is the ultimate source of truth — this
    /// constant is just for in-app messaging ("Join the first 500").
    static let foundersCohortSize = 500
}
