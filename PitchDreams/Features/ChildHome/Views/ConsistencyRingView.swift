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

    private var flameEmoji: String {
        if streak == 0 { return "💤" }
        if streak < 7 { return "✨" }
        if streak < 14 { return "🔥" }
        return "🔥"
    }

    private var ringColor: Color {
        if streak == 0 { return .gray }
        if streak < 7 { return .orange }
        if streak < 14 { return .orange }
        return .green
    }

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(ringColor.opacity(0.2), lineWidth: 10)
                    .frame(width: 120, height: 120)

                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        ringColor,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: progress)

                // Center content
                VStack(spacing: 2) {
                    Text(flameEmoji)
                        .font(.system(size: 28))
                    Text("\(streak)")
                        .font(.title2.bold())
                        .foregroundStyle(ringColor)
                        .contentTransition(.numericText())
                }
            }

            // Stats row
            HStack(spacing: 24) {
                statItem(label: "Target", value: "\(maxStreak)", icon: "target")
                statItem(label: "Progress", value: "\(progressPercent)%", icon: "chart.bar.fill")
                statItem(label: "Freezes", value: "\(freezes)", icon: "shield.fill")
            }

            // Message
            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func statItem(label: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
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
}
