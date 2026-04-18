import SwiftUI

/// Home-dashboard banner shown when GPS confirms the child is at a known
/// pitch. Highlights the active 2× XP multiplier. Tapping jumps to the
/// saved-pitches list so they can rename or review.
///
/// Matches `proposals/Stitch/pitch_location_banner.png`.
struct PitchLocationBanner: View {
    let pitch: TrainingPitch
    var onTap: () -> Void = {}

    @State private var badgePulse: CGFloat = 1.0

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap()
        }) {
            HStack(spacing: 14) {
                // Left soccer-ball tile
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.dsSecondary.opacity(0.18))
                        .frame(width: 52, height: 52)
                    Text("⚽️")
                        .font(.system(size: 24))
                }

                // Text stack
                VStack(alignment: .leading, spacing: 3) {
                    Text("YOU'RE AT THE PITCH")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(Color.dsSecondary)
                    Text(pitch.displayName.uppercased())
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(Color.dsOnSurface)
                        .lineLimit(1)
                    Text("Bonus XP active — 2× multiplier for this session")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.dsTertiaryContainer)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                Spacer(minLength: 0)

                // 2× badge (pulsing)
                Text("2×")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.dsTertiaryContainer)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.dsTertiaryContainer.opacity(0.15))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color.dsTertiaryContainer.opacity(0.4), lineWidth: 1)
                    )
                    .scaleEffect(badgePulse)
            }
            .padding(14)
            .background(Color.dsSurfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(Color.dsSecondary.opacity(0.35), lineWidth: 1.5)
            )
            .shadow(color: Color.dsSecondary.opacity(0.15), radius: 12)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("You're at \(pitch.displayName). 2× XP bonus active.")
        .onAppear {
            withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) {
                badgePulse = 1.08
            }
        }
    }
}

#Preview {
    ZStack {
        Color.dsBackground.ignoresSafeArea()
        PitchLocationBanner(
            pitch: TrainingPitch(
                id: "p1",
                nickname: "Home Pitch",
                centerLatitude: 37.78,
                centerLongitude: -122.4,
                radiusMeters: 75,
                firstVisitedAt: Date(),
                lastVisitedAt: Date(),
                visitCount: 12,
                isHomePitch: true
            )
        )
        .padding()
    }
}
