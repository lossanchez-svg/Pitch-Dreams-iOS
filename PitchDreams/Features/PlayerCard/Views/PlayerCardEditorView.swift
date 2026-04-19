import SwiftUI

/// Multi-step editor for the Player Card. Matches the mockup's flow:
/// archetype pick → stat selection (4 of 6) → move loadout → card frame.
/// Live card preview updates as each step is applied.
struct PlayerCardEditorView: View {
    @ObservedObject var viewModel: PlayerCardViewModel
    let onDismiss: () -> Void

    @State private var step: EditorStep = .archetype
    @State private var draftArchetype: PlayerArchetype = .allrounder
    @State private var draftStats: [CardStat] = []
    @State private var draftLoadout: [String] = []
    @State private var draftFrame: CardFrame = .standard
    @State private var isSaving = false

    enum EditorStep: Int, CaseIterable {
        case archetype, stats, loadout, frame

        var title: String {
            switch self {
            case .archetype: return "CHOOSE ARCHETYPE"
            case .stats:     return "DISPLAY STATS (4 OF 6)"
            case .loadout:   return "SIGNATURE MOVES (UP TO 4)"
            case .frame:     return "CARD FRAME"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dsBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.xl) {
                        stepIndicator
                            .padding(.top, 8)

                        Group {
                            switch step {
                            case .archetype: archetypeStep
                            case .stats:     statsStep
                            case .loadout:   loadoutStep
                            case .frame:     frameStep
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)

                        Spacer(minLength: 40)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if step == .archetype {
                        Button("Cancel") { onDismiss() }
                            .foregroundStyle(Color.dsOnSurfaceVariant)
                    } else {
                        Button {
                            goBack()
                        } label: {
                            Image(systemName: "chevron.left")
                                .foregroundStyle(.white)
                        }
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text(step.title)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(Color.dsAccentOrange)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text("\(step.rawValue + 1)/\(EditorStep.allCases.count)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                }
            }
            .toolbarBackground(Color.dsBackground, for: .navigationBar)
            .onAppear {
                // Seed drafts from current card state so choices persist across
                // editor opens that the user dismisses and returns to.
                draftArchetype = viewModel.card.archetype
                draftStats = viewModel.card.displayedStats.isEmpty
                    ? [.speed, .touch, .vision, .workRate]
                    : viewModel.card.displayedStats
                draftLoadout = viewModel.card.moveLoadout
                draftFrame = viewModel.card.cardFrame
            }
        }
    }

    // MARK: - Step indicator

    private var stepIndicator: some View {
        HStack(spacing: 6) {
            ForEach(EditorStep.allCases, id: \.self) { s in
                Capsule()
                    .fill(s.rawValue <= step.rawValue ? Color.dsAccentOrange : Color.dsSurfaceContainerHighest)
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Step 1: Archetype

    private var archetypeStep: some View {
        VStack(spacing: Spacing.xl) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(PlayerArchetype.allCases) { archetype in
                        archetypeCard(archetype)
                            .onTapGesture {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                draftArchetype = archetype
                            }
                    }
                }
                .padding(.horizontal, 4)
            }

            nextButton(label: "NEXT", enabled: true) {
                apply { await viewModel.setArchetype(draftArchetype) }
                step = .stats
            }
        }
    }

    private func archetypeCard(_ archetype: PlayerArchetype) -> some View {
        let selected = draftArchetype == archetype
        let accent = Color(hex: archetype.accentColorHex)
        return VStack(alignment: .leading, spacing: 8) {
            Spacer()
            HStack(spacing: 8) {
                Circle().fill(accent).frame(width: 10, height: 10)
                Text(archetype.displayName.uppercased())
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(.white)
            }
            Text(archetype.tagline)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.dsOnSurfaceVariant)
                .lineLimit(2)
        }
        .padding(14)
        .frame(width: 210, height: 130, alignment: .bottomLeading)
        .background(
            LinearGradient(
                colors: [accent.opacity(0.6), accent.opacity(0.15), Color.black.opacity(0.6)],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(selected ? accent : Color.white.opacity(0.08), lineWidth: selected ? 3 : 1)
        )
        .scaleEffect(selected ? 1.04 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selected)
    }

    // MARK: - Step 2: Stats

    private var statsStep: some View {
        VStack(spacing: Spacing.xl) {
            Text("Pick 4 stats to display on the card front. Tap to toggle.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.dsOnSurfaceVariant)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(CardStat.allCases) { stat in
                    statChip(stat)
                        .onTapGesture {
                            toggleStat(stat)
                        }
                }
            }

            Text("\(draftStats.count) of \(PlayerCard.displayedStatCount) selected")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(draftStats.count == PlayerCard.displayedStatCount ? Color.dsSecondary : Color.dsOnSurfaceVariant)

            nextButton(label: "NEXT", enabled: draftStats.count == PlayerCard.displayedStatCount) {
                apply { await viewModel.setDisplayedStats(draftStats) }
                step = .loadout
            }
        }
    }

    private func statChip(_ stat: CardStat) -> some View {
        let selected = draftStats.contains(stat)
        return VStack(spacing: 6) {
            Image(systemName: stat.iconSymbol)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.dsAccentOrange)
            Text(stat.displayName)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.dsOnSurface)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 72)
        .background(selected ? Color.dsAccentOrange.opacity(0.2) : Color.dsSurfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(selected ? Color.dsAccentOrange : Color.white.opacity(0.05), lineWidth: selected ? 2 : 1)
        )
    }

