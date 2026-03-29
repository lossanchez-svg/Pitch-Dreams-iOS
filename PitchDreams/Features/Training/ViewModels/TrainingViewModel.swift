import Foundation

@MainActor
final class TrainingViewModel: ObservableObject {
    @Published var checkInState: CheckInResponse?
    @Published var isCheckingIn = false
    @Published var errorMessage: String?

    let childId: String
    private let apiClient: APIClientProtocol

    init(childId: String, apiClient: APIClientProtocol = APIClient()) {
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
        do {
            let body = QuickCheckInBody(mood: mood, timeAvail: nil)
            let response: CheckInResponse = try await apiClient.request(
                APIRouter.createQuickCheckIn(childId: childId, body: body)
            )
            checkInState = response
        } catch {
            errorMessage = "Check-in failed. Please try again."
        }
        isCheckingIn = false
    }

    func fullCheckIn(
        energy: Int,
        soreness: String,
        focus: Int,
        mood: String,
        timeAvail: Int,
        painFlag: Bool
    ) async {
        isCheckingIn = true
        errorMessage = nil
        do {
            let body = CreateCheckInBody(
                energy: energy,
                soreness: soreness,
                focus: focus,
                mood: mood,
                timeAvail: timeAvail,
                painFlag: painFlag
            )
            let response: CheckInResponse = try await apiClient.request(
                APIRouter.createCheckIn(childId: childId, body: body)
            )
            checkInState = response
        } catch {
            errorMessage = "Check-in failed. Please try again."
        }
        isCheckingIn = false
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
