import XCTest
@testable import PitchDreams

/// Tests that coaching voice personality respects the parent-configured setting.
/// Verifies the full flow: parent saves personality → UserDefaults → voice calls use it.
@MainActor
final class CoachPersonalityTests: XCTestCase {

    private var mockAPI: MockAPIClient!
    private var mockVoice: MockCoachVoice!

    private let testDrills: [DrillDefinition] = [
        DrillDefinition(id: "drill-1", name: "Toe Taps", category: "Ball Mastery", description: "Quick toe taps", duration: 120, reps: 50, coachTip: "Stay light", difficulty: "beginner", spaceType: "small_indoor"),
        DrillDefinition(id: "drill-2", name: "Wall Passes", category: "Passing", description: "Two-touch wall passes", duration: 90, reps: 30, coachTip: "Both feet", difficulty: "intermediate", spaceType: "small_indoor"),
    ]

    override func setUp() {
        super.setUp()
        mockAPI = MockAPIClient()
        mockVoice = MockCoachVoice()
    }

    override func tearDown() {
        // Reset to default personality after each test
        for key in ["coachPersonality", "coachPersonality_test-child",
                     "coachPersonality_child-A", "coachPersonality_child-B",
                     "activeChildId", "someOtherKey"] {
            UserDefaults.standard.removeObject(forKey: key)
        }
        mockAPI = nil
        mockVoice = nil
        super.tearDown()
    }

    // MARK: - CoachPersonality.current reads from UserDefaults

    func testDefaultPersonalityIsManager() {
        UserDefaults.standard.removeObject(forKey: "coachPersonality")
        UserDefaults.standard.removeObject(forKey: "coachPersonality_test-child")
        UserDefaults.standard.removeObject(forKey: "activeChildId")
        XCTAssertEqual(CoachPersonality.current, .manager)
        XCTAssertEqual(CoachPersonality.current.rawValue, "manager")
    }

    func testSaveAndReadHypePersonality() {
        CoachPersonality.hype.save(forChildId: "test-child")
        XCTAssertEqual(CoachPersonality.current, .hype)
    }

    func testSaveAndReadZenPersonality() {
        CoachPersonality.zen.save(forChildId: "test-child")
        XCTAssertEqual(CoachPersonality.current, .zen)
    }

    func testSaveAndReadDrillPersonality() {
        CoachPersonality.drill.save(forChildId: "test-child")
        XCTAssertEqual(CoachPersonality.current, .drill)
    }

    func testInvalidUserDefaultsFallsBackToManager() {
        UserDefaults.standard.set("nonexistent_personality", forKey: "coachPersonality")
        XCTAssertEqual(CoachPersonality.current, .manager)
    }

    // MARK: - Persistence survives across multiple reads

    func testSavedPersonalityPersistsAcrossMultipleReads() {
        CoachPersonality.drill.save(forChildId: "test-child")

        // Read it multiple times — should never reset
        XCTAssertEqual(CoachPersonality.current, .drill)
        XCTAssertEqual(CoachPersonality.current, .drill)
        XCTAssertEqual(CoachPersonality.saved(forChildId: "test-child"), .drill)

        // Do unrelated UserDefaults work
        UserDefaults.standard.set("unrelated", forKey: "someOtherKey")
        UserDefaults.standard.synchronize()

        // Still persisted
        XCTAssertEqual(CoachPersonality.current, .drill)
        XCTAssertEqual(CoachPersonality.saved(forChildId: "test-child"), .drill)
    }

    func testOverwritePersonalityReplacesOldValue() {
        CoachPersonality.hype.save(forChildId: "test-child")
        XCTAssertEqual(CoachPersonality.current, .hype)

        CoachPersonality.zen.save(forChildId: "test-child")
        XCTAssertEqual(CoachPersonality.current, .zen)

        // Old value is gone
        XCTAssertNotEqual(CoachPersonality.current, .hype)
    }

