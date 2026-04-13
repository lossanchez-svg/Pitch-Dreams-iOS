import XCTest
@testable import PitchDreams

/// Integration tests that verify voice commands match correctly across
/// every screen in the training flow. Each test reconstructs the same
/// command arrays the views build and asserts against realistic transcripts.
final class VoiceFlowIntegrationTests: XCTestCase {

    // MARK: - Helpers

    /// Match a transcript against a command array and return the matched label.
    private func matchLabel(_ transcript: String, in commands: [VoiceCommand]) -> String? {
        VoiceCommandMatcher.match(transcript: transcript, commands: commands)?.label
    }

    // =========================================================================
    // MARK: - 1. TrainingSessionView (Check-In Screen)
    // =========================================================================

    /// Commands mirror TrainingSessionView.buildMoodCommands() + buildNavigationCommands()
    private func trainingSessionCommands() -> [VoiceCommand] {
        let moods: [(name: String, label: String)] = [
            ("EXCITED", "Excited"),
            ("FOCUSED", "Focused"),
            ("OKAY", "Okay"),
            ("TIRED", "Tired"),
            ("STRESSED", "Stressed"),
        ]
        var commands = moods.map { mood in
            VoiceCommand(label: mood.label, phrases: [mood.name.lowercased(), mood.label.lowercased()]) {}
        }
        commands += [
            VoiceCommand(label: "Start Training", phrases: ["start training", "start", "let's go", "begin"]) {},
            VoiceCommand(label: "Log Session", phrases: ["log session", "log it", "quick log", "log"]) {},
            VoiceCommand(label: "Mic Off", phrases: ["mic off", "stop listening", "mute mic"]) {},
        ]
        return commands
    }

    func testCheckIn_moodExcited() {
        XCTAssertEqual(matchLabel("I'm feeling excited", in: trainingSessionCommands()), "Excited")
    }

    func testCheckIn_moodFocused() {
        XCTAssertEqual(matchLabel("focused today", in: trainingSessionCommands()), "Focused")
    }

    func testCheckIn_moodTired() {
        XCTAssertEqual(matchLabel("I'm tired", in: trainingSessionCommands()), "Tired")
    }

    func testCheckIn_moodOkay() {
        XCTAssertEqual(matchLabel("okay I guess", in: trainingSessionCommands()), "Okay")
    }

    func testCheckIn_moodStressed() {
        XCTAssertEqual(matchLabel("feeling stressed", in: trainingSessionCommands()), "Stressed")
    }

    func testCheckIn_startTraining() {
        XCTAssertEqual(matchLabel("start training", in: trainingSessionCommands()), "Start Training")
    }

    func testCheckIn_startShortForm() {
        XCTAssertEqual(matchLabel("let's go", in: trainingSessionCommands()), "Start Training")
    }

    func testCheckIn_begin() {
        XCTAssertEqual(matchLabel("begin please", in: trainingSessionCommands()), "Start Training")
    }

    func testCheckIn_logSession() {
        XCTAssertEqual(matchLabel("log session", in: trainingSessionCommands()), "Log Session")
    }

    func testCheckIn_logIt() {
        XCTAssertEqual(matchLabel("log it", in: trainingSessionCommands()), "Log Session")
    }

    func testCheckIn_quickLog() {
        XCTAssertEqual(matchLabel("quick log", in: trainingSessionCommands()), "Log Session")
    }

    func testCheckIn_logAlone() {
        XCTAssertEqual(matchLabel("I want to log", in: trainingSessionCommands()), "Log Session")
    }

    func testCheckIn_micOff() {
        XCTAssertEqual(matchLabel("mic off", in: trainingSessionCommands()), "Mic Off")
    }

    func testCheckIn_stopListening() {
        XCTAssertEqual(matchLabel("stop listening", in: trainingSessionCommands()), "Mic Off")
    }

    func testCheckIn_muteMic() {
        XCTAssertEqual(matchLabel("mute mic", in: trainingSessionCommands()), "Mic Off")
    }

    func testCheckIn_noMatch() {
        XCTAssertNil(matchLabel("hello world", in: trainingSessionCommands()))
    }

