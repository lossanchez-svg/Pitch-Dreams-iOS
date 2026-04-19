import SwiftUI

/// Home-dashboard Mystery Box component. Two states:
///  - **Available** (default): gradient gift-box icon with orange bow, "TAP
///    TO OPEN" CTA, box-streak counter beneath.
///  - **Cooldown**: dimmed box, "COME BACK TOMORROW" badge, live
///    "NEXT BOX IN HH:MM:SS" countdown.
///
/// Matches `proposals/Stitch/mystery_box_closed.png`.
struct MysteryBoxCardView: View {
    @ObservedObject var viewModel: MysteryBoxViewModel
    var onTap: () -> Void

    @State private var pulseScale: CGFloat = 1.0
    @State private var tickTimer: Timer?
    @State private var liveCountdown: TimeInterval = 0

    var body: some View {
        Group {
            if viewModel.isAvailable {
                availableContent
            } else {
                cooldownContent
            }
        }
        .onAppear {
            liveCountdown = viewModel.secondsUntilNextBox
            startPulse()
            startTickTimer()
        }
        .onDisappear {
            tickTimer?.invalidate()
            tickTimer = nil
        }
    }

    // MARK: - Available

    private var availableContent: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onTap()
        } label: {
            HStack(spacing: 16) {
                giftBoxArt
                    .frame(width: 120, height: 120)

                VStack(alignment: .leading, spacing: 6) {
                    Text("TODAY'S MYSTERY")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(3)
                        .foregroundStyle(Color.dsTertiary)
                    Text("TAP TO OPEN")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(Color.dsAccentOrange)
                    if viewModel.boxStreak > 1 {
                        HStack(spacing: 4) {
                            Text("🎁")
                                .font(.system(size: 12))
                            Text("\(viewModel.boxStreak) DAY BOX STREAK")
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .tracking(1)
                                .foregroundStyle(Color.dsAccentOrange.opacity(0.9))
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(16)
            .background(
                ZStack {
                    Color.dsSurfaceContainerLow
                    RadialGradient(
                        colors: [Color.dsAccentOrange.opacity(0.22), Color.clear],
                        center: .init(x: 0.3, y: 0.5),
                        startRadius: 8,
                        endRadius: 200
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            .ghostBorder()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Today's mystery box. Tap to open. \(viewModel.boxStreak) day box streak.")
        .accessibilityHint("Daily reward loot box.")
    }

    // MARK: - Cooldown

    private var cooldownContent: some View {
        HStack(spacing: 16) {
            giftBoxArt
                .frame(width: 100, height: 100)
                .grayscale(0.9)
                .opacity(0.5)

            VStack(alignment: .leading, spacing: 6) {
                Text("COME BACK TOMORROW")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(3)
                    .foregroundStyle(Color.dsOnSurfaceVariant)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.dsSurfaceContainerHigh)
                    .clipShape(Capsule())
                Text("NEXT BOX IN \(formattedCountdown)")
                    .font(.system(size: 15, weight: .heavy, design: .rounded).monospacedDigit())
                    .foregroundStyle(Color.dsOnSurface)
                Text("STREAK PROTECTED")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color.dsSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color.dsSurfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .ghostBorder()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Mystery box already opened today. Next box in \(formattedCountdown). Streak protected.")
    }

    private var formattedCountdown: String {
        let total = Int(max(0, liveCountdown))
        let hours = total / 3600
        let mins = (total % 3600) / 60
        let secs = total % 60
        return String(format: "%02d:%02d:%02d", hours, mins, secs)
    }

    // MARK: - Gift-box art

    private var giftBoxArt: some View {
        ZStack {
            RadialGradient(
                colors: [Color.dsAccentOrange.opacity(0.45), Color.clear],
                center: .center,
                startRadius: 8,
                endRadius: 80
            )
            .frame(width: 140, height: 140)
            .blur(radius: 10)
            .opacity(viewModel.isAvailable ? 1 : 0)

            // Box body
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#3A1F0E"), Color(hex: "#1F0F06")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 84, height: 70)
                .overlay(
                    // Ribbon vertical
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.dsAccentOrange)
                        .frame(width: 12, height: 70)
                )
                .offset(y: 10)

            // Bow
            ZStack {
                Circle()
                    .fill(Color.dsAccentOrange)
                    .frame(width: 20, height: 20)
                    .offset(x: -10)
                Circle()
                    .fill(Color.dsAccentOrange)
                    .frame(width: 20, height: 20)
                    .offset(x: 10)
                Circle()
                    .fill(Color.dsTertiary)
                    .frame(width: 8, height: 8)
            }
            .offset(y: -18)

            // Sparkles
            ForEach(0..<4, id: \.self) { i in
                Image(systemName: "sparkle")
                    .font(.system(size: [12, 8, 10, 6][i]))
                    .foregroundStyle(Color.dsTertiary)
                    .offset(sparkleOffset(i))
            }
        }
        .scaleEffect(pulseScale)
    }

    private func sparkleOffset(_ i: Int) -> CGSize {
        let offsets: [CGSize] = [
            CGSize(width: -40, height: -30),
            CGSize(width: 42, height: -20),
            CGSize(width: -44, height: 30),
            CGSize(width: 38, height: 38)
        ]
        return offsets[i]
    }

    // MARK: - Timers

    private func startPulse() {
        guard viewModel.isAvailable else { return }
        withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
            pulseScale = 1.04
        }
    }

    private func startTickTimer() {
        tickTimer?.invalidate()
        guard !viewModel.isAvailable else { return }
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                liveCountdown = max(0, liveCountdown - 1)
                if liveCountdown == 0 {
                    await viewModel.load()
                }
            }
        }
    }
}
