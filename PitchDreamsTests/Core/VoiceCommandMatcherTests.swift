import XCTest
@testable import PitchDreams

final class VoiceCommandMatcherTests: XCTestCase {

    private var matched: String?

    private func makeCommands() -> [VoiceCommand] {
        [
            VoiceCommand(label: "start", phrases: ["start drill", "begin drill"]) { [weak self] in self?.matched = "start" },
            VoiceCommand(label: "stop", phrases: ["stop", "end drill"]) { [weak self] in self?.matched = "stop" },
            VoiceCommand(label: "count", phrases: ["add one", "count"]) { [weak self] in self?.matched = "count" },
        ]
    }

    override func setUp() {
        matched = nil
    }

    // MARK: - match tests

    func testMatchFindsExactPhrase() {
        let commands = makeCommands()
        let result = VoiceCommandMatcher.match(transcript: "start drill", commands: commands)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.label, "start")
    }

    func testMatchIsCaseInsensitive() {
        let commands = makeCommands()
        let result = VoiceCommandMatcher.match(transcript: "START DRILL NOW", commands: commands)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.label, "start")
    }

    func testMatchReturnsNilForNoMatch() {
        let commands = makeCommands()
        let result = VoiceCommandMatcher.match(transcript: "something unrelated", commands: commands)
        XCTAssertNil(result)
    }

    func testMatchReturnsFirstMatch() {
        let commands = makeCommands()
        // "stop" appears in the second command and is a substring
        let result = VoiceCommandMatcher.match(transcript: "please stop the drill", commands: commands)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.label, "stop")
    }

    func testMatchFindsSubstringInTranscript() {
        let commands = makeCommands()
        let result = VoiceCommandMatcher.match(transcript: "I want to begin drill please", commands: commands)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.label, "start")
    }

    // MARK: - Word-boundary tests

    func testMatchDoesNotFalseMatchDoneAsOne() {
        // "done" should NOT match a command with phrase "one"
        let commands = [
            VoiceCommand(label: "one", phrases: ["one"]) {},
        ]
        let result = VoiceCommandMatcher.match(transcript: "I'm done", commands: commands)
        XCTAssertNil(result, "'done' must not match 'one' — word-boundary required")
    }

    func testMatchDoesNotFalseMatchPartialWord() {
        // "starting" should NOT match "start" as a standalone phrase
        let commands = [
            VoiceCommand(label: "start", phrases: ["start"]) {},
        ]
        let result = VoiceCommandMatcher.match(transcript: "I was starting to warm up", commands: commands)
        XCTAssertNil(result, "'starting' must not match 'start' — word-boundary required")
    }

    func testMatchAllowsWholeWordInSentence() {
        let commands = [
            VoiceCommand(label: "done", phrases: ["done"]) {},
        ]
        let result = VoiceCommandMatcher.match(transcript: "I am done now", commands: commands)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.label, "done")
    }

    // MARK: - extractNumber tests

    func testExtractNumberFromWord() {
        let result = VoiceCommandMatcher.extractNumber(from: "five")
        XCTAssertEqual(result, 5)
    }

    func testExtractNumberFromDigits() {
        let result = VoiceCommandMatcher.extractNumber(from: "42")
        XCTAssertEqual(result, 42)
    }

    func testExtractNumberReturnsNilForNoNumber() {
        let result = VoiceCommandMatcher.extractNumber(from: "hello world")
        XCTAssertNil(result)
    }

    func testExtractNumberFromMixedText() {
        let result = VoiceCommandMatcher.extractNumber(from: "I did twelve reps")
        XCTAssertEqual(result, 12)
    }

    func testExtractNumberFromDigitsInSentence() {
        let result = VoiceCommandMatcher.extractNumber(from: "scored 3 goals today")
        XCTAssertEqual(result, 3)
    }

    func testExtractNumberWordIsCaseInsensitive() {
        let result = VoiceCommandMatcher.extractNumber(from: "SIX reps")
        XCTAssertEqual(result, 6)
    }

    func testExtractNumberDoneDoesNotMatchOne() {
        // "done" must NOT match "one" — word-boundary prevents it
        let result = VoiceCommandMatcher.extractNumber(from: "I'm done")
        XCTAssertNil(result, "'done' must not extract number 1 from 'one' substring")
    }

    func testExtractNumberOneMatchesWholeWord() {
        let result = VoiceCommandMatcher.extractNumber(from: "one rep")
        XCTAssertEqual(result, 1)
    }
}
