import XCTest
@testable import PitchDreams

final class BallPhysicsTests: XCTestCase {

    // MARK: - Parabolic Arc

    func testArcAtProgressZeroReturnsFrom() {
        let from = CGPoint(x: 10, y: 100)
        let to = CGPoint(x: 200, y: 50)
        let result = BallPhysics.parabolicArc(from: from, to: to, height: 50, progress: 0)
        XCTAssertEqual(result.x, from.x, accuracy: 0.01)
        XCTAssertEqual(result.y, from.y, accuracy: 0.01)
    }

    func testArcAtProgressOneReturnsTo() {
        let from = CGPoint(x: 10, y: 100)
        let to = CGPoint(x: 200, y: 50)
        let result = BallPhysics.parabolicArc(from: from, to: to, height: 50, progress: 1)
        XCTAssertEqual(result.x, to.x, accuracy: 0.01)
        XCTAssertEqual(result.y, to.y, accuracy: 0.01)
    }

    func testArcAtMidpointOffsetByHeight() {
        let from = CGPoint(x: 0, y: 100)
        let to = CGPoint(x: 100, y: 100)
        let height: CGFloat = 40

        let mid = BallPhysics.parabolicArc(from: from, to: to, height: height, progress: 0.5)

        // At midpoint, x should be halfway
        XCTAssertEqual(mid.x, 50, accuracy: 0.01)
        // y should be offset by height (parabola peaks at t=0.5)
        // yBase = 100, yOffset = -4 * 40 * 0.5 * (0.5-1) = -4*40*0.5*(-0.5) = 40
        // y = 100 - 40 = 60... wait, let me recalculate
        // yOffset = -4 * height * t * (t - 1) = -4 * 40 * 0.5 * (-0.5) = 40
        // y = yBase - yOffset = 100 - 40 = 60
        XCTAssertEqual(mid.y, 60, accuracy: 0.01)
    }

    // MARK: - Bounce Sequence

    func testBounceAtZeroReturnsStart() {
        let start = CGPoint(x: 50, y: 200)
        let result = BallPhysics.bounceSequence(start: start, bounceCount: 3, progress: 0)
        XCTAssertEqual(result.x, start.x, accuracy: 0.01)
        XCTAssertEqual(result.y, start.y, accuracy: 0.01)
    }

    func testBounceGroundContacts() {
        let start = CGPoint(x: 50, y: 200)
        // At the end of each bounce segment, ball should return near ground level
        let endOfFirstBounce = BallPhysics.bounceSequence(start: start, bounceCount: 3, progress: 0.333)
        // Should be close to start.y (ground level)
        XCTAssertEqual(endOfFirstBounce.y, start.y, accuracy: 1.0)
    }

    // MARK: - Linear Travel

    func testLinearInterpolation() {
        let from = CGPoint(x: 0, y: 0)
        let to = CGPoint(x: 100, y: 200)

        let mid = BallPhysics.linearTravel(from: from, to: to, progress: 0.5)
        XCTAssertEqual(mid.x, 50, accuracy: 0.01)
        XCTAssertEqual(mid.y, 100, accuracy: 0.01)

        let quarter = BallPhysics.linearTravel(from: from, to: to, progress: 0.25)
        XCTAssertEqual(quarter.x, 25, accuracy: 0.01)
        XCTAssertEqual(quarter.y, 50, accuracy: 0.01)
    }

    func testLinearAtZeroReturnsFrom() {
        let from = CGPoint(x: 10, y: 20)
        let to = CGPoint(x: 100, y: 200)
        let result = BallPhysics.linearTravel(from: from, to: to, progress: 0)
        XCTAssertEqual(result.x, from.x, accuracy: 0.01)
        XCTAssertEqual(result.y, from.y, accuracy: 0.01)
    }

    func testLinearAtOneReturnsTo() {
        let from = CGPoint(x: 10, y: 20)
        let to = CGPoint(x: 100, y: 200)
        let result = BallPhysics.linearTravel(from: from, to: to, progress: 1)
        XCTAssertEqual(result.x, to.x, accuracy: 0.01)
        XCTAssertEqual(result.y, to.y, accuracy: 0.01)
    }

    // MARK: - Edge Cases

    func testProgressClampedBelow() {
        let from = CGPoint(x: 0, y: 0)
        let to = CGPoint(x: 100, y: 100)
        let result = BallPhysics.linearTravel(from: from, to: to, progress: -0.5)
        XCTAssertEqual(result.x, from.x, accuracy: 0.01)
    }

    func testProgressClampedAbove() {
        let from = CGPoint(x: 0, y: 0)
        let to = CGPoint(x: 100, y: 100)
        let result = BallPhysics.linearTravel(from: from, to: to, progress: 1.5)
        XCTAssertEqual(result.x, to.x, accuracy: 0.01)
    }
}
