import SwiftUI

/// XP progress bar showing progress toward the next avatar evolution.
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

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Avatar thumbnail
            if UIImage(named: avatarAssetName) != nil {
                Image(avatarAssetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } else {
                Image(systemName: "figure.soccer")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.dsSecondary)
                    .frame(width: 40, height: 40)
                    .background(Color.dsSecondary.opacity(0.12))
                    .clipShape(Circle())
            }

            // Progress bar + labels
            VStack(alignment: .leading, spacing: 4) {
                // Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Track
                        Capsule()
                            .fill(Color.dsSurfaceContainerHighest)
                            .frame(height: 10)

                        // Fill
                        Capsule()
                            .fill(
                                isMaxed
                                    ? LinearGradient(colors: [Color.dsTertiaryContainer, Color.dsTertiary], startPoint: .leading, endPoint: .trailing)
                                    : DSGradient.orangeAccent
                            )
                            .frame(width: geo.size.width * progress, height: 10)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: progress)
                    }
                }
                .frame(height: 10)

                // XP label
                HStack {
                    if isMaxed {
                        Text("\(totalXP) XP")
                            .font(.system(size: 11, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundStyle(Color.dsTertiaryContainer)
                    } else {
                        Text("\(xpInStage) / \(xpNeeded) XP")
                            .font(.system(size: 11, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundStyle(Color.dsOnSurfaceVariant)
                    }
                    Spacer()
                }
            }

            // Next stage indicator
            if isMaxed {
                Text("LEGEND")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(Color.dsTertiaryContainer)
            } else {
                HStack(spacing: 2) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10, weight: .bold))
                    Text(nextStageLabel)
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                }
                .foregroundStyle(Color.dsAccentOrange)
            }
        }
        .padding(Spacing.lg)
        .background(Color.dsSurfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .ghostBorder()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Experience progress")
        .accessibilityValue(accessibilityDescription)
    }

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
