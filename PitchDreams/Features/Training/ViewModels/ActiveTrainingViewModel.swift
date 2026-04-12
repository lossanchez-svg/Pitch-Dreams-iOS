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
    var coachVoice: CoachVoiceProtocol = CoachVoice()
    private var hasSpokedMidDrill = false
    private var hasSpoken30s = false

    /// The coach personality used for all voice coaching in this session.
    /// Reads from the parent-configured setting stored in UserDefaults.
    var coachPersonality: String {
        CoachPersonality.current.rawValue
    }

    // MARK: - Avatar
    @Published var avatarAssetName: String = "default_stage1"

    // MARK: - Session Meta
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var sessionSaved = false

    let childId: String
    let spaceType: String
    private let apiClient: APIClientProtocol
    private var timerCancellable: AnyCancellable?
    private var reflectionTask: Task<Void, Never>?
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
        guard let start = sessionStartTime else { return 1 }
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
            let persona = CoachPersonality.current
            coachVoice.speak(
                persona.drillStartLine(name: drill.name, minutes: durationMinutes, tip: drill.coachTip),
                personality: coachPersonality
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
        let persona = CoachPersonality.current
        // Mid-drill at 60s remaining
        if timeRemaining == 60 && !hasSpokedMidDrill {
            hasSpokedMidDrill = true
            coachVoice.speak(persona.midDrillLine(secondsLeft: timeRemaining), personality: coachPersonality)
        }
        // 30s remaining
        if timeRemaining == 30 && !hasSpoken30s {
            hasSpoken30s = true
            coachVoice.speak(persona.thirtySecondsLine, personality: coachPersonality)
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
        coachVoice.speak(CoachPersonality.current.drillCompleteLine, personality: coachPersonality)
    }

    func confirmReps() {
        if isLastDrill {
            phase = .reflection
            loadReflectionOptions()
            // Voice: reflection start
            coachVoice.speak(CoachPersonality.current.reflectionLine, personality: coachPersonality)
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

    // MARK: - Profile / Avatar

    func loadProfile() async {
        do {
            let profile: ChildProfileDetail = try await apiClient.request(
                APIRouter.getProfile(childId: childId)
            )
            let streaks: StreakData? = try? await apiClient.request(
                APIRouter.getStreaks(childId: childId)
            )
            let milestones = streaks?.milestones ?? []
            avatarAssetName = Avatar.assetName(
                for: profile.avatarId,
                milestones: milestones,
                localMissionXP: MissionsViewModel.shared.localMissionXP
            )
        } catch {
            // Keep default avatar on failure — non-critical
        }
    }

    // MARK: - Reflection

    private func loadReflectionOptions() {
        reflectionTask?.cancel()
        reflectionTask = Task { @MainActor in
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

    /// Cancel timer and in-flight tasks. Call from view's onDisappear.
    func cleanup() {
        timerCancellable?.cancel()
        timerCancellable = nil
        reflectionTask?.cancel()
        reflectionTask = nil
        isTimerRunning = false
    }

    deinit {
        timerCancellable?.cancel()
        reflectionTask?.cancel()
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
            let _: SessionSaveResult = try await apiClient.request(
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
            MissionsViewModel.shared.recordEvent(.sessionLogged, childId: childId)
            phase = .complete
            // Voice: session complete
            coachVoice.speak(CoachPersonality.current.sessionCompleteLine, personality: coachPersonality)
        } catch {
            Log.api.error("Session save failed: \(error)")
            errorMessage = "Failed to save session: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