    func testPerChildPersonalityIsolation() {
        // Save different personalities for two children
        CoachPersonality.hype.save(forChildId: "child-A")
        CoachPersonality.drill.save(forChildId: "child-B")

        // Current reflects the last active child (child-B)
        XCTAssertEqual(CoachPersonality.current, .drill)

        // But each child's saved value is independent
        XCTAssertEqual(CoachPersonality.saved(forChildId: "child-A"), .hype)
        XCTAssertEqual(CoachPersonality.saved(forChildId: "child-B"), .drill)

        // Switch active child back to A
        CoachPersonality.hype.save(forChildId: "child-A")
        XCTAssertEqual(CoachPersonality.current, .hype)

        // child-B still has drill
        XCTAssertEqual(CoachPersonality.saved(forChildId: "child-B"), .drill)
    }

    func testSavedForChildIdReturnsManagerForUnknownChild() {
        XCTAssertEqual(CoachPersonality.saved(forChildId: "never-saved-child"), .manager)
    }

    func testSaveWritesBothChildSpecificAndGlobalKeys() {
        CoachPersonality.zen.save(forChildId: "test-child")

        // Child-specific key is set
        let childKey = UserDefaults.standard.string(forKey: "coachPersonality_test-child")
        XCTAssertEqual(childKey, "zen")

        // Global fallback key is also set
        let globalKey = UserDefaults.standard.string(forKey: "coachPersonality")
        XCTAssertEqual(globalKey, "zen")

        // Active child ID is tracked
        let activeChild = UserDefaults.standard.string(forKey: "activeChildId")
        XCTAssertEqual(activeChild, "test-child")
    }

    // MARK: - ActiveTrainingViewModel uses parent-configured personality

    func testStartDrillUsesConfiguredPersonality() {
        CoachPersonality.drill.save(forChildId: "test-child")

        let vm = ActiveTrainingViewModel(childId: "c", drills: testDrills, spaceType: "small_indoor", apiClient: mockAPI)
        vm.coachVoice = mockVoice

        vm.startDrill()

        XCTAssertEqual(mockVoice.lastPersonality, "drill")
    }

    func testStartDrillUsesHypePersonality() {
        CoachPersonality.hype.save(forChildId: "test-child")

        let vm = ActiveTrainingViewModel(childId: "c", drills: testDrills, spaceType: "small_indoor", apiClient: mockAPI)
        vm.coachVoice = mockVoice

        vm.startDrill()

        XCTAssertEqual(mockVoice.lastPersonality, "hype")
    }

    func testCompleteDrillUsesConfiguredPersonality() {
        CoachPersonality.zen.save(forChildId: "test-child")

        let vm = ActiveTrainingViewModel(childId: "c", drills: testDrills, spaceType: "small_indoor", apiClient: mockAPI)
        vm.coachVoice = mockVoice

        vm.startDrill()
        vm.completeDrill()

        // Last voice call should be the "Time!" announcement with zen personality
        XCTAssertEqual(mockVoice.lastPersonality, "zen")
    }

    func testReflectionUsesConfiguredPersonality() {
        CoachPersonality.drill.save(forChildId: "test-child")

        // Enqueue reflection tag responses
        mockAPI.enqueue([HighlightChip(id: "h1", key: "passing", label: "Passing")])
        mockAPI.enqueue([NextFocusChip(id: "n1", key: "shooting", label: "Shooting")])

        let vm = ActiveTrainingViewModel(childId: "c", drills: testDrills, spaceType: "small_indoor", apiClient: mockAPI)
        vm.coachVoice = mockVoice
        vm.currentDrillIndex = 1 // last drill

        vm.confirmReps()

        // "Quick reflection" announcement should use drill personality
        XCTAssertEqual(mockVoice.lastPersonality, "drill")
    }

    func testSessionCompleteUsesConfiguredPersonality() async {
        CoachPersonality.hype.save(forChildId: "test-child")

        mockAPI.enqueue(SessionSaveResult(sessionId: "s-1"))
        mockAPI.enqueue(LogDrillResult(logId: "l-1"))
        mockAPI.enqueue(LogDrillResult(logId: "l-2"))

        let vm = ActiveTrainingViewModel(childId: "c", drills: testDrills, spaceType: "small_indoor", apiClient: mockAPI)
        vm.coachVoice = mockVoice
        vm.startDrill()

        await vm.saveSession()

        // "Well done" announcement should use hype personality
        XCTAssertEqual(mockVoice.lastPersonality, "hype")
    }

