import Foundation

/// State for the Creativity Lab: variety counting, completion rewards, and
/// the chip-based move namer. The score IS the variety — the counter only
/// moves when the kid does something *different*.
@MainActor
final class CreativityViewModel: ObservableObject {

    @Published var activeChallenge: CreativityChallenge?
    @Published var varietyCount: Int = 0
    @Published var challengeComplete = false
    @Published var isSaving = false
    @Published var xpEarned: Int = 0
    @Published var errorMessage: String?

    @Published var completions: [String: Int] = [:]
    @Published var inventedMoves: [String] = []

    // Move namer
    @Published var namePartA: String?
    @Published var namePartB: String?

    let childId: String
    private let apiClient: APIClientProtocol
    private let store: CreativityStore
    private let xpStore: XPStore

    init(
        childId: String,
        apiClient: APIClientProtocol = APIClient.shared,
        store: CreativityStore = CreativityStore(),
        xpStore: XPStore = XPStore()
    ) {
        self.childId = childId
        self.apiClient = apiClient
        self.store = store
        self.xpStore = xpStore
    }

    var proposedMoveName: String? {
        guard let a = namePartA, let b = namePartB else { return nil }
        return MoveNameParts.combined(a, b)
    }

    func load() async {
        var next: [String: Int] = [:]
        for challenge in CreativityChallengeRegistry.all {
            next[challenge.id] = await store.completions(challengeId: challenge.id, childId: childId)
        }
        completions = next
        inventedMoves = await store.inventedMoves(childId: childId)
    }

    // MARK: - Challenge flow

    func begin(_ challenge: CreativityChallenge) {
        activeChallenge = challenge
        varietyCount = 0
        challengeComplete = false
        namePartA = nil
        namePartB = nil
        errorMessage = nil
    }

    /// One tap = one NEW way. Capped at the target — repetition scores zero.
    func countNewWay() {
        guard let challenge = activeChallenge, !challengeComplete else { return }
        varietyCount = min(varietyCount + 1, challenge.varietyTarget)
    }

    var targetReached: Bool {
        guard let challenge = activeChallenge else { return false }
        return varietyCount >= challenge.varietyTarget
    }

    func complete() async {
        guard let challenge = activeChallenge, targetReached, !challengeComplete, !isSaving else { return }
        isSaving = true
        errorMessage = nil

        do {
            let body = CreateSessionBody(
                activityType: "creativity_\(challenge.id)",
                effortLevel: 3,
                mood: "excited",
                duration: 1,
                win: "\(challenge.title) — \(challenge.varietyTarget) \(challenge.unit)",
                focus: nil
            )
            let _: SessionSaveResult = try await apiClient.request(
                APIRouter.createSession(childId: childId, body: body)
            )

            await store.recordCompletion(challengeId: challenge.id, childId: childId)
            MissionsViewModel.shared.recordEvent(.sessionLogged, childId: childId)

            let earned = XPCalculator.xpForSession(duration: 1, effortLevel: nil, activityType: "drill")
            let _ = await xpStore.addXP(earned, childId: childId)
            await xpStore.recordXPEntry(
                XPEntry(amount: earned, source: "creativity", date: Date()),
                childId: childId
            )
            xpEarned = earned
            challengeComplete = true
            await load()
        } catch {
            errorMessage = "Couldn't save the challenge: \(error.localizedDescription)"
        }
        isSaving = false
    }

    /// Save the invented move's name (invention challenges only).
    func saveInventedMove() async {
        guard let name = proposedMoveName,
              activeChallenge?.isInvention == true,
              challengeComplete else { return }
        await store.saveInventedMove(name, childId: childId)
        inventedMoves = await store.inventedMoves(childId: childId)
    }

    func exitChallenge() {
        activeChallenge = nil
        varietyCount = 0
        challengeComplete = false
    }
}
