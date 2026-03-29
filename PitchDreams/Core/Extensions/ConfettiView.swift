import SwiftUI

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var opacity: Double = 1.0
    @State private var elapsed: TimeInterval = 0

    private let particleCount = 60
    private let duration: TimeInterval = 3.0
    private let colors: [Color] = [.orange, .cyan, .green, .yellow, .purple, .pink]

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                if elapsed == 0 { return }
                let t = min(now - elapsed, duration)
                let fade = max(0, 1.0 - t / duration)

                for particle in particles {
                    let x = particle.startX * size.width + particle.velocityX * t
                    let y = particle.velocityY * t + 0.5 * 400 * t * t // gravity
                    let rotation = Angle.degrees(particle.rotationSpeed * t)
                    let scale = particle.size * max(0.3, 1.0 - t / duration)

                    var transform = context
                    transform.opacity = fade * particle.opacity
                    transform.translateBy(x: x, y: y)
                    transform.rotate(by: rotation)

                    let rect = CGRect(
                        x: -scale / 2,
                        y: -scale / 2,
                        width: scale,
                        height: scale * particle.aspectRatio
                    )
                    transform.fill(
                        RoundedRectangle(cornerRadius: 2).path(in: rect),
                        with: .color(particle.color)
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .onAppear {
            particles = (0..<particleCount).map { _ in
                ConfettiParticle(
                    startX: Double.random(in: 0.1...0.9),
                    velocityX: Double.random(in: -80...80),
                    velocityY: Double.random(in: 30...120),
                    rotationSpeed: Double.random(in: 90...720),
                    size: CGFloat.random(in: 6...14),
                    aspectRatio: CGFloat.random(in: 0.4...1.5),
                    opacity: Double.random(in: 0.7...1.0),
                    color: colors.randomElement() ?? .orange
                )
            }
            elapsed = Date.now.timeIntervalSinceReferenceDate
        }
    }
}

private struct ConfettiParticle {
    let startX: Double
    let velocityX: Double
    let velocityY: Double
    let rotationSpeed: Double
    let size: CGFloat
    let aspectRatio: CGFloat
    let opacity: Double
    let color: Color
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ConfettiView()
    }
}
