import Foundation

/// Runs a Scan & Solve round and saves the result like any first-touch
/// drill: session log, missions, XP, and a personal best on clean touches.
@MainActor
final class ScanSolveViewModel: ObservableObject {

    enum Phase: Equatable {
        case intro
        case playing
        case report
        case done
    }

    @Published var phase: Phase = .intro
    @Published var pace: ScanPace = ScanSolveRound.defaultPace
    @Published var round: ScanSolveRound?
    @Published var cleanCount: Int = 0
    @Published var isSaving = false
    @Published var xpEarned: Int = 0
    @Published var isNewPersonalBest = false
    @Published var errorMessage: String?
    @Published var bestClean: Int = 0

    /// PB metric key for clean directional touches.
    static let pbMetric = "scan_solve_clean"

    let childId: String
    private let apiClient: APIClientProtocol
    private let xpStore: XPStore
    private let pbStore: PersonalBestStore

    init(
        childId: String,
        apiClient: APIClientProtocol = APIClient.shared,
        xpStore: XPStore = XPStore(),
        pbStore: PersonalBestStore = PersonalBestStore()
    ) {
        self.childId = childId
        self.apiClient = apiClient
        self.xpStore = xpStore
        self.pbStore = pbStore
    }

    var commandCount: Int {
        round?.commands.count ?? ScanSolveRound.defaultCount
    }

    func loadBest() async {
        bestClean = await pbStore.getBest(metric: Self.pbMetric, childId: childId)
    }

    func start(seed: UInt64? = nil) {
        round = seed.map { ScanSolveRound.generate(interval: pace.interval, seed: $0) }
            ?? ScanSolveRound.generate(interval: pace.interval)
        cleanCount = 0
        errorMessage = nil
        phase = .playing
    }

    func finishRound() {
        guard phase == .playing else { return }
        // Default the self-report to a hopeful-but-honest midpoint.
        cleanCount = min(cleanCount, commandCount)
        phase = .report
    }

    func cancel() {
        round = nil
        phase = .intro
    }

    func save() async {
        guard phase == .report, !isSaving else { return }
        isSaving = true
        errorMessage = nil
        let clean = min(max(cleanCount, 0), commandCount)

        do {
            let body = CreateSessionBody(
                activityType: "first_touch_scan_solve",
                effortLevel: 3,
                mood: "focused",
                duration: 1,
                win: "\(clean)/\(commandCount) clean directional touches",
                focus: nil
            )
            let _: SessionSaveResult = try await apiClient.request(
                APIRouter.createSession(childId: childId, body: body)
            )

            MissionsViewModel.shared.recordEvent(.firstTouchDrillCompleted, childId: childId)
            MissionsViewModel.shared.recordEvent(.sessionLogged, childId: childId)

            var earned = XPCalculator.xpForSession(duration: 1, effortLevel: nil, activityType: "drill")
            let isPB = await pbStore.checkAndUpdate(metric: Self.pbMetric, value: clean, childId: childId)
            if isPB {
                earned += XPCalculator.xpForPersonalBest
                isNewPersonalBest = true
                bestClean = clean
            }

            let _ = await xpStore.addXP(earned, childId: childId)
            await xpStore.recordXPEntry(
                XPEntry(amount: earned, source: isPB ? "personal_best" : "first_touch", date: Date()),
                childId: childId
            )
            xpEarned = earned
            phase = .done
        } catch {
            errorMessage = "Couldn't save the round: \(error.localizedDescription)"
        }
        isSaving = false
    }
}
