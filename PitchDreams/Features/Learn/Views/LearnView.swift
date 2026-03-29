import SwiftUI

struct LearnView: View {
    let childId: String
    @StateObject private var viewModel: LearnViewModel

    init(childId: String) {
        self.childId = childId
        _viewModel = StateObject(wrappedValue: LearnViewModel(childId: childId))
    }

    var body: some View {
        List {
            if viewModel.isLoading && viewModel.lessonProgress.isEmpty {
                Section {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
            } else {
                // Progress summary
                Section {
                    HStack {
                        Image(systemName: "book.fill")
                            .foregroundStyle(.cyan)
                        Text("\(viewModel.completedCount) of \(viewModel.totalCount) lessons completed")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                    }
                }

                // Lessons by track
                ForEach(viewModel.lessonsByTrack, id: \.track) { group in
                    Section {
                        ForEach(group.lessons) { enriched in
                            NavigationLink {
                                LessonDetailView(
                                    lesson: enriched.tacticalLesson,
                                    childId: childId,
                                    isCompleted: enriched.isCompleted,
                                    quizScore: enriched.quizScore,
                                    quizTotal: enriched.quizTotal,
                                    onMarkComplete: {
                                        await viewModel.markComplete(lessonId: enriched.id)
                                    }
                                )
                            } label: {
                                lessonCard(enriched)
                            }
                        }
                    } header: {
                        HStack(spacing: 6) {
                            Image(systemName: TacticalLessonRegistry.trackIcon(group.track))
                            Text(TacticalLessonRegistry.trackDisplayName(group.track))
                        }
                    }
                }
            }

            if let error = viewModel.errorMessage {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.subheadline)
                }
            }
        }
        .navigationTitle("Learn")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.loadProgress()
        }
        .task {
            await viewModel.loadProgress()
        }
    }

    // MARK: - Lesson Card

    private func lessonCard(_ enriched: EnrichedLesson) -> some View {
        HStack {
            Image(systemName: enriched.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(enriched.isCompleted ? .green : .secondary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(enriched.tacticalLesson.title)
                    .font(.subheadline.weight(.medium))

                HStack(spacing: 8) {
                    Text(enriched.tacticalLesson.difficulty.capitalized)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(difficultyColor(enriched.tacticalLesson.difficulty).opacity(0.15))
                        .foregroundStyle(difficultyColor(enriched.tacticalLesson.difficulty))
                        .clipShape(Capsule())

                    Label("\(enriched.tacticalLesson.readingTimeMinutes) min", systemImage: "clock")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let score = enriched.quizScore, let total = enriched.quizTotal {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(score)/\(total)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(quizColor(score: score, total: total))
                    Text("Quiz")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Helpers

    private func difficultyColor(_ difficulty: String) -> Color {
        switch difficulty {
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
        LearnView(childId: "preview-child")
    }
}
