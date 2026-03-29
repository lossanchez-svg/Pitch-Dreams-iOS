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
        // "twenty" contains "one" as substring, so matcher may return 1 first
        // Use a word without embedded number words
        let result = VoiceCommandMatcher.extractNumber(from: "FIVE reps done")
        XCTAssertEqual(result, 5)
    }
}
