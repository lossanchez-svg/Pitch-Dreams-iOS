import XCTest
@testable import PitchDreams

final class TrainingMoveLinkTests: XCTestCase {

    func testMatches_emptyReturnsEmpty() {
        XCTAssertTrue(TrainingMoveLink.matches(trainingDrillIds: []).isEmpty)
    }

    func testMatches_unmappedDrillReturnsEmpty() {
        XCTAssertTrue(TrainingMoveLink.matches(trainingDrillIds: ["bogus-drill"]).isEmpty)
    }

    func testMatches_soleRollsHitsScissorAndCroquetaStage1() {
        let hits = TrainingMoveLink.matches(trainingDrillIds: ["bm-sole-rolls"])
        let scissorHit = hits.contains { $0.moveId == "move-scissor" && $0.stage == 1 }
        let croquetaHit = hits.contains { $0.moveId == "move-la-croqueta" && $0.stage == 1 }
        XCTAssertTrue(scissorHit)
        XCTAssertTrue(croquetaHit)
    }

    func testMatches_1v1MovesHitsAllMasteryStages() {
        let hits = TrainingMoveLink.matches(trainingDrillIds: ["drib-1v1-moves"])
        let scissorMastery = hits.contains { $0.moveId == "move-scissor" && $0.stage == 3 }
        let croquetaMastery = hits.contains { $0.moveId == "move-la-croqueta" && $0.stage == 3 }
        XCTAssertTrue(scissorMastery)
        XCTAssertTrue(croquetaMastery)
    }

    func testRepsPerMatch_smallEnough() {
        // Guard against accidental inflation — should stay a small bump.
        XCTAssertLessThanOrEqual(TrainingMoveLink.repsPerMatch, 10)
        XCTAssertGreaterThan(TrainingMoveLink.repsPerMatch, 0)
    }
}

@MainActor
final class SignatureMoveStore_TrainingCreditTests: XCTestCase {
    var defaults: UserDefaults!
    var store: SignatureMoveStore!
    let childId = "credit-child"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "TrainingCreditTests")!
        defaults.removePersistentDomain(forName: "TrainingCreditTests")
        store = SignatureMoveStore(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "TrainingCreditTests")
        super.tearDown()
    }

    func testCreditFromTraining_creditsScissorStage1() async {
        let credited = await store.creditFromTraining(
            trainingDrillIds: ["bm-sole-rolls"],
            childId: childId
        )
        let names = credited.map(\.move.name)
        XCTAssertTrue(names.contains("Scissor"))

        // Scissor Stage 1 Drill 1 (scis-1-1) is the first incomplete drill.
        let progress = await store.getProgress(moveId: "move-scissor", childId: childId)
        XCTAssertEqual(progress.drillReps["scis-1-1"] ?? 0, TrainingMoveLink.repsPerMatch)
    }

    func testCreditFromTraining_onlyCurrentStage() async {
        // Advance Scissor to stage 2 by completing stage 1 drills.
        _ = await store.recordDrillAttempt(moveId: "move-scissor", drillId: "scis-1-1", reps: 1, childId: childId)
        _ = await store.recordDrillAttempt(moveId: "move-scissor", drillId: "scis-1-2", reps: 40, childId: childId)
        _ = await store.recordStageConfidence(moveId: "move-scissor", stage: 1, confidence: 3, childId: childId)

        // Training drill that maps to Scissor Stage 1 should now NOT credit
        // (since current stage is 2), but a Stage 2 drill (bm-foundation)
        // should credit.
        let stage1Only = await store.creditFromTraining(
            trainingDrillIds: ["bm-sole-rolls"],
            childId: childId
        )
        XCTAssertFalse(stage1Only.contains { $0.move.name == "Scissor" })

        let stage2Match = await store.creditFromTraining(
            trainingDrillIds: ["bm-foundation"],
            childId: childId
        )
        XCTAssertTrue(stage2Match.contains { $0.move.name == "Scissor" })
    }

    func testCreditFromTraining_dedupesWhenMultipleDrillsTargetSameMove() async {
        // bm-sole-rolls + bm-toe-taps both map to Scissor Stage 1.
        // Should credit Scissor only once per session.
        let credited = await store.creditFromTraining(
            trainingDrillIds: ["bm-sole-rolls", "bm-toe-taps"],
            childId: childId
        )
        let scissorHits = credited.filter { $0.move.name == "Scissor" }
        XCTAssertEqual(scissorHits.count, 1, "dedup should collapse to a single credit per move per session")
    }

    func testCreditFromTraining_skipsMasteredMoves() async {
        // Mastery state: mark Scissor as mastered.
        // Simulate: walk through all three stages hitting the real thresholds.
        for stage in 1...3 {
            // Drop in enough reps to satisfy minTotalReps + at least N drills
            guard let stageDef = SignatureMoveRegistry.scissor.stages.first(where: { $0.order == stage }) else { continue }
            for drill in stageDef.drills {
                _ = await store.recordDrillAttempt(moveId: "move-scissor", drillId: drill.id, reps: drill.targetReps, childId: childId)
            }
            _ = await store.recordStageConfidence(
                moveId: "move-scissor",
                stage: stage,
                confidence: stageDef.masteryCriteria.requiredConfidence,
                childId: childId
            )
        }
        let progress = await store.getProgress(moveId: "move-scissor", childId: childId)
        XCTAssertTrue(progress.isMastered)

        let credited = await store.creditFromTraining(
            trainingDrillIds: ["bm-sole-rolls", "bm-foundation", "drib-1v1-moves"],
            childId: childId
        )
        XCTAssertFalse(credited.contains { $0.move.name == "Scissor" })
    }
}
