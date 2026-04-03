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
        if streak == 0 { return "\u{1F4A4}" }  // zzz
        if streak < 7 { return "\u{2728}" }     // sparkles
        return "\u{1F525}"                       // fire
    }

    private var ringColor: Color {
        if streak == 0 { return .gray }
        if streak < 14 { return .orange }
        return .green
    }

    var body: some View {
        HStack(spacing: 20) {
            // Ring on the left
            ZStack {
                Circle()
                    .stroke(ringColor.opacity(0.15), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        ringColor,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: progress)

                VStack(spacing: 2) {
                    Text(flameEmoji)
                        .font(.system(size: 22))
                    Text("\(streak)")
                        .font(.title3.bold().monospacedDigit())
                        .foregroundStyle(ringColor)
                        .contentTransition(.numericText())
                }
            }
            .frame(width: 100, height: 100)

            // Stats stacked on the right
            VStack(alignment: .leading, spacing: 10) {
                // Message at top
                Text(message)
                    .font(.headline)
                    .foregroundStyle(.primary)

                // Stats grid
                HStack(spacing: 16) {
                    statItem(label: "Target", value: "\(maxStreak)", icon: "target")
                    statItem(label: "Progress", value: "\(progressPercent)%", icon: "chart.bar.fill")
                    statItem(label: "Freezes", value: "\(freezes)", icon: "shield.fill")
                }
            }

            Spacer(minLength: 0)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func statItem(label: String, value: String, icon: String) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.bold().monospacedDigit())
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
