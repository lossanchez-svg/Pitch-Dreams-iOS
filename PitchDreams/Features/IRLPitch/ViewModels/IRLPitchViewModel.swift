import SwiftUI
import CoreLocation

/// Home-facing wrapper around `PitchDetector` + `PitchStore`. Owns the
/// input state for the designation flow so views stay stateless.
@MainActor
final class IRLPitchViewModel: ObservableObject {
    @Published var pitches: [TrainingPitch] = []
    @Published var draftNickname: String = ""
    @Published var draftMarkAsHome: Bool = true
    @Published var isSaving: Bool = false

    let childId: String
    let detector: PitchDetector
    private let store: PitchStore

    init(
        childId: String,
        detector: PitchDetector? = nil,
        store: PitchStore = PitchStore()
    ) {
        self.childId = childId
        self.store = store
        self.detector = detector ?? PitchDetector(store: store)
    }

    func loadPitches() async {
        pitches = await store.getAll(childId: childId)
    }

    func start() {
        detector.start(childId: childId)
    }

    /// Confirm the currently-pending new location as a real pitch with
    /// the drafted name + home flag. Refreshes the pitches list on
    /// success.
    func saveDesignation() async {
        guard detector.pendingNewLocation != nil else { return }
        isSaving = true
        let trimmedName = draftNickname.trimmingCharacters(in: .whitespaces)
        let finalName = trimmedName.isEmpty ? (draftMarkAsHome ? "Home Pitch" : nil) : trimmedName
        await detector.designateCurrentDwellAsPitch(
            nickname: finalName,
            isHome: draftMarkAsHome
        )
        await loadPitches()
        draftNickname = ""
        isSaving = false
    }

    func dismissDesignation() {
        detector.dismissPendingNew()
        draftNickname = ""
    }

    func deletePitch(_ pitch: TrainingPitch) async {
        await store.deletePitch(id: pitch.id, childId: childId)
        await loadPitches()
    }

    func setHome(_ pitch: TrainingPitch) async {
        await store.setHomePitch(id: pitch.id, childId: childId)
        await loadPitches()
    }
}
