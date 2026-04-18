import XCTest
@testable import PitchDreams

final class MysteryBoxEngineTests: XCTestCase {

    // Context with all reward types eligible.
    private let openContext = MysteryBoxContext(
        lockedMoveIds: ["move-scissor", "move-body-feint"],
        availableCosmeticIds: ["color_red", "color_blue"],
        streakShieldsMaxed: false
    )

    // MARK: - Reward generation

    func testGenerateReward_alwaysReturnsValidType() {
        for _ in 0..<100 {
            let reward = MysteryBoxEngine.generateReward(context: openContext)
            XCTAssertNotNil(MysteryRewardType(rawValue: reward.type.rawValue))
        }
    }

    func testGenerateReward_noLockedMoves_skipsMoveAttempt() {
        var count = 0
        let context = MysteryBoxContext(lockedMoveIds: [], availableCosmeticIds: ["a"], streakShieldsMaxed: false)
        for _ in 0..<200 {
            let reward = MysteryBoxEngine.generateReward(context: context)
            if reward.type == .moveAttempt { count += 1 }
        }
        XCTAssertEqual(count, 0, "moveAttempt should be filtered when no locked moves")
    }

    func testGenerateReward_noCosmetics_skipsCosmeticDrop() {
        var count = 0
        let context = MysteryBoxContext(lockedMoveIds: ["m"], availableCosmeticIds: [], streakShieldsMaxed: false)
        for _ in 0..<200 {
            let reward = MysteryBoxEngine.generateReward(context: context)
            if reward.type == .cosmeticDrop { count += 1 }
        }
        XCTAssertEqual(count, 0)
    }

    func testGenerateReward_shieldsMaxed_skipsBonusShield() {
        var count = 0
        let context = MysteryBoxContext(lockedMoveIds: ["m"], availableCosmeticIds: ["c"], streakShieldsMaxed: true)
        for _ in 0..<200 {
            let reward = MysteryBoxEngine.generateReward(context: context)
            if reward.type == .bonusShield { count += 1 }
        }
        XCTAssertEqual(count, 0)
    }

    func testGenerateReward_deterministicWithMockedRandom() {
        // roll = 0 → first eligible type wins (smallXP at drop rate 0.30).
        let reward = MysteryBoxEngine.generateReward(context: openContext, randomSource: { 0.0 })
        XCTAssertEqual(reward.type, .smallXP)
    }

    // MARK: - Public odds

    func testPublicOdds_sumToOne() {
        let odds = MysteryBoxEngine.publicOdds(context: openContext)
        let total = odds.reduce(0.0) { $0 + $1.rate }
        XCTAssertEqual(total, 1.0, accuracy: 0.001)
    }

    func testPublicOdds_skipsFilteredTypes() {
        let context = MysteryBoxContext(lockedMoveIds: [], availableCosmeticIds: [], streakShieldsMaxed: true)
        let odds = MysteryBoxEngine.publicOdds(context: context)
        let types = odds.map(\.type)
        XCTAssertFalse(types.contains(.moveAttempt))
        XCTAssertFalse(types.contains(.cosmeticDrop))
        XCTAssertFalse(types.contains(.bonusShield))
    }
}

final class MysteryBoxStoreTests: XCTestCase {
    var defaults: UserDefaults!
    var store: MysteryBoxStore!
    let childId = "box-test"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "MysteryBoxStoreTests")!
        defaults.removePersistentDomain(forName: "MysteryBoxStoreTests")
        store = MysteryBoxStore(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "MysteryBoxStoreTests")
        super.tearDown()
    }

    private func makeReward(at date: Date) -> MysteryReward {
        MysteryReward(id: UUID(), type: .smallXP, xpAmount: 25, cosmeticId: nil, moveAttemptMoveId: nil, openedAt: date)
    }

    func testBoxAvailable_trueByDefault() async {
        let available = await store.isBoxAvailable(childId: childId)
        XCTAssertTrue(available)
    }

    func testRecordOpen_flipsAvailableFalseSameDay() async {
        let now = Date()
        await store.recordOpen(reward: makeReward(at: now), childId: childId)
        let available = await store.isBoxAvailable(childId: childId, now: now)
        XCTAssertFalse(available)
    }

    func testRecordOpen_availableAgainNextDay() async {
        let now = Date()
        await store.recordOpen(reward: makeReward(at: now), childId: childId)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        let available = await store.isBoxAvailable(childId: childId, now: tomorrow)
        XCTAssertTrue(available)
    }

    func testBoxStreak_consecutiveDays() async {
        let now = Date()
        let calendar = Calendar.current
        for daysAgo in 0..<5 {
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
            await store.recordOpen(reward: makeReward(at: date), childId: childId)
        }
        let streak = await store.boxStreak(childId: childId, now: now)
        XCTAssertEqual(streak, 5)
    }

    func testBoxStreak_gapResets() async {
        let now = Date()
        let calendar = Calendar.current
        // Open today and 5 days ago — gap between
        await store.recordOpen(reward: makeReward(at: now), childId: childId)
        await store.recordOpen(reward: makeReward(at: calendar.date(byAdding: .day, value: -5, to: now)!), childId: childId)
        let streak = await store.boxStreak(childId: childId, now: now)
        XCTAssertEqual(streak, 1, "only today should count if yesterday is missing")
    }

    func testHistory_capsAt60Entries() async {
        let now = Date()
        let calendar = Calendar.current
        for i in 0..<70 {
            let date = calendar.date(byAdding: .day, value: -i, to: now)!
            await store.recordOpen(reward: makeReward(at: date), childId: childId)
        }
        let history = await store.getHistory(childId: childId)
        XCTAssertEqual(history.count, 60)
    }

    func testClear_resetsAll() async {
        await store.recordOpen(reward: makeReward(at: Date()), childId: childId)
        await store.clear(childId: childId)
        let available = await store.isBoxAvailable(childId: childId)
        let history = await store.getHistory(childId: childId)
        XCTAssertTrue(available)
        XCTAssertTrue(history.isEmpty)
    }
}
