import SwiftUI

/// The shareable weekly recap card (390x520pt, Instagram Stories format).
struct WeeklyRecapCardView: View {
    let recap: WeeklyRecap

    /// Rotating gradient presets that change weekly.
    private var gradientColors: [Color] {
        let week = Calendar.current.component(.weekOfYear, from: recap.weekStarting)
        let presets: [[Color]] = [
            [Color(hex: "#1A1A2E"), Color(hex: "#16213E"), Color(hex: "#0F3460")],
            [Color(hex: "#0D0221"), Color(hex: "#0D1B2A"), Color(hex: "#1B2838")],
            [Color(hex: "#1A0A2E"), Color(hex: "#2D1B69"), Color(hex: "#11001C")],
            [Color(hex: "#071E22"), Color(hex: "#1D3B43"), Color(hex: "#0B3D3F")],
            [Color(hex: "#2C0735"), Color(hex: "#190019"), Color(hex: "#0D0015")],
        ]
        return presets[week % presets.count]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "soccerball")
                        .font(.system(size: 10))
                    Text("WEEKLY RECAP")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(2)
                }
                .foregroundStyle(Color.dsSecondary)

                Text(recap.weekLabel)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
            }
            .padding(.top, 28)

            // Avatar
            avatarSection
                .padding(.top, 16)

            // Big session count
            VStack(spacing: 2) {
                Text("\(recap.sessionsCompleted)")
                    .font(DSFont.display(56))
                    .foregroundStyle(Color.dsOnSurface)
                    .contentTransition(.numericText())

                Text("SESSIONS")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color.dsOnSurfaceVariant)
            }
            .padding(.top, 8)

            // Three stat pills
            HStack(spacing: 12) {
                statPill(value: recap.formattedMinutes, label: "TIME", icon: "clock.fill")
                statPill(value: "\(recap.currentStreak)", label: "STREAK", icon: "flame.fill")
                statPill(value: "+\(recap.xpEarned)", label: "XP", icon: "bolt.fill")
            }
            .padding(.top, 20)

            // 7-day dots
            weekdayDots
                .padding(.top, 20)

            Spacer()

            // Watermark
            Text("PitchDreams")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.25))
                .padding(.bottom, 20)
        }
        .frame(width: 390, height: 520)
        .background(
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xxl))
    }

    // MARK: - Avatar
    // Matches `proposals/Stitch/weekly_recap_card.png` — avatar inside a
    // gold ring with stage name pill nested at the bottom edge. The ring
    // color shifts with avatar stage (gold at Legend, cyan at Pro, subtle
    // at Rookie).

    private var avatarRingColor: Color {
        switch recap.avatarStage {
        case .rookie: return Color.dsTertiaryContainer.opacity(0.5)
        case .pro:    return Color.dsSecondary
        case .legend: return Color.dsTertiary
        }
    }

    @ViewBuilder
    private var avatarSection: some View {
        let assetName = Avatar.assetName(for: recap.avatarId, totalXP: recap.totalXP)
        VStack(spacing: -12) {
            ZStack {
                Circle()
                    .stroke(avatarRingColor, lineWidth: 2)
                    .frame(width: 106, height: 106)
                Circle()
                    .fill(Color.dsAccentOrange.opacity(0.25))
                    .frame(width: 120, height: 120)
                    .blur(radius: 18)

                if UIImage(named: assetName) != nil {
                    Image(assetName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 98, height: 98)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "figure.soccer")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.dsSecondary.opacity(0.4))
                        .frame(width: 98, height: 98)
                        .background(Color.dsSurfaceContainerLow)
                        .clipShape(Circle())
                }
            }
            .zIndex(1)

            Text(recap.avatarStage.title.uppercased())
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color(hex: "#2A1A08"))
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color.dsTertiaryContainer)
                .clipShape(Capsule())
                .shadow(color: Color.dsTertiaryContainer.opacity(0.3), radius: 6)
        }
    }

    // MARK: - Stat Pill

    private func statPill(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(Color.dsAccentOrange)
            Text(value)
                .font(.system(size: 16, weight: .heavy, design: .rounded).monospacedDigit())
                .foregroundStyle(Color.dsOnSurface)
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .tracking(1)
                .foregroundStyle(Color.dsOnSurfaceVariant)
        }
        .frame(width: 90, height: 70)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }

    // MARK: - Weekday Dots

    private var weekdayDots: some View {
        let days = ["M", "T", "W", "T", "F", "S", "S"]
        let activity = recap.weekdayActivity
        return HStack(spacing: 14) {
            ForEach(0..<7, id: \.self) { i in
                VStack(spacing: 4) {
                    Circle()
                        .fill(activity[i] ? Color.dsAccentOrange : Color.dsSurfaceContainerHighest)
                        .frame(width: 10, height: 10)
                    Text(days[i])
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                }
            }
        }
    }
}

#Preview {
    WeeklyRecapCardView(recap: WeeklyRecap(
        weekStarting: Date().addingTimeInterval(-7 * 86400),
        sessionsCompleted: 5,
        totalMinutes: 150,
        currentStreak: 12,
        xpEarned: 340,
        totalXP: 820,
        avatarId: "wolf",
        bestDrill: nil,
        personalBests: 2,
        improvementStat: nil
    ))
    .padding()
    .background(Color.dsBackground)
}
