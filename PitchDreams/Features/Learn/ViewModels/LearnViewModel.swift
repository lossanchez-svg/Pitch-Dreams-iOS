import Foundation

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
