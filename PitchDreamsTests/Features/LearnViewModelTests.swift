import XCTest
@testable import PitchDreams

@MainActor
final class LearnViewModelTests: XCTestCase {
    var mockAPI: MockAPIClient!
    var viewModel: LearnViewModel!

    override func setUp() {
        mockAPI = MockAPIClient()
        viewModel = LearnViewModel(childId: "test-child", apiClient: mockAPI)
    }

    func testLoadProgressMergesWithRegistry() async {
        let progress = [
            TestFixtures.makeLessonProgress(lessonId: "3point-scan", completed: true),
            TestFixtures.makeLessonProgress(id: "lp-002", lessonId: "press-triggers", completed: false),
        ]
        mockAPI.enqueue(progress)

        await viewModel.loadProgress()

        let enriched = viewModel.enrichedLessons
        XCTAssertEqual(enriched.count, TacticalLessonRegistry.all.count)

        let scanLesson = enriched.first { $0.id == "3point-scan" }
        XCTAssertNotNil(scanLesson)
        XCTAssertTrue(scanLesson?.isCompleted ?? false)

        let pressLesson = enriched.first { $0.id == "press-triggers" }
        XCTAssertNotNil(pressLesson)
        XCTAssertFalse(pressLesson?.isCompleted ?? true)
    }

    func testMarkCompleteCallsAPI() async {
        let result = TestFixtures.makeLessonProgressResult()
        mockAPI.enqueue(result) // markComplete
        mockAPI.enqueue([LessonProgress]()) // reload progress

        await viewModel.markComplete(lessonId: "3point-scan")

        XCTAssertTrue(mockAPI.calledEndpoints.contains("/children/test-child/lessons/3point-scan/progress"))
        XCTAssertNil(viewModel.errorMessage)
    }

    func testCompletedCount() async {
        let progress = [
            TestFixtures.makeLessonProgress(id: "lp-1", lessonId: "3point-scan", completed: true),
            TestFixtures.makeLessonProgress(id: "lp-2", lessonId: "press-triggers", completed: true),
            TestFixtures.makeLessonProgress(id: "lp-3", lessonId: "third-man-run", completed: false),
        ]
        mockAPI.enqueue(progress)

        await viewModel.loadProgress()

        XCTAssertEqual(viewModel.completedCount, 2)
        XCTAssertEqual(viewModel.totalCount, TacticalLessonRegistry.all.count)
    }

    func testLessonsByTrack() async {
        mockAPI.enqueue([LessonProgress]())

        await viewModel.loadProgress()

        let tracks = viewModel.lessonsByTrack
        XCTAssertEqual(tracks.count, 3) // scanning, decision_chain, tempo
    }

    func testSubmitQuizCallsAPI() async {
        mockAPI.enqueue(TestFixtures.makeLessonProgressResult())
        mockAPI.enqueue([LessonProgress]())

        await viewModel.submitQuiz(lessonId: "3point-scan", score: 4, total: 5)

        XCTAssertTrue(mockAPI.calledEndpoints.contains("/children/test-child/lessons/3point-scan/quiz"))
    }
}
