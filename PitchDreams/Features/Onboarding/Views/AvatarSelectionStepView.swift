import SwiftUI

/// Dedicated full-screen "Choose Your Legend" avatar selection during onboarding.
/// Matches the Stitch onboarding_choose_avatar_1 mockup.
struct AvatarSelectionStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var selectedIndex: Int = 0

    private let avatarOptions: [Avatar] = [.wolf, .lion, .eagle, .fox, .shark, .panther, .bear, .default]

    private var selectedAvatar: Avatar {
        avatarOptions[selectedIndex]
    }

    // Cosmetic stat flavor per avatar (not from API)
    private var avatarStats: (speed: Int, agility: Int, stamina: Int) {
        switch selectedAvatar {
        case .wolf:    return (88, 92, 60)
        case .lion:    return (75, 70, 95)
        case .eagle:   return (94, 85, 55)
        case .fox:     return (90, 96, 50)
        case .shark:   return (82, 78, 88)
        case .panther: return (91, 93, 65)
        case .bear:    return (60, 55, 98)
        case .default: return (70, 70, 70)
        }
    }

    var body: some View {
        ZStack {
            Color.dsBackground
                .ignoresSafeArea()

            // Atmospheric glow
            RadialGradient(
                colors: [avatarGlowColor.opacity(0.15), .clear],
                center: .init(x: 0.5, y: 0.3),
                startRadius: 10,
                endRadius: 300
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 8) {
                        Text("PHASE 01: IDENTIFICATION")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(3)
                            .foregroundStyle(Color.dsSecondary)

                        Text("CHOOSE YOUR\nROOKIE")
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.dsOnSurface)
                    }
                    .padding(.top, 8)

                    // Hero avatar with level badge
                    ZStack(alignment: .bottom) {
                        // Glow backdrop
                        RadialGradient(
                            colors: [avatarGlowColor.opacity(0.2), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 180
                        )
                        .frame(width: 320, height: 320)

                        // Avatar image
                        heroAvatar
                            .frame(width: 280, height: 280)

                        // Level badge
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.dsSecondary)
                                .frame(width: 8, height: 8)
                            Text("LVL. 01 \(selectedAvatar.displayName.uppercased())")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1)
                                .foregroundStyle(Color.dsOnSurface)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.dsSurfaceContainerHighest.opacity(0.9))
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .offset(y: -10)
                    }
                    .padding(.top, 12)

                    // Thumbnail row
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(avatarOptions.enumerated()), id: \.offset) { index, avatar in
                                Button {
                                    withAnimation(.dsSnappy) {
                                        selectedIndex = index
                                    }
                                } label: {
                                    avatarThumbnail(avatar, isSelected: index == selectedIndex)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, Spacing.xl)
                    }
                    .padding(.top, 20)

                    // Stats section
                    statsSection
                        .padding(.horizontal, Spacing.xl)
                        .padding(.top, 24)

                    // CTA
                    Button {
                        viewModel.avatarId = selectedAvatar.rawValue
                        viewModel.nextStep()
                    } label: {
                        HStack(spacing: 8) {
                            Text("START JOURNEY")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .tracking(2)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundStyle(Color.dsCTALabel)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(DSGradient.primaryCTA)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                        .dsPrimaryShadow()
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, 28)

                    // Disclaimer
                    Text("CHARACTER SELECTION IS FINAL FOR THIS SEASON")
                        .font(.system(size: 9, weight: .medium))
                        .tracking(1.5)
                        .foregroundStyle(Color.dsOnSurfaceVariant.opacity(0.5))
                        .padding(.top, 12)
                        .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            if let idx = avatarOptions.firstIndex(where: { $0.rawValue == viewModel.avatarId }) {
                selectedIndex = idx
            }
        }
        .onChange(of: selectedIndex) { _ in
            // Keep viewModel in sync so swiping past this step still persists the choice
            viewModel.avatarId = selectedAvatar.rawValue
        }
    }

    // MARK: - Hero Avatar

    @ViewBuilder
    private var heroAvatar: some View {
        let assetName = selectedAvatar.assetName(stage: .rookie)
        if UIImage(named: assetName) != nil {
            Image(assetName)
                .resizable()
                .scaledToFit()
                .shadow(color: avatarGlowColor.opacity(0.3), radius: 20)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.dsSurfaceContainerHigh)
                Image(systemName: "figure.soccer")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
            }
        }
    }

    // MARK: - Thumbnail

    private func avatarThumbnail(_ avatar: Avatar, isSelected: Bool) -> some View {
        let assetName = avatar.assetName(stage: .rookie)
        return ZStack {
            Circle()
                .fill(isSelected ? Color.dsSurfaceContainerHigh : Color.dsSurfaceContainerLowest)
                .frame(width: 56, height: 56)

            if UIImage(named: assetName) != nil {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                    .grayscale(isSelected ? 0 : 0.8)
                    .opacity(isSelected ? 1.0 : 0.4)
            } else {
                Image(systemName: "figure.soccer")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
            }
        }
        .overlay(
            Circle()
                .stroke(isSelected ? Color.dsSecondary : .clear, lineWidth: 2)
                .frame(width: 56, height: 56)
        )
        .shadow(color: isSelected ? Color.dsSecondary.opacity(0.3) : .clear, radius: 8)
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("\(selectedAvatar.displayName.uppercased()) STATS")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(Color.dsOnSurface)

                Spacer()

                // Tier dots
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { _ in
                        Circle()
                            .fill(Color.dsAccentOrange)
                            .frame(width: 6, height: 6)
                    }
                }
            }

            statBar(label: "SPEED", value: avatarStats.speed)
            statBar(label: "AGILITY", value: avatarStats.agility)
            statBar(label: "STAMINA", value: avatarStats.stamina)
        }
        .padding(Spacing.xl)
        .background(Color.dsSurfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .ghostBorder()
    }

    private func statBar(label: String, value: Int) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .tracking(1)
                .foregroundStyle(Color.dsOnSurfaceVariant)
                .frame(width: 70, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.dsSurfaceContainerHighest)
                        .frame(height: 8)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.dsSecondary, Color.dsSecondaryContainer],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(value) / 100.0, height: 8)
                        .shadow(color: Color.dsSecondary.opacity(0.4), radius: 4)
                }
            }
            .frame(height: 8)

            Text("\(value)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Color.dsSecondary)
                .frame(width: 28, alignment: .trailing)
        }
    }

    // MARK: - Glow Color

    private var avatarGlowColor: Color {
        switch selectedAvatar {
        case .panther: return Color(hex: "#8B5CF6")
        case .wolf: return Color.dsSecondary
        case .lion: return Color.dsAccentOrange
        case .eagle: return Color.dsSecondary
        case .fox: return Color.dsAccentOrange
        case .shark: return Color.dsSecondary
        case .bear: return Color.dsTertiaryContainer
        case .default: return Color.dsSecondary
        }
    }
}

#Preview {
    AvatarSelectionStepView(viewModel: OnboardingViewModel(authManager: AuthManager()))
}
