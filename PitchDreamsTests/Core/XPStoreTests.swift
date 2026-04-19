import XCTest
@testable import PitchDreams

final class XPStoreTests: XCTestCase {
    var store: XPStore!
    var defaults: UserDefaults!

    override func setUp() {
        defaults = UserDefaults(suiteName: "XPStoreTests")!
        defaults.removePersistentDomain(forName: "XPStoreTests")
        store = XPStore(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "XPStoreTests")
    }

    func testGetTotalXP_defaultsToZero() async {
        let xp = await store.getTotalXP(childId: "child1")
        XCTAssertEqual(xp, 0)
    }

    func testAddXP_accumulatesCorrectly() async {
        let _ = await store.addXP(100, childId: "child1")
        let _ = await store.addXP(200, childId: "child1")
        let total = await store.getTotalXP(childId: "child1")
        XCTAssertEqual(total, 300)
    }

    func testAddXP_detectsEvolution() async {
        // Start with 450, add 100 -> crosses 500 threshold -> Pro
        let _ = await store.addXP(450, childId: "child1")
        let result = await store.addXP(100, childId: "child1")
        XCTAssertTrue(result.evolved)
        XCTAssertEqual(result.oldStage, .rookie)
        XCTAssertEqual(result.newStage, .pro)
        XCTAssertEqual(result.newTotal, 550)
    }

    func testAddXP_noEvolutionWithinStage() async {
        let _ = await store.addXP(200, childId: "child1")
        let result = await store.addXP(50, childId: "child1")
        XCTAssertFalse(result.evolved)
        XCTAssertEqual(result.oldStage, .rookie)
        XCTAssertEqual(result.newStage, .rookie)
    }

    func testAddXP_detectsLegendEvolution() async {
        let _ = await store.addXP(1900, childId: "child1")
        let result = await store.addXP(200, childId: "child1")
        XCTAssertTrue(result.evolved)
        XCTAssertEqual(result.oldStage, .pro)
        XCTAssertEqual(result.newStage, .legend)
    }

    func testAddXP_isolatesChildren() async {
        let _ = await store.addXP(100, childId: "child1")
        let _ = await store.addXP(200, childId: "child2")
        let xp1 = await store.getTotalXP(childId: "child1")
        let xp2 = await store.getTotalXP(childId: "child2")
        XCTAssertEqual(xp1, 100)
        XCTAssertEqual(xp2, 200)
    }

    func testRecordXPEntry_andRetrieve() async {
        let entry = XPEntry(amount: 50, source: "drill", date: Date())
        await store.recordXPEntry(entry, childId: "child1")
        let history = await store.getXPHistory(childId: "child1")
        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history[0].amount, 50)
        XCTAssertEqual(history[0].source, "drill")
    }

    func testXPHistory_capsAt100Entries() async {
        for i in 0..<110 {
            let entry = XPEntry(amount: i, source: "test", date: Date())
            await store.recordXPEntry(entry, childId: "child1")
        }
        let history = await store.getXPHistory(childId: "child1")
        XCTAssertEqual(history.count, 100)
        // Should keep the most recent 100 (suffix)
        XCTAssertEqual(history.first?.amount, 10)
        XCTAssertEqual(history.last?.amount, 109)
    }

    func testGetXPHistory_emptyByDefault() async {
        let history = await store.getXPHistory(childId: "child1")
        XCTAssertTrue(history.isEmpty)
    }
}
