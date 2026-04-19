import SwiftUI

/// 2-second opening animation. Three visual phases per the mockup:
///  • Phase A (0.0-1.0s): box shakes ±5° with a cyan glow pulse
///  • Phase B (1.0-1.5s): lid lifts + vertical light beam + radial burst
///    in rarity color
///  • Phase C (1.5-2.0s): box dissolves to light, reward icon emerges
/// Auto-transitions to the reveal view when phase C completes.
///
/// Matches `proposals/Stitch/mystery_box_opening.png`.
struct MysteryBoxOpeningView: View {
    let reward: MysteryReward
    var onComplete: () -> Void

    enum Phase: Equatable { case shake, lift, emerge }

    @State private var phase: Phase = .shake
    @State private var shakeRotation: Double = 0
    @State private var lidLift: CGFloat = 0
    @State private var lidRotation: Double = 0
    @State private var lightOpacity: Double = 0
    @State private var boxScale: CGFloat = 1.0
    @State private var boxOpacity: Double = 1.0
    @State private var iconScale: CGFloat = 0.1
    @State private var iconOpacity: Double = 0
    @State private var radialBurstOpacity: Double = 0

    private var rarityColor: Color { Color(hex: reward.type.rarity.accentColorHex) }

    var body: some View {
        ZStack {
            // Deep dark base
            Color(hex: "#04070E").ignoresSafeArea()

            // Rarity radial burst — intensifies during lift/emerge
            RadialGradient(
                colors: [rarityColor.opacity(0.5), rarityColor.opacity(0.15), Color.clear],
                center: .center,
                startRadius: 20,
                endRadius: 400
            )
            .ignoresSafeArea()
            .opacity(radialBurstOpacity)

            // Box + lid + emerging icon
            ZStack {
                // Light beam — visible during lift/emerge
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [rarityColor.opacity(0.9), rarityColor.opacity(0.2), Color.clear],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 90, height: 320)
                    .offset(y: -120)
                    .blur(radius: 12)
                    .opacity(lightOpacity)

                // Box body
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#3A1F0E"), Color(hex: "#1F0F06")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 180, height: 150)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.dsAccentOrange)
                            .frame(width: 26, height: 150)
                    )
                    .scaleEffect(boxScale)
                    .opacity(boxOpacity)
                    .rotationEffect(.degrees(shakeRotation))

                // Lid — a flat orange rectangle that lifts + tilts off
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [Color.dsAccentOrange, Color(hex: "#C95020")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 200, height: 30)
                    .offset(y: -65 - lidLift)
                    .rotationEffect(.degrees(lidRotation), anchor: .bottomTrailing)
                    .shadow(color: Color.dsAccentOrange.opacity(0.5), radius: 8)
                    .opacity(boxOpacity)

                // Emerging reward icon — visible at the end
                Image(systemName: iconForReward())
                    .font(.system(size: 80, weight: .medium))
                    .foregroundStyle(rarityColor)
                    .shadow(color: rarityColor.opacity(0.8), radius: 20)
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)
                    .offset(y: -20)
            }

            // Frame label (for debug reference during Stitch matching — kept
            // hidden in production builds so the animation feels clean)
            VStack {
                Spacer()
                Text(phaseLabel)
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.15))
                    .padding(.bottom, 60)
            }
        }
        .onAppear(perform: startSequence)
    }

    private var phaseLabel: String {
        switch phase {
        case .shake:  return "KINETIC PREVIEW"
        case .lift:   return "POWER ASCENDING"
        case .emerge: return "REWARD MANIFEST"
        }
    }

    // MARK: - Sequence

    private func startSequence() {
        // Phase A — shake (0.0s - 1.0s)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.easeInOut(duration: 0.12).repeatCount(7, autoreverses: true)) {
            shakeRotation = 5
        }
        withAnimation(.easeIn(duration: 1.0)) {
            radialBurstOpacity = 0.3
        }

        // Phase B — lift (1.0s - 1.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            phase = .lift
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                lidLift = 60
                lidRotation = 35
                lightOpacity = 1.0
                radialBurstOpacity = 0.7
            }
        }

        // Phase C — emerge (1.5s - 2.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            phase = .emerge
            withAnimation(.easeOut(duration: 0.45)) {
                boxOpacity = 0
                boxScale = 1.25
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.55).delay(0.1)) {
                iconOpacity = 1
                iconScale = 1.0
            }
        }

        // Complete — hand off to reveal
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            onComplete()
        }
    }

    // MARK: - Icon mapping

    /// Pick an appropriate SF Symbol for the reward type, used during the
    /// emerge phase. Matched up with the reveal screen's iconography.
    private func iconForReward() -> String {
        switch reward.type {
        case .smallXP, .mediumXP, .mysteryReward:
            return "bolt.fill"
        case .moveAttempt:
            return "scissors"
        case .feverTime:
            return "flame.fill"
        case .cosmeticDrop:
            return "paintpalette.fill"
        case .bonusShield:
            return "shield.fill"
        case .legendaryDrop:
            return "crown.fill"
        }
    }
}
