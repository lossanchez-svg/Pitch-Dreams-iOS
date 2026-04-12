import Foundation
import Combine

@MainActor
final class LessonPlayerViewModel: ObservableObject {
    let lesson: AnimatedTacticalLesson

    @Published var currentStepIndex: Int = 0
    @Published var isAutoAdvancing: Bool = true
    @Published var isCompleted: Bool = false
    @Published var voiceEnabled: Bool = true

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

    // MARK: - Init

    init(lesson: AnimatedTacticalLesson, voice: CoachVoiceProtocol? = nil) {
        self.lesson = lesson
        self.voice = voice
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
        voice.speak(currentStep.narration, personality: CoachPersonality.current.rawValue)
    }
}
