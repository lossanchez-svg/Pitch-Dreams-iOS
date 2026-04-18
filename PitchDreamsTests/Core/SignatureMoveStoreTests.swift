import XCTest
@testable import PitchDreams

final class SignatureMoveStoreTests: XCTestCase {
    var defaults: UserDefaults!
    var store: SignatureMoveStore!
    let childId = "move-test"
    let moveId = "move-scissor"
    // Scissor Stage 1, Drill 2 — "The Swing, No Ball", target 40 reps.
    let mimicDrillId = "scis-1-2"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "SignatureMoveStoreTests")!
        defaults.removePersistentDomain(forName: "SignatureMoveStoreTests")
        store = SignatureMoveStore(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "SignatureMoveStoreTests")
        super.tearDown()
    }

    // MARK: - Initial state

    func testInitialProgress_stage1Unlocked_notMastered() async {
        let p = await store.getProgress(moveId: moveId, childId: childId)
        XCTAssertEqual(p.currentStage, 1)
        XCTAssertFalse(p.isMastered)
        XCTAssertTrue(p.completedDrillIds.isEmpty)
    }

    // MARK: - Drill attempts

    func testRecordDrillAttempt_addsReps() async {
        _ = await store.recordDrillAttempt(moveId: moveId, drillId: mimicDrillId, reps: 10, childId: childId)
        let p = await store.getProgress(moveId: moveId, childId: childId)
        XCTAssertEqual(p.drillReps[mimicDrillId], 10)
    }

    func testRecordDrillAttempt_completesAtTarget() async {
        let result = await store.recordDrillAttempt(moveId: moveId, drillId: mimicDrillId, reps: 40, childId: childId)
        XCTAssertTrue(result.drillCompleted)
        let p = await store.getProgress(moveId: moveId, childId: childId)
        XCTAssertTrue(p.completedDrillIds.contains(mimicDrillId))
    }

    func testRecordDrillAttempt_belowTarget_notCompleted() async {
        let result = await store.recordDrillAttempt(moveId: moveId, drillId: mimicDrillId, reps: 20, childId: childId)
        XCTAssertFalse(result.drillCompleted)
    }

    func testRecordDrillAttempt_onLockedStage_noChange() async {
        // Drill in stage 2 while current stage is 1.
        let stage2Drill = "scis-2-1"
        let result = await store.recordDrillAttempt(moveId: moveId, drillId: stage2Drill, reps: 50, childId: childId)
        XCTAssertFalse(result.drillCompleted)
        XCTAssertFalse(result.stageCanComplete)
        let p = await store.getProgress(moveId: moveId, childId: childId)
        XCTAssertNil(p.drillReps[stage2Drill])
    }

    // MARK: - Stage advancement

    func testRecordStageConfidence_belowThreshold_doesNotAdvance() async {
        // Meet the drill criteria first
        _ = await store.recordDrillAttempt(moveId: moveId, drillId: "scis-1-1", reps: 1, childId: childId)
        _ = await store.recordDrillAttempt(moveId: moveId, drillId: mimicDrillId, reps: 40, childId: childId)
        let result = await store.recordStageConfidence(moveId: moveId, stage: 1, confidence: 2, childId: childId)
        XCTAssertFalse(result.stageAdvanced)
        let p = await store.getProgress(moveId: moveId, childId: childId)
        XCTAssertEqual(p.currentStage, 1)
    }

    func testRecordStageConfidence_meetsThreshold_advances() async {
        _ = await store.recordDrillAttempt(moveId: moveId, drillId: "scis-1-1", reps: 1, childId: childId)
        _ = await store.recordDrillAttempt(moveId: moveId, drillId: mimicDrillId, reps: 40, childId: childId)
        let result = await store.recordStageConfidence(moveId: moveId, stage: 1, confidence: 3, childId: childId)
        XCTAssertTrue(result.stageAdvanced)
        XCTAssertFalse(result.moveMastered)
        let p = await store.getProgress(moveId: moveId, childId: childId)
        XCTAssertEqual(p.currentStage, 2)
    }

    func testRecordStageConfidence_finalStage_masters() async {
        // Burn through all 3 stages
        // Stage 1
        _ = await store.recordDrillAttempt(moveId: moveId, drillId: "scis-1-1", reps: 1, childId: childId)
        _ = await store.recordDrillAttempt(moveId: moveId, drillId: "scis-1-2", reps: 40, childId: childId)
        _ = await store.recordStageConfidence(moveId: moveId, stage: 1, confidence: 3, childId: childId)
        // Stage 2
        _ = await store.recordDrillAttempt(moveId: moveId, drillId: "scis-2-1", reps: 30, childId: childId)
        _ = await store.recordDrillAttempt(moveId: moveId, drillId: "scis-2-2", reps: 25, childId: childId)
        _ = await store.recordDrillAttempt(moveId: moveId, drillId: "scis-2-3", reps: 20, childId: childId)
        _ = await store.recordStageConfidence(moveId: moveId, stage: 2, confidence: 4, childId: childId)
        // Stage 3
        _ = await store.recordDrillAttempt(moveId: moveId, drillId: "scis-3-1", reps: 20, childId: childId)
        _ = await store.recordDrillAttempt(moveId: moveId, drillId: "scis-3-2", reps: 10, childId: childId)
        let result = await store.recordStageConfidence(moveId: moveId, stage: 3, confidence: 5, childId: childId)
        XCTAssertTrue(result.moveMastered)
        let p = await store.getProgress(moveId: moveId, childId: childId)
        XCTAssertTrue(p.isMastered)
        XCTAssertEqual(p.currentStage, 4)
    }

    // MARK: - Persistence

    func testAllProgress_returnsEntryPerMove() async {
        let all = await store.allProgress(childId: childId)
        XCTAssertEqual(all.count, SignatureMoveRegistry.launchMoves.count)
    }

    func testClear_resetsAllMoves() async {
        _ = await store.recordDrillAttempt(moveId: moveId, drillId: mimicDrillId, reps: 40, childId: childId)
        await store.clear(childId: childId)
        let p = await store.getProgress(moveId: moveId, childId: childId)
        XCTAssertEqual(p.currentStage, 1)
        XCTAssertTrue(p.completedDrillIds.isEmpty)
    }
}
