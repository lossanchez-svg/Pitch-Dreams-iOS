import XCTest
import CoreGraphics
@testable import PitchDreams

final class QuizEvaluatorTests: XCTestCase {

    // MARK: - Multiple choice

    func testMultipleChoice_correctOption() {
        let question = QuizQuestion(
            id: "q",
            question: "How many?",
            type: .multipleChoice(
                options: [
                    QuizOption(id: "a", label: "1"),
                    QuizOption(id: "b", label: "2"),
                    QuizOption(id: "c", label: "3")
                ],
                correctOptionId: "b"
            )
        )
        XCTAssertTrue(QuizEvaluator.evaluate(question: question, userAnswer: .option("b")))
    }

    func testMultipleChoice_wrongOption() {
        let question = QuizQuestion(
            id: "q",
            question: "How many?",
            type: .multipleChoice(
                options: [QuizOption(id: "a", label: "1"), QuizOption(id: "b", label: "2")],
                correctOptionId: "b"
            )
        )
        XCTAssertFalse(QuizEvaluator.evaluate(question: question, userAnswer: .option("a")))
    }

    func testMultipleChoice_answerTypeMismatch_returnsFalse() {
        // Tap answer on a multiple-choice question is nonsense → false.
        let question = QuizQuestion(
            id: "q",
            question: "How many?",
            type: .multipleChoice(
                options: [QuizOption(id: "a", label: "1")],
                correctOptionId: "a"
            )
        )
        let size = CGSize(width: 100, height: 100)
        XCTAssertFalse(QuizEvaluator.evaluate(
            question: question,
            userAnswer: .tap(CGPoint(x: 50, y: 50), pitchSize: size)
        ))
    }

    // MARK: - Tap on player

    func testTapOnPlayer_correctId() {
        let question = QuizQuestion(
            id: "q",
            question: "Tap the striker",
            type: .tapOnPlayer(
                correctPlayerId: "striker",
                referenceDiagram: TacticalDiagramState()
            )
        )
        XCTAssertTrue(QuizEvaluator.evaluate(question: question, userAnswer: .player("striker")))
    }

    func testTapOnPlayer_wrongId() {
        let question = QuizQuestion(
            id: "q",
            question: "Tap the striker",
            type: .tapOnPlayer(correctPlayerId: "striker", referenceDiagram: TacticalDiagramState())
        )
        XCTAssertFalse(QuizEvaluator.evaluate(question: question, userAnswer: .player("keeper")))
    }

    // MARK: - Tap on pitch

    func testTapOnPitch_withinRadius_correct() {
        // Target at (50, 50), 10% radius. Tap within 5 pts of target on a
        // 100x100 canvas is at ~5% offset — well inside the radius.
        let question = QuizQuestion(
            id: "q",
            question: "Tap the midfielder's next spot",
            type: .tapOnPitch(
                targetX: 50, targetY: 50,
                radiusPercent: 10,
                referenceDiagram: TacticalDiagramState()
            )
        )
        let size = CGSize(width: 100, height: 100)
        XCTAssertTrue(QuizEvaluator.evaluate(
            question: question,
            userAnswer: .tap(CGPoint(x: 52, y: 48), pitchSize: size)
        ))
    }

    func testTapOnPitch_outsideRadius_wrong() {
        let question = QuizQuestion(
            id: "q",
            question: "Tap the midfielder's next spot",
            type: .tapOnPitch(
                targetX: 50, targetY: 50,
                radiusPercent: 5,
                referenceDiagram: TacticalDiagramState()
            )
        )
        // Tap at (80, 80) on a 100pt canvas = 80% pct; 30pt away from 50%
        // → well outside a 5% tolerance.
        let size = CGSize(width: 100, height: 100)
        XCTAssertFalse(QuizEvaluator.evaluate(
            question: question,
            userAnswer: .tap(CGPoint(x: 80, y: 80), pitchSize: size)
        ))
    }

    func testTapOnPitch_zeroSize_returnsFalseInsteadOfDividingByZero() {
        let question = QuizQuestion(
            id: "q",
            question: "Tap",
            type: .tapOnPitch(
                targetX: 50, targetY: 50,
                radiusPercent: 10,
                referenceDiagram: TacticalDiagramState()
            )
        )
        XCTAssertFalse(QuizEvaluator.evaluate(
            question: question,
            userAnswer: .tap(CGPoint(x: 50, y: 50), pitchSize: .zero)
        ))
    }

    // MARK: - Age-adaptive copy resolvers

    func testQuestionYoung_fallsBackWhenAgeOver11() {
        let question = QuizQuestion(
            id: "q",
            question: "Standard wording",
            questionYoung: "Simpler wording",
            type: .multipleChoice(options: [], correctOptionId: "")
        )
        XCTAssertEqual(question.preferredQuestion(childAge: 14), "Standard wording")
    }

    func testQuestionYoung_picksYoungForAgeUnder12() {
        let question = QuizQuestion(
            id: "q",
            question: "Standard wording",
            questionYoung: "Simpler wording",
            type: .multipleChoice(options: [], correctOptionId: "")
        )
        XCTAssertEqual(question.preferredQuestion(childAge: 9), "Simpler wording")
    }

    func testQuestionYoung_fallsBackWhenYoungAbsent() {
        let question = QuizQuestion(
            id: "q",
            question: "Only version",
            type: .multipleChoice(options: [], correctOptionId: "")
        )
        XCTAssertEqual(question.preferredQuestion(childAge: 9), "Only version")
    }

    func testOptionLabel_youngVariant() {
        let option = QuizOption(id: "a", label: "Three times or more", labelYoung: "3 times or more")
        XCTAssertEqual(option.preferredLabel(childAge: 8), "3 times or more")
        XCTAssertEqual(option.preferredLabel(childAge: 15), "Three times or more")
    }

    // MARK: - Registry

    func testRegistry_returnsThreePointScanQuiz() {
        let quiz = LessonQuizRegistry.quiz(for: "3point-scan")
        XCTAssertNotNil(quiz)
        XCTAssertEqual(quiz?.questions.count, 3)
    }

    func testRegistry_nilForUnknownLesson() {
        XCTAssertNil(LessonQuizRegistry.quiz(for: "does-not-exist"))
    }

    func testRegistry_threePointScanFirstQuestionCorrectAnswerIsC() {
        // Sanity-check the authored content itself: "three or more" is the
        // right answer to the scan count question.
        guard let quiz = LessonQuizRegistry.quiz(for: "3point-scan"),
              let first = quiz.questions.first else {
            return XCTFail("Expected 3point-scan quiz")
        }
        switch first.type {
        case let .multipleChoice(_, correctOptionId):
            XCTAssertEqual(correctOptionId, "c")
        default:
            XCTFail("Expected multipleChoice type")
        }
    }
}
