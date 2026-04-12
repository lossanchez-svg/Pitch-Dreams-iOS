import SwiftUI

/// Celebration modal shown when a weekly mission is completed.
/// Mirrors `EvolutionModal.swift` (confetti via `.celebration` modifier + spring-in icon).
struct MissionCompleteModal: View {
    let mission: Mission
    let onDismiss: () -> Void

    @State private var iconScale: CGFloat = 0
    @State private var showCelebration = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Mission Complete!")
                .font(.title.weight(.heavy))
                .foregroundStyle(Color.dsAccentOrange)
                .textCase(.uppercase)

            Image(systemName: mission.iconSystemName)
                .font(.system(size: 120, weight: .bold))
                .foregroundStyle(Color.dsAccentOrange)
                .frame(width: 200, height: 200)
                .background(Color.dsAccentOrange.opacity(0.12))
                .clipShape(Circle())
                .scaleEffect(iconScale)
                .shadow(color: Color.dsAccentOrange.opacity(0.4), radius: 24)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                        iconScale = 1.1
                    }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.6)) {
                        iconScale = 1.0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showCelebration = true
                    }
                }

            VStack(spacing: 6) {
                Text(mission.title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                Text("+\(mission.xpReward) XP")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.dsAccentOrange)
            }
            .padding(.horizontal, 32)

            Spacer()

            Button {
                onDismiss()
            } label: {
                Text("Nice!")
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
    }
}

#Preview {
    MissionCompleteModal(
        mission: MissionRegistry.all[0],
        onDismiss: {}
    )
}
