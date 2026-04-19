import SwiftUI

/// XP progress bar showing progress toward the next avatar evolution.
/// Visually matches `proposals/Stitch/home_xp_bar.png` — avatar wrapped in
/// a stage-colored ring (cyan for Pro, gold for Legend), 12pt orange-peach
/// gradient fill, "NEXT RANK" label stacked on the right.
struct XPBarView: View {
    let avatarAssetName: String
    let totalXP: Int
    let progress: Double
    let xpInStage: Int
    let xpNeeded: Int
    let currentStage: AvatarStage

    private var isMaxed: Bool { currentStage == .legend }

    private var nextStageLabel: String {
        switch currentStage {
        case .rookie: return "Pro"
        case .pro:    return "Legend"
        case .legend: return "LEGEND"
        }
    }

    /// Stage-appropriate ring color around the avatar: cyan once you're
    /// Pro, gold at Legend, subtle charcoal while still Rookie.
    private var avatarRingColor: Color {
        switch currentStage {
        case .rookie: return Color.dsSurfaceContainerHighest
        case .pro:    return Color.dsSecondary
        case .legend: return Color.dsTertiary
        }
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            avatarWithRing

            // Progress bar + labels
            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.dsSurfaceContainerHighest)
                            .frame(height: 12)
                        Capsule()
                            .fill(fillStyle)
                            .frame(width: geo.size.width * progress, height: 12)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: progress)
                    }
                }
                .frame(height: 12)

                // XP label beneath the bar
                HStack {
                    if isMaxed {
                        Text("\(totalXP) XP")
                            .font(.system(size: 11, weight: .heavy, design: .rounded).monospacedDigit())
                            .foregroundStyle(Color.dsTertiaryContainer)
                    } else {
                        Text("\(xpInStage) / \(xpNeeded) XP")
                            .font(.system(size: 11, weight: .heavy, design: .rounded).monospacedDigit())
                            .foregroundStyle(Color.dsOnSurfaceVariant)
                    }
                    Spacer()
                }
            }

            nextRankBlock
        }
        .padding(Spacing.lg)
        .background(Color.dsSurfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .ghostBorder()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Experience progress")
        .accessibilityValue(accessibilityDescription)
    }

    // MARK: - Avatar

    @ViewBuilder
    private var avatarWithRing: some View {
        let ringSize: CGFloat = 44
        ZStack {
            Circle()
                .stroke(avatarRingColor, lineWidth: 2)
                .frame(width: ringSize, height: ringSize)

            if UIImage(named: avatarAssetName) != nil {
                Image(avatarAssetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: ringSize - 6, height: ringSize - 6)
                    .clipShape(Circle())
            } else {
                Image(systemName: "figure.soccer")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.dsSecondary)
                    .frame(width: ringSize - 6, height: ringSize - 6)
                    .background(Color.dsSecondary.opacity(0.12))
                    .clipShape(Circle())
            }
        }
    }

    // MARK: - Fill style

    private var fillStyle: AnyShapeStyle {
        if isMaxed {
            return AnyShapeStyle(LinearGradient(
                colors: [Color.dsTertiaryContainer, Color.dsTertiary],
                startPoint: .leading, endPoint: .trailing
            ))
        }
        return AnyShapeStyle(LinearGradient(
            colors: [Color.dsAccentOrange, Color(hex: "#FFB88A"), Color(hex: "#FFE6DE")],
            startPoint: .leading, endPoint: .trailing
        ))
    }

    // MARK: - Next-rank block

    @ViewBuilder
    private var nextRankBlock: some View {
        if isMaxed {
            VStack(alignment: .trailing, spacing: 1) {
                Text("LEGEND")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(Color.dsTertiaryContainer)
                Image(systemName: "medal.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.dsTertiaryContainer)
            }
        } else {
            VStack(alignment: .trailing, spacing: 1) {
                HStack(spacing: 3) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10, weight: .bold))
                    Text(nextStageLabel)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                }
                .foregroundStyle(Color.dsAccentOrange)
                Text("NEXT RANK")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(Color.dsOnSurfaceVariant)
            }
        }
    }

    // MARK: - Accessibility

    private var accessibilityDescription: String {
        if isMaxed {
            return "Legend stage reached. \(totalXP) total XP."
        }
        let percent = Int((progress * 100).rounded())
        return "\(xpInStage) of \(xpNeeded) XP toward \(nextStageLabel). \(percent) percent complete."
    }
}

#Preview {
    VStack(spacing: 16) {
        XPBarView(avatarAssetName: "wolf_stage1", totalXP: 250, progress: 0.5, xpInStage: 250, xpNeeded: 500, currentStage: .rookie)
        XPBarView(avatarAssetName: "wolf_stage2", totalXP: 1200, progress: 0.47, xpInStage: 700, xpNeeded: 1500, currentStage: .pro)
        XPBarView(avatarAssetName: "wolf_stage3", totalXP: 3000, progress: 1.0, xpInStage: 0, xpNeeded: 0, currentStage: .legend)
    }
    .padding()
    .background(Color.dsBackground)
}
