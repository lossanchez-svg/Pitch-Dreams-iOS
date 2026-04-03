import CoreGraphics

/// Pure math functions for ball trajectory calculations.
/// All functions take `progress` in 0.0–1.0 and return a point.
enum BallPhysics {

    /// Parabolic arc from `from` to `to` with peak `height` above the midpoint.
    static func parabolicArc(
        from: CGPoint,
        to: CGPoint,
        height: CGFloat,
        progress: CGFloat
    ) -> CGPoint {
        let t = max(0, min(1, progress))
        let x = from.x + (to.x - from.x) * t
        // Parabola: -4h * t * (t - 1) peaks at t=0.5
        let yBase = from.y + (to.y - from.y) * t
        let yOffset = -4 * height * t * (t - 1)
        return CGPoint(x: x, y: yBase - yOffset)
    }

    /// Sequence of bounces starting at `start`, each bounce lower than the last.
    /// Returns the y position (bouncing upward from start.y).
    static func bounceSequence(
        start: CGPoint,
        bounceCount: Int,
        progress: CGFloat
    ) -> CGPoint {
        let t = max(0, min(1, progress))
        let count = max(1, bounceCount)
        let segmentLength = 1.0 / CGFloat(count)

        let currentBounce = min(Int(t / segmentLength), count - 1)
        let localT = (t - CGFloat(currentBounce) * segmentLength) / segmentLength

        // Each bounce is shorter: height decays exponentially
        let decay = pow(0.6, CGFloat(currentBounce))
        let bounceHeight = 80.0 * decay

        // Parabolic arc within each bounce segment
        let yOffset = -4 * bounceHeight * localT * (localT - 1)

        return CGPoint(x: start.x, y: start.y - yOffset)
    }

    /// Simple linear interpolation from `from` to `to`.
    static func linearTravel(
        from: CGPoint,
        to: CGPoint,
        progress: CGFloat
    ) -> CGPoint {
        let t = max(0, min(1, progress))
        return CGPoint(
            x: from.x + (to.x - from.x) * t,
            y: from.y + (to.y - from.y) * t
        )
    }
}
