import XCTest
@testable import PitchDreams

final class ResetRoutineTests: XCTestCase {

    func testPhaseSequenceAndDurations() {
        let routine = ResetRoutine()
        XCTAssertEqual(routine.phases.map(\.kind), [.breatheIn, .breatheOut, .cue])
        XCTAssertEqual(routine.phases.map(\.duration), [4, 6, 3])
        XCTAssertEqual(routine.totalDuration, 13)
    }

    func testPhaseAtBoundaries() {
        let routine = ResetRoutine()

        XCTAssertEqual(routine.phase(at: 0)?.phase.kind, .breatheIn)
        XCTAssertEqual(routine.phase(at: 3.99)?.phase.kind, .breatheIn)
        XCTAssertEqual(routine.phase(at: 4.0)?.phase.kind, .breatheOut)
        XCTAssertEqual(routine.phase(at: 9.99)?.phase.kind, .breatheOut)
        XCTAssertEqual(routine.phase(at: 10.0)?.phase.kind, .cue)
        XCTAssertEqual(routine.phase(at: 12.99)?.phase.kind, .cue)
        XCTAssertNil(routine.phase(at: 13.0), "Routine is over at total duration")
        XCTAssertNil(routine.phase(at: -1), "Negative elapsed is not a phase")
    }

    func testProgressWithinPhase() {
        let routine = ResetRoutine()

        let midIn = routine.phase(at: 2.0)!
        XCTAssertEqual(midIn.index, 0)
        XCTAssertEqual(midIn.progress, 0.5, accuracy: 0.001)

        let midOut = routine.phase(at: 7.0)!
        XCTAssertEqual(midOut.index, 1)
        XCTAssertEqual(midOut.progress, 0.5, accuracy: 0.001)
    }

    func testCueWordAppearsInPrompt() {
        let routine = ResetRoutine(cueWord: "Next ball")
        let cue = routine.phases.last!
        XCTAssertTrue(cue.prompt.contains("Next ball"))
    }

    func testDefaultCueWordsAvailable() {
        XCTAssertFalse(ResetRoutine.defaultCueWords.isEmpty)
        XCTAssertEqual(ResetRoutine().cueWord, ResetRoutine.defaultCueWords[0])
    }
}
