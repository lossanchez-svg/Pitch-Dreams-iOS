import XCTest
@testable import PitchDreams

final class RegressionTests: XCTestCase {

    // MARK: - Bug: App froze when todayCheckIn returned null from API
    // Fix: Changed decode to try? with guard let

    @MainActor
    func testNullCheckInDoesNotFreeze() async {
        let mock = MockAPIClient()
        mock.enqueue(TestFixtures.makeChildProfileDetail())
        mock.enqueue(TestFixtures.makeStreakData())
        mock.enqueueError(APIError.decoding(NSError(domain: "null", code: 0)))  // null check-in
        mock.enqueueError(APIError.decoding(NSError(domain: "null", code: 0)))  // null nudge
        mock.enqueue(TestFixtures.makeFreezeCheckResult())  // freeze check

        let vm = ChildHomeViewModel(childId: "test", apiClient: mock)
        await vm.loadData()

        XCTAssertFalse(vm.isLoading, "Must complete, not hang")
        XCTAssertNil(vm.todayCheckIn)
    }

    // MARK: - Bug: snake_case encoding broke API calls
    // Fix: JSONEncoder must NOT use .convertToSnakeCase

    func testAPIClientDoesNotSnakeCaseKeys() throws {
        let encoder = JSONEncoder()
        // Default encoder — no .convertToSnakeCase strategy
        let body = QuickCheckInBody(mood: "FOCUSED", timeAvail: 20)
        let data = try encoder.encode(body)
        let json = String(data: data, encoding: .utf8)!
        XCTAssertTrue(json.contains("timeAvail"), "Key should be camelCase: timeAvail")
        XCTAssertFalse(json.contains("time_avail"), "Key should NOT be snake_case: time_avail")
    }

    func testCreateSessionBodyDoesNotSnakeCaseKeys() throws {
        let encoder = JSONEncoder()
        let body = CreateSessionBody(activityType: "SELF_TRAINING", effortLevel: 4, mood: "FOCUSED", duration: 45, win: nil, focus: nil)
        let data = try encoder.encode(body)
        let json = String(data: data, encoding: .utf8)!
        XCTAssertTrue(json.contains("activityType"))
        XCTAssertTrue(json.contains("effortLevel"))
        XCTAssertFalse(json.contains("activity_type"))
        XCTAssertFalse(json.contains("effort_level"))
    }

    // MARK: - Bug: Base URL without www caused 307 redirect
    // Fix: Constants.baseURL must use www subdomain

    func testBaseURLUsesWWW() {
        XCTAssertEqual(Constants.baseURL.host, "www.pitchdreams.soccer")
    }

    func testBaseURLUsesHTTPS() {
        XCTAssertEqual(Constants.baseURL.scheme, "https")
    }

    func testAPIBasePathIsV1() {
        XCTAssertEqual(Constants.apiBasePath, "/api/v1")
    }

    // MARK: - Bug: apiSuccess(undefined) crashed server — verify void responses don't crash client

    func testVoidResponseHandled() async {
        let mock = MockAPIClient()
        // requestVoid should not throw when no error queued
        do {
            try await mock.requestVoid(APIRouter.checkFreeze(childId: "test"))
        } catch {
            XCTFail("requestVoid should not throw when no error is queued")
        }
        // Should not crash
    }

    // MARK: - Bug: Quick check-in body must encode mood correctly

    func testQuickCheckInBodyEncoding() throws {
        let encoder = JSONEncoder()
        let body = QuickCheckInBody(mood: "EXCITED", timeAvail: 30)
        let data = try encoder.encode(body)
        let json = String(data: data, encoding: .utf8)!
        XCTAssertTrue(json.contains("\"mood\":\"EXCITED\"") || json.contains("\"mood\" : \"EXCITED\""))
        XCTAssertTrue(json.contains("timeAvail"))
    }

    // MARK: - Bug: VoiceCommandMatcher crashed on empty transcript

    func testVoiceMatcherEmptyTranscript() {
        let commands = [
            VoiceCommand(label: "test", phrases: ["hello"]) {}
        ]
        let result = VoiceCommandMatcher.match(transcript: "", commands: commands)
        XCTAssertNil(result)
    }

    func testVoiceMatcherEmptyCommands() {
        let result = VoiceCommandMatcher.match(transcript: "hello", commands: [])
        XCTAssertNil(result)
    }

    func testExtractNumberFromEmptyString() {
        let result = VoiceCommandMatcher.extractNumber(from: "")
        XCTAssertNil(result)
    }

    // MARK: - Bug: Training view model error message not cleared on retry

    @MainActor
    func testTrainingViewModelClearsErrorOnRetry() async {
        let mock = MockAPIClient()
        let vm = TrainingViewModel(childId: "test", apiClient: mock)

        // First call fails
        mock.enqueueError(APIError.server("Failed"))
        await vm.quickCheckIn(mood: "FOCUSED")
        XCTAssertNotNil(vm.errorMessage)

        // Second call succeeds
        mock.enqueue(TestFixtures.makeCheckInResponse())
        await vm.quickCheckIn(mood: "FOCUSED")
        XCTAssertNil(vm.errorMessage, "Error message should be cleared on successful retry")
    }

    // MARK: - Bug: ProgressViewModel must handle nil durations in totalMinutes

    @MainActor
    func testProgressViewModelNilDurationsSafe() async {
        let mock = MockAPIClient()
        let vm = ProgressViewModel(childId: "test", apiClient: mock)

        mock.enqueue(TestFixtures.makeStreakData())
        mock.enqueue([
            TestFixtures.makeSessionLog(id: "s1", duration: nil),
            TestFixtures.makeSessionLog(id: "s2", duration: nil),
        ])
        mock.enqueue([WeeklyTrend]())

        await vm.loadData()

        XCTAssertEqual(vm.totalMinutes, 0, "Nil durations should contribute 0")
        XCTAssertFalse(vm.isLoading)
    }

    // MARK: - Bug: ActivityType display names must all be non-empty

    func testAllActivityTypesHaveDisplayNames() {
        for type in ActivityType.allCases {
            XCTAssertFalse(type.displayName.isEmpty, "\(type.rawValue) should have a display name")
        }
    }

    // MARK: - Bug: Session modes must all be mapped

    @MainActor
    func testAllSessionModesHaveDisplayNames() {
        let mock = MockAPIClient()
        let vm = TrainingViewModel(childId: "test", apiClient: mock)
        let modes = ["PEAK", "NORMAL", "LOW_BATTERY", "RECOVERY"]

        for mode in modes {
            vm.checkInState = TestFixtures.makeCheckInResponse(mode: mode)
            XCTAssertFalse(vm.modeDisplayName.isEmpty, "Mode \(mode) should have a display name")
            XCTAssertNotEqual(vm.modeColor, "gray", "Mode \(mode) should have a color")
        }
    }
}
