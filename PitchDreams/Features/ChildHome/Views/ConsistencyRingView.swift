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

    var body: some View {
        HStack(spacing: 20) {
            // Ring on the left
            ZStack {
                Circle()
                    .stroke(Color.dsSurfaceContainerHighest, lineWidth: 6)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Color.dsSecondary,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: progress)

                VStack(spacing: 2) {
                    Text("\(streak)")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(Color.dsOnSurface)
                        .contentTransition(.numericText())
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.dsAccentOrange)
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
                    statItem(icon: "shield.fill", color: .dsError, value: "\(freezes)", label: "Freezes")
                }
            }

            Spacer(minLength: 0)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.dsSurfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .ghostBorder()
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
    }
    .padding()
    .background(Color.dsBackground)
}
