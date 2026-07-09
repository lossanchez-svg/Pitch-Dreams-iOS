import Foundation

@MainActor
final class TrainingViewModel: ObservableObject {
    @Published var checkInState: CheckInResponse?
    @Published var isCheckingIn = false
    @Published var errorMessage: String?

    let childId: String
    private let apiClient: APIClientProtocol

    init(childId: String, apiClient: APIClientProtocol = APIClient.shared) {
        self.childId = childId
        self.apiClient = apiClient
    }

    // MARK: - Computed

    var sessionMode: String? {
        checkInState?.modeResult.mode
    }

    var modeExplanation: String? {
        checkInState?.modeResult.explanation
    }

    var modeDisplayName: String {
        guard let mode = sessionMode else { return "" }
        switch mode {
        case "PEAK": return "Peak Day"
        case "NORMAL": return "Normal"
        case "LOW_BATTERY": return "Low Battery"
        case "RECOVERY": return "Recovery"
        default: return mode
        }
    }

    var modeColor: String {
        guard let mode = sessionMode else { return "gray" }
        switch mode {
        case "PEAK": return "green"
        case "NORMAL": return "blue"
        case "LOW_BATTERY": return "yellow"
        case "RECOVERY": return "purple"
        default: return "gray"
        }
    }

    // MARK: - Actions

    func quickCheckIn(mood: String) async {
        isCheckingIn = true
        errorMessage = nil
        let body = QuickCheckInBody(mood: mood, timeAvail: nil)
        do {
            let response: CheckInResponse = try await apiClient.request(
                APIRouter.createQuickCheckIn(childId: childId, body: body)
            )
            checkInState = response
            MissionsViewModel.shared.recordEvent(.checkInCompleted, childId: childId)
        } catch APIError.network, APIError.server {
            // Offline or transient backend failure — queue the check-in and
            // let the kid train with a locally-computed mode. The server
            // recomputes when the queued check-in syncs.
            await SessionSyncQueue.shared.enqueueQuickCheckIn(childId: childId, body: body)
            checkInState = Self.offlineCheckInResponse(
                childId: childId, energy: 3, mood: mood, timeAvail: 20, painFlag: false
            )
            MissionsViewModel.shared.recordEvent(.checkInCompleted, childId: childId)
            Log.api.info("Quick check-in queued for retry for child \(self.childId)")
        } catch {
            errorMessage = "Check-in failed. Please try again."
        }
        isCheckingIn = false
    }

    /// Full check-in trimmed to the inputs that actually shape the session:
    /// energy, mood, time available, and a safety pain flag. Soreness and focus
    /// are no longer asked of the kid (too abstract for the age group) — they
    /// default here so the server's `SessionMode` calculation still has values.
    func fullCheckIn(
        energy: Int,
        mood: String,
        timeAvail: Int,
        painFlag: Bool
    ) async {
        isCheckingIn = true
        errorMessage = nil
        let body = CreateCheckInBody(
            energy: energy,
            soreness: Soreness.none.rawValue,
            focus: energy,
            mood: mood,
            timeAvail: timeAvail,
            painFlag: painFlag
        )
        do {
            let response: CheckInResponse = try await apiClient.request(
                APIRouter.createCheckIn(childId: childId, body: body)
            )
            checkInState = response
            MissionsViewModel.shared.recordEvent(.checkInCompleted, childId: childId)
        } catch APIError.network, APIError.server {
            await SessionSyncQueue.shared.enqueueCheckIn(childId: childId, body: body)
            checkInState = Self.offlineCheckInResponse(
                childId: childId, energy: energy, mood: mood,
                timeAvail: timeAvail, painFlag: painFlag
            )
            MissionsViewModel.shared.recordEvent(.checkInCompleted, childId: childId)
            Log.api.info("Full check-in queued for retry for child \(self.childId)")
        } catch {
            errorMessage = "Check-in failed. Please try again."
        }
        isCheckingIn = false
    }

    /// Conservative local stand-in for the server's SessionMode calculation,
    /// used only when a check-in is queued offline. Mirrors the documented
    /// mode rules: pain always wins, low energy throttles, high energy with
    /// enough time peaks. The server's answer replaces this on next sync.
    static func offlineCheckInResponse(
        childId: String, energy: Int, mood: String, timeAvail: Int, painFlag: Bool
    ) -> CheckInResponse {
        let mode: SessionMode
        if painFlag {
            mode = .recovery
        } else if energy <= 2 {
            mode = .lowBattery
        } else if energy >= 4 && timeAvail >= 20 {
            mode = .peak
        } else {
            mode = .normal
        }
        let checkIn = CheckIn(
            id: "offline-\(UUID().uuidString)",
            childId: childId,
            energy: energy,
            soreness: Soreness.none.rawValue,
            focus: energy,
            mood: mood,
            timeAvail: timeAvail,
            painFlag: painFlag,
            mode: mode.rawValue,
            modeExplanation: nil,
            qualityRating: nil,
            completed: false,
            activityId: nil,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        return CheckInResponse(
            checkIn: checkIn,
            modeResult: SessionModeResult(
                mode: mode.rawValue,
                explanation: "You're offline — we'll sync this check-in when you're back. Train on!"
            )
        )
    }

    func loadTodayCheckIn() async {
        // API returns null when no check-in today — that's normal
        guard let checkIn: CheckIn = try? await apiClient.request(
            APIRouter.todayCheckIn(childId: childId)
        ) else { return }

        checkInState = CheckInResponse(
            checkIn: checkIn,
            modeResult: SessionModeResult(
                mode: checkIn.mode,
                explanation: checkIn.modeExplanation ?? "Continue with your session."
            )
        )
    }
}
