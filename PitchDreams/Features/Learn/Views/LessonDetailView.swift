import SwiftUI

struct LessonDetailView: View {
    let lesson: TacticalLesson
    let childId: String
    let isCompleted: Bool
    let quizScore: Int?
    let quizTotal: Int?
    let onMarkComplete: () async -> Void

    @State private var isMarking = false
    @State private var completedSteps: Set<Int> = []
    @State private var visibleSteps: Set<Int> = []
    @State private var showingLessonPlayer = false
    @State private var showCompletionCelebration = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                startLessonButton
                diagramSection
                stepsSection
                quizSection
                completeButton
            }
            .padding()
        }
        .celebration(isPresented: $showCompletionCelebration)
        .navigationTitle(lesson.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Sections

    @ViewBuilder
    private var headerSection: some View {
        HStack(spacing: 8) {
            trackBadge
            difficultyBadge
            Spacer()
            Label("\(lesson.readingTimeMinutes) min read", systemImage: "clock")
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        Text(lesson.title)
            .font(.title.bold())

        if isCompleted {
            Label("Completed", systemImage: "checkmark.seal.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.dsSecondary)
        }

        Text(lesson.description)
            .font(.body)
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var startLessonButton: some View {
        if TacticalLessonRegistry.animatedLesson(for: lesson.id) != nil {
            Button {
                showingLessonPlayer = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                    Text("Start Lesson")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(trackSwiftUIColor.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .fullScreenCover(isPresented: $showingLessonPlayer) {
                if let animated = TacticalLessonRegistry.animatedLesson(for: lesson.id) {
                    LessonPlayerView(lesson: animated)
                }
            }
        }
    }

    @ViewBuilder
    private var diagramSection: some View {
        if !lesson.diagram.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Label("Tactical View", systemImage: "sportscourt.fill")
                    .font(.headline)
                TacticalPitchView(elements: lesson.diagram)
                    .padding(.bottom, 20)
            }
        }
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Learning Steps", systemImage: "list.number")
                .font(.headline)

            ForEach(Array(lesson.steps.enumerated()), id: \.offset) { index, step in
                stepRow(index: index, step: step)
            }
        }
        .onAppear {
            for index in lesson.steps.indices {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                    withAnimation { _ = visibleSteps.insert(index) }
                }
            }
        }
    }

    private func stepRow(index: Int, step: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if completedSteps.contains(index) {
                    completedSteps.remove(index)
                } else {
                    completedSteps.insert(index)
                }
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(completedSteps.contains(index) ? Color.green : trackSwiftUIColor)
                    .frame(width: 24, height: 24)
                    .overlay {
                        if completedSteps.contains(index) {
                            Image(systemName: "checkmark")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                        } else {
                            Text("\(index + 1)")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                        }
                    }

                Text(step)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(completedSteps.contains(index) ? .secondary : .primary)
                    .strikethrough(completedSteps.contains(index))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .opacity(visibleSteps.contains(index) ? 1 : 0)
        .offset(x: visibleSteps.contains(index) ? 0 : -20)
        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.1), value: visibleSteps)
    }

    @ViewBuilder
    private var quizSection: some View {
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
    }

    @ViewBuilder
    private var completeButton: some View {
        if !isCompleted {
            Button {
                isMarking = true
                Task {
                    await onMarkComplete()
                    MissionsViewModel.shared.recordEvent(.lessonRead, childId: childId)
                    isMarking = false
                    showCompletionCelebration = true
                }
            } label: {
                Group {
                    if isMarking {
                        ProgressView()
                    } else {
                        Label("Mark Complete", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(DSGradient.secondaryCTA)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(isMarking)
        }
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
        case "scanning": return Color.dsSecondary
        case "decision_chain": return Color.dsTertiary
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
