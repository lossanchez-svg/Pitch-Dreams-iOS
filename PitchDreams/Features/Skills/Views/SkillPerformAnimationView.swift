import SwiftUI

/// Canvas-based skill performance animation driven by `TimelineView(.animation)`.
/// Uses `progress: CGFloat` (0.0-1.0) for 60fps frame rendering.
struct SkillPerformAnimationView: View {
    let animationKey: SkillAnimationKey
    let isPlaying: Bool
    var onComplete: (() -> Void)?
    var accentColor: Color = .cyan

    @State private var startDate: Date?
    @State private var phase: AnimationPhase = .idle
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var config: SkillAnimationConfig {
        SkillAnimationRegistry.config(for: animationKey)
    }

    enum AnimationPhase {
        case idle, active, complete
    }

    var body: some View {
        TimelineView(.animation(paused: !isPlaying || phase == .complete)) { timeline in
            let progress = computeProgress(at: timeline.date)

            ZStack {
                // Background glow
                RadialGradient(
                    colors: [accentColor.opacity(0.15), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 100
                )

                // Speed lines layer
                SpeedLinesView(
                    direction: config.speedLineDirection,
                    color: accentColor,
                    progress: progress
                )

                // Main skill animation
                Canvas { context, size in
                    SkillAnimationRenderer.draw(
                        key: animationKey,
                        context: &context,
                        size: size,
                        progress: progress,
                        accentColor: accentColor
                    )
                }

                // Particle field
                ParticleFieldView(
                    count: 8,
                    color: accentColor,
                    progress: progress
                )

                // Impact flash
                if config.hasImpactFlash && progress > 0.6 {
                    let flashProgress = (progress - 0.6) / 0.4
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [accentColor.opacity(0.6 * (1 - flashProgress)), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 60 * flashProgress
                            )
                        )
                        .allowsHitTesting(false)
                }
            }
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onChange(of: isPlaying) { playing in
            if playing {
                startDate = Date()
                phase = .active
            } else {
                phase = .idle
                startDate = nil
            }
        }
    }

    private func computeProgress(at date: Date) -> CGFloat {
        guard let start = startDate, phase == .active else { return 0 }

        let elapsed = date.timeIntervalSince(start)
        let duration = reduceMotion ? max(0.5, config.durationSeconds) : config.durationSeconds
        let progress = min(1.0, CGFloat(elapsed / duration))

        if progress >= 1.0 && phase == .active {
            DispatchQueue.main.async {
                phase = .complete
                onComplete?()
            }
        }

        return progress
    }
}
