import Foundation
import Combine

enum TrainingPhase {
    case drilling
    case repConfirm
    case reflection
    case complete
}

@MainActor
final class ActiveTrainingViewModel: ObservableObject {
    // MARK: - Drill State
    @Published var currentDrillIndex: Int = 0
    @Published var timeRemaining: Int = 0
    @Published var repCount: Int = 0
    @Published var isTimerRunning: Bool = false
    @Published var sessionDrills: [DrillDefinition] = []
    @Published var phase: TrainingPhase = .drilling

    // MARK: - Reflection State
    @Published var reflectionRPE: Int = 5
    @Published var reflectionMood: String = "okay"
    @Published var selectedHighlights: Set<String> = []
    @Published var selectedNextFocus: Set<String> = []
    @Published var highlightOptions: [HighlightChip] = []
    @Published var nextFocusOptions: [NextFocusChip] = []

    // MARK: - Voice Coaching
    @Published var coachVoice = CoachVoice()
    private var hasSpokedMidDrill = false
    private var hasSpoken30s = false

    // MARK: - Session Meta
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var sessionSaved = false

    let childId: String
    let spaceType: String
    private let apiClient: APIClientProtocol
    private var timerCancellable: AnyCancellable?
    private var sessionStartTime: Date?

    var currentDrill: DrillDefinition? {
        guard currentDrillIndex < sessionDrills.count else { return nil }
        return sessionDrills[currentDrillIndex]
    }

    var drillProgress: String {
        "\(currentDrillIndex + 1) of \(sessionDrills.count)"
    }

    var totalDrills: Int { sessionDrills.count }

    var isLastDrill: Bool {
        currentDrillIndex >= sessionDrills.count - 1
    }

    var sessionDurationMinutes: Int {
        guard let start = sessionStartTime else { return 0 }
        return max(1, Int(Date().timeIntervalSince(start) / 60))
    }

    init(childId: String, drills: [DrillDefinition], spaceType: String, apiClient: APIClientProtocol = APIClient()) {
        self.childId = childId
        self.spaceType = spaceType
        self.apiClient = apiClient
        self.sessionDrills = drills
        if let first = drills.first {
            self.timeRemaining = first.duration
        }
    }

    // MARK: - Timer

    func startDrill() {
        if sessionStartTime == nil {
            sessionStartTime = Date()
        }
        hasSpokedMidDrill = false
        hasSpoken30s = false

        // Voice: announce drill start
        if let drill = currentDrill {
            let durationMinutes = max(1, drill.duration / 60)
            coachVoice.speak(
                "\(drill.name). You've got \(durationMinutes) minutes. \(drill.coachTip)",
                personality: "manager"
            )
        }

        isTimerRunning = true
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    guard let self, self.isTimerRunning else { return }
                    if self.timeRemaining > 0 {
                        self.timeRemaining -= 1
                        self.checkVoiceMilestones()
                    } else {
                        self.completeDrill()
                    }
                }
            }
    }

    private func checkVoiceMilestones() {
        // Mid-drill at 60s remaining
        if timeRemaining == 60 && !hasSpokedMidDrill {
            hasSpokedMidDrill = true
            coachVoice.speak("Keep going. \(timeRemaining) seconds to go.", personality: "hype")
        }
        // 30s remaining
        if timeRemaining == 30 && !hasSpoken30s {
            hasSpoken30s = true
            coachVoice.speak("Thirty seconds! Finish strong.", personality: "hype")
        }
    }

    func pauseTimer() {
        isTimerRunning = false
        timerCancellable?.cancel()
    }

    func completeDrill() {
        pauseTimer()
        phase = .repConfirm
        // Voice: timer expired
        coachVoice.speak("Time! How many reps did you get?", personality: "manager")
    }

    func confirmReps() {
        if isLastDrill {
            phase = .reflection
            loadReflectionOptions()
            // Voice: reflection start
            coachVoice.speak("Quick reflection. How hard was that, 1 to 10?", personality: "zen")
        } else {
            nextDrill()
        }
    }

    func nextDrill() {
        guard !isLastDrill else {
            phase = .reflection
            loadReflectionOptions()
            return
        }
        currentDrillIndex += 1
        if let drill = currentDrill {
            timeRemaining = drill.duration
            repCount = 0
        }
        phase = .drilling
    }

    func incrementReps() {
        repCount += 1
    }

    // MARK: - Reflection

    private func loadReflectionOptions() {
        Task {
            do {
                highlightOptions = try await apiClient.request(APIRouter.highlightTags)
            } catch {
                highlightOptions = []
            }
            do {
                nextFocusOptions = try await apiClient.request(APIRouter.nextFocusTags)
            } catch {
                nextFocusOptions = []
            }
        }
    }

    // MARK: - Save

    func saveSession() async {
        isLoading = true
        errorMessage = nil
        do {
            let body = CreateSessionBody(
                activityType: "SELF_TRAINING",
                effortLevel: reflectionRPE,
                mood: reflectionMood.uppercased(),
                duration: sessionDurationMinutes,
                win: selectedHighlights.isEmpty ? nil : selectedHighlights.joined(separator: ", "),
                focus: selectedNextFocus.isEmpty ? nil : selectedNextFocus.joined(separator: ", ")
            )
            let _: SessionLog = try await apiClient.request(
                APIRouter.createSession(childId: childId, body: body)
            )
            // Log each drill
            for drill in sessionDrills {
                let drillBody = LogDrillBody(
                    drillKey: drill.id,
                    repsCount: drill.reps,
                    confidence: reflectionRPE
                )
                let _: LogDrillResult = try await apiClient.request(
                    APIRouter.logDrill(childId: childId, body: drillBody)
                )
            }
            sessionSaved = true
            phase = .complete
            // Voice: session complete
            coachVoice.speak("Well done. Session complete.", personality: "manager")
        } catch {
            errorMessage = "Failed to save session. Please try again."
        }
        isLoading = false
    }
}