    // MARK: - All speak calls in a session use the same personality

    func testAllVoiceCallsInDrillFlowUseConfiguredPersonality() {
        CoachPersonality.zen.save(forChildId: "test-child")

        let vm = ActiveTrainingViewModel(childId: "c", drills: testDrills, spaceType: "small_indoor", apiClient: mockAPI)
        vm.coachVoice = mockVoice

        // 1. Start drill → speaks drill name with zen
        vm.startDrill()
        XCTAssertEqual(mockVoice.speakCallCount, 1)
        XCTAssertEqual(mockVoice.lastPersonality, "zen")

        // 2. Complete drill → speaks "Time!" with zen
        vm.completeDrill()
        XCTAssertEqual(mockVoice.speakCallCount, 2)
        XCTAssertEqual(mockVoice.lastPersonality, "zen")

        // 3. Confirm reps (non-last drill) → advances to next drill
        vm.confirmReps()
        // No voice call on non-last confirmReps — it calls nextDrill
        XCTAssertEqual(mockVoice.speakCallCount, 2)

        // All voice calls used zen personality
        XCTAssertEqual(mockVoice.speakCallCount, 2)
    }

    // MARK: - Personality changes mid-session

    func testPersonalityChangeReflectedImmediately() {
        CoachPersonality.manager.save(forChildId: "test-child")

        let vm = ActiveTrainingViewModel(childId: "c", drills: testDrills, spaceType: "small_indoor", apiClient: mockAPI)
        vm.coachVoice = mockVoice

        vm.startDrill()
        XCTAssertEqual(mockVoice.lastPersonality, "manager")

        // Parent changes personality mid-session (unlikely but possible)
        CoachPersonality.drill.save(forChildId: "test-child")

        vm.completeDrill()
        XCTAssertEqual(mockVoice.lastPersonality, "drill")
    }

    // MARK: - InteractivePitchViewModel uses configured personality

    func testInteractivePitchUsesConfiguredPersonality() {
        CoachPersonality.hype.save(forChildId: "test-child")

        let vm = InteractivePitchViewModel(voice: mockVoice)
        let player = TacticalPlayer(
            id: "p1",
            x: 0.5,
            y: 0.5,
            type: .self_,
            label: "You",
            description: "Your position"
        )

        vm.tapPlayer(player, at: .zero)

        XCTAssertEqual(mockVoice.lastPersonality, "hype")
    }

    func testInteractivePitchZenPersonality() {
        CoachPersonality.zen.save(forChildId: "test-child")

        let vm = InteractivePitchViewModel(voice: mockVoice)
        let arrow = TacticalArrow(
            id: "a1",
            fromX: 0, fromY: 0,
            toX: 1, toY: 1,
            type: .pass,
            label: "Through ball",
            description: "Play through"
        )

        vm.tapArrow(arrow, at: .zero)

        XCTAssertEqual(mockVoice.lastPersonality, "zen")
    }

    // MARK: - Personality-Specific Text Content

    func testDrillStartTextMatchesPersonality() {
        let drills = testDrills

        CoachPersonality.manager.save(forChildId: "test-child")
        let vmManager = ActiveTrainingViewModel(childId: "c", drills: drills, spaceType: "small_indoor", apiClient: mockAPI)
        vmManager.coachVoice = mockVoice
        vmManager.startDrill()
        let managerText = mockVoice.spokenTexts.last!
        XCTAssertTrue(managerText.contains("You've got"), "Manager should say 'You've got'")

        CoachPersonality.hype.save(forChildId: "test-child")
        let vmHype = ActiveTrainingViewModel(childId: "c", drills: drills, spaceType: "small_indoor", apiClient: mockAPI)
        vmHype.coachVoice = mockVoice
        vmHype.startDrill()
        let hypeText = mockVoice.spokenTexts.last!
        XCTAssertTrue(hypeText.contains("Let's go"), "Hype should say 'Let's go'")

        CoachPersonality.zen.save(forChildId: "test-child")
        let vmZen = ActiveTrainingViewModel(childId: "c", drills: drills, spaceType: "small_indoor", apiClient: mockAPI)
        vmZen.coachVoice = mockVoice
        vmZen.startDrill()
        let zenText = mockVoice.spokenTexts.last!
        XCTAssertTrue(zenText.contains("Take a breath"), "Zen should say 'Take a breath'")

        CoachPersonality.drill.save(forChildId: "test-child")
        let vmDrill = ActiveTrainingViewModel(childId: "c", drills: drills, spaceType: "small_indoor", apiClient: mockAPI)
        vmDrill.coachVoice = mockVoice
        vmDrill.startDrill()
        let drillText = mockVoice.spokenTexts.last!
        XCTAssertTrue(drillText.contains("Execute"), "Drill should say 'Execute'")
    }

