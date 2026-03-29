import Foundation

struct EnrichedLesson: Identifiable {
    let id: String
    let tacticalLesson: TacticalLesson
    let progress: LessonProgress?

    var isCompleted: Bool { progress?.completed ?? false }
    var quizScore: Int? { progress?.quizScore }
    var quizTotal: Int? { progress?.quizTotal }
}

@MainActor
final class LearnViewModel: ObservableObject {
    @Published var lessonProgress: [LessonProgress] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    let childId: String
    private let apiClient: APIClientProtocol

    init(childId: String, apiClient: APIClientProtocol = APIClient()) {
        self.childId = childId
        self.apiClient = apiClient
    }

    /// All lessons from the registry enriched with progress data
    var enrichedLessons: [EnrichedLesson] {
        TacticalLessonRegistry.all.map { lesson in
            let progress = lessonProgress.first { $0.lessonId == lesson.id }
            return EnrichedLesson(id: lesson.id, tacticalLesson: lesson, progress: progress)
        }
    }

    /// Lessons grouped by track
    var lessonsByTrack: [(track: String, lessons: [EnrichedLesson])] {
        TacticalLessonRegistry.tracks.compactMap { track in
            let lessons = enrichedLessons.filter { $0.tacticalLesson.track == track }
            guard !lessons.isEmpty else { return nil }
            return (track: track, lessons: lessons)
        }
    }

    var completedCount: Int {
        enrichedLessons.filter(\.isCompleted).count
    }

    var totalCount: Int {
        enrichedLessons.count
    }

    func loadProgress() async {
        isLoading = true
        errorMessage = nil
        do {
            lessonProgress = try await apiClient.request(
                APIRouter.lessonProgress(childId: childId)
            )
        } catch {
            errorMessage = "Could not load lesson progress."
        }
        isLoading = false
    }

    func markComplete(lessonId: String) async {
        errorMessage = nil
        do {
            let body = LessonProgressBody(completed: true)
            let _: LessonProgressResult = try await apiClient.request(
                APIRouter.updateLessonProgress(childId: childId, lessonId: lessonId, body: body)
            )
            await loadProgress()
        } catch {
            errorMessage = "Failed to mark lesson complete."
        }
    }

    func submitQuiz(lessonId: String, score: Int, total: Int) async {
        errorMessage = nil
        do {
            let body = QuizResultBody(score: score, total: total)
            let _: LessonProgressResult = try await apiClient.request(
                APIRouter.submitQuiz(childId: childId, lessonId: lessonId, body: body)
            )
            await loadProgress()
        } catch {
            errorMessage = "Failed to submit quiz result."
        }
    }
}
