import Foundation

/// Assembles the Confidence Evidence Bank from data the app already stores:
/// mastered signature moves, first-touch personal bests, the current streak,
/// and total logged sessions. Read-only — this feature collects nothing new.
@MainActor
final class ConfidenceViewModel: ObservableObject {
    @Published var snapshot = ConfidenceSnapshot()
    @Published var isLoading = true

    let childId: String
    private let apiClient: APIClientProtocol
    private let moveStore: SignatureMoveStore
    private let pbStore: PersonalBestStore

    /// Sessions fetched to count volume; hitting this cap means "N+" copy.
    static let sessionFetchLimit = 100

    /// The first-touch metrics worth bragging about, with kid-facing labels.
    static let personalBestMetrics: [(key: String, label: String)] = [
        ("juggling_both_feet", "Juggling"),
        ("wall_ball_pass", "Wall pass"),
        ("wall_ball_one_touch", "One touch"),
    ]

    init(
        childId: String,
        apiClient: APIClientProtocol = APIClient.shared,
        moveStore: SignatureMoveStore = SignatureMoveStore(),
        pbStore: PersonalBestStore = PersonalBestStore()
    ) {
        self.childId = childId
        self.apiClient = apiClient
        self.moveStore = moveStore
        self.pbStore = pbStore
    }

    func load() async {
        isLoading = true
        var next = ConfidenceSnapshot()

        // Signature moves: mastered + in-progress, from the local store.
        let allProgress = await moveStore.allProgress(childId: childId)
        next.masteredMoveNames = allProgress
            .filter { $0.progress.isMastered }
            .map { $0.move.name }
        next.inProgressMoveNames = allProgress
            .filter { !$0.progress.isMastered && $0.progress.currentStage > 1 }
            .map { $0.move.name }

        // Personal bests from the local PB store.
        var bests: [(label: String, value: Int)] = []
        for metric in Self.personalBestMetrics {
            let value = await pbStore.getBest(metric: metric.key, childId: childId)
            if value > 0 {
                bests.append((label: metric.label, value: value))
            }
        }
        next.personalBests = bests

        // Streak + session volume from the server; failures just omit the
        // line — the Evidence Bank degrades, it never errors at the kid.
        if let streaks: StreakData = try? await apiClient.request(APIRouter.getStreaks(childId: childId)) {
            next.currentStreak = streaks.milestones.max() ?? 0
        }
        if let sessions: [SessionLog] = try? await apiClient.request(
            APIRouter.listSessions(childId: childId, limit: Self.sessionFetchLimit)
        ) {
            next.totalSessions = sessions.count
            next.sessionCountIsFloor = sessions.count >= Self.sessionFetchLimit
        }

        snapshot = next
        isLoading = false
    }
}
