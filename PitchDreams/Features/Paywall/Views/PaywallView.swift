import SwiftUI

/// Scaffold paywall UI. Copy + pricing + headline messaging are placeholders
/// until Track D product decisions finalize. The structure (hero + benefits
/// + plan picker + CTA + restore/legal) is stable — future passes will swap
/// copy, hero art, and benefit icons without touching the plumbing.
struct PaywallView: View {
    @StateObject private var viewModel: PaywallViewModel
    @Environment(\.dismiss) private var dismiss

    init(
        manager: SubscriptionManager,
        entitlementStore: EntitlementStore,
        context: PaywallContext
    ) {
        _viewModel = StateObject(wrappedValue: PaywallViewModel(
            manager: manager,
            entitlementStore: entitlementStore,
            context: context
        ))
    }

    var body: some View {
        ZStack {
            Color.dsBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    closeBar
                    hero
                    benefits
                    planPicker
                    ctaButton
                    footer
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .task { await viewModel.onAppear() }
    }

    // MARK: - Sections

    private var closeBar: some View {
        HStack {
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
                    .frame(width: 32, height: 32)
                    .background(Color.dsSurfaceContainerHigh)
                    .clipShape(Circle())
            }
        }
        .padding(.top, 8)
    }

    private var hero: some View {
        VStack(spacing: 12) {
            Image(systemName: "star.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color.dsAccentOrange)

            Text(headline)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.dsOnSurface)

            Text(subhead)
                .font(.system(size: 15, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.dsOnSurfaceVariant)
                .padding(.horizontal, 12)
        }
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 12) {
            benefitRow(icon: "chart.line.uptrend.xyaxis", text: "Parent Insights Dashboard")
            benefitRow(icon: "chart.bar.fill", text: "Advanced trends & comparisons")
            benefitRow(icon: "doc.richtext", text: "Development Profile PDF report")
            benefitRow(icon: "envelope.fill", text: "Weekly parent insights email")
            benefitRow(icon: "moon.fill", text: "Rest Day intelligence for parents")
            benefitRow(icon: "clock.arrow.circlepath", text: "Unlimited training history")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.dsSurfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
    }

    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color.dsSecondary)
                .frame(width: 24)
            Text(text)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.dsOnSurface)
            Spacer()
        }
    }

    private var planPicker: some View {
        VStack(spacing: 10) {
            ForEach(viewModel.yearlyOptions, id: \.id) { product in
                planRow(product: product, isFeatured: product.tier == .premiumYearly)
            }
            ForEach(viewModel.monthlyOptions, id: \.id) { product in
                planRow(product: product, isFeatured: false)
            }

            if viewModel.yearlyOptions.isEmpty && viewModel.monthlyOptions.isEmpty {
                Text("Loading plans…")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
                    .padding()
            }
        }
    }

    private func planRow(product: SubscriptionProduct, isFeatured: Bool) -> some View {
        let selected = viewModel.selectedProduct?.id == product.id
        return Button {
            viewModel.selectedProduct = product
        } label: {
            HStack(spacing: 12) {
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(selected ? Color.dsSecondary : Color.dsOnSurfaceVariant)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(product.tier.displayName)
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.dsOnSurface)
                        if isFeatured {
                            Text("BEST VALUE")
                                .font(.system(size: 9, weight: .heavy, design: .rounded))
                                .tracking(1)
                                .foregroundStyle(Color.dsCTALabel)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.dsAccentOrange)
                                .clipShape(Capsule())
                        }
                    }
                    Text(product.displayPrice)
                        .font(.system(size: 14, weight: .medium, design: .rounded).monospacedDigit())
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                }
                Spacer()
            }
            .padding(14)
            .background(Color.dsSurfaceContainerLow)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(selected ? Color.dsSecondary : Color.white.opacity(0.06), lineWidth: selected ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        }
        .buttonStyle(.plain)
    }

    private var ctaButton: some View {
        Button {
            Task {
                let ok = await viewModel.purchaseSelected()
                if ok { dismiss() }
            }
        } label: {
            HStack(spacing: 8) {
                if viewModel.selectedProduct == nil {
                    Text("Select a plan")
                } else {
                    Text("CONTINUE")
                        .tracking(2)
                    Image(systemName: "arrow.right")
                }
            }
            .font(.system(size: 15, weight: .black, design: .rounded))
            .foregroundStyle(Color.dsCTALabel)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(DSGradient.primaryCTA)
            .clipShape(Capsule())
            .dsPrimaryShadow()
        }
        .disabled(viewModel.selectedProduct == nil || viewModel.purchaseInFlight)
        .opacity((viewModel.selectedProduct == nil || viewModel.purchaseInFlight) ? 0.5 : 1)
    }

    private var footer: some View {
        VStack(spacing: 8) {
            Button {
                Task { await viewModel.restorePurchases() }
            } label: {
                Text("Restore Purchases")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
            }

            Text("Subscriptions auto-renew. Cancel anytime in Settings.")
                .font(.system(size: 11))
                .foregroundStyle(Color.dsOnSurfaceVariant.opacity(0.7))
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Button("Terms") { /* TODO: link to live ToS */ }
                Button("Privacy") { /* TODO: link to live Privacy Policy */ }
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Color.dsOnSurfaceVariant)
        }
        .padding(.top, 8)
    }

    // MARK: - Context-driven copy

    // Copy reflects Model 1: the kid's training experience stays free; paid
    // tiers unlock PARENT insights and multi-kid support. Every headline
    // speaks to the parent.

    private var headline: String {
        switch viewModel.context {
        case .streakMilestone:      return "Your Kid Is Committed.\nSee Their Full Development."
        case .parentDashboard:      return "See the Full Picture\nof Your Kid's Training."
        case .historyHorizon:       return "Track Every Session.\nSee the Full Journey."
        case .advancedAnalytics:    return "Deeper Insights\nInto Their Progress."
        case .developmentReport:    return "A Report Coaches Actually Read."
        case .addSecondChild:       return "Track All Your Kids\nIn One Place."
        case .settingsBrowse:       return "Unlock the Parent Dashboard."
        }
    }

    private var subhead: String {
        switch viewModel.context {
        case .streakMilestone:      return "They've built a real habit. Get the weekly insights, rest-day intelligence, and development reports that help them keep going."
        case .parentDashboard:      return "Weekly insights, rest-day intelligence, and a PDF report you can share with coaches — all for 1% of what you already spend on soccer."
        case .historyHorizon:       return "Free tier shows last 30 days. Premium unlocks every session, ever — the full arc of their development."
        case .advancedAnalytics:    return "Trend charts, month-over-month progress, age-group benchmarks — the data behind the streaks."
        case .developmentReport:    return "A seasonal development PDF perfect for coaches, grandparents, or college applications."
        case .addSecondChild:       return "Family plan covers up to 4 kids with one parent dashboard and a gentle sibling league."
        case .settingsBrowse:       return "Kids train free forever. Parents unlock the insights — analytics, reports, multi-kid support."
        }
    }

}

#Preview {
    PaywallView(
        manager: SubscriptionManager(entitlementStore: EntitlementStore()),
        entitlementStore: EntitlementStore(),
        context: .streakMilestone
    )
}