    // =========================================================================
    // MARK: - 2. SpaceSelectionView
    // =========================================================================

    private func spaceSelectionCommands() -> [VoiceCommand] {
        [
            VoiceCommand(label: "Small Indoor", phrases: ["small", "bedroom", "hallway"]) {},
            VoiceCommand(label: "Large Indoor", phrases: ["large", "gym", "garage"]) {},
            VoiceCommand(label: "Outdoor", phrases: ["outdoor", "field", "park", "outside"]) {},
            VoiceCommand(label: "Mic Off", phrases: ["mic off", "stop listening", "mute mic"]) {},
        ]
    }

    func testSpace_small() {
        XCTAssertEqual(matchLabel("small space", in: spaceSelectionCommands()), "Small Indoor")
    }

    func testSpace_bedroom() {
        XCTAssertEqual(matchLabel("in my bedroom", in: spaceSelectionCommands()), "Small Indoor")
    }

    func testSpace_hallway() {
        XCTAssertEqual(matchLabel("the hallway", in: spaceSelectionCommands()), "Small Indoor")
    }

    func testSpace_large() {
        XCTAssertEqual(matchLabel("large room", in: spaceSelectionCommands()), "Large Indoor")
    }

    func testSpace_gym() {
        XCTAssertEqual(matchLabel("at the gym", in: spaceSelectionCommands()), "Large Indoor")
    }

    func testSpace_garage() {
        XCTAssertEqual(matchLabel("in the garage", in: spaceSelectionCommands()), "Large Indoor")
    }

    func testSpace_outdoor() {
        XCTAssertEqual(matchLabel("outdoor", in: spaceSelectionCommands()), "Outdoor")
    }

    func testSpace_field() {
        XCTAssertEqual(matchLabel("on the field", in: spaceSelectionCommands()), "Outdoor")
    }

    func testSpace_park() {
        XCTAssertEqual(matchLabel("at the park", in: spaceSelectionCommands()), "Outdoor")
    }

    func testSpace_outside() {
        XCTAssertEqual(matchLabel("I'm outside", in: spaceSelectionCommands()), "Outdoor")
    }

    func testSpace_micOff() {
        XCTAssertEqual(matchLabel("mic off please", in: spaceSelectionCommands()), "Mic Off")
    }

    func testSpace_noMatch() {
        XCTAssertNil(matchLabel("something random", in: spaceSelectionCommands()))
    }

    // Word-boundary: "parking" should NOT match "park"
    func testSpace_parkingDoesNotMatchPark() {
        XCTAssertNil(matchLabel("I'm in the parking lot", in: spaceSelectionCommands()),
                     "'parking' must not match 'park' — word-boundary required")
    }

    // =========================================================================
    // MARK: - 3. ActiveDrillView (Drilling Phase)
    // =========================================================================

    private func activeDrillCommands() -> [VoiceCommand] {
        [
            VoiceCommand(label: "Pause", phrases: ["pause", "hold", "wait"]) {},
            VoiceCommand(label: "Resume", phrases: ["resume", "restart", "continue", "start"]) {},
            VoiceCommand(label: "Done", phrases: ["done", "finish", "complete"]) {},
            VoiceCommand(label: "Next", phrases: ["next", "skip"]) {},
            VoiceCommand(label: "Mic Off", phrases: ["mic off", "stop listening", "mute mic"]) {},
            VoiceCommand(label: "Cancel", phrases: ["cancel", "stop", "quit"]) {},
        ]
    }

    func testDrill_pause() {
        XCTAssertEqual(matchLabel("pause", in: activeDrillCommands()), "Pause")
    }

    func testDrill_hold() {
        XCTAssertEqual(matchLabel("hold on", in: activeDrillCommands()), "Pause")
    }

    func testDrill_wait() {
        XCTAssertEqual(matchLabel("wait a sec", in: activeDrillCommands()), "Pause")
    }

    func testDrill_resume() {
        XCTAssertEqual(matchLabel("resume please", in: activeDrillCommands()), "Resume")
    }

    func testDrill_continue() {
        XCTAssertEqual(matchLabel("continue now", in: activeDrillCommands()), "Resume")
    }

