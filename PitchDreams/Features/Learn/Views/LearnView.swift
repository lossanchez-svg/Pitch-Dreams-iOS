import SwiftUI

struct LearnView: View {
    let childId: String
    @StateObject private var viewModel: LearnViewModel

    init(childId: String) {
        self.childId = childId
        _viewModel = StateObject(wrappedValue: LearnViewModel(childId: childId))
    }

    var body: some View {
        ZStack {
            Color.dsBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    if viewModel.isLoading && viewModel.lessonProgress.isEmpty {
                        ForEach(0..<4, id: \.self) { _ in
                            HStack(spacing: 12) {
                                SkeletonView(width: 28, height: 28)
                                VStack(alignment: .leading, spacing: 6) {
                                    SkeletonView(width: 160, height: 14)
                                    SkeletonView(width: 100, height: 10)
                                }
                                Spacer()
                            }
                            .padding(Spacing.lg)
                            .background(Color.dsSurfaceContainer)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                        }
                    } else {
                        // Progress summary
                        HStack(spacing: 10) {
                            Image(systemName: "book.fill")
                                .foregroundStyle(Color.dsSecondary)
                            Text("\(viewModel.completedCount) of \(viewModel.totalCount) lessons completed")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color.dsOnSurface)
                            Spacer()
                        }
                        .padding(Spacing.lg)
                        .background(Color.dsSurfaceContainer)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                        .ghostBorder()

                        // Lessons by track
                        ForEach(viewModel.lessonsByTrack, id: \.track) { group in
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                HStack(spacing: 6) {
                                    Image(systemName: TacticalLessonRegistry.trackIcon(group.track))
                                        .foregroundStyle(trackColor(group.track))
                                    Text(TacticalLessonRegistry.trackDisplayName(group.track).uppercased())
                                        .font(.system(size: 11, weight: .heavy))
                                        .tracking(2)
                                        .foregroundStyle(trackColor(group.track))
                                }
                                .padding(.top, 8)

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
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    if let error = viewModel.errorMessage {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .foregroundStyle(Color.dsError)
                    }
                }
                .padding(Spacing.xl)
                .padding(.bottom, 100)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.dsBackground, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Text("LEARN")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color.dsSecondary)
            }
        }
        .refreshable {
            await viewModel.loadProgress()
        }
        .task {
            await viewModel.loadProgress()
        }
    }

    private func lessonCard(_ enriched: EnrichedLesson) -> some View {
        HStack(spacing: 14) {
            Image(systemName: enriched.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22))
                .foregroundStyle(enriched.isCompleted ? Color.dsSecondary : Color.dsSurfaceContainerHighest)

            VStack(alignment: .leading, spacing: 4) {
                Text(enriched.tacticalLesson.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.dsOnSurface)

                HStack(spacing: 8) {
                    Text(enriched.tacticalLesson.difficulty.capitalized)
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.5)
                        .foregroundStyle(difficultyColor(enriched.tacticalLesson.difficulty))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(difficultyColor(enriched.tacticalLesson.difficulty).opacity(0.15))
                        .clipShape(Capsule())

                    HStack(spacing: 3) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text("\(enriched.tacticalLesson.readingTimeMinutes) min")
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(Color.dsOnSurfaceVariant)
                }
            }

            Spacer()

            if let score = enriched.quizScore, let total = enriched.quizTotal {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(score)/\(total)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(quizColor(score: score, total: total))
                    Text("QUIZ")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                }
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
            }
        }
        .padding(Spacing.lg)
        .background(Color.dsSurfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
    }

    // MARK: - Helpers

    private func trackColor(_ track: String) -> Color {
        switch track {
        case "scanning": return Color.dsSecondary
        case "decision_chain": return Color(hex: "#8B5CF6")
        case "tempo": return Color.dsAccentOrange
        default: return Color.dsSecondary
        }
    }

    private func difficultyColor(_ difficulty: String) -> Color {
        switch difficulty {
        case "beginner": return Color.dsSecondary
        case "intermediate": return Color.dsAccentOrange
        case "advanced": return Color.dsError
        default: return Color.dsOnSurfaceVariant
        }
    }

    private func quizColor(score: Int, total: Int) -> Color {
        guard total > 0 else { return Color.dsOnSurfaceVariant }
        let pct = Double(score) / Double(total)
        if pct >= 0.8 { return Color.dsSecondary }
        if pct >= 0.5 { return Color.dsAccentOrange }
        return Color.dsError
    }
}

#Preview {
    NavigationStack {
        LearnView(childId: "preview-child")
    }
}
