import SwiftUI

/// Deterministic particle positions (index-seeded, not random) for reproducible rendering.
struct ParticleFieldView: View {
    let count: Int
    let color: Color
    let progress: CGFloat

    var body: some View {
        Canvas { context, size in
            let fadeIn = min(1.0, progress * 2.5)
            let fadeOut = max(0, 1.0 - (progress - 0.6) / 0.4)
            let opacity = min(fadeIn, fadeOut)

            guard opacity > 0 else { return }

            for i in 0..<count {
                let seed = CGFloat(i)

                // Deterministic positions seeded from index
                let baseAngle = CGFloat.pi * 2 * seed / CGFloat(count)
                let radius = min(size.width, size.height) * (0.15 + seed.truncatingRemainder(dividingBy: 3) * 0.12)

                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let expandedRadius = radius * (0.5 + progress * 0.8)

                let x = center.x + cos(baseAngle) * expandedRadius
                let y = center.y + sin(baseAngle) * expandedRadius

                // Particle size shrinks as it disperses
                let particleSize = max(1, 4.0 * (1.0 - progress * 0.6))

                // Stagger opacity per particle
                let particleDelay = seed * 0.05
                let particleOpacity = opacity * max(0, min(1, (progress - particleDelay) * 3))

                let rect = CGRect(
                    x: x - particleSize / 2,
                    y: y - particleSize / 2,
                    width: particleSize,
                    height: particleSize
                )

                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(color.opacity(particleOpacity))
                )
            }
        }
        .allowsHitTesting(false)
    }
}
