import SwiftUI

/// Shown after a successful purchase instead of silently dismissing the
/// paywall. Parent sees a clear confirmation of what tier they landed on
/// plus a "here's what's new" list so they know where to click next.
struct WelcomeToPremiumView: View {
    let tier: SubscriptionTier
    let onContinue: () -> Void

    @State private var appear = false
    @State private var confettiPulse = false

    var body: some View {
        ZStack {
            Color.dsBackground.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                // Hero
                ZStack {
                    Circle()
                        .fill(Color.dsAccentOrange.opacity(confettiPulse ? 0.25 : 0.12))
                        .frame(width: 180, height: 180)
                        .blur(radius: 22)
                    Image(systemName: "sparkles")
                        .font(.system(size: 56, weight: .heavy))
                        .foregroundStyle(Color.dsAccentOrange)
                        .scaleEffect(appear ? 1 : 0.5)
                        .opacity(appear ? 1 : 0)
                }

                VStack(spacing: 8) {
                    Text("WELCOME TO \(tier.displayName.uppercased())")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .tracking(3)
                        .foregroundStyle(Color.dsAccentOrange)

                    Text(headline)
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(Color.dsOnSurface)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 10)

                // What just unlocked
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(unlockedHighlights, id: \.self) { line in
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.dsSecondary)
                            Text(line)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.dsOnSurface)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.dsSurfaceContainerLow)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                .padding(.horizontal, 20)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 20)

                Spacer()

                Button {
                    onContinue()
                } label: {
                    HStack(spacing: 8) {
                        Text("EXPLORE PREMIUM")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .tracking(2)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(Color.dsCTALabel)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(DSGradient.primaryCTA)
                    .clipShape(Capsule())
                    .dsPrimaryShadow()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
                appear = true
            }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                confettiPulse = true
            }
        }
    }

    // MARK: - Copy

    private var headline: String {
        switch tier {
        case .familyMonthly, .familyYearly:
            return "Now tracking the whole family."
        case .founders:
            return "Founders locked in — thanks for being early."
        default:
            return "Your parent dashboard just got deeper."
        }
    }

    /// 3-4 concrete things the parent just unlocked. Tier-aware so Family
    /// users see the multi-kid line and founders users get a thank-you.
    private var unlockedHighlights: [String] {
        var lines = [
            "Trends & month-over-month analytics",
            "Weekly insights email",
            "Development Profile PDF reports",
            "Full training history — no 30-day cap"
        ]
        if tier == .familyMonthly || tier == .familyYearly {
            lines.append("Up to 4 kids on one dashboard")
        }
        return lines
    }
}

#Preview {
    WelcomeToPremiumView(tier: .premiumYearly) {}
}