    func testDrillCompleteTextMatchesPersonality() {
        CoachPersonality.hype.save(forChildId: "test-child")
        let vm = ActiveTrainingViewModel(childId: "c", drills: testDrills, spaceType: "small_indoor", apiClient: mockAPI)
        vm.coachVoice = mockVoice
        vm.startDrill()
        vm.completeDrill()
        let text = mockVoice.spokenTexts.last!
        XCTAssertTrue(text.contains("Great work"), "Hype drill complete should say 'Great work'")
    }

    func testReflectionTextMatchesPersonality() {
        CoachPersonality.zen.save(forChildId: "test-child")
        mockAPI.enqueue([HighlightChip(id: "h1", key: "p", label: "Passing")])
        mockAPI.enqueue([NextFocusChip(id: "n1", key: "s", label: "Shooting")])

        let vm = ActiveTrainingViewModel(childId: "c", drills: testDrills, spaceType: "small_indoor", apiClient: mockAPI)
        vm.coachVoice = mockVoice
        vm.currentDrillIndex = 1
        vm.confirmReps()
        let text = mockVoice.spokenTexts.last!
        XCTAssertTrue(text.contains("Let's reflect"), "Zen reflection should say 'Let's reflect'")
    }

    func testSessionCompleteTextMatchesPersonality() async {
        CoachPersonality.drill.save(forChildId: "test-child")
        mockAPI.enqueue(SessionSaveResult(sessionId: "s-1"))
        mockAPI.enqueue(LogDrillResult(logId: "l-1"))
        mockAPI.enqueue(LogDrillResult(logId: "l-2"))

        let vm = ActiveTrainingViewModel(childId: "c", drills: testDrills, spaceType: "small_indoor", apiClient: mockAPI)
        vm.coachVoice = mockVoice
        vm.startDrill()
        await vm.saveSession()
        let text = mockVoice.spokenTexts.last!
        XCTAssertTrue(text.contains("Dismissed"), "Drill sergeant session complete should say 'Dismissed'")
    }

    func testAllPersonalitiesHaveDistinctLines() {
        // Verify each personality produces unique text for the same cue
        let personas = CoachPersonality.allCases
        let completionLines = personas.map { $0.sessionCompleteLine }
        let reflectionLines = personas.map { $0.reflectionLine }
        let thirtySecLines = personas.map { $0.thirtySecondsLine }

        // All lines should be unique — no two personas say the same thing
        XCTAssertEqual(Set(completionLines).count, personas.count, "Session complete lines should all be unique")
        XCTAssertEqual(Set(reflectionLines).count, personas.count, "Reflection lines should all be unique")
        XCTAssertEqual(Set(thirtySecLines).count, personas.count, "30-second lines should all be unique")
    }

    func testCoachLinesContainDrillNameAndTip() {
        // All personalities should include the drill name and tip
        for persona in CoachPersonality.allCases {
            let line = persona.drillStartLine(name: "Toe Taps", minutes: 2, tip: "Stay light")
            XCTAssertTrue(line.contains("Toe Taps"), "\(persona.displayName) drill start should include drill name")
            XCTAssertTrue(line.contains("Stay light"), "\(persona.displayName) drill start should include tip")
            XCTAssertTrue(line.contains("2"), "\(persona.displayName) drill start should include minutes")
        }
    }
}
