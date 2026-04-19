import SwiftUI

/// Declarative feature-gate modifier. Use at the call site to conditionally
/// render premium UI without sprinkling `if store.has(.X)` everywhere.
///
/// ```swift
/// WeeklyRecapCardView(recap: recap)
///     .gated(by: .weeklyRecapExport, context: .weeklyRecapShare)
/// ```
///
/// When the feature is unlocked: renders the wrapped view as-is.
/// When locked: renders a tappable preview that opens the paywall.
struct FeatureGateModifier: ViewModifier {
    let feature: Feature
    let context: PaywallContext

    @EnvironmentObject private var entitlementStore: EntitlementStore
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @State private var showPaywall = false

    func body(content: Content) -> some View {
        Group {
            if entitlementStore.has(feature) {
                content
            } else {
                content
                    .overlay {
                        Color.black.opacity(0.55)
                            .overlay {
                                VStack(spacing: 8) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 22))
                                        .foregroundStyle(Color.dsAccentOrange)
                                    Text("PREMIUM")
                                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                                        .tracking(2)
                                        .foregroundStyle(Color.dsAccentOrange)
                                    Text("Tap to unlock")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(.white.opacity(0.9))
                                }
                            }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                    .onTapGesture { showPaywall = true }
                    .accessibilityLabel("Locked premium feature — tap to unlock")
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(
                manager: subscriptionManager,
                entitlementStore: entitlementStore,
                context: context
            )
        }
    }
}

extension View {
    /// Gate this view behind a premium feature. When locked, the view is
    /// dimmed with a "tap to unlock" overlay that presents the paywall.
    ///
    /// - Parameters:
    ///   - feature: Which feature grants access.
    ///   - context: Where the paywall was triggered from — drives copy.
    func gated(by feature: Feature, context: PaywallContext) -> some View {
        modifier(FeatureGateModifier(feature: feature, context: context))
    }
}
