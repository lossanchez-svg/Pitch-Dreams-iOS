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
                VStack(spacing: Spacing.xl) {
                    if viewModel.isLoading && viewModel.lessonProgress.isEmpty {
                        ForEach(0..<4, id: \.self) { _ in
                            SkeletonView(height: 70)
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                        }
                    } else {
                        // Hero progress card
                        progressSummary

                        // Lessons by track
                        ForEach(viewModel.lessonsByTrack, id: \.track) { group in
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                // Track header
                                HStack(spacing: 8) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(trackColor(group.track))
                                        .frame(width: 4, height: 20)
                                    Image(systemName: TacticalLessonRegistry.trackIcon(group.track))
                                        .foregroundStyle(trackColor(group.track))
                                    Text(TacticalLessonRegistry.trackDisplayName(group.track).uppercased())
                                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                                        .tracking(2)
                                        .foregroundStyle(trackColor(group.track))
                                    Spacer()
                                    let trackCompleted = group.lessons.filter(\.isCompleted).count
                                    Text("\(trackCompleted)/\(group.lessons.count)")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color.dsOnSurfaceVariant)
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
                                        lessonCard(enriched, trackColor: trackColor(group.track))
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

    // MARK: - Progress Summary

    private var progressSummary: some View {
        VStack(spacing: Spacing.lg) {
            HStack(spacing: Spacing.lg) {
                // Completion ring
                ZStack {
                    Circle()
                        .stroke(Color.dsSurfaceContainerHighest, lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: completionProgress)
                        .stroke(
                            Color.dsSecondary,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text("\(viewModel.completedCount)")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.dsOnSurface)
                        Text("/\(viewModel.totalCount)")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.dsOnSurfaceVariant)
                    }
                }
                .frame(width: 72, height: 72)

                VStack(alignment: .leading, spacing: 4) {
                    Text("LESSON PROGRESS")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                    Text("\(viewModel.completedCount) of \(viewModel.totalCount) complete")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.dsOnSurface)

                    if viewModel.totalCount > 0 {
                        Text("\(Int(completionProgress * 100))% mastery")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.dsSecondary)
                    }
                }

                Spacer()
            }
        }
        .padding(Spacing.xl)
        .background(Color.dsSurfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .ghostBorder()
    }

    private var completionProgress: Double {
        guard viewModel.totalCount > 0 else { return 0 }
        return Double(viewModel.completedCount) / Double(viewModel.totalCount)
    }

    // MARK: - Lesson Card

    private func lessonCard(_ enriched: EnrichedLesson, trackColor: Color) -> some View {
        HStack(spacing: 14) {
            // Completion indicator
            ZStack {
                Circle()
                    .fill(enriched.isCompleted ? trackColor.opacity(0.15) : Color.dsSurfaceContainerHighest)
                    .frame(width: 40, height: 40)
                Image(systemName: enriched.isCompleted ? "checkmark" : "play.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(enriched.isCompleted ? trackColor : Color.dsOnSurfaceVariant)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(enriched.tacticalLesson.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.dsOnSurface)
                    .lineLimit(1)

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
