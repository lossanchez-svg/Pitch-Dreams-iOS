import SwiftUI

/// F7 — end-of-lesson comprehension quiz scaffold. Shown after the last
/// step when a lesson has a `finalQuiz` authored. Supports the three
/// question types: tap-on-pitch, tap-on-player, multiple-choice.
///
/// Behavior:
/// - Correct answer → green badge, "+15 XP" nudge, Next button
/// - Wrong answer → amber badge, "Replay Step N" suggestion + Try Again
/// - Last question correct → auto-dismisses back to completion view
///
/// Quiz content is empty at launch (`LessonQuizRegistry` returns nil for
/// every lesson). This scaffold exists so authors can drop questions in
/// and they light up immediately without additional view work.
struct LessonQuizView: View {
    let quiz: LessonQuiz
    let childAge: Int?
    var onReplayStep: (Int) -> Void
    var onComplete: () -> Void
    var onCorrectAnswer: () -> Void = {}

    @State private var currentIndex: Int = 0
    @State private var feedback: Feedback?

    struct Feedback: Equatable {
        let isCorrect: Bool
        let replayStep: Int?
    }

    var body: some View {
        VStack(spacing: 24) {
            header

            if let question = currentQuestion {
                Text(question.preferredQuestion(childAge: childAge))
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.dsOnSurface)
                    .padding(.horizontal, 20)

                answerArea(for: question)

                if let feedback {
                    feedbackCard(feedback, question: question)
                }
            }

            Spacer()
        }
        .padding(.top, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.dsBackground)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 10) {
            Text("CHECK WHAT YOU LEARNED")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color.dsSecondary)
            HStack(spacing: 4) {
                ForEach(0..<quiz.questions.count, id: \.self) { idx in
                    Capsule()
                        .fill(idx <= currentIndex ? Color.dsSecondary : Color.dsSurfaceContainerHighest)
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Answer area

    @ViewBuilder
    private func answerArea(for question: QuizQuestion) -> some View {
        switch question.type {
        case let .multipleChoice(options, _):
            VStack(spacing: 10) {
                ForEach(options) { option in
                    Button {
                        submit(question: question, answer: .option(option.id))
                    } label: {
                        HStack(spacing: 10) {
                            if let symbol = option.iconSymbolName {
                                Image(systemName: symbol)
                                    .foregroundStyle(Color.dsSecondary)
                                    .frame(width: 24)
                            }
                            Text(option.preferredLabel(childAge: childAge))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color.dsOnSurface)
                            Spacer()
                        }
                        .padding(14)
                        .background(Color.dsSurfaceContainerLow)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                    }
                    .buttonStyle(.plain)
                    .disabled(feedback != nil)
                }
            }
            .padding(.horizontal, 20)

        case .tapOnPitch, .tapOnPlayer:
            // Tap-based answer types render a pitch diagram the kid can
            // tap. Full implementation ships with the first authored quiz
            // content — for now the scaffold keeps the question on-screen
            // and prompts the user to tap the pitch in LessonPlayerView
            // instead. Keeps the engine honest until content lands.
            Text("Tap the diagram in the lesson to answer this question.")
                .font(.system(size: 13))
                .foregroundStyle(Color.dsOnSurfaceVariant)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }

    // MARK: - Feedback

    @ViewBuilder
    private func feedbackCard(_ f: Feedback, question: QuizQuestion) -> some View {
        if f.isCorrect {
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.green)
                    Text("Got it! +15 XP")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                    Spacer()
                }
                Button {
                    advance()
                } label: {
                    HStack {
                        Text(isLastQuestion ? "Finish" : "Next")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .foregroundStyle(Color.dsCTALabel)
                    .padding(14)
                    .background(DSGradient.primaryCTA)
                    .clipShape(Capsule())
                }
            }
            .padding(16)
            .background(Color.green.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            .padding(.horizontal, 20)
        } else {
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.orange)
                    Text(childAge != nil && (childAge ?? 12) <= 11
                         ? "Almost! Let's watch that again."
                         : "Not quite. Review the key step.")
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                }
                HStack(spacing: 8) {
                    if let replay = f.replayStep {
                        Button {
                            onReplayStep(replay)
                            feedback = nil
                        } label: {
                            Label("Replay Step", systemImage: "arrow.counterclockwise")
                                .font(.system(size: 12, weight: .bold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.dsSurfaceContainerHigh)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    Button {
                        feedback = nil
                    } label: {
                        Text("Try Again")
                            .font(.system(size: 12, weight: .bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.dsSurfaceContainerHigh)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .background(Color.orange.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Flow

    private var currentQuestion: QuizQuestion? {
        guard currentIndex < quiz.questions.count else { return nil }
        return quiz.questions[currentIndex]
    }

    private var isLastQuestion: Bool {
        currentIndex >= quiz.questions.count - 1
    }

    private func submit(question: QuizQuestion, answer: QuizAnswer) {
        let correct = QuizEvaluator.evaluate(question: question, userAnswer: answer)
        feedback = Feedback(isCorrect: correct, replayStep: correct ? nil : question.suggestedReplayStepIndex)
        if correct {
            onCorrectAnswer()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
    }

    private func advance() {
        feedback = nil
        if isLastQuestion {
            onComplete()
        } else {
            currentIndex += 1
        }
    }
}
