import SwiftUI

struct LessonDetailView: View {
    let lesson: TacticalLesson
    let childId: String
    let isCompleted: Bool
    let quizScore: Int?
    let quizTotal: Int?
    let onMarkComplete: () async -> Void

    @State private var isMarking = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header badges
                HStack(spacing: 8) {
                    trackBadge
                    difficultyBadge
                    Spacer()
                    Label("\(lesson.readingTimeMinutes) min read", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Title
                Text(lesson.title)
                    .font(.title.bold())

                if isCompleted {
                    Label("Completed", systemImage: "checkmark.seal.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.green)
                }

                // Description
                Text(lesson.description)
                    .font(.body)
                    .foregroundStyle(.secondary)

                // Learning Steps
                VStack(alignment: .leading, spacing: 12) {
                    Label("Learning Steps", systemImage: "list.number")
                        .font(.headline)

                    ForEach(Array(lesson.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .frame(width: 24, height: 24)
                                .background(trackSwiftUIColor)
                                .clipShape(Circle())

                            Text(step)
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                // Quiz results if available
                if let score = quizScore, let total = quizTotal {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Quiz Result", systemImage: "checkmark.circle.fill")
                            .font(.headline)

                        HStack {
                            Text("\(score)/\(total)")
                                .font(.title2.bold())
                                .foregroundStyle(quizColor(score: score, total: total))
                            Text("correct")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                // Mark Complete button
                if !isCompleted {
                    Button {
                        isMarking = true
                        Task {
                            await onMarkComplete()
                            isMarking = false
                        }
                    } label: {
                        if isMarking {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.green.gradient)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        } else {
                            Label("Mark Complete", systemImage: "checkmark.circle.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.green.gradient)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .disabled(isMarking)
                }
            }
            .padding()
        }
        .navigationTitle(lesson.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Helpers

    private var trackBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: TacticalLessonRegistry.trackIcon(lesson.track))
                .font(.caption2)
            Text(TacticalLessonRegistry.trackDisplayName(lesson.track))
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(trackSwiftUIColor.opacity(0.15))
        .foregroundStyle(trackSwiftUIColor)
        .clipShape(Capsule())
    }

    private var difficultyBadge: some View {
        Text(lesson.difficulty.capitalized)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(difficultyColor.opacity(0.15))
            .foregroundStyle(difficultyColor)
            .clipShape(Capsule())
    }

    private var trackSwiftUIColor: Color {
        switch lesson.track {
        case "scanning": return .cyan
        case "decision_chain": return .purple
        case "tempo": return .orange
        default: return .blue
        }
    }

    private var difficultyColor: Color {
        switch lesson.difficulty {
        case "beginner": return .green
        case "intermediate": return .orange
        case "advanced": return .red
        default: return .secondary
        }
    }

    private func quizColor(score: Int, total: Int) -> Color {
        guard total > 0 else { return .secondary }
        let pct = Double(score) / Double(total)
        if pct >= 0.8 { return .green }
        if pct >= 0.5 { return .orange }
        return .red
    }
}

#Preview {
    NavigationStack {
        LessonDetailView(
            lesson: TacticalLessonRegistry.all.first!,
            childId: "preview-child",
            isCompleted: false,
            quizScore: nil,
            quizTotal: nil,
            onMarkComplete: {}
        )
    }
}
