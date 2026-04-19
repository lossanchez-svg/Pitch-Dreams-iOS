import Foundation
import CoreGraphics

/// F7 — end-of-lesson comprehension check. 2-3 questions per lesson, not
/// pass/fail. Correct answers award a small XP bonus; wrong answers suggest
/// a replay of a specific step and let the kid try again.
struct LessonQuiz: Equatable {
    let questions: [QuizQuestion]
}

struct QuizQuestion: Identifiable, Equatable {
    let id: String
    let question: String
    let questionYoung: String?
    let type: QuizQuestionType
    /// Step index to replay when the kid gets this wrong. Nil = no replay.
    let suggestedReplayStepIndex: Int?

    init(
        id: String,
        question: String,
        questionYoung: String? = nil,
        type: QuizQuestionType,
        suggestedReplayStepIndex: Int? = nil
    ) {
        self.id = id
        self.question = question
        self.questionYoung = questionYoung
        self.type = type
        self.suggestedReplayStepIndex = suggestedReplayStepIndex
    }

    func preferredQuestion(childAge: Int?) -> String {
        if let age = childAge, age <= 11, let y = questionYoung { return y }
        return question
    }
}

/// Three interaction shapes, each targeting a different learning dimension:
/// - `tapOnPitch`: spatial reasoning ("where should the midfielder go next?")
/// - `tapOnPlayer`: reading the board ("which player has the most space?")
/// - `multipleChoice`: concept recall ("how many times should you scan?")
enum QuizQuestionType: Equatable {
    case tapOnPitch(
        targetX: Double,         // 0-100 percent
        targetY: Double,         // 0-100 percent
        radiusPercent: Double,   // tolerance radius
        referenceDiagram: TacticalDiagramState
    )
    case tapOnPlayer(
        correctPlayerId: String,
        referenceDiagram: TacticalDiagramState
    )
    case multipleChoice(
        options: [QuizOption],
        correctOptionId: String
    )
}

struct QuizOption: Identifiable, Equatable {
    let id: String
    let label: String
    let labelYoung: String?
    let iconSymbolName: String?

    init(id: String, label: String, labelYoung: String? = nil, iconSymbolName: String? = nil) {
        self.id = id
        self.label = label
        self.labelYoung = labelYoung
        self.iconSymbolName = iconSymbolName
    }

    func preferredLabel(childAge: Int?) -> String {
        if let age = childAge, age <= 11, let y = labelYoung { return y }
        return label
    }
}

/// Shape the kid's answer can take. Maps 1:1 to the question type.
enum QuizAnswer: Equatable {
    case tap(CGPoint, pitchSize: CGSize)
    case player(String)
    case option(String)
}

/// Pure evaluator — takes a question + answer, returns whether it's correct.
/// Lifted out of the ViewModel so unit tests can cover it without actor hops.
enum QuizEvaluator {
    static func evaluate(question: QuizQuestion, userAnswer: QuizAnswer) -> Bool {
        switch (question.type, userAnswer) {
        case let (.tapOnPitch(targetX, targetY, radius, _), .tap(point, size)):
            guard size.width > 0, size.height > 0 else { return false }
            let userPctX = Double(point.x / size.width) * 100
            let userPctY = Double(point.y / size.height) * 100
            let dx = userPctX - targetX
            let dy = userPctY - targetY
            return (dx * dx + dy * dy).squareRoot() <= radius
        case let (.tapOnPlayer(correctId, _), .player(tappedId)):
            return correctId == tappedId
        case let (.multipleChoice(_, correctId), .option(chosenId)):
            return correctId == chosenId
        default:
            return false
        }
    }
}

extension AnimatedTacticalLesson {
    /// F7 — associate a quiz with a lesson out-of-band (the main lesson init
    /// stays unchanged). Populated from the registry when authoring.
    /// Returns nil until lesson-specific quizzes are authored.
    var finalQuiz: LessonQuiz? {
        LessonQuizRegistry.quiz(for: id)
    }
}

/// Registry of lesson-to-quiz mappings. Kept separate from the lesson
/// registry so quizzes can ship on a different cadence than lessons.
/// First authored quiz: "3-Point Scan" — establishes the pattern; other
/// lesson quizzes land one-at-a-time afterwards.
enum LessonQuizRegistry {
    private static let quizzes: [String: LessonQuiz] = [
        "3point-scan": threePointScanQuiz
    ]

    static func quiz(for lessonId: String) -> LessonQuiz? {
        quizzes[lessonId]
    }

    // MARK: - 3-Point Scan (first authored)

    private static let threePointScanQuiz = LessonQuiz(questions: [
        QuizQuestion(
            id: "scan-q1",
            question: "How many times should you scan before receiving the ball?",
            questionYoung: "How many times should you look around before the ball gets to you?",
            type: .multipleChoice(
                options: [
                    QuizOption(id: "a", label: "Once", labelYoung: "1 time", iconSymbolName: "1.circle"),
                    QuizOption(id: "b", label: "Twice", labelYoung: "2 times", iconSymbolName: "2.circle"),
                    QuizOption(id: "c", label: "Three times or more", labelYoung: "3 times or more", iconSymbolName: "3.circle"),
                    QuizOption(id: "d", label: "Never", labelYoung: "0 times", iconSymbolName: "xmark.circle"),
                ],
                correctOptionId: "c"
            ),
            suggestedReplayStepIndex: 0
        ),
        QuizQuestion(
            id: "scan-q2",
            question: "What's the danger signal when a center-back steps forward to press?",
            questionYoung: "What happens when a defender runs out to steal the ball from you?",
            type: .multipleChoice(
                options: [
                    QuizOption(id: "a", label: "They close you down — pass backward", labelYoung: "They come close — pass back", iconSymbolName: "arrow.uturn.backward.circle"),
                    QuizOption(id: "b", label: "They leave a gap behind them you can exploit", labelYoung: "They leave a hole behind them", iconSymbolName: "arrow.up.forward.circle"),
                    QuizOption(id: "c", label: "Nothing changes — hold your position", labelYoung: "Nothing happens — stay where you are", iconSymbolName: "equal.circle"),
                    QuizOption(id: "d", label: "You lose the ball automatically", labelYoung: "You lose the ball every time", iconSymbolName: "exclamationmark.circle"),
                ],
                correctOptionId: "b"
            ),
            suggestedReplayStepIndex: 2
        ),
        QuizQuestion(
            id: "scan-q3",
            question: "When should you start scanning: after the ball arrives or before?",
            questionYoung: "When should you look around: after you have the ball or before?",
            type: .multipleChoice(
                options: [
                    QuizOption(id: "a", label: "After you receive — you need the ball first", labelYoung: "After you have the ball", iconSymbolName: "arrow.forward.circle"),
                    QuizOption(id: "b", label: "Only when the coach tells you to", labelYoung: "When someone tells me to", iconSymbolName: "person.wave.2"),
                    QuizOption(id: "c", label: "Before — so your first touch has a plan", labelYoung: "Before — so you already know what to do", iconSymbolName: "arrow.backward.circle"),
                    QuizOption(id: "d", label: "Doesn't matter — just react", labelYoung: "Doesn't matter — just play", iconSymbolName: "questionmark.circle"),
                ],
                correctOptionId: "c"
            ),
            suggestedReplayStepIndex: 0
        )
    ])
}
