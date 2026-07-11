import SwiftUI

/// Post-match reflection — one screen, all taps, and deliberately never asks
/// about goals scored or mistakes made. What it banks is bravery: the hard
/// thing the kid tried feeds the Evidence Bank's courage line.
struct MatchReflectionView: View {
    @StateObject private var viewModel: MatchModeViewModel
    @Environment(\.dismiss) private var dismiss

    init(childId: String) {
        _viewModel = StateObject(wrappedValue: MatchModeViewModel(childId: childId))
    }

    private let effortOptions: [(value: Int, emoji: String, label: String)] = [
        (1, "\u{1F60C}", "Easy"),
        (2, "\u{1F642}", "Light"),
        (3, "\u{1F4AA}", "Solid"),
        (4, "\u{1F525}", "Hard"),
        (5, "\u{1F624}", "Everything"),
    ]

    var body: some View {
        ZStack {
            Color.dsBackground.ignoresSafeArea()

            if viewModel.reflectionSaved {
                savedState
            } else {
                form
            }
        }
        .task { await viewModel.load() }
    }

    // MARK: - Form

    private var form: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                VStack(spacing: 6) {
                    Text("AFTER THE MATCH")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .tracking(3)
                        .foregroundStyle(Color.dsTertiary)
                    Text("Forget the score.\nWhat did you try?")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.dsOnSurface)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Spacing.lg)

                // Effort
                sectionCard(title: "HOW HARD DID YOU GO?") {
                    HStack(spacing: 8) {
                        ForEach(effortOptions, id: \.value) { option in
                            let isSelected = viewModel.effortLevel == option.value
                            Button {
                                viewModel.effortLevel = option.value
                            } label: {
                                VStack(spacing: 5) {
                                    Text(option.emoji).font(.system(size: 24))
                                    Text(option.label.uppercased())
                                        .font(.system(size: 8, weight: .bold))
                                        .tracking(0.5)
                                        .foregroundStyle(isSelected ? Color.dsSecondary : Color.dsOnSurfaceVariant)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(isSelected ? Color.dsSecondary.opacity(0.15) : Color.dsSurfaceContainerHighest)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Brave thing — the courage flywheel input
                sectionCard(title: "SOMETHING BRAVE YOU TRIED") {
                    optionalChips(
                        options: MatchPresets.braveThings,
                        selection: $viewModel.braveThingTried
                    )
                }

                // Proud decision
                sectionCard(title: "A DECISION YOU'RE PROUD OF") {
                    optionalChips(
                        options: MatchPresets.proudDecisions,
                        selection: $viewModel.decisionImProudOf
                    )
                }

                Text("Tap what fits — or nothing. Trying counts even when it didn't come off.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.dsOnSurfaceVariant.opacity(0.8))

                Button {
                    Task { await viewModel.saveReflection() }
                } label: {
                    Text("BANK IT")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(Color.dsCTALabel)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(DSGradient.primaryCTA)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                        .dsPrimaryShadow()
                }
                .buttonStyle(.plain)
            }
            .padding(Spacing.xl)
        }
    }

    private func optionalChips(options: [String], selection: Binding<String?>) -> some View {
        VStack(spacing: 8) {
            ForEach(options, id: \.self) { option in
                let isSelected = selection.wrappedValue == option
                Button {
                    // Tap again to deselect — brave claims are optional.
                    selection.wrappedValue = isSelected ? nil : option
                } label: {
                    HStack {
                        Text(option)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(isSelected ? Color.dsSecondary : Color.dsOnSurface)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 15))
                                .foregroundStyle(Color.dsSecondary)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isSelected ? Color.dsSecondary.opacity(0.12) : Color.dsSurfaceContainerHighest)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .tracking(2)
                .foregroundStyle(Color.dsOnSurfaceVariant)
            content()
        }
        .padding(Spacing.lg)
        .background(Color.dsSurfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .ghostBorder()
    }

    // MARK: - Saved

    private var savedState: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            Image(systemName: "bolt.heart.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.dsTertiary)

            Text("Banked.")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.dsOnSurface)

            if viewModel.bravePlays > 0 {
                Text(viewModel.bravePlays == 1
                     ? "That's your first match with something brave banked."
                     : "That's \(viewModel.bravePlays) matches with something brave banked.")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.dsOnSurface)
                    .multilineTextAlignment(.center)
            }

            Text("It's in your Evidence Bank now — proof for the next big game.")
                .font(.system(size: 13))
                .foregroundStyle(Color.dsOnSurfaceVariant)
                .multilineTextAlignment(.center)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("DONE")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color.dsCTALabel)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(DSGradient.primaryCTA)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                    .dsPrimaryShadow()
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.xl)
    }
}

#Preview {
    MatchReflectionView(childId: "preview")
}
