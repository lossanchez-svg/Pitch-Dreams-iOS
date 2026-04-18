import Foundation
import Combine

@MainActor
final class LessonPlayerViewModel: ObservableObject {
    let lesson: AnimatedTacticalLesson

    @Published var currentStepIndex: Int = 0
    @Published var isAutoAdvancing: Bool = true
    @Published var isCompleted: Bool = false
    @Published var voiceEnabled: Bool = true
    /// F4 — when true, animations + narration pace are halved. Users toggle
    /// this from the lesson player's slow-mo button to re-watch a step at
    /// 0.5× without losing context.
    @Published var isSlowMo: Bool = false

    /// F2 — the child's age (optional). Drives `preferredNarration` selection:
    /// ages ≤ 11 get the `narrationYoung` variant when authored.
    private(set) var childAge: Int?

    private(set) var voice: CoachVoiceProtocol?
    private var autoAdvanceTask: Task<Void, Never>?

    // MARK: - Computed

    var currentStep: TacticalStep {
        lesson.steps[currentStepIndex]
    }

    var totalSteps: Int {
        lesson.steps.count
    }

    var progressFraction: Double {
        guard totalSteps > 0 else { return 0 }
        return Double(currentStepIndex + 1) / Double(totalSteps)
    }

    /// Effective animation rate: 1.0 normal, 0.5 in slow-mo.
    var animationRate: Double {
        isSlowMo ? 0.5 : 1.0
    }

    /// F2 — narration text that should actually be spoken for this child.
    /// Falls back to `narration` when no young variant exists or the child
    /// is over 11.
    var currentNarrationText: String {
        currentStep.preferredNarration(childAge: childAge)
    }

    /// F1 — caption shown during the spotlight phase, age-resolved.
    var currentSpotlightCaption: String? {
        currentStep.preferredSpotlightCaption(childAge: childAge)
    }

    // MARK: - Init

    init(
        lesson: AnimatedTacticalLesson,
        childAge: Int? = nil,
        voice: CoachVoiceProtocol? = nil
    ) {
        self.lesson = lesson
        self.childAge = childAge
        self.voice = voice
    }

    /// Set child age after init (used when the profile loads asynchronously
    /// from the host view).
    func setChildAge(_ age: Int?) {
        childAge = age
    }

    /// Set voice after init (needed when @StateObject creates the voice separately).
    func setVoice(_ voice: CoachVoiceProtocol) {
        self.voice = voice
    }

    // MARK: - Navigation

    func goToNext() {
        cancelAutoAdvance()
        if currentStepIndex < totalSteps - 1 {
            currentStepIndex += 1
            speakCurrentStep()
            scheduleAutoAdvanceIfNeeded()
        } else {
            isCompleted = true
            voice?.stop()
        }
    }

    func goToPrevious() {
        cancelAutoAdvance()
        guard currentStepIndex > 0 else { return }
        isCompleted = false
        currentStepIndex -= 1
        speakCurrentStep()
        scheduleAutoAdvanceIfNeeded()
    }

    func goToStep(_ index: Int) {
        cancelAutoAdvance()
        let clamped = max(0, min(totalSteps - 1, index))
        currentStepIndex = clamped
        isCompleted = false
        isAutoAdvancing = false  // Manual jump pauses auto-advance
        speakCurrentStep()
    }

    // MARK: - Toggles

    func toggleAutoAdvance() {
        isAutoAdvancing.toggle()
        if isAutoAdvancing {
            scheduleAutoAdvanceIfNeeded()
        } else {
            cancelAutoAdvance()
        }
    }

    func toggleVoice() {
        voiceEnabled.toggle()
        if !voiceEnabled {
            voice?.stop()
        } else {
            speakCurrentStep()
        }
    }

    /// F4 — toggle slow-motion. When enabled, auto-advance is disabled so the
    /// user can savor the step, and the narration is re-spoken at half speed.
    func toggleSlowMo() {
        isSlowMo.toggle()
        if isSlowMo {
            // Pause auto-advance so a slow-mo step doesn't get interrupted.
            isAutoAdvancing = false
            cancelAutoAdvance()
        }
        // Re-speak the current step at the new rate so the audio matches.
        speakCurrentStep()
    }

    // MARK: - Lifecycle

    func onAppear() {
        speakCurrentStep()
        scheduleAutoAdvanceIfNeeded()
    }

    func onDisappear() {
        cancelAutoAdvance()
        voice?.stop()
    }

    // MARK: - Auto-advance

    private func scheduleAutoAdvanceIfNeeded() {
        cancelAutoAdvance()
        guard isAutoAdvancing, !isCompleted else { return }

        let step = currentStep
        autoAdvanceTask = Task { [weak self] in
            // Wait for step duration
            try? await Task.sleep(for: .seconds(step.duration))
            guard !Task.isCancelled else { return }

            // If voice is speaking, wait for it to finish
            if let voice = self?.voice, self?.voiceEnabled == true {
                while voice.isSpeaking {
                    try? await Task.sleep(for: .milliseconds(200))
                    guard !Task.isCancelled else { return }
                }
            }

            self?.goToNext()
        }
    }

    private func cancelAutoAdvance() {
        autoAdvanceTask?.cancel()
        autoAdvanceTask = nil
    }

    // MARK: - Voice

    private func speakCurrentStep() {
        guard voiceEnabled, let voice else { return }
        voice.speak(
            currentNarrationText,
            personality: CoachPersonality.current.rawValue,
            rate: isSlowMo ? 0.5 : 1.0
        )
    }
}