    func testDrill_start() {
        XCTAssertEqual(matchLabel("start", in: activeDrillCommands()), "Resume")
    }

    func testDrill_done() {
        XCTAssertEqual(matchLabel("I'm done", in: activeDrillCommands()), "Done")
    }

    func testDrill_finish() {
        XCTAssertEqual(matchLabel("finish it", in: activeDrillCommands()), "Done")
    }

    func testDrill_complete() {
        XCTAssertEqual(matchLabel("complete", in: activeDrillCommands()), "Done")
    }

    func testDrill_next() {
        XCTAssertEqual(matchLabel("next drill", in: activeDrillCommands()), "Next")
    }

    func testDrill_skip() {
        XCTAssertEqual(matchLabel("skip this one", in: activeDrillCommands()), "Next")
    }

    func testDrill_cancel() {
        XCTAssertEqual(matchLabel("cancel the drill", in: activeDrillCommands()), "Cancel")
    }

    func testDrill_quit() {
        XCTAssertEqual(matchLabel("I quit", in: activeDrillCommands()), "Cancel")
    }

    func testDrill_stop() {
        XCTAssertEqual(matchLabel("stop everything", in: activeDrillCommands()), "Cancel")
    }

    func testDrill_micOff() {
        XCTAssertEqual(matchLabel("mic off", in: activeDrillCommands()), "Mic Off")
    }

    func testDrill_noMatch() {
        XCTAssertNil(matchLabel("hello there", in: activeDrillCommands()))
    }

    // Word-boundary: "starting" should NOT match "start"
    func testDrill_startingDoesNotMatchStart() {
        XCTAssertNil(matchLabel("I was starting to stretch", in: activeDrillCommands()),
                     "'starting' must not match 'start' — word-boundary required")
    }

    // Word-boundary: "done" should NOT false-match rep number "one"
    func testDrill_doneDoesNotExtractNumberOne() {
        let number = VoiceCommandMatcher.extractNumber(from: "I'm done")
        XCTAssertNil(number, "'done' must not extract as number 1")
    }

    // Rep counting with extractNumber
    func testDrill_repCountSpoken() {
        XCTAssertEqual(VoiceCommandMatcher.extractNumber(from: "twelve reps"), 12)
    }

    func testDrill_repCountDigit() {
        XCTAssertEqual(VoiceCommandMatcher.extractNumber(from: "I did 15"), 15)
    }

    func testDrill_repCountFive() {
        XCTAssertEqual(VoiceCommandMatcher.extractNumber(from: "five"), 5)
    }

    func testDrill_repCountTwenty() {
        XCTAssertEqual(VoiceCommandMatcher.extractNumber(from: "twenty"), 20)
    }

    // =========================================================================
    // MARK: - 4. ReflectionView
    // =========================================================================

    /// Base reflection commands (present at all steps)
    private func reflectionBaseCommands() -> [VoiceCommand] {
        [
            VoiceCommand(label: "Next", phrases: ["next", "continue"]) {},
            VoiceCommand(label: "Back", phrases: ["back", "previous"]) {},
            VoiceCommand(label: "Save", phrases: ["save", "done", "finish"]) {},
            VoiceCommand(label: "Mic Off", phrases: ["mic off", "stop listening", "mute mic"]) {},
        ]
    }

    /// Reflection commands at step 3 (mood step) — includes mood options
    private func reflectionMoodStepCommands() -> [VoiceCommand] {
        let moodOptions: [(name: String, label: String)] = [
            ("GREAT", "Great"),
            ("GOOD", "Good"),
            ("OKAY", "Okay"),
            ("TIRED", "Tired"),
            ("OFF", "Off"),
        ]
        var commands = reflectionBaseCommands()
        for mood in moodOptions {
            commands.append(VoiceCommand(label: mood.label, phrases: [mood.label.lowercased(), mood.name.lowercased()]) {})
        }
        return commands
    }

    func testReflection_next() {
        XCTAssertEqual(matchLabel("next", in: reflectionBaseCommands()), "Next")
    }

    func testReflection_continue() {
        XCTAssertEqual(matchLabel("continue please", in: reflectionBaseCommands()), "Next")
    }

