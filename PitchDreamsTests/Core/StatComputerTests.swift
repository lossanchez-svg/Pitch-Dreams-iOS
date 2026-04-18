import XCTest
@testable import PitchDreams

final class StatComputerTests: XCTestCase {
    var defaults: UserDefaults!
    var xpStore: XPStore!
    var computer: StatComputer!
    let childId = "stat-test"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "StatComputerTests")!
        defaults.removePersistentDomain(forName: "StatComputerTests")
        xpStore = XPStore(defaults: defaults)
        computer = StatComputer(xpStore: xpStore)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "StatComputerTests")
        super.tearDown()
    }

    private func makeCard(archetype: PlayerArchetype = .allrounder) -> PlayerCard {
        PlayerCard(
            childId: childId,
            archetype: archetype,
            displayedStats: [.speed, .touch, .vision, .workRate],
            moveLoadout: [],
            clubCrestDesign: .defaultDesign,
            cardFrame: .standard,
            archetypeTagline: nil
        )
    }

    private func makeSession(focus: String? = nil) -> SessionLog {
        SessionLog(
            id: UUID().uuidString,
            childId: childId,
            activityType: "SELF_TRAINING",
            effortLevel: 5,
            mood: "FOCUSED",
            duration: 30,
            win: nil,
            focus: focus,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
    }

    func testBaselineReturnedWithNoSessions() async {
        let card = makeCard(archetype: .speedster)
        let stats = await computer.computeStats(for: card, sessions: [])
        XCTAssertEqual(stats.speed, 90, "speedster baseline speed is 90 with no sessions")
    }

    func testVolumeBonus_appliesAtEvery50Sessions() async {
        let card = makeCard(archetype: .allrounder)
        let sessions = (0..<50).map { _ in makeSession() }
        let stats = await computer.computeStats(for: card, sessions: sessions)
        // Allrounder baseline is 75 everywhere; +1 volume bonus from 50 sessions.
        XCTAssertEqual(stats.speed, 76)
    }

    func testVolumeBonus_capsAt10() async {
        let card = makeCard(archetype: .allrounder)
        let sessions = (0..<1000).map { _ in makeSession() }
        let stats = await computer.computeStats(for: card, sessions: sessions)
        // Capped at +10 everywhere → baseline 75 + 10 = 85.
        // (Plus any XP bonus, which is 0 since we didn't add XP.)
        XCTAssertEqual(stats.speed, 85)
    }

    func testBallMastery_bumpsTouch() async {
        let card = makeCard(archetype: .allrounder)
        let sessions = (0..<30).map { _ in makeSession(focus: "ball_mastery") }
        let stats = await computer.computeStats(for: card, sessions: sessions)
        // Allrounder touch 75 + 0 volume bonus (need 50 sessions) + 3 ball-mastery (30/10).
        XCTAssertEqual(stats.touch, 78)
    }

    func testShooting_bumpsShotPower() async {
        let card = makeCard(archetype: .allrounder)
        let sessions = (0..<16).map { _ in makeSession(focus: "shooting") }
        let stats = await computer.computeStats(for: card, sessions: sessions)
        // 16/8 = +2 shot power.
        XCTAssertEqual(stats.shotPower, 77)
    }

    func testXPBonus_bumpsWorkRateAndComposure() async {
        let card = makeCard(archetype: .allrounder)
        _ = await xpStore.addXP(1500, childId: childId)
        let stats = await computer.computeStats(for: card, sessions: [])
        // 1500/500 = +3 workRate + +3 composure.
        XCTAssertEqual(stats.workRate, 78)
        XCTAssertEqual(stats.composure, 78)
    }

    func testStatsClampAt99() async {
        let card = makeCard(archetype: .magician)
        // Pile on so the cap is exceeded.
        _ = await xpStore.addXP(100_000, childId: childId)
        let shooting = (0..<500).map { _ in makeSession(focus: "shooting") }
        let ball = (0..<500).map { _ in makeSession(focus: "ball_mastery") }
        let stats = await computer.computeStats(for: card, sessions: shooting + ball)
        XCTAssertLessThanOrEqual(stats.touch, 99)
        XCTAssertLessThanOrEqual(stats.shotPower, 99)
        XCTAssertLessThanOrEqual(stats.workRate, 99)
    }

    func testOverallRating_averagesDisplayedStats() async {
        let stats = CardStats(speed: 90, touch: 80, vision: 70, shotPower: 60, workRate: 50, composure: 40)
        let rating = await computer.overallRating(
            stats: stats,
            displayed: [.speed, .touch, .vision, .workRate]
        )
        // (90 + 80 + 70 + 50) / 4 = 72.5 → rounded 73
        XCTAssertEqual(rating, 73)
    }
}
