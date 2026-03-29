import SwiftUI

struct ChildProfileStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    private let positions = ["Forward", "Midfielder", "Defender", "Goalkeeper", "Just playing for fun"]
    private let goalOptions = [
        "Improve dribbling", "Get faster", "Learn the game",
        "Make the team", "Better passing", "Have fun"
    ]
    private let avatarIds = ["default", "lion", "eagle", "wolf", "fox", "shark", "panther", "bear"]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Nickname
                VStack(alignment: .leading, spacing: 6) {
                    Text("Nickname")
                        .font(.subheadline.weight(.medium))
                    TextField("Player name (1-20 characters)", text: $viewModel.nickname)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                    if viewModel.nickname.count > 20 {
                        Text("Max 20 characters")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                // Age
                VStack(alignment: .leading, spacing: 6) {
                    Text("Age")
                        .font(.subheadline.weight(.medium))
                    Picker("Age", selection: $viewModel.age) {
                        ForEach(8...18, id: \.self) { age in
                            Text("\(age) years old").tag(age)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                }

                // Position
                VStack(alignment: .leading, spacing: 6) {
                    Text("Position")
                        .font(.subheadline.weight(.medium))
                    Picker("Position", selection: $viewModel.position) {
                        ForEach(positions, id: \.self) { pos in
                            Text(pos).tag(pos)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                }

                // Goals
                VStack(alignment: .leading, spacing: 8) {
                    Text("Goals")
                        .font(.subheadline.weight(.medium))
                    Text("Select what your player wants to work on")
                        .font(.caption)
                        .foregroundStyle(.secondary)

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
                                    .font(.subheadline)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(isSelected ? Color.accentColor.opacity(0.15) : Color(.secondarySystemBackground))
                                    .foregroundColor(isSelected ? .accentColor : .primary)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Avatar
                VStack(alignment: .leading, spacing: 8) {
                    Text("Avatar")
                        .font(.subheadline.weight(.medium))
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(avatarIds, id: \.self) { aid in
                                let isSelected = viewModel.avatarId == aid
                                Button {
                                    viewModel.avatarId = aid
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: avatarIcon(aid))
                                            .font(.title)
                                            .frame(width: 52, height: 52)
                                            .background(isSelected ? Color.accentColor.opacity(0.15) : Color(.secondarySystemBackground))
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle().stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                                            )
                                        Text(aid.capitalized)
                                            .font(.caption2)
                                            .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                // Next button
                Button {
                    Task { await viewModel.createChild() }
                } label: {
                    Text("Next")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isChildProfileValid ? Color.accentColor : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .font(.headline)
                        .cornerRadius(12)
                }
                .disabled(!viewModel.isChildProfileValid || viewModel.isLoading)

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
    }

    private func avatarIcon(_ id: String) -> String {
        switch id {
        case "lion": return "crown.fill"
        case "eagle": return "bird.fill"
        case "wolf": return "pawprint.fill"
        case "fox": return "hare.fill"
        case "shark": return "fish.fill"
        case "panther": return "cat.fill"
        case "bear": return "bear.fill"
        default: return "person.crop.circle.fill"
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
