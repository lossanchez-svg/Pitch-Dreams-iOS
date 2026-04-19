import SwiftUI
import Combine

/// Orchestrates the full Signature Move learning flow across the 8 screens
/// it spans: overview → stage intro → drill player → drill complete →
/// stage complete → (optional) record self → mastery celebration.
///
/// One instance per move being studied. Owns the transient drill state
/// (reps, elapsed time, current coach cue / mistake) and writes through
/// to `SignatureMoveStore` + `XPStore` at stage boundaries.
@MainActor
final class SignatureMoveLearningViewModel: ObservableObject {

    // MARK: - Flow step

    enum FlowStep: Equatable {
        case overview
        case stageIntro(stage: Int)
        case drillPlayer(stage: Int, drillId: String)
        case drillComplete(stage: Int, drillId: String)
        case stageComplete(stage: Int, xpAwarded: Int)
        case recordSelf(stage: Int)
        case mastered(xpAwarded: Int)
    }

    // MARK: - State

    @Published var currentStep: FlowStep = .overview
    @Published var progress: MoveProgress
    @Published var currentDrillReps: Int = 0
    @Published var currentDrillTime: Int = 0       // seconds elapsed
    @Published var currentCue: String?
    @Published var currentMistakeIndex: Int = 0
    @Published var pendingStageForConfidence: Int? = nil

    let move: SignatureMove
    let childId: String
    let childAge: Int?

    private let store: SignatureMoveStore
    private let xpStore: XPStore
    private let voice: CoachVoiceProtocol
    private var cueTimer: Timer?
    private var mistakeTimer: Timer?
    private var elapsedTimer: Timer?

    // MARK: - Init

    init(
        move: SignatureMove,
        childId: String,
        childAge: Int? = nil,
        store: SignatureMoveStore = SignatureMoveStore(),
        xpStore: XPStore = XPStore(),
        voice: CoachVoiceProtocol? = nil
    ) {
        self.move = move
        self.childId = childId
        self.childAge = childAge
        self.store = store
        self.xpStore = xpStore
        self.voice = voice ?? CoachVoice()
        self.progress = .initial(for: move.id)
    }

    func load() async {
        progress = await store.getProgress(moveId: move.id, childId: childId)
    }

    deinit {
        cueTimer?.invalidate()
        mistakeTimer?.invalidate()
        elapsedTimer?.invalidate()
    }

    // MARK: - Derived

    /// Age <=11 users get the young variant of instructions / cues / mistakes
    /// when authored. 12+ gets the standard variant.
    var isYoung: Bool { (childAge ?? 12) <= 11 }

    /// The drill tied to `currentStep`, if any.
    var activeDrill: MoveDrill? {
        guard case let .drillPlayer(stage, drillId) = currentStep else { return nil }
        return drill(stage: stage, drillId: drillId)
    }

    /// Age-adapted instructions for the currently-playing drill.
    func instructions(for drill: MoveDrill) -> String {
        (isYoung ? drill.instructionsYoung : drill.instructions) ?? drill.instructions
    }

    /// Next common-mistake card, rotating through the authored list.
    func currentMistake(for drill: MoveDrill) -> String? {
        let mistakes = (isYoung ? drill.commonMistakesYoung : drill.commonMistakes) ?? drill.commonMistakes
        guard !mistakes.isEmpty else { return nil }
        return mistakes[currentMistakeIndex % mistakes.count]
    }

    // MARK: - Navigation

    func beginStage(_ order: Int) {
        guard order <= progress.currentStage else { return }
        currentStep = .stageIntro(stage: order)
    }

    func startDrill(stage: Int, drillId: String) {
        guard drill(stage: stage, drillId: drillId) != nil else { return }
        currentDrillReps = 0
        currentDrillTime = 0
        currentMistakeIndex = 0
        currentCue = nil
        currentStep = .drillPlayer(stage: stage, drillId: drillId)
        startCueLoop(stage: stage, drillId: drillId)
        startMistakeLoop(stage: stage, drillId: drillId)
        startElapsedTimer()
    }

