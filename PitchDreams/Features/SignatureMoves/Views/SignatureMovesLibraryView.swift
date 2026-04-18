import SwiftUI

/// Entry screen for the Signature Moves system. Shows a 2-column grid of
/// all 10 moves with per-tile rarity badges, progress state (locked / in
/// progress / mastered), and a filter-pill row across the top.
///
/// Tapping an unlocked move opens its learning flow via
/// `SignatureMoveLearningContainer`. Placeholder-only moves show a
/// "coming soon" sheet instead of the flow.
struct SignatureMovesLibraryView: View {
    let childId: String
    let childAge: Int?

    @StateObject private var viewModel: SignatureMovesLibraryViewModel
    @State private var presentedMove: SignatureMove?
    @State private var showComingSoon: SignatureMove?
    @Environment(\.dismiss) private var dismiss

    init(childId: String, childAge: Int? = nil) {
        self.childId = childId
        self.childAge = childAge
        _viewModel = StateObject(wrappedValue: SignatureMovesLibraryViewModel(childId: childId))
    }

    var body: some View {
        ZStack {
            Color.dsBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, 6)

                filterPills
                    .padding(.top, 18)

                ScrollView(showsIndicators: false) {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ],
                        spacing: 12
                    ) {
                        ForEach(viewModel.filteredEntries, id: \.move.id) { entry in
                            moveTile(entry)
                                .onTapGesture {
                                    handleTileTap(entry)
                                }
                        }
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(.white)
                }
                .accessibilityLabel("Back")
            }
        }
        .toolbarBackground(Color.dsBackground, for: .navigationBar)
        .task { await viewModel.load() }
        .fullScreenCover(item: $presentedMove) { move in
            NavigationStack {
                SignatureMoveLearningContainer(
                    move: move,
                    childId: childId,
                    childAge: childAge,
                    onDismiss: {
                        presentedMove = nil
                        Task { await viewModel.load() }
                    }
                )
            }
        }
        .sheet(item: $showComingSoon) { move in
            ComingSoonSheet(move: move, onDismiss: { showComingSoon = nil })
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("SIGNATURE MOVES")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color.dsAccentOrange)
                Text("\(viewModel.masteredCount) of \(viewModel.totalCount) mastered")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.dsSecondary)
            }
            Spacer()
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.dsOnSurfaceVariant)
                .accessibilityHidden(true)
        }
    }

    // MARK: - Filter pills

    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(SignatureMovesLibraryViewModel.Filter.allCases, id: \.self) { filter in
                    pill(for: filter)
                        .onTapGesture {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            viewModel.selectedFilter = filter
                        }
                }
            }
            .padding(.horizontal, Spacing.xl)
        }
    }

    private func pill(for filter: SignatureMovesLibraryViewModel.Filter) -> some View {
        let selected = viewModel.selectedFilter == filter
        return Text(filter.displayName.uppercased())
            .font(.system(size: 12, weight: .heavy, design: .rounded))
            .tracking(1)
            .foregroundStyle(selected ? Color(hex: "#06293A") : Color.dsOnSurfaceVariant)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(selected ? Color.dsSecondary : Color.dsSurfaceContainerLow)
            .clipShape(Capsule())
    }

    // MARK: - Tile

    private func moveTile(_ entry: SignatureMovesLibraryViewModel.Entry) -> some View {
        let move = entry.move
        let progress = entry.progress
        let rarityColor = Color(hex: move.rarity.accentColorHex)
        let isMastered = progress.isMastered
        let isPlaceholder = !entry.isPlayable

        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(move.rarity.displayName.uppercased())
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(rarityColor)
                Spacer()
                if isMastered {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.dsTertiaryContainer)
                } else if isPlaceholder {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                }
            }

            Spacer()

            Image(systemName: move.iconSymbolName)
                .font(.system(size: 44, weight: .medium))
                .foregroundStyle(moveIconColor(entry: entry))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)

            Text(move.name)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(isPlaceholder ? Color.dsOnSurfaceVariant : Color.dsOnSurface)
                .frame(maxWidth: .infinity, alignment: .center)

            Spacer()

            progressBar(entry: entry)
                .padding(.top, 12)
        }
        .padding(14)
        .frame(height: 180)
        .background(Color.dsSurfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(
                    isMastered ? Color.dsTertiaryContainer.opacity(0.5) : Color.white.opacity(0.05),
                    lineWidth: isMastered ? 1.5 : 1
                )
        )
        .opacity(isPlaceholder ? 0.6 : 1.0)
    }

    private func moveIconColor(entry: SignatureMovesLibraryViewModel.Entry) -> Color {
        if entry.progress.isMastered { return Color.dsTertiaryContainer }
        if !entry.isPlayable { return Color.dsOnSurfaceVariant.opacity(0.5) }
        if entry.progress.currentStage > 1 { return Color.dsAccentOrange }
        return Color(hex: entry.move.rarity.accentColorHex)
    }

    @ViewBuilder
    private func progressBar(entry: SignatureMovesLibraryViewModel.Entry) -> some View {
        // 3-dot indicator for playable moves; full empty bar for placeholders.
        let stages = 3
        let current = entry.progress.currentStage
        HStack(spacing: 4) {
            ForEach(0..<stages, id: \.self) { i in
                Capsule()
                    .fill(dotColor(for: i, current: current, mastered: entry.progress.isMastered))
                    .frame(height: 3)
            }
        }
    }

    private func dotColor(for index: Int, current: Int, mastered: Bool) -> Color {
        if mastered { return Color.dsTertiaryContainer }
        // index is 0-based, current is 1-based. A dot fills once its stage
        // is completed (i.e., index < current - 1 means earlier stages done).
        if index + 1 < current { return Color.dsAccentOrange }
        if index + 1 == current { return Color.dsAccentOrange.opacity(0.45) }
        return Color.dsSurfaceContainerHighest
    }

    // MARK: - Tile interaction

    private func handleTileTap(_ entry: SignatureMovesLibraryViewModel.Entry) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if entry.isPlayable {
            presentedMove = entry.move
        } else {
            showComingSoon = entry.move
        }
    }
}

