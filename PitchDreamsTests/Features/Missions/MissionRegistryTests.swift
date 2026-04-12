import XCTest
@testable import PitchDreams

final class MissionRegistryTests: XCTestCase {
    func testWeeklyMissionsIsDeterministic() {
        let a = MissionRegistry.weeklyMissions(childId: "child-123", weekKey: "2026-W15")
        let b = MissionRegistry.weeklyMissions(childId: "child-123", weekKey: "2026-W15")
        XCTAssertEqual(a.map(\.id), b.map(\.id))
        XCTAssertEqual(a.count, 3)
    }

    func testWeeklyMissionsDiffersAcrossWeeks() {
        let week15 = MissionRegistry.weeklyMissions(childId: "child-abc", weekKey: "2026-W15")
        let week16 = MissionRegistry.weeklyMissions(childId: "child-abc", weekKey: "2026-W16")
        // They *may* overlap, but the full 3-tuple should almost never match.
        XCTAssertNotEqual(week15.map(\.id), week16.map(\.id))
    }

    func testWeeklyMissionsDiffersAcrossChildren() {
        let kidA = MissionRegistry.weeklyMissions(childId: "alice", weekKey: "2026-W15")
        let kidB = MissionRegistry.weeklyMissions(childId: "bob", weekKey: "2026-W15")
        XCTAssertNotEqual(kidA.map(\.id), kidB.map(\.id))
    }

    func testWeeklyMissionsHasThreeDistinctMissions() {
        let missions = MissionRegistry.weeklyMissions(childId: "x", weekKey: "2026-W20")
        XCTAssertEqual(missions.count, 3)
        XCTAssertEqual(Set(missions.map(\.id)).count, 3, "Missions should be distinct")
    }

    func testWeekKeyFormat() {
        let key = MissionRegistry.weekKey(for: Date(timeIntervalSince1970: 1_712_534_400)) // 2024-04-08
        XCTAssertTrue(key.contains("-W"))
        XCTAssertEqual(key.count, 8)
    }

    func testEventTypeMatchingThreshold() {
        let mission: MissionEventType = .wallBallReps(min: 30)
        XCTAssertTrue(mission.matches(incoming: .wallBallReps(min: 0), count: 30))
        XCTAssertTrue(mission.matches(incoming: .wallBallReps(min: 0), count: 100))
        XCTAssertFalse(mission.matches(incoming: .wallBallReps(min: 0), count: 29))
        XCTAssertFalse(mission.matches(incoming: .jugglingTaps(min: 0), count: 100))
    }

    func testEventTypeMatchingSimple() {
        XCTAssertTrue(MissionEventType.sessionLogged.matches(incoming: .sessionLogged, count: 1))
        XCTAssertTrue(MissionEventType.lessonRead.matches(incoming: .lessonRead, count: 1))
        XCTAssertFalse(MissionEventType.sessionLogged.matches(incoming: .lessonRead, count: 1))
    }
}
