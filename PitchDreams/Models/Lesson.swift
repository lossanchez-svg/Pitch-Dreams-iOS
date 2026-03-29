import Foundation

struct LessonProgress: Codable, Identifiable {
    let id: String
    let childId: String
    let lessonId: String
    let completed: Bool
    let quizScore: Int?
    let quizTotal: Int?
}

struct LessonProgressResult: Codable {
    let progressId: String
}
