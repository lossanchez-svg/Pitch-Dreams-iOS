import SwiftUI

struct StreakMilestoneModal: View {
    let milestone: Int
    let freezeAwarded: Bool
    var childId: String = ""
    let onDismiss: () -> Void

    @State private var flameScale: CGFloat = 0
    @State private var showCelebration = false
    @State private var xpBonus: Int = 0
    @StateObject private var coachVoice = CoachVoice()

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            // Flame animation
            Text("🔥")
                .font(.system(size: 72))
                .scaleEffect(flameScale)
                .onAppear {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                        flameScale = 1.2
                    }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.5)) {
                        flameScale = 1.0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        showCelebration = true
                    }
                }

            // Big number
            Text("\(milestone)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(Color.dsAccentOrange)

            Text("Day Streak!")
                .font(.title.bold())
                .accessibilityLabel("\(milestone) day streak reached!")

            if freezeAwarded {
                HStack(spacing: 8) {
                    Image(systemName: "shield.fill")
                        .foregroundStyle(Color.dsSecondary)
                    Text("You earned a streak freeze!")
                        .font(.subheadline.weight(.medium))
                }
                .padding()
                .background(Color.dsSecondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if xpBonus > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(Color.dsAccentOrange)
                    Text("+\(xpBonus) Bonus XP!")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.dsAccentOrange)
                }
                .padding()
                .background(Color.dsAccentOrange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Spacer()

            Button {
                onDismiss()
            } label: {
                Text("Keep Going!")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DSGradient.orangeAccent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .celebration(isPresented: $showCelebration)
        .task {
            guard !childId.isEmpty else { return }
            // Award streak bonus XP
            let bonus = XPCalculator.xpForStreakMilestone(milestone)
            let xpStore = XPStore()
            let _ = await xpStore.addXP(bonus, childId: childId)
            await xpStore.recordXPEntry(
                XPEntry(amount: bonus, source: "streak_bonus", date: Date()),
                childId: childId
            )
            xpBonus = bonus
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            ReviewPromptManager.noteStreakMilestone(milestone)

            // Coach voice celebrates the milestone, tuned to the active
            // personality. Runs after haptic so the two land together.
            let personality = CoachPersonality.saved(forChildId: childId)
            coachVoice.speak(personality.streakMilestoneLine(milestone), personality: personality.rawValue)
        }
    }
}

#Preview {
    StreakMilestoneModal(milestone: 30, freezeAwarded: true, childId: "preview") { }
}
