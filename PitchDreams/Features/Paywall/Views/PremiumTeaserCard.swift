import SwiftUI

/// Dismissible "Unlock Parent Insights" card for the parent dashboard.
/// Sits between the greeting and the children list. Stays hidden for paid
/// users, and disappears for 7 days after the parent dismisses it — so it's
/// persistent without being a nag. Tapping the card opens the paywall.
///
/// This is the lightweight Track D stopgap while the actual premium
/// surfaces (advanced analytics, dev-profile PDF, etc.) get built — keeps
/// the subscription flow discoverable in-app without needing those views.
struct PremiumTeaserCard: View {
    @EnvironmentObject private var entitlementStore: EntitlementStore
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    /// Last time the parent tapped dismiss. Stored as Unix timestamp
    /// (0 = never dismissed). The card hides for `Self.cooldown` after.
    @AppStorage("premiumTeaserDismissedAt") private var dismissedAtEpoch: Double = 0
    @State private var showPaywall = false

    /// How long the card stays hidden after dismissal before returning.
    /// A week felt right: long enough to not annoy, short enough that a
    /// parent who loves the app will see the pitch again at a different
    /// moment of their weekly rhythm.
    private static let cooldown: TimeInterval = 7 * 24 * 60 * 60

    var body: some View {
        if shouldShow {
            card
                .sheet(isPresented: $showPaywall) {
                    PaywallView(
                        manager: subscriptionManager,
                        entitlementStore: entitlementStore,
                        context: .settingsBrowse
                    )
                }
        }
    }

    // MARK: - Visibility

    private var shouldShow: Bool {
        guard !entitlementStore.isPaid else { return false }
        guard dismissedAtEpoch > 0 else { return true }
        let dismissedAt = Date(timeIntervalSince1970: dismissedAtEpoch)
        return Date().timeIntervalSince(dismissedAt) > Self.cooldown
    }

    // MARK: - Card

    private var card: some View {
        Button {
            showPaywall = true
        } label: {
            HStack(alignment: .top, spacing: 14) {
                // Badge
                ZStack {
                    Circle()
                        .fill(Color.dsAccentOrange.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.dsAccentOrange)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text("UNLOCK PARENT INSIGHTS")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .tracking(2)
                            .foregroundStyle(Color.dsAccentOrange)
                        Spacer(minLength: 0)
                    }

                    Text("See the full development picture.")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.dsOnSurface)

                    Text("Trends, rest-day intel, and a PDF report coaches actually read — from \(PricingReference.premiumMonthly).")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                        .lineLimit(2)
                }

                // Close button — dismisses for the cooldown window
                Button {
                    dismissedAtEpoch = Date().timeIntervalSince1970
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                        .frame(width: 22, height: 22)
                        .background(Color.dsSurfaceContainerHigh)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss for now")
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.dsSurfaceContainerLow)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(Color.dsAccentOrange.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Unlock Parent Insights premium features")
        .accessibilityHint("Tap to see plans")
    }
}

#Preview {
    VStack {
        PremiumTeaserCard()
            .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.dsBackground)
    .environmentObject(EntitlementStore())
    .environmentObject(SubscriptionManager(entitlementStore: EntitlementStore()))
}
