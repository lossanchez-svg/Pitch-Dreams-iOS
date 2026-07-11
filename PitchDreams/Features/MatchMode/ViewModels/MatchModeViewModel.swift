import Foundation

/// State for the pre-match prep flow and post-match reflection.
/// Persistence is local (`MatchStore`); nothing here is sent to a server.
@MainActor
final class MatchModeViewModel: ObservableObject {

    // Prep
    @Published var selectedGoal: String?
    @Published var selectedCue: String = MatchPresets.powerCues[0]
    @Published var savedPrep: MatchPrep?

    // Reflection
    @Published var effortLevel: Int = 3
    @Published var braveThingTried: String?
    @Published var decisionImProudOf: String?
    @Published var reflectionSaved = false
    @Published var bravePlays: Int = 0

    let childId: String
    private let store: MatchStore

    init(childId: String, store: MatchStore = MatchStore()) {
        self.childId = childId
        self.store = store
    }

    var canSavePrep: Bool { selectedGoal != nil }

    func load() async {
        savedPrep = await store.latestPrep(childId: childId)
        bravePlays = await store.bravePlays(childId: childId)
    }

    func savePrep(now: Date = Date()) async {
        guard let goal = selectedGoal else { return }
        let prep = MatchPrep(processGoal: goal, powerCue: selectedCue, preppedAt: now)
        await store.savePrep(prep, childId: childId)
        savedPrep = prep
    }

    func saveReflection(now: Date = Date()) async {
        guard !reflectionSaved else { return }
        let reflection = MatchReflection(
            braveThingTried: braveThingTried,
            effortLevel: effortLevel,
            decisionImProudOf: decisionImProudOf,
            reflectedAt: now
        )
        await store.recordReflection(reflection, childId: childId)
        bravePlays = await store.bravePlays(childId: childId)
        reflectionSaved = true
    }
}