    private func toggleStat(_ stat: CardStat) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if let idx = draftStats.firstIndex(of: stat) {
            draftStats.remove(at: idx)
        } else if draftStats.count < PlayerCard.displayedStatCount {
            draftStats.append(stat)
        }
    }

    // MARK: - Step 3: Move loadout

    private var loadoutStep: some View {
        VStack(spacing: Spacing.xl) {
            Text(viewModel.unlockedMoves.isEmpty
                 ? "Master a signature move to equip it on your card."
                 : "Pick up to 4 mastered moves for your loadout.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.dsOnSurfaceVariant)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if !viewModel.unlockedMoves.isEmpty {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(viewModel.unlockedMoves) { move in
                        loadoutCard(move)
                            .onTapGesture { toggleMove(move) }
                    }
                }
            }

            Text("\(draftLoadout.count) of \(PlayerCard.maxMoveLoadout) equipped")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.dsOnSurfaceVariant)

            nextButton(label: "NEXT", enabled: true) {
                apply { await viewModel.setMoveLoadout(draftLoadout) }
                step = .frame
            }
        }
    }

    private func loadoutCard(_ move: SignatureMove) -> some View {
        let selected = draftLoadout.contains(move.id)
        let accent = Color(hex: move.rarity.accentColorHex)
        return VStack(spacing: 10) {
            Image(systemName: move.iconSymbolName)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(accent)
            Text(move.name)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.dsOnSurface)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 110)
        .background(Color.dsSurfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(selected ? accent : Color.white.opacity(0.05), lineWidth: selected ? 2 : 1)
        )
    }

    private func toggleMove(_ move: SignatureMove) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if let idx = draftLoadout.firstIndex(of: move.id) {
            draftLoadout.remove(at: idx)
        } else if draftLoadout.count < PlayerCard.maxMoveLoadout {
            draftLoadout.append(move.id)
        }
    }

    // MARK: - Step 4: Frame

    private var frameStep: some View {
        VStack(spacing: Spacing.xl) {
            Text("Locked frames unlock as you progress.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.dsOnSurfaceVariant)

            VStack(spacing: 10) {
                ForEach(CardFrame.allCases) { frame in
                    frameRow(frame)
                        .onTapGesture {
                            if viewModel.unlockedFrames.contains(frame) {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                draftFrame = frame
                            }
                        }
                }
            }

            nextButton(label: "SAVE CARD", enabled: true) {
                apply { await viewModel.setFrame(draftFrame) }
                onDismiss()
            }
        }
    }

    private func frameRow(_ frame: CardFrame) -> some View {
        let unlocked = viewModel.unlockedFrames.contains(frame)
        let selected = draftFrame == frame
        return HStack(spacing: 12) {
            Text(frame.displayName.uppercased())
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .tracking(1)
                .foregroundStyle(unlocked ? Color.dsOnSurface : Color.dsOnSurfaceVariant)
            Spacer()
            if !unlocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
            } else if selected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.dsSecondary)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(Color.dsSurfaceContainerLow)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(
                    selected ? Color.dsSecondary : Color.white.opacity(0.05),
                    lineWidth: selected ? 2 : 1
                )
        )
        .opacity(unlocked ? 1 : 0.6)
    }

    // MARK: - Shared next button

    private func nextButton(label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        } label: {
            Text(label)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color.dsCTALabel)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(enabled ? AnyShapeStyle(DSGradient.primaryCTA) : AnyShapeStyle(Color.gray.opacity(0.3)))
                .clipShape(Capsule())
                .dsPrimaryShadow()
        }
        .disabled(!enabled || isSaving)
        .padding(.horizontal, 8)
    }

    // MARK: - Helpers

    private func apply(_ work: @escaping () async -> Void) {
        isSaving = true
        Task {
            await work()
            isSaving = false
        }
    }

    private func goBack() {
        guard let prev = EditorStep(rawValue: step.rawValue - 1) else { return }
        step = prev
    }
}
