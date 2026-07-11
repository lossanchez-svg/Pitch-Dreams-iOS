import SwiftUI

/// The Creativity Lab — the one room in the app where repetition scores
/// zero. Challenges reward doing things *differently*; the invention
/// challenge ends with the kid naming a move of their own.
struct CreativityLabView: View {
    @StateObject private var viewModel: CreativityViewModel
    @State private var showXPToast = false

    init(childId: String) {
        _viewModel = StateObject(wrappedValue: CreativityViewModel(childId: childId))
    }

    var body: some View {
        ZStack {
            Color.dsBackground.ignoresSafeArea()

            if let challenge = viewModel.activeChallenge {
                activeChallengeView(challenge)
            } else {
                labHome
            }
        }
        .overlay(alignment: .top) {
            XPEarnedToast(amount: viewModel.xpEarned, isPresented: $showXPToast)
                .padding(.top, 60)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.dsBackground, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Text("CREATIVITY LAB")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color.dsSecondary)
            }
        }
        .task { await viewModel.load() }
    }

    // MARK: - Lab home

    private var labHome: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                VStack(spacing: 8) {
                    Image(systemName: "paintpalette.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.dsSecondary)
                    Text("Never do the same\nrep twice.")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.dsOnSurface)
                        .multilineTextAlignment(.center)
                    Text("In here, only NEW counts. Weird is good. Invent things.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                }
                .padding(.top, Spacing.lg)

                if !viewModel.inventedMoves.isEmpty {
                    inventedMovesCard
                }

                VStack(spacing: 12) {
                    ForEach(CreativityChallengeRegistry.all) { challenge in
                        challengeCard(challenge)
                    }
                }
            }
            .padding(Spacing.xl)
            .padding(.bottom, 40)
        }
    }

    private var inventedMovesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MY INVENTED MOVES")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color.dsTertiary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.inventedMoves, id: \.self) { move in
                        HStack(spacing: 5) {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 11))
                            Text(move)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.dsTertiary.opacity(0.12))
                        .foregroundStyle(Color.dsTertiary)
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.dsSurfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .ghostBorder()
    }

    private func challengeCard(_ challenge: CreativityChallenge) -> some View {
        Button {
            viewModel.begin(challenge)
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.dsSecondary.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: challenge.icon)
                        .font(.system(size: 19))
                        .foregroundStyle(Color.dsSecondary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(challenge.title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.dsOnSurface)
                    Text("\(challenge.varietyTarget) different \(challenge.unit)")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                }

                Spacer()

                if let done = viewModel.completions[challenge.id], done > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 11))
                        Text("\u{00D7}\(done)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(Color.dsTertiaryContainer)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
            }
            .padding(Spacing.lg)
            .background(Color.dsSurfaceContainer)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            .ghostBorder()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Active challenge

    private func activeChallengeView(_ challenge: CreativityChallenge) -> some View {
        VStack(spacing: Spacing.xl) {
            VStack(spacing: 8) {
                Image(systemName: challenge.icon)
                    .font(.system(size: 36))
                    .foregroundStyle(Color.dsSecondary)
                Text(challenge.title)
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.dsOnSurface)
                    .multilineTextAlignment(.center)
                Text(challenge.prompt)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, Spacing.lg)

            Spacer()

            if viewModel.challengeComplete {
                completedContent(challenge)
            } else {
                countingContent(challenge)
            }

            Spacer()

            Button {
                viewModel.exitChallenge()
            } label: {
                Text(viewModel.challengeComplete ? "BACK TO THE LAB" : "Cancel")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
            }
            .buttonStyle(.plain)
            .padding(.bottom, Spacing.lg)
        }
        .padding(Spacing.xl)
    }

    private func countingContent(_ challenge: CreativityChallenge) -> some View {
        VStack(spacing: Spacing.xl) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(viewModel.varietyCount)")
                    .font(.system(size: 88, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.dsSecondary)
                    .contentTransition(.numericText())
                Text("/ \(challenge.varietyTarget)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
            }

            Text("different \(challenge.unit) so far")
                .font(.system(size: 14))
                .foregroundStyle(Color.dsOnSurfaceVariant)

            Button {
                withAnimation(.spring(response: 0.25)) {
                    viewModel.countNewWay()
                }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                Text("THAT WAS A NEW ONE")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(.white)
                    .frame(width: 220, height: 90)
                    .background(DSGradient.secondaryCTA)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                    .dsPrimaryShadow()
            }
            .buttonStyle(.plain)
            .disabled(viewModel.targetReached)
            .opacity(viewModel.targetReached ? 0.4 : 1)

            if viewModel.targetReached {
                Button {
                    Task {
                        await viewModel.complete()
                        if viewModel.challengeComplete { showXPToast = true }
                    }
                } label: {
                    Group {
                        if viewModel.isSaving {
                            ProgressView().tint(Color.dsCTALabel)
                        } else {
                            Text("DONE — BANK IT")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .tracking(2)
                        }
                    }
                    .foregroundStyle(Color.dsCTALabel)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(DSGradient.primaryCTA)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                    .dsPrimaryShadow()
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isSaving)
            }

            if let error = viewModel.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color.dsError)
            }
        }
    }

    @ViewBuilder
    private func completedContent(_ challenge: CreativityChallenge) -> some View {
        VStack(spacing: Spacing.xl) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)

            Text("Challenge complete!")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.dsOnSurface)

            if challenge.isInvention {
                moveNamer
            } else {
                Text("\(challenge.varietyTarget) different \(challenge.unit). Nobody else's session looked like that one.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
                    .multilineTextAlignment(.center)
            }
        }
    }

    /// Two taps, zero typing: pick a word from each row, get a move name.
    private var moveNamer: some View {
        VStack(spacing: Spacing.lg) {
            Text("Now name it. It's yours forever.")
                .font(.system(size: 14))
                .foregroundStyle(Color.dsOnSurfaceVariant)

            namePartRow(MoveNameParts.first, selection: $viewModel.namePartA)
            namePartRow(MoveNameParts.second, selection: $viewModel.namePartB)

            if let name = viewModel.proposedMoveName {
                if viewModel.inventedMoves.contains(name) {
                    Label("\u{201C}\(name)\u{201D} saved to your moves!", systemImage: "wand.and.stars")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.dsTertiary)
                } else {
                    Button {
                        Task { await viewModel.saveInventedMove() }
                    } label: {
                        Text("CLAIM \u{201C}\(name.uppercased())\u{201D}")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .tracking(1)
                            .foregroundStyle(Color.dsCTALabel)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(DSGradient.primaryCTA)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                            .dsPrimaryShadow()
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func namePartRow(_ parts: [String], selection: Binding<String?>) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(parts, id: \.self) { part in
                    let isSelected = selection.wrappedValue == part
                    Button {
                        selection.wrappedValue = part
                    } label: {
                        Text(part)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(isSelected ? Color.dsSecondary : Color.dsOnSurface)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(isSelected ? Color.dsSecondary.opacity(0.15) : Color.dsSurfaceContainerHighest)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(
                                    isSelected ? Color.dsSecondary.opacity(0.35) : .clear,
                                    lineWidth: 1
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CreativityLabView(childId: "preview")
    }
}
