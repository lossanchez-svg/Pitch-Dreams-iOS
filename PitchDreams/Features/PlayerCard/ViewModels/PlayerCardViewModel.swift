import SwiftUI

/// Loads and maintains the Player Card display state. Pulls the stored
/// `PlayerCard` from `PlayerCardStore`, derives live stats via `StatComputer`
/// from the child's session history, and tracks unlocked signature-move
/// metadata for the loadout UI.
///
/// View mutations (archetype picker, stat selection, frame change, loadout
/// changes) go through the store and trigger a refresh so the computed
/// `stats` / `overallRating` update too.
@MainActor
final class PlayerCardViewModel: ObservableObject {
    @Published var card: PlayerCard
    @Published var stats: CardStats
    @Published var overallRating: Int = 75
    @Published var avatarAssetName: String = "wolf_stage1"
    @Published var avatarStage: AvatarStage = .rookie
    @Published var position: String = ""
    @Published var totalXP: Int = 0
    @Published var unlockedMoves: [SignatureMove] = []
    @Published var unlockedFrames: [CardFrame] = [.standard]
    @Published var isLoading = false

    let childId: String
    private let apiClient: APIClientProtocol
    private let store: PlayerCardStore
    private let xpStore: XPStore
    private let moveStore: SignatureMoveStore
    private let statComputer: StatComputer

    init(
        childId: String,
        apiClient: APIClientProtocol = APIClient(),
        store: PlayerCardStore = PlayerCardStore(),
        xpStore: XPStore = XPStore(),
        moveStore: SignatureMoveStore = SignatureMoveStore(),
        statComputer: StatComputer? = nil
    ) {
        self.childId = childId
        self.apiClient = apiClient
        self.store = store
        self.xpStore = xpStore
        self.moveStore = moveStore
        self.statComputer = statComputer ?? StatComputer(xpStore: xpStore)
        // Seed with defaults; `load()` overwrites with real data.
        self.card = PlayerCard(
            childId: childId,
            archetype: .allrounder,
            displayedStats: [.speed, .touch, .vision, .workRate],
            moveLoadout: [],
            clubCrestDesign: .defaultDesign,
            cardFrame: .standard,
            archetypeTagline: nil
        )
        self.stats = PlayerArchetype.allrounder.baselineStats
    }

    func load() async {
        isLoading = true
        card = await store.get(childId: childId)

        async let sessionsTask: [SessionLog]? = try? apiClient.request(
            APIRouter.listSessions(childId: childId, limit: 200)
        )
        async let profileTask: ChildProfileDetail? = try? apiClient.request(
            APIRouter.getProfile(childId: childId)
        )
        let sessions = (await sessionsTask) ?? []
        if let profile = await profileTask {
            position = profile.position ?? ""
        }

        totalXP = await xpStore.getTotalXP(childId: childId)
        avatarStage = XPCalculator.avatarStageForXP(totalXP)
        avatarAssetName = Avatar.assetName(for: childProfileAvatarId(await profileTask), totalXP: totalXP)

        let newStats = await statComputer.computeStats(for: card, sessions: sessions)
        stats = newStats
        overallRating = await statComputer.overallRating(
            stats: newStats,
            displayed: card.displayedStats.isEmpty ? [.speed, .touch, .vision, .workRate] : card.displayedStats
        )

        unlockedMoves = await moveStore.unlockedMoves(childId: childId)
        unlockedFrames = computeUnlockedFrames(avatarStage: avatarStage, totalXP: totalXP)

        isLoading = false
    }

    // MARK: - Mutations

    func setArchetype(_ archetype: PlayerArchetype) async {
        await store.updateArchetype(archetype, childId: childId)
        await load()
    }

    func setDisplayedStats(_ newStats: [CardStat]) async {
        let clamped = Array(newStats.prefix(PlayerCard.displayedStatCount))
        await store.updateDisplayedStats(clamped, childId: childId)
        card.displayedStats = clamped
        overallRating = await statComputer.overallRating(stats: stats, displayed: clamped)
    }

    func setMoveLoadout(_ moveIds: [String]) async {
        await store.updateMoveLoadout(moveIds, childId: childId)
        card.moveLoadout = Array(moveIds.prefix(PlayerCard.maxMoveLoadout))
    }

    func setFrame(_ frame: CardFrame) async {
        guard unlockedFrames.contains(frame) else { return }
        await store.updateFrame(frame, childId: childId)
        card.cardFrame = frame
    }

    // MARK: - Private

    private func childProfileAvatarId(_ profile: ChildProfileDetail?) -> String? {
        profile?.avatarId
    }

    /// Frames unlock as the child progresses: Bronze at Pro, Silver at Legend.
    /// Gold / Legendary / Platinum frames require milestones tracked elsewhere
    /// — they'll wire in as achievements are implemented.
    private func computeUnlockedFrames(avatarStage: AvatarStage, totalXP: Int) -> [CardFrame] {
        var unlocked: [CardFrame] = [.standard]
        if avatarStage.rawValue >= AvatarStage.pro.rawValue { unlocked.append(.bronze) }
        if avatarStage.rawValue >= AvatarStage.legend.rawValue { unlocked.append(.silver) }
        return unlocked
    }
}