    func incrementRep() {
        currentDrillReps += 1
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    /// Mark the current drill done. Writes reps to the store and routes to
    /// the drill-complete screen, which will prompt for confidence.
    func completeDrill() async {
        stopTimers()
        guard case let .drillPlayer(stage, drillId) = currentStep else { return }
        _ = await store.recordDrillAttempt(
            moveId: move.id, drillId: drillId,
            reps: currentDrillReps, childId: childId
        )
        progress = await store.getProgress(moveId: move.id, childId: childId)
        currentStep = .drillComplete(stage: stage, drillId: drillId)
    }

    /// After the drill-complete screen, either go to the next drill in the
    /// stage, or — if this was the last drill — prompt for stage confidence.
    func continueAfterDrillComplete() {
        guard case let .drillComplete(stage, drillId) = currentStep else { return }
        guard let stageDef = move.stages.first(where: { $0.order == stage }) else { return }
        if let nextDrill = nextDrill(in: stageDef, after: drillId) {
            startDrill(stage: stage, drillId: nextDrill.id)
        } else {
            pendingStageForConfidence = stage
        }
    }

    /// Submit the user's confidence rating (1-5) for a finished stage.
    /// Routes to stageComplete, recordSelf (stage 3 + recording required),
    /// or mastered based on what advances.
    func submitConfidence(_ confidence: Int) async {
        guard let stage = pendingStageForConfidence else { return }
        let stageDef = move.stages.first(where: { $0.order == stage })
        let result = await store.recordStageConfidence(
            moveId: move.id, stage: stage, confidence: confidence, childId: childId
        )
        progress = await store.getProgress(moveId: move.id, childId: childId)
        pendingStageForConfidence = nil

        if result.moveMastered {
            let xp = move.rarity.masteryXP
            _ = await xpStore.addXP(xp, childId: childId)
            await xpStore.recordXPEntry(
                XPEntry(amount: xp, source: "move_mastery", date: Date()),
                childId: childId
            )
            currentStep = .mastered(xpAwarded: xp)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else if result.stageAdvanced {
            let xp = move.rarity.stageXP
            _ = await xpStore.addXP(xp, childId: childId)
            await xpStore.recordXPEntry(
                XPEntry(amount: xp, source: "move_stage", date: Date()),
                childId: childId
            )
            // If the final stage requires recording, route through the capstone.
            if stage == 3, stageDef?.masteryCriteria.requiresVideoRecording == true {
                currentStep = .recordSelf(stage: stage)
            } else {
                currentStep = .stageComplete(stage: stage, xpAwarded: xp)
            }
        } else {
            // Criteria not met yet — send user back to the stage intro so they
            // can re-try remaining drills.
            currentStep = .stageIntro(stage: stage)
        }
    }

    /// After recording (or skipping), complete the final stage via the store
    /// again so the video path is persisted, then advance to mastery.
    func finishRecording(videoPath: String?) async {
        guard case let .recordSelf(stage) = currentStep else { return }
        let result = await store.recordStageConfidence(
            moveId: move.id, stage: stage,
            confidence: progress.stageConfidenceRatings[stage] ?? 5,
            videoPath: videoPath,
            childId: childId
        )
        progress = await store.getProgress(moveId: move.id, childId: childId)
        if result.moveMastered {
            let xp = move.rarity.masteryXP
            _ = await xpStore.addXP(xp, childId: childId)
            currentStep = .mastered(xpAwarded: xp)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            currentStep = .stageComplete(stage: stage, xpAwarded: move.rarity.stageXP)
        }
    }

    func finishAndReturnToOverview() {
        stopTimers()
        currentStep = .overview
    }

    // MARK: - Timers

    private func startCueLoop(stage: Int, drillId: String) {
        cueTimer?.invalidate()
        guard let d = drill(stage: stage, drillId: drillId) else { return }
        let cues = (isYoung ? d.coachCuesYoung : d.coachCues) ?? d.coachCues
        guard !cues.isEmpty else { return }
        // First cue fires immediately so the user sees the coach active.
        currentCue = cues[0]
        voice.speak(cues[0], personality: CoachPersonality.current.rawValue)
        cueTimer = Timer.scheduledTimer(withTimeInterval: 12.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                let pick = cues.randomElement() ?? cues[0]
                self.currentCue = pick
                self.voice.speak(pick, personality: CoachPersonality.current.rawValue)
            }
        }
    }

    private func startMistakeLoop(stage: Int, drillId: String) {
        mistakeTimer?.invalidate()
        guard let d = drill(stage: stage, drillId: drillId) else { return }
        let mistakes = (isYoung ? d.commonMistakesYoung : d.commonMistakes) ?? d.commonMistakes
        guard !mistakes.isEmpty else { return }
        mistakeTimer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.currentMistakeIndex = (self.currentMistakeIndex + 1) % mistakes.count
            }
        }
    }

    private func startElapsedTimer() {
        elapsedTimer?.invalidate()
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.currentDrillTime += 1
            }
        }
    }

    private func stopTimers() {
        cueTimer?.invalidate(); cueTimer = nil
        mistakeTimer?.invalidate(); mistakeTimer = nil
        elapsedTimer?.invalidate(); elapsedTimer = nil
    }

    // MARK: - Lookup helpers

    private func drill(stage: Int, drillId: String) -> MoveDrill? {
        move.stages.first { $0.order == stage }?.drills.first { $0.id == drillId }
    }

    private func nextDrill(in stage: MoveStage, after drillId: String) -> MoveDrill? {
        guard let idx = stage.drills.firstIndex(where: { $0.id == drillId }) else { return nil }
        let nextIdx = idx + 1
        return nextIdx < stage.drills.count ? stage.drills[nextIdx] : nil
    }
}
