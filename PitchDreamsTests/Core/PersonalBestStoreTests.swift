import XCTest
@testable import PitchDreams

final class PersonalBestStoreTests: XCTestCase {
    var store: PersonalBestStore!
    var defaults: UserDefaults!

    override func setUp() {
        defaults = UserDefaults(suiteName: "PersonalBestStoreTests")!
        defaults.removePersistentDomain(forName: "PersonalBestStoreTests")
        store = PersonalBestStore(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "PersonalBestStoreTests")
    }

    func testCheckAndUpdate_firstValueIsAlwaysPB() async {
        let isPB = await store.checkAndUpdate(metric: "juggling", value: 20, childId: "child1")
        XCTAssertTrue(isPB)
    }

    func testCheckAndUpdate_higherValueIsPB() async {
        let _ = await store.checkAndUpdate(metric: "juggling", value: 20, childId: "child1")
        let isPB = await store.checkAndUpdate(metric: "juggling", value: 30, childId: "child1")
        XCTAssertTrue(isPB)
    }

    func testCheckAndUpdate_sameValueIsNotPB() async {
        let _ = await store.checkAndUpdate(metric: "juggling", value: 20, childId: "child1")
        let isPB = await store.checkAndUpdate(metric: "juggling", value: 20, childId: "child1")
        XCTAssertFalse(isPB)
    }

    func testCheckAndUpdate_lowerValueIsNotPB() async {
        let _ = await store.checkAndUpdate(metric: "juggling", value: 30, childId: "child1")
        let isPB = await store.checkAndUpdate(metric: "juggling", value: 20, childId: "child1")
        XCTAssertFalse(isPB)
    }

    func testGetBest_returnsStoredValue() async {
        let _ = await store.checkAndUpdate(metric: "wall_ball", value: 45, childId: "child1")
        let best = await store.getBest(metric: "wall_ball", childId: "child1")
        XCTAssertEqual(best, 45)
    }

    func testGetBest_defaultsToZero() async {
        let best = await store.getBest(metric: "nonexistent", childId: "child1")
        XCTAssertEqual(best, 0)
    }

    func testCheckAndUpdate_isolatesMetrics() async {
        let _ = await store.checkAndUpdate(metric: "juggling", value: 50, childId: "child1")
        let _ = await store.checkAndUpdate(metric: "wall_ball", value: 30, childId: "child1")
        let juggling = await store.getBest(metric: "juggling", childId: "child1")
        let wallBall = await store.getBest(metric: "wall_ball", childId: "child1")
        XCTAssertEqual(juggling, 50)
        XCTAssertEqual(wallBall, 30)
    }

    func testCheckAndUpdate_isolatesChildren() async {
        let _ = await store.checkAndUpdate(metric: "juggling", value: 50, childId: "child1")
        let _ = await store.checkAndUpdate(metric: "juggling", value: 30, childId: "child2")
        let best1 = await store.getBest(metric: "juggling", childId: "child1")
        let best2 = await store.getBest(metric: "juggling", childId: "child2")
        XCTAssertEqual(best1, 50)
        XCTAssertEqual(best2, 30)
    }
}