    func testReflection_back() {
        XCTAssertEqual(matchLabel("go back", in: reflectionBaseCommands()), "Back")
    }

    func testReflection_previous() {
        XCTAssertEqual(matchLabel("previous step", in: reflectionBaseCommands()), "Back")
    }

    func testReflection_save() {
        XCTAssertEqual(matchLabel("save it", in: reflectionBaseCommands()), "Save")
    }

    func testReflection_done() {
        XCTAssertEqual(matchLabel("I'm done", in: reflectionBaseCommands()), "Save")
    }

    func testReflection_finish() {
        XCTAssertEqual(matchLabel("finish up", in: reflectionBaseCommands()), "Save")
    }

    func testReflection_micOff() {
        XCTAssertEqual(matchLabel("mic off", in: reflectionBaseCommands()), "Mic Off")
    }

    func testReflection_stopListening() {
        XCTAssertEqual(matchLabel("stop listening please", in: reflectionBaseCommands()), "Mic Off")
    }

    func testReflection_muteMic() {
        XCTAssertEqual(matchLabel("mute mic", in: reflectionBaseCommands()), "Mic Off")
    }

    // RPE number extraction (step 0)
    func testReflection_rpeNumber() {
        let number = VoiceCommandMatcher.extractNumber(from: "seven")
        XCTAssertEqual(number, 7)
    }

    func testReflection_rpeNumberInSentence() {
        let number = VoiceCommandMatcher.extractNumber(from: "I'd say about eight")
        XCTAssertEqual(number, 8)
    }

    func testReflection_rpeBoundaryLow() {
        let number = VoiceCommandMatcher.extractNumber(from: "one")
        XCTAssertEqual(number, 1)
    }

    func testReflection_rpeBoundaryHigh() {
        let number = VoiceCommandMatcher.extractNumber(from: "ten")
        XCTAssertEqual(number, 10)
    }

    // Mood matching (step 3 only)
    func testReflection_moodGreat() {
        XCTAssertEqual(matchLabel("feeling great", in: reflectionMoodStepCommands()), "Great")
    }

    func testReflection_moodGood() {
        XCTAssertEqual(matchLabel("pretty good", in: reflectionMoodStepCommands()), "Good")
    }

    func testReflection_moodOkay() {
        XCTAssertEqual(matchLabel("I'm okay", in: reflectionMoodStepCommands()), "Okay")
    }

    func testReflection_moodTired() {
        XCTAssertEqual(matchLabel("I'm tired", in: reflectionMoodStepCommands()), "Tired")
    }

    func testReflection_moodOff() {
        XCTAssertEqual(matchLabel("feeling off today", in: reflectionMoodStepCommands()), "Off")
    }

    // Mood should NOT match at base step (before step 3)
    func testReflection_moodNotAvailableAtBaseStep() {
        XCTAssertNil(matchLabel("feeling great", in: reflectionBaseCommands()),
                     "Mood commands should only be available at step 3")
    }

    func testReflection_noMatch() {
        XCTAssertNil(matchLabel("something random", in: reflectionBaseCommands()))
    }

    // =========================================================================
    // MARK: - 5. Cross-Screen Consistency
    // =========================================================================

    /// "mic off" should work on every screen
    func testMicOff_availableOnAllScreens() {
        let screens: [(String, [VoiceCommand])] = [
            ("TrainingSession", trainingSessionCommands()),
            ("SpaceSelection", spaceSelectionCommands()),
            ("ActiveDrill", activeDrillCommands()),
            ("Reflection", reflectionBaseCommands()),
        ]
        for (screen, commands) in screens {
            XCTAssertEqual(matchLabel("mic off", in: commands), "Mic Off",
                           "Mic Off should be available on \(screen)")
        }
    }

    /// "stop listening" should work on every screen
    func testStopListening_availableOnAllScreens() {
        let screens: [(String, [VoiceCommand])] = [
            ("TrainingSession", trainingSessionCommands()),
            ("SpaceSelection", spaceSelectionCommands()),
            ("ActiveDrill", activeDrillCommands()),
            ("Reflection", reflectionBaseCommands()),
        ]
        for (screen, commands) in screens {
            XCTAssertEqual(matchLabel("stop listening", in: commands), "Mic Off",
                           "Stop Listening should be available on \(screen)")
        }
    }

