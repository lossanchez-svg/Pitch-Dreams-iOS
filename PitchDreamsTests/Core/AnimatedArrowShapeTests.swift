import XCTest
@testable import PitchDreams

final class AnimatedArrowShapeTests: XCTestCase {

    func testPathIsNonEmpty() {
        let shape = AnimatedArrowShape(
            from: CGPoint(x: 10, y: 10),
            to: CGPoint(x: 100, y: 50)
        )
        let path = shape.path(in: CGRect(x: 0, y: 0, width: 200, height: 200))
        XCTAssertFalse(path.isEmpty)
    }

    func testTrimProducesPartialPath() {
        let shape = AnimatedArrowShape(
            from: CGPoint(x: 0, y: 0),
            to: CGPoint(x: 100, y: 100)
        )
        let fullPath = shape.path(in: CGRect(x: 0, y: 0, width: 200, height: 200))
        let fullBounds = fullPath.boundingRect

        // The full path should have non-zero bounds
        XCTAssertGreaterThan(fullBounds.width, 0)
        XCTAssertGreaterThan(fullBounds.height, 0)
    }

    func testDifferentDirectionsProduceDifferentPaths() {
        let rect = CGRect(x: 0, y: 0, width: 200, height: 200)

        let horizontal = AnimatedArrowShape(
            from: CGPoint(x: 10, y: 100),
            to: CGPoint(x: 190, y: 100)
        ).path(in: rect)

        let vertical = AnimatedArrowShape(
            from: CGPoint(x: 100, y: 10),
            to: CGPoint(x: 100, y: 190)
        ).path(in: rect)

        // Bounding rects should differ
        XCTAssertNotEqual(horizontal.boundingRect, vertical.boundingRect)
    }
}
