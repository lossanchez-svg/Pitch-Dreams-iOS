import XCTest
@testable import PitchDreams

@MainActor
final class InteractivePitchViewModelTests: XCTestCase {

    func testTapPlayerSetsElementAndPosition() {
        let vm = InteractivePitchViewModel()
        let player = TacticalPlayer(id: "p1", x: 50, y: 50, type: .self_, label: "You", highlight: true)
        let pos = CGPoint(x: 100, y: 100)

        vm.tapPlayer(player, at: pos)

        XCTAssertEqual(vm.selectedElementId, "p1")
        XCTAssertEqual(vm.popoverPosition, pos)
        XCTAssertFalse(vm.popoverText.isEmpty)
    }

    func testDismissClearsSelection() {
        let vm = InteractivePitchViewModel()
        let player = TacticalPlayer(id: "p1", x: 50, y: 50, type: .self_)
        vm.tapPlayer(player, at: .zero)

        vm.dismiss()

        XCTAssertNil(vm.selectedElementId)
        XCTAssertTrue(vm.popoverText.isEmpty)
    }

    func testDescriptionForPlayerTypes() {
        let vm = InteractivePitchViewModel()

        let selfPlayer = TacticalPlayer(id: "s", x: 0, y: 0, type: .self_, label: "CM")
        XCTAssertEqual(vm.descriptionForPlayer(selfPlayer), "You: CM")

        let teammate = TacticalPlayer(id: "t", x: 0, y: 0, type: .teammate, label: "LW")
        XCTAssertEqual(vm.descriptionForPlayer(teammate), "Teammate: LW")

        let opponent = TacticalPlayer(id: "o", x: 0, y: 0, type: .opponent)
        XCTAssertEqual(vm.descriptionForPlayer(opponent), "Opponent")
    }

    func testDescriptionForArrowTypes() {
        let vm = InteractivePitchViewModel()

        let pass = TacticalArrow(id: "a1", fromX: 0, fromY: 0, toX: 1, toY: 1, type: .pass, label: "Through ball!")
        XCTAssertEqual(vm.descriptionForArrow(pass), "Pass: Through ball!")

        let run = TacticalArrow(id: "a2", fromX: 0, fromY: 0, toX: 1, toY: 1, type: .run)
        XCTAssertEqual(vm.descriptionForArrow(run), "Run")

        let scan = TacticalArrow(id: "a3", fromX: 0, fromY: 0, toX: 1, toY: 1, type: .scan, label: "Check 1")
        XCTAssertEqual(vm.descriptionForArrow(scan), "Scan: Check 1")
    }

    func testDescriptionForZoneTypes() {
        let vm = InteractivePitchViewModel()

        let space = TacticalZone(id: "z1", x: 0, y: 0, w: 10, h: 10, type: .space, label: "Gap")
        XCTAssertEqual(vm.descriptionForZone(space), "Open space: Gap")

        let danger = TacticalZone(id: "z2", x: 0, y: 0, w: 10, h: 10, type: .danger)
        XCTAssertEqual(vm.descriptionForZone(danger), "Danger zone")

        let opp = TacticalZone(id: "z3", x: 0, y: 0, w: 10, h: 10, type: .opportunity, label: "Channel")
        XCTAssertEqual(vm.descriptionForZone(opp), "Opportunity: Channel")
    }

    func testTapCallsSpeak() {
        let mock = MockCoachVoice()
        let vm = InteractivePitchViewModel(voice: mock)
        let player = TacticalPlayer(id: "p1", x: 50, y: 50, type: .self_, label: "You")

        vm.tapPlayer(player, at: .zero)

        XCTAssertEqual(mock.speakCallCount, 1)
        XCTAssertEqual(mock.spokenTexts.last, "You: You")
    }

    func testCustomDescriptionOverridesDefault() {
        let vm = InteractivePitchViewModel()
        let player = TacticalPlayer(id: "p1", x: 0, y: 0, type: .self_, label: "CM", description: "Central midfielder controlling the tempo")
        XCTAssertEqual(vm.descriptionForPlayer(player), "Central midfielder controlling the tempo")
    }
}
