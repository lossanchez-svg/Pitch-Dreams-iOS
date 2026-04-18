import SwiftUI

/// Shown when a child's avatar evolves into a new stage (Rookie -> Pro -> Legend).
/// Matches `proposals/Stitch/evolution_celebration_enhanced.png` — a centered
/// vertical-spine timeline where the current stage is emphasized with a cyan
/// ring + glow + "CURRENT STAGE" chip, while surrounding stages render as
/// small circular tokens (dim + locked if not yet reached).
struct EvolutionModal: View {
    let avatar: Avatar
    let newStage: AvatarStage
    var totalXP: Int = 0
    let onDismiss: () -> Void

    @State private var avatarScale: CGFloat = 0
    @State private var glowPulse: Bool = false
    @State private var showCelebration = false
    @StateObject private var coachVoice = CoachVoice()

    var body: some View {
        ZStack {
            Color.dsBackground
                .ignoresSafeArea()
                .accessibilityHidden(true)

            ScrollView {
                VStack(spacing: 0) {
                    header
                        .padding(.top, 24)

                    // Vertical timeline, centered spine
                    VStack(spacing: 0) {
                        ForEach(AvatarStage.allCases, id: \.rawValue) { stage in
                            stageNode(stage)
                            if stage != .legend {
                                spineConnector(
                                    from: stage,
                                    to: AvatarStage(rawValue: stage.rawValue + 1) ?? .legend
                                )
                            }
                        }
                    }
                    .padding(.top, 28)
                    .padding(.horizontal, 24)

                    beginCTA
                        .padding(.horizontal, 24)
                        .padding(.top, 32)
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
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true).delay(0.4)) {
                glowPulse = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showCelebration = true
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                ReviewPromptManager.noteAvatarEvolution(to: newStage)
                let personality = CoachPersonality.current
                coachVoice.speak(personality.avatarEvolutionLine(to: newStage), personality: personality.rawValue)
            }
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                Text("EVOLUTION PROTOCOL")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(3)
            }
            .foregroundStyle(Color.dsSecondary)

            Text("Your Evolution\nPath")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.dsOnSurface)

            if totalXP > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text("YOU'VE EARNED \(totalXP) XP!")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .tracking(1)
                }
                .foregroundStyle(Color.dsCTALabel)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(DSGradient.primaryCTA)
                )
                .dsPrimaryShadow()
                .padding(.top, 4)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Stage Node

    @ViewBuilder
    private func stageNode(_ stage: AvatarStage) -> some View {
        let isCurrent = stage == newStage
        let isUnlocked = stage.rawValue <= newStage.rawValue

        if isCurrent {
            currentStageCard(stage)
        } else {
            compactStageToken(stage, isUnlocked: isUnlocked)
        }
    }

    // MARK: - Compact (non-current) token

    @ViewBuilder
    private func compactStageToken(_ stage: AvatarStage, isUnlocked: Bool) -> some View {
        let assetName = avatar.assetName(stage: stage)
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.dsSurfaceContainerLow)
                    .frame(width: 72, height: 72)
                Circle()
                    .stroke(
                        isUnlocked ? Color.dsSecondary.opacity(0.5) : Color.white.opacity(0.08),
                        lineWidth: 1.5
                    )
                    .frame(width: 72, height: 72)

                if UIImage(named: assetName) != nil {
                    Image(assetName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 64)
                        .clipShape(Circle())
                        .grayscale(isUnlocked ? 0 : 0.85)
                        .opacity(isUnlocked ? 0.85 : 0.35)
                } else {
                    Image(systemName: isUnlocked ? "figure.soccer" : "lock.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.dsOnSurfaceVariant.opacity(0.5))
                }

                if isUnlocked {
                    // Small cyan check badge bottom-right
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.dsSecondary)
                        .background(Circle().fill(Color.dsBackground))
                        .offset(x: 24, y: 24)
                }
            }

            Text(stage.title.uppercased())
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color.dsOnSurfaceVariant.opacity(isUnlocked ? 0.9 : 0.5))
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(stage.title) stage, \(isUnlocked ? "complete" : "locked")")
    }

    // MARK: - Current stage hero card

    @ViewBuilder
    private func currentStageCard(_ stage: AvatarStage) -> some View {
        let assetName = avatar.assetName(stage: stage)
        let level = max(1, totalXP / 100)

        VStack(spacing: 14) {
            // CURRENT STAGE chip
            Text("CURRENT STAGE")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color.dsCTALabel)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.dsSecondary)
                )
                .shadow(color: Color.dsSecondary.opacity(0.4), radius: 8)

            // Avatar with cyan ring + glow
            ZStack {
                Circle()
                    .fill(Color.dsSecondary.opacity(glowPulse ? 0.22 : 0.10))
                    .frame(width: 180, height: 180)
                    .blur(radius: 20)

                Circle()
                    .stroke(Color.dsSecondary, lineWidth: 2)
                    .frame(width: 150, height: 150)

                if UIImage(named: assetName) != nil {
                    Image(assetName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 140, height: 140)
                        .clipShape(Circle())
                        .scaleEffect(avatarScale)
                } else {
                    Image(systemName: "figure.soccer")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.dsSecondary)
                        .frame(width: 140, height: 140)
                        .background(Color.dsSurfaceContainerHigh)
                        .clipShape(Circle())
                        .scaleEffect(avatarScale)
                }

                // Sparkle badge bottom-right
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.dsCTALabel)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.dsSecondary))
                    .shadow(color: Color.dsSecondary.opacity(0.5), radius: 6)
                    .offset(x: 54, y: 54)
            }
            .padding(.top, 4)

            // Stage + avatar name combined
            Text("\(stage.title.uppercased()) \(avatar.displayName.uppercased())")
                .font(.system(size: 24, weight: .heavy, design: .rounded).italic())
                .foregroundStyle(Color.dsOnSurface)

            // Level unlocked row
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.dsSecondary)
                Text("LEVEL \(level) UNLOCKED")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color.dsSecondary)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .fill(Color.dsSurfaceContainerLow)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .stroke(Color.dsSecondary.opacity(0.55), lineWidth: 1.5)
        )
        .shadow(color: Color.dsSecondary.opacity(0.2), radius: 20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Current stage \(stage.title) \(avatar.displayName). Level \(level) unlocked.")
    }

    // MARK: - Spine connector between stages

    @ViewBuilder
    private func spineConnector(from: AvatarStage, to: AvatarStage) -> some View {
        let fromUnlocked = from.rawValue <= newStage.rawValue
        let toUnlocked = to.rawValue <= newStage.rawValue
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        fromUnlocked ? Color.dsSecondary.opacity(0.6) : Color.white.opacity(0.08),
                        toUnlocked ? Color.dsSecondary.opacity(0.6) : Color.white.opacity(0.08)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 2, height: 28)
            .frame(maxWidth: .infinity)
    }

    // MARK: - CTA

    @ViewBuilder
    private var beginCTA: some View {
        Button {
            onDismiss()
        } label: {
            HStack(spacing: 10) {
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
    }
}

#Preview("Pro (current)") {
    EvolutionModal(avatar: .wolf, newStage: .pro, totalXP: 1200) { }
}

#Preview("Legend (current)") {
    EvolutionModal(avatar: .lion, newStage: .legend, totalXP: 3200) { }
}

#Preview("Rookie (current)") {
    EvolutionModal(avatar: .fox, newStage: .rookie, totalXP: 120) { }
}
