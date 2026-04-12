import SwiftUI

/// Shown when a child's avatar evolves into a new stage (Rookie -> Pro -> Legend).
/// Can also be navigated to directly to view the full evolution path.
struct EvolutionModal: View {
    let avatar: Avatar
    let newStage: AvatarStage
    let onDismiss: () -> Void

    @State private var avatarScale: CGFloat = 0
    @State private var showCelebration = false

    var body: some View {
        ZStack {
            Color.dsBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .foregroundStyle(Color.dsSecondary)
                            Text("EVOLUTION PROTOCOL")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(3)
                                .foregroundStyle(Color.dsSecondary)
                        }
                        .padding(.top, 24)

                        Text("Your Evolution\nPath")
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.dsOnSurface)
                    }

                    // Timeline
                    VStack(spacing: 0) {
                        ForEach(AvatarStage.allCases, id: \.rawValue) { stage in
                            evolutionStageCard(stage)
                        }
                    }
                    .padding(.top, 32)
                    .padding(.horizontal, 24)

                    // CTA
                    Button {
                        onDismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Text("BEGIN DAILY GRIND")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .tracking(2)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundStyle(Color.dsCTALabel)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(DSGradient.primaryCTA)
                        .clipShape(Capsule())
                        .dsPrimaryShadow()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 40)
                    .padding(.bottom, 60)
                }
            }
        }
        .celebration(isPresented: $showCelebration)
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
    }

    // MARK: - Stage Card

    @ViewBuilder
    private func evolutionStageCard(_ stage: AvatarStage) -> some View {
        let isCurrent = stage == newStage
        let isUnlocked = stage.rawValue <= newStage.rawValue
        let isLast = stage == .legend

        HStack(alignment: .top, spacing: 20) {
            // Timeline spine
            VStack(spacing: 0) {
                // Dot
                ZStack {
                    Circle()
                        .fill(isUnlocked ? Color.dsSecondary : Color.dsSurfaceContainerHighest)
                        .frame(width: 16, height: 16)

                    if isCurrent {
                        Circle()
                            .fill(Color.dsSecondary)
                            .frame(width: 16, height: 16)
                            .shadow(color: Color.dsSecondary.opacity(0.6), radius: 8)
                    }
                }
                .padding(.top, 20)

                // Line
                if !isLast {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    isUnlocked ? Color.dsSecondary.opacity(0.5) : Color.dsSurfaceContainerHighest,
                                    Color.dsSurfaceContainerHighest
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 2)
                }
            }
            .frame(width: 16)

            // Card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(stage.title)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(isCurrent ? Color.dsOnSurface : Color.dsOnSurfaceVariant)

                        if isCurrent {
                            Text("CURRENT STAGE")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(2)
                                .foregroundStyle(Color.dsSecondary)
                        }
                    }

                    Spacer()
                }

                // Avatar image
                let assetName = avatar.assetName(stage: stage)
                if UIImage(named: assetName) != nil {
                    Image(assetName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: isCurrent ? 160 : 100)
                        .frame(maxWidth: .infinity)
                        .scaleEffect(isCurrent ? avatarScale : 1.0)
                        .grayscale(isUnlocked ? 0 : 0.8)
                        .opacity(isUnlocked ? 1 : 0.4)
                        .blur(radius: isUnlocked ? 0 : 2)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.dsSurfaceContainerHigh)
                        .frame(height: isCurrent ? 160 : 100)
                        .overlay(
                            Image(systemName: isUnlocked ? "figure.soccer" : "lock.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(Color.dsOnSurfaceVariant.opacity(0.4))
                        )
                }

                // Requirement pills for locked stages
                if !isUnlocked {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("REQUIREMENTS")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(2)
                            .foregroundStyle(Color.dsOnSurfaceVariant)

                        requirementPill(
                            icon: "flame.fill",
                            text: "Reach Level \(stage.unlockMilestone)",
                            color: .dsAccentOrange
                        )

                        if stage == .legend {
                            requirementPill(
                                icon: "star.fill",
                                text: "Legendary (200 XP)",
                                color: .dsTertiaryContainer
                            )
                        } else {
                            requirementPill(
                                icon: "bolt.fill",
                                text: "Practice \(stage.unlockMilestone) days",
                                color: .dsSecondary
                            )
                        }
                    }
                }
            }
            .padding(20)
            .background(isCurrent ? Color.dsSurfaceContainer : Color.dsSurfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(
                        isCurrent ? Color.dsSecondary.opacity(0.2) : Color.white.opacity(0.05),
                        lineWidth: 1
                    )
            )
            .padding(.bottom, 16)
        }
    }

    private func requirementPill(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(color)
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.dsOnSurfaceVariant)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.dsSurfaceContainerHigh)
        .clipShape(Capsule())
    }
}

#Preview {
    EvolutionModal(avatar: .wolf, newStage: .pro) { }
}
