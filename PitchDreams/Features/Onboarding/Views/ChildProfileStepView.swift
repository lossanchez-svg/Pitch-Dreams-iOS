import SwiftUI

/// Step 2 of onboarding: child profile form fields.
/// Avatar was already selected in the previous step (AvatarSelectionStepView).
struct ChildProfileStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    private let positions = ["Forward", "Midfielder", "Defender", "Goalkeeper", "Just playing for fun"]
    private let goalOptions = [
        "Improve dribbling", "Get faster", "Learn the game",
        "Make the team", "Better passing", "Have fun"
    ]

    private var selectedAvatar: Avatar {
        Avatar.resolve(viewModel.avatarId)
    }

    var body: some View {
        ZStack {
            Color.dsBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Selected avatar preview (read-only)
                    avatarPreview
                        .padding(.top, 8)

                    // Form fields
                    formFields

                    // CTA
                    Button {
                        Task { await viewModel.createChild() }
                    } label: {
                        HStack(spacing: 8) {
                            if viewModel.isLoading {
                                ProgressView().tint(Color.dsCTALabel)
                            } else {
                                Text("CREATE PLAYER")
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                                    .tracking(2)
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .bold))
                            }
                        }
                        .foregroundStyle(Color.dsCTALabel)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(viewModel.isChildProfileValid ? DSGradient.primaryCTA : LinearGradient(colors: [Color.dsSurfaceContainerHighest, Color.dsSurfaceContainerHighest], startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                        .dsPrimaryShadow()
                    }
                    .disabled(!viewModel.isChildProfileValid || viewModel.isLoading)
                    .opacity(viewModel.isChildProfileValid ? 1 : 0.5)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
        }
    }

    // MARK: - Avatar Preview

    private var avatarPreview: some View {
        HStack(spacing: 14) {
            let assetName = selectedAvatar.assetName(stage: .rookie)
            ZStack {
                Circle()
                    .fill(Color.dsSurfaceContainerHigh)
                    .frame(width: 56, height: 56)
                if UIImage(named: assetName) != nil {
                    Image(assetName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "figure.soccer")
                        .foregroundStyle(Color.dsSecondary)
                }
            }
            .overlay(Circle().stroke(Color.dsSecondary, lineWidth: 2).frame(width: 56, height: 56))

            VStack(alignment: .leading, spacing: 2) {
                Text("YOUR LEGEND")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(Color.dsOnSurfaceVariant)
                Text(selectedAvatar.displayName)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.dsPrimaryPeach)
            }

            Spacer()
        }
        .padding(Spacing.lg)
        .background(Color.dsSurfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .ghostBorder()
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
                        .foregroundStyle(Color.dsError)
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
