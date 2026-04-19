import Foundation

/// Tracks per-child signature move progress. One `MoveProgress` record per
/// (childId, moveId) pair. The store handles the game mechanics:
///  - `recordDrillAttempt` bumps rep counts and flags drill/stage completion
///  - `recordStageConfidence` applies the final gate (confidence + optional
///    video) and decides whether the stage advances or the move is mastered
///
/// All operations are actor-serialized to prevent concurrent drill saves
/// from double-counting reps.
actor SignatureMoveStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Reads

    func getProgress(moveId: String, childId: String) -> MoveProgress {
        guard let data = defaults.data(forKey: key(moveId: moveId, childId: childId)),
              let progress = try? JSONDecoder().decode(MoveProgress.self, from: data) else {
            return .initial(for: moveId)
        }
        return progress
    }

    func allProgress(childId: String) -> [(move: SignatureMove, progress: MoveProgress)] {
        SignatureMoveRegistry.launchMoves.map { move in
            (move: move, progress: getProgress(moveId: move.id, childId: childId))
        }
    }

    func unlockedMoves(childId: String) -> [SignatureMove] {
        SignatureMoveRegistry.launchMoves.filter {
            getProgress(moveId: $0.id, childId: childId).isMastered
        }
    }

    // MARK: - Writes

    /// Record reps toward a specific drill. Returns whether the drill was
    /// completed by this attempt and whether the whole stage is now eligible
    /// to complete (the confidence gate is still required).
    @discardableResult
    func recordDrillAttempt(
        moveId: String,
        drillId: String,
        reps: Int,
        childId: String
    ) -> DrillAttemptResult {
        guard let move = SignatureMoveRegistry.move(id: moveId) else {
            return DrillAttemptResult(drillCompleted: false, stageCanComplete: false)
        }
        var progress = getProgress(moveId: moveId, childId: childId)
        guard let (stage, drill) = findStageAndDrill(in: move, drillId: drillId) else {
            return DrillAttemptResult(drillCompleted: false, stageCanComplete: false)
        }
        guard stage.order <= progress.currentStage else {
            // Trying to record a drill on a locked/future stage — refuse.
            return DrillAttemptResult(drillCompleted: false, stageCanComplete: false)
        }

        let prior = progress.drillReps[drillId] ?? 0
        progress.drillReps[drillId] = prior + reps
        progress.lastAttemptAt = Date()

        let nowComplete = (progress.drillReps[drillId] ?? 0) >= drill.targetReps
        if nowComplete {
            progress.completedDrillIds.insert(drillId)
        }

        let canComplete = canStageComplete(stage: stage, progress: progress)
        save(progress, childId: childId)

        return DrillAttemptResult(drillCompleted: nowComplete, stageCanComplete: canComplete)
    }

    /// Apply a stage's confidence rating (and optional video path). If the
    /// stage's mastery criteria are met, advance `currentStage`. If the
    /// advanced stage is past 3, the move is mastered and `masteredAt` is
    /// stamped.
    @discardableResult
    func recordStageConfidence(
        moveId: String,
        stage: Int,
        confidence: Int,
        videoPath: String? = nil,
        childId: String
    ) -> StageAdvanceResult {
        guard let move = SignatureMoveRegistry.move(id: moveId),
              let stageDef = move.stages.first(where: { $0.order == stage }) else {
            return StageAdvanceResult(stageAdvanced: false, moveMastered: false)
        }

        var progress = getProgress(moveId: moveId, childId: childId)
        progress.stageConfidenceRatings[stage] = confidence
        if let videoPath { progress.recordedVideoPath = videoPath }

        let confidenceMet = confidence >= stageDef.masteryCriteria.requiredConfidence
        let drillsMet = canStageComplete(stage: stageDef, progress: progress)
        let videoMet = !stageDef.masteryCriteria.requiresVideoRecording || videoPath != nil

        if confidenceMet && drillsMet && videoMet {
            progress.currentStage = min(4, stage + 1)
            if progress.currentStage == 4 && progress.masteredAt == nil {
                progress.masteredAt = Date()
                save(progress, childId: childId)
                return StageAdvanceResult(stageAdvanced: true, moveMastered: true)
            }
            save(progress, childId: childId)
            return StageAdvanceResult(stageAdvanced: true, moveMastered: false)
        }

        save(progress, childId: childId)
        return StageAdvanceResult(stageAdvanced: false, moveMastered: false)
    }

    /// Wipe all progress for a child (reset-progress flow).
    func clear(childId: String) {
        for move in SignatureMoveRegistry.launchMoves {
            defaults.removeObject(forKey: key(moveId: move.id, childId: childId))
        }
    }

    /// Credit in-progress moves for a normal training session via the
    /// `TrainingMoveLink` mapping. For each matching (move, stage) pair
    /// whose stage matches the move's current stage, the first incomplete
    /// drill in that stage gets `TrainingMoveLink.repsPerMatch` reps.
    ///
    /// Returns the list of moves + total reps credited so the caller can
    /// surface an optional "you made progress on X" notification.
    @discardableResult
    func creditFromTraining(
        trainingDrillIds: [String],
        childId: String
    ) -> [(move: SignatureMove, repsCredited: Int)] {
        let matches = TrainingMoveLink.matches(trainingDrillIds: trainingDrillIds)
        guard !matches.isEmpty else { return [] }

        var credited: [(move: SignatureMove, repsCredited: Int)] = []
        // Dedupe to one credit per move per session — a heavy multi-drill
        // session shouldn't cascade-advance a single move.
        var seenMoveIds: Set<String> = []

        for match in matches where !seenMoveIds.contains(match.moveId) {
            guard let move = SignatureMoveRegistry.move(id: match.moveId) else { continue }
            let progress = getProgress(moveId: move.id, childId: childId)
            // Only credit the move's *current* in-progress stage.
            guard match.stage == progress.currentStage, !progress.isMastered else { continue }
            guard let stageDef = move.stages.first(where: { $0.order == match.stage }) else { continue }
            guard let targetDrill = stageDef.drills.first(where: {
                !progress.completedDrillIds.contains($0.id)
            }) else { continue }

            _ = recordDrillAttempt(
                moveId: move.id,
                drillId: targetDrill.id,
                reps: TrainingMoveLink.repsPerMatch,
                childId: childId
            )
            credited.append((move: move, repsCredited: TrainingMoveLink.repsPerMatch))
            seenMoveIds.insert(move.id)
        }

        return credited
    }

    // MARK: - Private

    private func save(_ progress: MoveProgress, childId: String) {
        guard let data = try? JSONEncoder().encode(progress) else { return }
        defaults.set(data, forKey: key(moveId: progress.moveId, childId: childId))
    }

    private func key(moveId: String, childId: String) -> String {
        "move_progress_\(childId)_\(moveId)"
    }

    private func findStageAndDrill(in move: SignatureMove, drillId: String) -> (MoveStage, MoveDrill)? {
        for stage in move.stages {
            if let drill = stage.drills.first(where: { $0.id == drillId }) {
                return (stage, drill)
            }
        }
        return nil
    }

    private func canStageComplete(stage: MoveStage, progress: MoveProgress) -> Bool {
        let completed = stage.drills.filter { progress.completedDrillIds.contains($0.id) }.count
        let totalReps = stage.drills.reduce(0) { $0 + (progress.drillReps[$1.id] ?? 0) }
        return completed >= stage.masteryCriteria.requiredDrillsCompleted
            && totalReps >= stage.masteryCriteria.minTotalReps
    }
}
