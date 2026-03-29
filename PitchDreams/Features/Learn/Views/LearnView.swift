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
            } else if viewModel.lessonProgress.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "book.closed")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No Lessons Yet")
                            .font(.headline)
                        Text("Start a training arc to unlock lessons.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .listRowBackground(Color.clear)
                }
            } else {
                Section("Lessons") {
                    ForEach(viewModel.lessonProgress) { lesson in
                        lessonRow(lesson)
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

    // MARK: - Lesson Row

    private func lessonRow(_ lesson: LessonProgress) -> some View {
        HStack {
            Image(systemName: lesson.completed ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(lesson.completed ? .green : .secondary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(LessonRegistry.title(for: lesson.lessonId))
                    .font(.subheadline.weight(.medium))
                if lesson.completed {
                    Text("Completed")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else {
                    Text("In Progress")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let score = lesson.quizScore, let total = lesson.quizTotal {
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

    private func formatLessonId(_ id: String) -> String {
        id.replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
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
