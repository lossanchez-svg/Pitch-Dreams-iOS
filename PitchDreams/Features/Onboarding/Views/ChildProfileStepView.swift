import SwiftUI

struct ChildProfileStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    private let positions = ["Forward", "Midfielder", "Defender", "Goalkeeper", "Just playing for fun"]
    private let goalOptions = [
        "Improve dribbling", "Get faster", "Learn the game",
        "Make the team", "Better passing", "Have fun"
    ]
    private let avatarOptions: [Avatar] = [.wolf, .lion, .eagle, .fox, .shark, .panther, .bear, .default]

    @State private var selectedAvatarIndex: Int = 0

    private var selectedAvatar: Avatar {
        avatarOptions[selectedAvatarIndex]
    }

    var body: some View {
        ZStack {
            Color.dsBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 4) {
                        Text("SELECT STRIKER")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(3)
                            .foregroundStyle(Color.dsSecondary)

                        Text("PICK YOUR\nPLAYER")
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.dsOnSurface)

                        Text("You'll evolve together")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.dsOnSurfaceVariant)
                            .padding(.top, 4)
                    }
                    .padding(.top, 16)

                    // Avatar Carousel
                    avatarCarousel
                        .padding(.top, 24)

                    // Character name
                    Text(selectedAvatar.displayName.uppercased())
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .italic()
                        .tracking(-1)
                        .foregroundStyle(Color.dsPrimaryPeach)
                        .padding(.top, 16)

                    Text(avatarTagline(selectedAvatar))
                        .font(.system(size: 12, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                        .textCase(.uppercase)

                    // Evolution preview strip
                    evolutionStages
                        .padding(.top, 20)

                    // Form fields
                    formFields
                        .padding(.top, 32)
                        .padding(.horizontal, 24)

                    // CTA
                    Button {
                        viewModel.avatarId = selectedAvatar.rawValue
                        Task { await viewModel.createChild() }
                    } label: {
                        Text("CHOOSE \(selectedAvatar.displayName.uppercased())")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .tracking(2)
                            .foregroundStyle(Color(hex: "#5B1B00"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(DSGradient.primaryCTA)
                            .clipShape(Capsule())
                            .dsPrimaryShadow()
                    }
                    .disabled(!viewModel.isChildProfileValid || viewModel.isLoading)
                    .opacity(viewModel.isChildProfileValid ? 1 : 0.5)
                    .padding(.horizontal, 24)
                    .padding(.top, 32)

                    Spacer(minLength: 60)
                }
            }
        }
        .onAppear {
            // Sync initial selection
            if let idx = avatarOptions.firstIndex(where: { $0.rawValue == viewModel.avatarId }) {
                selectedAvatarIndex = idx
            }
            viewModel.avatarId = selectedAvatar.rawValue
        }
        .onChange(of: selectedAvatarIndex) { _ in
            viewModel.avatarId = selectedAvatar.rawValue
        }
    }

    // MARK: - Avatar Carousel

    private var avatarCarousel: some View {
        TabView(selection: $selectedAvatarIndex) {
            ForEach(Array(avatarOptions.enumerated()), id: \.offset) { index, avatar in
                VStack {
                    // Glowing platform
                    ZStack {
                        // Platform glow
                        Ellipse()
                            .fill(
                                RadialGradient(
                                    colors: [avatarGlowColor(avatar).opacity(0.3), .clear],
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: 120
                                )
                            )
                            .frame(width: 260, height: 80)
                            .offset(y: 100)

                        // Avatar image
                        let assetName = avatar.assetName(stage: .rookie)
                        if UIImage(named: assetName) != nil {
                            Image(assetName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 220, height: 220)
                                .shadow(color: avatarGlowColor(avatar).opacity(0.3), radius: 20)
                        } else {
                            ZStack {
                                Circle()
                                    .fill(Color.dsSurfaceContainerHigh)
                                    .frame(width: 180, height: 180)
                                Image(systemName: "figure.soccer")
                                    .font(.system(size: 60))
                                    .foregroundStyle(Color.dsSecondary)
                            }
                        }
                    }
                    .frame(height: 260)
                }
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 280)

        // Page indicator
    }

    // MARK: - Evolution Stages Preview

    private var evolutionStages: some View {
        HStack(spacing: 0) {
            ForEach(AvatarStage.allCases, id: \.rawValue) { stage in
                if stage != .rookie {
                    // Connecting line
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.dsSecondary.opacity(0.3), Color.dsSecondary.opacity(0.1)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 2)
                        .frame(maxWidth: 40)
                }

                VStack(spacing: 6) {
                    let assetName = selectedAvatar.assetName(stage: stage)
                    ZStack {
                        Circle()
                            .fill(Color.dsSurfaceContainerHigh)
                            .frame(width: 52, height: 52)

                        if UIImage(named: assetName) != nil {
                            Image(assetName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 44, height: 44)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.dsOnSurfaceVariant.opacity(0.4))
                        }
                    }
                    .overlay(
                        Circle()
                            .stroke(
                                stage == .rookie ? Color.dsSecondary : Color.dsSurfaceContainerHighest,
                                lineWidth: 2
                            )
                    )

                    Text(stage.title.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(stage == .rookie ? Color.dsSecondary : Color.dsOnSurfaceVariant)
                }
            }
        }
    }

    // MARK: - Form Fields

    private var formFields: some View {
        VStack(spacing: 20) {
            // Nickname
            VStack(alignment: .leading, spacing: 8) {
                Text("NICKNAME")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(Color.dsOnSurfaceVariant)

                TextField("Player name", text: $viewModel.nickname)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color.dsSurfaceContainerHighest)
                    .foregroundStyle(Color.dsOnSurface)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))

                if viewModel.nickname.count > 20 {
                    Text("Max 20 characters")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            // Age
            VStack(alignment: .leading, spacing: 8) {
                Text("AGE")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(Color.dsOnSurfaceVariant)

                Picker("Age", selection: $viewModel.age) {
                    ForEach(8...18, id: \.self) { age in
                        Text("\(age) years old").tag(age)
                    }
                }
                .pickerStyle(.menu)
                .tint(Color.dsSecondary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.dsSurfaceContainerHighest)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            }

            // Position
            VStack(alignment: .leading, spacing: 8) {
                Text("POSITION")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(Color.dsOnSurfaceVariant)

                Picker("Position", selection: $viewModel.position) {
                    ForEach(positions, id: \.self) { pos in
                        Text(pos).tag(pos)
                    }
                }
                .pickerStyle(.menu)
                .tint(Color.dsSecondary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.dsSurfaceContainerHighest)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            }

            // Goals
            VStack(alignment: .leading, spacing: 8) {
                Text("GOALS")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(Color.dsOnSurfaceVariant)

                Text("Select what your player wants to work on")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.dsOnSurfaceVariant)

                FlowLayout(spacing: 8) {
                    ForEach(goalOptions, id: \.self) { goal in
                        let isSelected = viewModel.selectedGoals.contains(goal)
                        Button {
                            if isSelected {
                                viewModel.selectedGoals.remove(goal)
                            } else {
                                viewModel.selectedGoals.insert(goal)
                            }
                        } label: {
                            Text(goal)
                                .font(.system(size: 14, weight: .medium))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(isSelected ? Color.dsSecondary.opacity(0.15) : Color.dsSurfaceContainerHighest)
                                .foregroundColor(isSelected ? Color.dsSecondary : Color.dsOnSurface)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().stroke(isSelected ? Color.dsSecondary : Color.clear, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func avatarGlowColor(_ avatar: Avatar) -> Color {
        switch avatar {
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

    private func avatarTagline(_ avatar: Avatar) -> String {
        switch avatar {
        case .wolf: return "The Striker. Fast. Fearless."
        case .lion: return "The Captain. Bold. Relentless."
        case .eagle: return "The Visionary. Sharp. Decisive."
        case .fox: return "The Trickster. Quick. Creative."
        case .shark: return "The Hunter. Fierce. Focused."
        case .panther: return "The Shadow. Silent. Lethal."
        case .bear: return "The Wall. Strong. Immovable."
        case .default: return "The Rookie. Ready. Determined."
        }
    }
}

// MARK: - Flow Layout (iOS 16 compatible)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, offset) in result.offsets.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + offset.x, y: bounds.minY + offset.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (offsets: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var offsets: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            offsets.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }

        return (offsets, CGSize(width: maxWidth, height: currentY + lineHeight))
    }
}
