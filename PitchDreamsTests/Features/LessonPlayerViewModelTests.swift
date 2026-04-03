import XCTest
@testable import PitchDreams

@MainActor
final class LessonPlayerViewModelTests: XCTestCase {

    private var lesson: AnimatedTacticalLesson {
        AnimatedTacticalLessonRegistry.all.first!
    }

    private func makeVM(voice: MockCoachVoice? = nil) -> (LessonPlayerViewModel, MockCoachVoice) {
        let mock = voice ?? MockCoachVoice()
        let vm = LessonPlayerViewModel(lesson: lesson, voice: mock)
        return (vm, mock)
    }

    // MARK: - Initial State

    func testInitialState() {
        let (vm, _) = makeVM()
        XCTAssertEqual(vm.currentStepIndex, 0)
        XCTAssertTrue(vm.isAutoAdvancing)
        XCTAssertFalse(vm.isCompleted)
        XCTAssertTrue(vm.voiceEnabled)
    }

    // MARK: - goToNext

    func testGoToNextIncrements() {
        let (vm, _) = makeVM()
        vm.goToNext()
        XCTAssertEqual(vm.currentStepIndex, 1)
        XCTAssertFalse(vm.isCompleted)
    }

    func testGoToNextOnLastSetsCompleted() {
        let (vm, _) = makeVM()
        // Navigate to last step
        for _ in 0..<(vm.totalSteps - 1) {
            vm.goToNext()
        }
        XCTAssertEqual(vm.currentStepIndex, vm.totalSteps - 1)

        // One more should complete
        vm.goToNext()
        XCTAssertTrue(vm.isCompleted)
    }

    // MARK: - goToPrevious

    func testGoToPreviousDecrements() {
        let (vm, _) = makeVM()
        vm.goToNext()
        vm.goToNext()
        XCTAssertEqual(vm.currentStepIndex, 2)

        vm.goToPrevious()
        XCTAssertEqual(vm.currentStepIndex, 1)
    }

    func testGoToPreviousOnZeroIsNoOp() {
        let (vm, _) = makeVM()
        vm.goToPrevious()
        XCTAssertEqual(vm.currentStepIndex, 0)
    }

    func testGoToPreviousClearsCompleted() {
        let (vm, _) = makeVM()
        // Go to end
        for _ in 0..<vm.totalSteps {
            vm.goToNext()
        }
        XCTAssertTrue(vm.isCompleted)

        vm.goToPrevious()
        XCTAssertFalse(vm.isCompleted)
    }

    // MARK: - goToStep

    func testGoToStepJumps() {
        let (vm, _) = makeVM()
        vm.goToStep(3)
        XCTAssertEqual(vm.currentStepIndex, 3)
    }

    func testGoToStepClamps() {
        let (vm, _) = makeVM()
        vm.goToStep(100)
        XCTAssertEqual(vm.currentStepIndex, vm.totalSteps - 1)

        vm.goToStep(-5)
        XCTAssertEqual(vm.currentStepIndex, 0)
    }

    func testGoToStepPausesAutoAdvance() {
        let (vm, _) = makeVM()
        XCTAssertTrue(vm.isAutoAdvancing)
        vm.goToStep(2)
        XCTAssertFalse(vm.isAutoAdvancing)
    }

    // MARK: - Toggles

    func testToggleAutoAdvance() {
        let (vm, _) = makeVM()
        XCTAssertTrue(vm.isAutoAdvancing)
        vm.toggleAutoAdvance()
        XCTAssertFalse(vm.isAutoAdvancing)
        vm.toggleAutoAdvance()
        XCTAssertTrue(vm.isAutoAdvancing)
    }

    func testToggleVoice() {
        let (vm, _) = makeVM()
        XCTAssertTrue(vm.voiceEnabled)
        vm.toggleVoice()
        XCTAssertFalse(vm.voiceEnabled)
        vm.toggleVoice()
        XCTAssertTrue(vm.voiceEnabled)
    }

    // MARK: - Progress

    func testProgressFraction() {
        let (vm, _) = makeVM()
        // Step 0 of 5 → 1/5 = 0.2
        XCTAssertEqual(vm.progressFraction, 1.0 / Double(vm.totalSteps), accuracy: 0.01)

        vm.goToNext()
        // Step 1 of 5 → 2/5 = 0.4
        XCTAssertEqual(vm.progressFraction, 2.0 / Double(vm.totalSteps), accuracy: 0.01)
    }

    // MARK: - Voice Integration

    func testSpeakCalledOnGoToNext() {
        let (vm, mock) = makeVM()
        vm.onAppear()  // speaks step 0
        let initialCount = mock.speakCallCount
        vm.goToNext()
        XCTAssertEqual(mock.speakCallCount, initialCount + 1)
    }

    func testSpeakCalledWithNarration() {
        let (vm, mock) = makeVM()
        vm.onAppear()
        XCTAssertEqual(mock.spokenTexts.last, vm.lesson.steps[0].narration)
    }

    func testToggleVoiceOffStopsSpeaking() {
        let mock = MockCoachVoice()
        mock.simulateSpeaking = true
        let (vm, _) = makeVM(voice: mock)
        vm.onAppear()
        XCTAssertTrue(mock.isSpeaking)
        vm.toggleVoice()
        XCTAssertEqual(mock.stopCallCount, 1)
    }
}
