import Foundation

@MainActor
final class FirstTouchViewModel: ObservableObject {
    @Published var drillStats: [DrillStat] = []
    @Published var isLoading = true
    @Published var isSaving = false
    @Published var saveSuccess = false
    @Published var errorMessage: String?

    // Active drill state
    @Published var activeCount: Int = 0
    @Published var activeDrillKey: String?

    let childId: String
    private let apiClient: APIClientProtocol

    init(childId: String, apiClient: APIClientProtocol = APIClient()) {
        self.childId = childId
        self.apiClient = apiClient
    }

    // Juggling drill keys
    static let jugglingDrills = [
        ("juggling_both_feet", "Both Feet"),
        ("juggling_right_only", "Right Foot Only"),
        ("juggling_left_only", "Left Foot Only"),
        ("juggling_thigh", "Thigh Juggles"),
    ]

    // Wall ball drill keys
    static let wallBallDrills = [
        ("wall_ball_pass", "Wall Pass"),
        ("wall_ball_one_touch", "One Touch"),
        ("wall_ball_volley", "Volley"),
    ]

    var jugglingStats: [DrillStat] {
        drillStats.filter { stat in
            Self.jugglingDrills.contains { $0.0 == stat.drillKey }
        }
    }

    var wallBallStats: [DrillStat] {
        drillStats.filter { stat in
            Self.wallBallDrills.contains { $0.0 == stat.drillKey }
        }
    }

    var jugglingBest: Int {
        jugglingStats.map(\.totalAttempts).max() ?? 0
    }

    var wallBallBest: Int {
        wallBallStats.map(\.totalAttempts).max() ?? 0
    }

    func loadStats() async {
        isLoading = true
        do {
            drillStats = try await apiClient.request(APIRouter.drillStats(childId: childId))
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func startDrill(_ drillKey: String) {
        activeDrillKey = drillKey
        activeCount = 0
        saveSuccess = false
    }

    func incrementCount() {
        activeCount += 1
    }

    func saveDrill() async {
        guard let drillKey = activeDrillKey else { return }
        isSaving = true
        saveSuccess = false

        do {
            // Save as a quick session (first touch drills aren't in the skill registry)
            let label = drillKey.replacingOccurrences(of: "_", with: " ").capitalized
            let body = CreateSessionBody(
                activityType: "first_touch_\(drillKey)",
                effortLevel: 3,
                mood: "focused",
                duration: 1,
                win: "\(activeCount) reps — \(label)",
                focus: nil
            )
            let _: SessionSaveResult = try await apiClient.request(
                APIRouter.createSession(childId: childId, body: body)
            )
            saveSuccess = true
            // Record mission events — thresholded drills use `activeCount` as the incoming count
            // so missions like "wall_30_twice" only tick when this drill actually hit the bar.
            MissionsViewModel.shared.recordEvent(.firstTouchDrillCompleted, childId: childId)
            MissionsViewModel.shared.recordEvent(.sessionLogged, childId: childId)
            let isJuggling = Self.jugglingDrills.contains { $0.0 == drillKey }
            if isJuggling {
                MissionsViewModel.shared.recordEvent(.jugglingTaps(min: 0), count: activeCount, childId: childId)
            } else {
                MissionsViewModel.shared.recordEvent(.wallBallReps(min: 0), count: activeCount, childId: childId)
            }
            activeDrillKey = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    func cancelDrill() {
        activeDrillKey = nil
        activeCount = 0
    }
}