    /// "mute mic" should work on every screen
    func testMuteMic_availableOnAllScreens() {
        let screens: [(String, [VoiceCommand])] = [
            ("TrainingSession", trainingSessionCommands()),
            ("SpaceSelection", spaceSelectionCommands()),
            ("ActiveDrill", activeDrillCommands()),
            ("Reflection", reflectionBaseCommands()),
        ]
        for (screen, commands) in screens {
            XCTAssertEqual(matchLabel("mute mic", in: commands), "Mic Off",
                           "Mute Mic should be available on \(screen)")
        }
    }

    // =========================================================================
    // MARK: - 6. Full Flow Simulation
    // =========================================================================

    /// Simulates a user speaking through the entire training flow end-to-end.
    func testFullTrainingFlowVoiceProgression() {
        // Step 1: Check-in — say mood
        XCTAssertEqual(matchLabel("I'm feeling focused", in: trainingSessionCommands()), "Focused")

        // Step 2: Check-in — start training
        XCTAssertEqual(matchLabel("start training", in: trainingSessionCommands()), "Start Training")

        // Step 3: Space selection — pick outdoor
        XCTAssertEqual(matchLabel("I'm at the park", in: spaceSelectionCommands()), "Outdoor")

        // Step 4: Active drill — start/resume
        XCTAssertEqual(matchLabel("start", in: activeDrillCommands()), "Resume")

        // Step 5: Active drill — pause
        XCTAssertEqual(matchLabel("hold on", in: activeDrillCommands()), "Pause")

        // Step 6: Active drill — resume
        XCTAssertEqual(matchLabel("continue", in: activeDrillCommands()), "Resume")

        // Step 7: Active drill — record reps
        XCTAssertEqual(VoiceCommandMatcher.extractNumber(from: "twenty"), 20)

        // Step 8: Active drill — finish
        XCTAssertEqual(matchLabel("I'm done", in: activeDrillCommands()), "Done")

        // Step 9: Rep confirm — next
        XCTAssertEqual(matchLabel("next", in: activeDrillCommands()), "Next")

        // Step 10: Reflection — RPE
        XCTAssertEqual(VoiceCommandMatcher.extractNumber(from: "seven"), 7)

        // Step 11: Reflection — advance steps
        XCTAssertEqual(matchLabel("next", in: reflectionBaseCommands()), "Next")
        XCTAssertEqual(matchLabel("next", in: reflectionBaseCommands()), "Next")
        XCTAssertEqual(matchLabel("next", in: reflectionBaseCommands()), "Next")

        // Step 12: Reflection — set mood (step 3)
        XCTAssertEqual(matchLabel("feeling great", in: reflectionMoodStepCommands()), "Great")

        // Step 13: Reflection — save
        XCTAssertEqual(matchLabel("save", in: reflectionMoodStepCommands()), "Save")
    }

    /// Simulates a user who wants to log an external session instead of training in-app.
    func testLogExternalSessionVoiceFlow() {
        // Step 1: Check-in — say mood
        XCTAssertEqual(matchLabel("okay", in: trainingSessionCommands()), "Okay")

        // Step 2: Navigate to activity log
        XCTAssertEqual(matchLabel("log session", in: trainingSessionCommands()), "Log Session")
    }

    /// Simulates a user cancelling mid-drill.
    func testCancelMidDrillVoiceFlow() {
        // Step 1: Check-in
        XCTAssertEqual(matchLabel("excited", in: trainingSessionCommands()), "Excited")

        // Step 2: Start training
        XCTAssertEqual(matchLabel("let's go", in: trainingSessionCommands()), "Start Training")

        // Step 3: Pick space
        XCTAssertEqual(matchLabel("gym", in: spaceSelectionCommands()), "Large Indoor")

        // Step 4: Start drill, then cancel
        XCTAssertEqual(matchLabel("start", in: activeDrillCommands()), "Resume")
        XCTAssertEqual(matchLabel("cancel", in: activeDrillCommands()), "Cancel")
    }
}
