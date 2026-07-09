import XCTest
@testable import PitchDreams

final class SessionSyncQueueTests: XCTestCase {

    var defaults: UserDefaults!
    var mockAPI: MockAPIClient!
    var queue: SessionSyncQueue!
    let childId = "child-sync-test"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "SessionSyncQueueTests")!
        defaults.removePersistentDomain(forName: "SessionSyncQueueTests")
        mockAPI = MockAPIClient()
        queue = SessionSyncQueue(defaults: defaults, apiClient: mockAPI)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "SessionSyncQueueTests")
        super.tearDown()
    }

    // MARK: - Enqueue / Load

    func testEnqueueSession_incrementsPendingCount() async {
        let body = CreateSessionBody(activityType: "SELF_TRAINING", effortLevel: 5,
                                     mood: "GOOD", duration: 20, win: nil, focus: nil)
        _ = await queue.enqueueSession(childId: childId, body: body)
        let count = await queue.pendingCount()
        XCTAssertEqual(count, 1)
    }

    func testEnqueueQuickSession_persistsAcrossInstances() async {
        let body = QuickSessionBody(type: "solo", duration: 30, effort: 4)
        _ = await queue.enqueueQuickSession(childId: childId, body: body)

        // Spin up a fresh queue instance pointed at the same defaults
        let reopened = SessionSyncQueue(defaults: defaults, apiClient: MockAPIClient())
        let count = await reopened.pendingCount()
        XCTAssertEqual(count, 1)
    }

    // MARK: - Flush outcomes

    func testFlush_whenEmpty_returnsDrained() async {
        let outcome = await queue.flush()
        XCTAssertEqual(outcome, .drained)
    }

    func testFlush_successfulSend_drainsQueue() async {
        let body = CreateSessionBody(activityType: "SELF_TRAINING", effortLevel: 5,
                                     mood: "GOOD", duration: 20, win: nil, focus: nil)
        _ = await queue.enqueueSession(childId: childId, body: body)

        mockAPI.enqueue(SessionSaveResult(sessionId: "s-1"))

        let outcome = await queue.flush()
        XCTAssertEqual(outcome, .drained)
        let pending = await queue.pendingCount()
        XCTAssertEqual(pending, 0)
    }

    func testFlush_networkError_keepsEntryForRetry() async {
        let body = CreateSessionBody(activityType: "SELF_TRAINING", effortLevel: 5,
                                     mood: "GOOD", duration: 20, win: nil, focus: nil)
        _ = await queue.enqueueSession(childId: childId, body: body)

        let urlError = URLError(.notConnectedToInternet)
        mockAPI.enqueueError(APIError.network(urlError))

        let outcome = await queue.flush()
        XCTAssertEqual(outcome, .partial(remaining: 1))
        let pending = await queue.pendingCount()
        XCTAssertEqual(pending, 1)
    }

    func testFlush_serverError_keepsEntryForRetry() async {
        // Regression: a transient 5xx used to be treated as permanent failure
        // and permanently dropped an offline-queued session.
        let body = QuickSessionBody(type: "solo", duration: 30, effort: 4)
        _ = await queue.enqueueQuickSession(childId: childId, body: body)

        mockAPI.enqueueError(APIError.server("temporarily overloaded"))

        let outcome = await queue.flush()
        XCTAssertEqual(outcome, .partial(remaining: 1))
        let pending = await queue.pendingCount()
        XCTAssertEqual(pending, 1)
    }

    func testFlush_validationError_dropsEntry() async {
        // A 4xx means the server rejected the payload itself — retrying is
        // pointless, so the entry is dropped.
        let body = QuickSessionBody(type: "solo", duration: 30, effort: 4)
        _ = await queue.enqueueQuickSession(childId: childId, body: body)

        mockAPI.enqueueError(APIError.validation("bad payload"))

        let outcome = await queue.flush()
        XCTAssertEqual(outcome, .drained)
        let pending = await queue.pendingCount()
        XCTAssertEqual(pending, 0)
    }

    func testFlush_serverError_dropsAfterMaxAttempts() async {
        let body = QuickSessionBody(type: "solo", duration: 30, effort: 4)
        _ = await queue.enqueueQuickSession(childId: childId, body: body)

        // maxAttempts is 6: six failing flushes retain the entry while
        // incrementing attempts; the seventh gives up.
        for _ in 0..<6 {
            mockAPI.enqueueError(APIError.server("still down"))
            _ = await queue.flush()
        }
        var pending = await queue.pendingCount()
        XCTAssertEqual(pending, 1)

        _ = await queue.flush()
        pending = await queue.pendingCount()
        XCTAssertEqual(pending, 0)
    }

    func testFlush_unauthorized_keepsEntryForLaterRetry() async {
        let body = QuickSessionBody(type: "solo", duration: 30, effort: 4)
        _ = await queue.enqueueQuickSession(childId: childId, body: body)

        mockAPI.enqueueError(APIError.unauthorized)

        let outcome = await queue.flush()
        XCTAssertEqual(outcome, .partial(remaining: 1))
    }

    func testFlush_partiallyRecoverable_reportsRemainingCount() async {
        let bodyA = CreateSessionBody(activityType: "SELF_TRAINING", effortLevel: 5,
                                      mood: "GOOD", duration: 20, win: nil, focus: nil)
        let bodyB = QuickSessionBody(type: "solo", duration: 15, effort: 3)

        _ = await queue.enqueueSession(childId: childId, body: bodyA)
        _ = await queue.enqueueQuickSession(childId: childId, body: bodyB)

        // First call succeeds, second fails with network — should retain 1.
        mockAPI.enqueue(SessionSaveResult(sessionId: "s-a"))
        mockAPI.enqueueError(APIError.network(URLError(.timedOut)))

        let outcome = await queue.flush()
        XCTAssertEqual(outcome, .partial(remaining: 1))
    }

    // MARK: - Activity + check-in kinds

    func testEnqueueActivity_flushDeliversViaRequestVoid() async {
        let body = CreateActivityBody(
            activityType: "OFFICIAL_GAME", durationMinutes: 60, gameIQImpact: "MEDIUM",
            intensityRPE: 7, opponentName: "Rovers", notes: nil,
            facilityId: nil, coachId: nil, programId: nil,
            focusTagIds: nil, highlightIds: nil, nextFocusIds: nil
        )
        _ = await queue.enqueueActivity(childId: childId, body: body)

        // requestVoid path: enqueue a nil-error slot so the mock succeeds.
        mockAPI.enqueue(0)

        let outcome = await queue.flush()
        XCTAssertEqual(outcome, .drained)
        XCTAssertTrue(mockAPI.calledEndpoints.contains(where: { $0.contains("activities") }))
    }

    func testEnqueueActivity_networkErrorKeptForRetry() async {
        let body = CreateActivityBody(
            activityType: "OFFICIAL_GAME", durationMinutes: 60, gameIQImpact: "MEDIUM",
            intensityRPE: 7, opponentName: nil, notes: nil,
            facilityId: nil, coachId: nil, programId: nil,
            focusTagIds: nil, highlightIds: nil, nextFocusIds: nil
        )
        _ = await queue.enqueueActivity(childId: childId, body: body)
        mockAPI.enqueueError(APIError.network(URLError(.notConnectedToInternet)))

        let outcome = await queue.flush()
        XCTAssertEqual(outcome, .partial(remaining: 1))
    }

    // MARK: - Clear

    func testClear_removesAllEntries() async {
        let body = QuickSessionBody(type: "solo", duration: 30, effort: 4)
        _ = await queue.enqueueQuickSession(childId: childId, body: body)
        await queue.clear()
        let count = await queue.pendingCount()
        XCTAssertEqual(count, 0)
    }
}
