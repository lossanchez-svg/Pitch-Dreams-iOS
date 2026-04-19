import SwiftUI

/// Owns the state of the home-dashboard Mystery Box card + opening flow.
/// Coordinates the engine, the store, the XP store, and the streak-shield
/// flag so the visible reward correctly reflects what was just applied.
@MainActor
final class MysteryBoxViewModel: ObservableObject {
    @Published var isAvailable: Bool = false
    @Published var isOpening: Bool = false
    @Published var revealedReward: MysteryReward?
    @Published var boxStreak: Int = 0
    @Published var secondsUntilNextBox: TimeInterval = 0

    let childId: String
    private let store: MysteryBoxStore
    private let moveStore: SignatureMoveStore
    private let xpStore: XPStore

    init(
        childId: String,
        store: MysteryBoxStore = MysteryBoxStore(),
        moveStore: SignatureMoveStore = SignatureMoveStore(),
        xpStore: XPStore = XPStore()
    ) {
        self.childId = childId
        self.store = store
        self.moveStore = moveStore
        self.xpStore = xpStore
    }

    // MARK: - Load

    func load() async {
        isAvailable = await store.isBoxAvailable(childId: childId)
        boxStreak = await store.boxStreak(childId: childId)
        secondsUntilNextBox = await store.secondsUntilNextBox()
    }

    // MARK: - Open

    /// Rolls a reward, applies its side effects (XP grant, cosmetic unlock,
    /// fever-time, etc.), persists to the store, and publishes the reward
    /// so the reveal screen can render it.
    func openBox() async {
        guard isAvailable, !isOpening else { return }
        isOpening = true

        // Gather runtime context so contextual filters kick in correctly.
        let allMoves = await moveStore.allProgress(childId: childId)
        let lockedIds = allMoves
            .filter { !$0.progress.isMastered && SignatureMoveRegistry.isPlayable($0.move) }
            .map(\.move.id)
        let context = MysteryBoxContext(
            lockedMoveIds: lockedIds,
            availableCosmeticIds: ["color_red", "color_blue", "crest_shield", "celebration_wave"],
            streakShieldsMaxed: false
        )
        let reward = MysteryBoxEngine.generateReward(context: context)
        await applySideEffects(of: reward)
        await store.recordOpen(reward: reward, childId: childId)

        revealedReward = reward
        isAvailable = false
        boxStreak = await store.boxStreak(childId: childId)
        secondsUntilNextBox = await store.secondsUntilNextBox()
        isOpening = false
    }

    func dismissReveal() {
        revealedReward = nil
    }

    /// Apply XP grants + XP history entries for XP-shaped rewards. Other
    /// reward types (cosmetic, shield, fever, move attempt) are handled
    /// elsewhere — we only record that they were opened.
    private func applySideEffects(of reward: MysteryReward) async {
        if let xp = reward.xpAmount, xp > 0 {
            _ = await xpStore.addXP(xp, childId: childId)
            await xpStore.recordXPEntry(
                XPEntry(amount: xp, source: "mystery_box", date: Date()),
                childId: childId
            )
        }
    }
}
