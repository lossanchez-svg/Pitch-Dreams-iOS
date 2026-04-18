import XCTest
@testable import PitchDreams

final class PlayerCardStoreTests: XCTestCase {
    var defaults: UserDefaults!
    var store: PlayerCardStore!
    let childId = "card-test"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "PlayerCardStoreTests")!
        defaults.removePersistentDomain(forName: "PlayerCardStoreTests")
        store = PlayerCardStore(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "PlayerCardStoreTests")
        super.tearDown()
    }

    func testDefaultCard_allrounder() async {
        let card = await store.get(childId: childId)
        XCTAssertEqual(card.archetype, .allrounder)
        XCTAssertEqual(card.displayedStats.count, PlayerCard.displayedStatCount)
        XCTAssertEqual(card.moveLoadout, [])
        XCTAssertEqual(card.cardFrame, .standard)
    }

    func testUpdateArchetype_persists() async {
        await store.updateArchetype(.speedster, childId: childId)
        let card = await store.get(childId: childId)
        XCTAssertEqual(card.archetype, .speedster)
    }

    func testUpdateArchetype_setsDefaultTagline() async {
        await store.updateArchetype(.playmaker, childId: childId)
        let card = await store.get(childId: childId)
        XCTAssertEqual(card.archetypeTagline, PlayerArchetype.playmaker.tagline)
    }

    func testUpdateMoveLoadout_capsAtFour() async {
        await store.updateMoveLoadout(["a", "b", "c", "d", "e", "f"], childId: childId)
        let card = await store.get(childId: childId)
        XCTAssertEqual(card.moveLoadout.count, PlayerCard.maxMoveLoadout)
    }

    func testUpdateDisplayedStats_capsAtFour() async {
        await store.updateDisplayedStats([.speed, .touch, .vision, .workRate, .composure, .shotPower], childId: childId)
        let card = await store.get(childId: childId)
        XCTAssertEqual(card.displayedStats.count, 4)
    }

    func testUpdateFrame_persists() async {
        await store.updateFrame(.gold, childId: childId)
        let card = await store.get(childId: childId)
        XCTAssertEqual(card.cardFrame, .gold)
    }

    func testClear_removesStoredCard() async {
        await store.updateArchetype(.speedster, childId: childId)
        await store.clear(childId: childId)
        let card = await store.get(childId: childId)
        XCTAssertEqual(card.archetype, .allrounder, "After clear, default should be restored")
    }

    func testTwoChildren_isolated() async {
        await store.updateArchetype(.speedster, childId: "kidA")
        await store.updateArchetype(.wall, childId: "kidB")
        let a = await store.get(childId: "kidA")
        let b = await store.get(childId: "kidB")
        XCTAssertEqual(a.archetype, .speedster)
        XCTAssertEqual(b.archetype, .wall)
    }
}
