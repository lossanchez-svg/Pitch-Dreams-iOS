import SwiftUI

struct ConsistencyRingView: View {
    let streak: Int
    let maxStreak: Int
    let freezes: Int

    init(streak: Int, maxStreak: Int = 30, freezes: Int = 0) {
        self.streak = streak
        self.maxStreak = maxStreak
        self.freezes = freezes
    }

    private var progress: Double {
        guard maxStreak > 0 else { return 0 }
        return min(1.0, Double(streak) / Double(maxStreak))
    }

    private var progressPercent: Int {
        Int(progress * 100)
    }

    private var message: String {
        if progress == 0 { return "Start today!" }
        if progress < 0.5 { return "Keep going!" }
        if progress < 1.0 { return "Great consistency!" }
        return "Outstanding!"
    }

    // MARK: - Escalating Flame

    private var flameIcon: String {
        streak >= 30 ? "flame.circle.fill" : "flame.fill"
    }

    private var flameSize: CGFloat {
        switch streak {
        case 0...6:   return 14
        case 7...13:  return 18
        case 14...29: return 22
        case 30...99: return 26
        default:      return 30  // 100+ days
        }
    }

    private var flameColor: Color {
        switch streak {
        case 0...6:   return Color.dsAccentOrange
        case 7...13:  return Color.dsAccentOrange
        case 14...29: return Color(hex: "#FF4500")
        default:      return Color(hex: "#FF0000")
        }
    }

    /// 100+ day streaks get a legendary gold outer halo ring around the
    /// main streak ring — matches the third variant in
    /// `proposals/Stitch/streak_ring_enhanced.png`.
    private var hasLegendaryHalo: Bool { streak >= 100 }

    /// Ring fill color darkens from orange (day 1+) through red (14+)
    /// then to gold for the legendary tier.
    private var ringColor: Color {
        switch streak {
        case 0..<7:    return Color.dsSecondary
        case 7..<14:   return Color.dsAccentOrange
        case 14..<100: return Color(hex: "#FF4500")
        default:       return Color.dsTertiaryContainer  // 100+
        }
    }

    var body: some View {
        HStack(spacing: 20) {
            // Ring on the left
            ZStack {
                // Legendary outer halo — only at 100+ days
                if hasLegendaryHalo {
                    Circle()
                        .stroke(Color.dsTertiaryContainer.opacity(0.4), lineWidth: 2)
                        .frame(width: 102, height: 102)
                        .blur(radius: 3)
                    Circle()
                        .stroke(Color.dsTertiary, lineWidth: 2)
                        .frame(width: 98, height: 98)
                }

                Circle()
                    .stroke(Color.dsSurfaceContainerHighest, lineWidth: 6)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        ringColor,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8, dampingFraction: 0.7), value: progress)

                VStack(spacing: 2) {
                    Text("\(streak)")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(Color.dsOnSurface)
                        .contentTransition(.numericText())
                    flameImage
                }
            }
            .frame(width: 90, height: 90)

            // Stats stacked on the right
            VStack(alignment: .leading, spacing: 10) {
                Text(message)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.dsOnSurface)

                HStack(spacing: 16) {
                    statItem(icon: "bolt", color: .dsSecondary, value: "\(maxStreak)", label: "Target")
                    statItem(icon: "chart.bar.fill", color: .dsTertiaryContainer, value: "\(progressPercent)%", label: "Progress")
                    shieldItem
                }
            }

            Spacer(minLength: 0)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.dsSurfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .ghostBorder()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Training streak")
        .accessibilityValue("\(streak) day\(streak == 1 ? "" : "s"). \(freezes) shield\(freezes == 1 ? "" : "s") available. \(progressPercent) percent toward \(maxStreak) day target.")
    }

    // MARK: - Flame Image (iOS 16 compatible)

    @ViewBuilder
    private var flameImage: some View {
        let base = Image(systemName: flameIcon)
            .font(.system(size: flameSize))
            .foregroundStyle(flameColor)
        if #available(iOS 17.0, *) {
            base.symbolEffect(.pulse, options: .repeating, isActive: streak >= 7)
        } else {
            base
        }
    }

    // MARK: - Shield Bank
    // Matches the mockup's inline shield-icon visualization: the count is
    // shown as literal shield pips (up to 3), with a numeric overflow
    // suffix for bigger banks. Falls back to a single shield + count when
    // shields are zero so the column layout stays stable.

    @ViewBuilder
    private var shieldItem: some View {
        VStack(spacing: 4) {
            shieldIcons
            Text("\(freezes)")
                .font(.system(size: 13, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(Color.dsOnSurface)
            Text("SHIELDS")
                .font(.system(size: 9, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(Color.dsOnSurfaceVariant)
        }
    }

    @ViewBuilder
    private var shieldIcons: some View {
        if freezes == 0 {
            pulsingShield(color: Color.dsError)
        } else {
            HStack(spacing: 2) {
                // Up to 3 pips side-by-side; if the user has >3, show
                // "3+" rather than a cluttered row.
                ForEach(0..<min(freezes, 3), id: \.self) { _ in
                    pulsingShield(color: Color.dsSecondary)
                }
                if freezes > 3 {
                    Text("+")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.dsSecondary)
                }
            }
        }
    }

    @ViewBuilder
    private func pulsingShield(color: Color) -> some View {
        let icon = Image(systemName: "shield.fill")
            .font(.system(size: 12))
            .foregroundStyle(color)
        if #available(iOS 17.0, *) {
            icon.symbolEffect(.pulse, options: .repeating, isActive: freezes > 0)
        } else {
            icon
        }
    }

    private func statItem(icon: String, color: Color, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(Color.dsOnSurface)
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(Color.dsOnSurfaceVariant)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ConsistencyRingView(streak: 0)
        ConsistencyRingView(streak: 12, freezes: 2)
        ConsistencyRingView(streak: 30, freezes: 1)
        ConsistencyRingView(streak: 100, freezes: 3)
    }
    .padding()
    .background(Color.dsBackground)
}
