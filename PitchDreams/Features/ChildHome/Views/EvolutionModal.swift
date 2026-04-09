import SwiftUI

/// Shown when a child's avatar evolves into a new stage (Rookie → Pro → Legend).
struct EvolutionModal: View {
    let avatar: Avatar
    let newStage: AvatarStage
    let onDismiss: () -> Void

    @State private var avatarScale: CGFloat = 0
    @State private var showCelebration = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Evolved!")
                .font(.title.weight(.heavy))
                .foregroundStyle(.orange)
                .textCase(.uppercase)

            Image(avatar.assetName(stage: newStage))
                .resizable()
                .scaledToFit()
                .frame(width: 240, height: 240)
                .scaleEffect(avatarScale)
                .shadow(color: .orange.opacity(0.4), radius: 24)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                        avatarScale = 1.1
                    }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.6)) {
                        avatarScale = 1.0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showCelebration = true
                    }
                }

            VStack(spacing: 6) {
                Text("\(avatar.displayName) — \(newStage.title)")
                    .font(.title2.bold())
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            Button {
                onDismiss()
            } label: {
                Text("Let's go!")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.orange.gradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .celebration(isPresented: $showCelebration)
    }

    private var subtitle: String {
        switch newStage {
        case .rookie:
            return "Welcome to the pitch."
        case .pro:
            return "You hit a 7-day streak. Your \(avatar.displayName.lowercased()) is leveling up."
        case .legend:
            return "30-day streak. You've reached the final form."
        }
    }
}

#Preview {
    EvolutionModal(avatar: .wolf, newStage: .legend) { }
}