// MARK: - ViewModel

@MainActor
final class SignatureMovesLibraryViewModel: ObservableObject {
    struct Entry: Identifiable {
        let move: SignatureMove
        let progress: MoveProgress
        let isPlayable: Bool
        var id: String { move.id }
    }

    enum Filter: CaseIterable, Equatable {
        case all, common, rare, epic, legendary, unlocked, inProgress

        var displayName: String {
            switch self {
            case .all:        return "All"
            case .common:     return "Common"
            case .rare:       return "Rare"
            case .epic:       return "Epic"
            case .legendary:  return "Legendary"
            case .unlocked:   return "Unlocked"
            case .inProgress: return "In Progress"
            }
        }

        func matches(_ entry: Entry) -> Bool {
            switch self {
            case .all:        return true
            case .common:     return entry.move.rarity == .common
            case .rare:       return entry.move.rarity == .rare
            case .epic:       return entry.move.rarity == .epic
            case .legendary:  return entry.move.rarity == .legendary
            case .unlocked:   return entry.progress.isMastered
            case .inProgress: return !entry.progress.isMastered && entry.progress.currentStage > 1
            }
        }
    }

    @Published var entries: [Entry] = []
    @Published var selectedFilter: Filter = .all

    let childId: String
    private let store: SignatureMoveStore

    init(childId: String, store: SignatureMoveStore = SignatureMoveStore()) {
        self.childId = childId
        self.store = store
    }

    var totalCount: Int { SignatureMoveRegistry.launchMoves.count }
    var masteredCount: Int { entries.filter { $0.progress.isMastered }.count }
    var filteredEntries: [Entry] { entries.filter { selectedFilter.matches($0) } }

    func load() async {
        let all = await store.allProgress(childId: childId)
        entries = all.map { pair in
            Entry(
                move: pair.move,
                progress: pair.progress,
                isPlayable: SignatureMoveRegistry.isPlayable(pair.move)
            )
        }
    }
}

// MARK: - Coming-soon sheet

private struct ComingSoonSheet: View {
    let move: SignatureMove
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.dsBackground.ignoresSafeArea()
            VStack(spacing: Spacing.xl) {
                Spacer()
                Image(systemName: move.iconSymbolName)
                    .font(.system(size: 72, weight: .medium))
                    .foregroundStyle(Color(hex: move.rarity.accentColorHex))
                Text(move.name)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.dsOnSurface)
                Text("COMING SOON")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(3)
                    .foregroundStyle(Color.dsAccentOrange)
                Text("Full lesson content for this move is a post-launch bonus drop. Check back — we ship a new one every 3–4 weeks.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Spacer()
                Button {
                    onDismiss()
                } label: {
                    Text("GOT IT")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(Color.dsCTALabel)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(DSGradient.primaryCTA)
                        .clipShape(Capsule())
                        .dsPrimaryShadow()
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 32)
            }
        }
    }
}

#Preview {
    NavigationStack {
        SignatureMovesLibraryView(childId: "preview", childAge: 12)
    }
}
