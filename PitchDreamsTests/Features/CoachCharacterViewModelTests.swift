import XCTest
@testable import PitchDreams

@MainActor
final class CoachCharacterViewModelTests: XCTestCase {

    func testInitialMoodIsIdle() {
        let vm = CoachCharacterViewModel()
        XCTAssertEqual(vm.mood, .idle)
        XCTAssertFalse(vm.isSpeaking)
        XCTAssertTrue(vm.speechText.isEmpty)
    }

    func testSpeakSetsMoodAndText() {
        let vm = CoachCharacterViewModel()
        vm.speak("Hello player!")
        XCTAssertEqual(vm.mood, .speaking)
        XCTAssertEqual(vm.speechText, "Hello player!")
        XCTAssertTrue(vm.isSpeaking)
    }

    func testStopSpeakingClearsMoodAndText() {
        let vm = CoachCharacterViewModel()
        vm.speak("Testing")
        vm.stopSpeaking()
        XCTAssertEqual(vm.mood, .idle)
        XCTAssertTrue(vm.speechText.isEmpty)
        XCTAssertFalse(vm.isSpeaking)
    }

    func testListenSetsMood() {
        let vm = CoachCharacterViewModel()
        vm.listen()
        XCTAssertEqual(vm.mood, .listening)
        XCTAssertFalse(vm.isSpeaking)
    }

    func testSetMoodEncouraging() {
        let vm = CoachCharacterViewModel()
        vm.setMood(.encouraging)
        XCTAssertEqual(vm.mood, .encouraging)
    }

    func testSetMoodCelebrating() {
        let vm = CoachCharacterViewModel()
        vm.setMood(.celebrating)
        XCTAssertEqual(vm.mood, .celebrating)
    }

    func testRapidMoodChangesUseLatest() {
        let vm = CoachCharacterViewModel()
        vm.setMood(.encouraging)
        vm.setMood(.celebrating)
        vm.setMood(.skeptical)
        XCTAssertEqual(vm.mood, .skeptical)
    }

    func testSpeakAfterListenOverrides() {
        let vm = CoachCharacterViewModel()
        vm.listen()
        vm.speak("Now speaking")
        XCTAssertEqual(vm.mood, .speaking)
        XCTAssertEqual(vm.speechText, "Now speaking")
        XCTAssertTrue(vm.isSpeaking)
    }

    func testEncouragingAutoReturnsToIdle() async throws {
        let vm = CoachCharacterViewModel()
        vm.setMood(.encouraging, duration: 0.1)
        XCTAssertEqual(vm.mood, .encouraging)

        try await Task.sleep(for: .milliseconds(200))
        XCTAssertEqual(vm.mood, .idle)
    }
}
