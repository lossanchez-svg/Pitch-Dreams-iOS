import SwiftUI

/// Full-screen mastery celebration — the single most emotional screen in
/// the move journey. Rarity-tinted radial burst behind a glowing move icon,
/// the mastered move name in huge type, "+N XP" badge, and a primary CTA
/// that routes to the Player Card editor loadout slot.
///
/// Matches `proposals/Stitch/signature_move_unlocked_celebration.png`.
struct SignatureMoveUnlockedView: View {
    let move: SignatureMove
    let xpAwarded: Int
    let onDismiss: () -> Void

    @State private var showCelebration = false
    @State private var iconScale: CGFloat = 0.3
    @State private var xpPulse: CGFloat = 1.0

    var body: some View {
        ZStack {
            radialBurstBackground

            VStack(spacing: 28) {
                header
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, 8)

                Spacer()

                Text("MASTERED!")
                    .font(.system(size: 52, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: rarityColor.opacity(0.6), radius: 18)

                Text(move.name)
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(rarityColor)

                Image(systemName: move.iconSymbolName)
                    .font(.system(size: 120, weight: .medium))
                    .foregroundStyle(rarityColor)
                    .shadow(color: rarityColor.opacity(0.7), radius: 26)
                    .scaleEffect(iconScale)

                Text("\u{201C}\(move.famousFor)\u{201D}")
                    .font(.system(size: 13, weight: .medium))
                    .italic()
                    .foregroundStyle(Color.dsOnSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                xpBadge

                Spacer()

                currentLoadoutRow
                    .padding(.horizontal, Spacing.xl)

                addToCardCTA
                    .padding(.horizontal, Spacing.xl)
                    .padding(.bottom, 28)
            }
        }
        .celebration(isPresented: $showCelebration)
        .onAppear {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            withAnimation(.spring(response: 0.7, dampingFraction: 0.55).delay(0.1)) {
                iconScale = 1.0
            }
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                xpPulse = 1.08
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showCelebration = true
            }
        }
    }

    // MARK: - Styling

    private var rarityColor: Color { Color(hex: move.rarity.accentColorHex) }

    private var radialBurstBackground: some View {
        ZStack {
            Color.dsBackground
            RadialGradient(
                colors: [
                    rarityColor.opacity(0.45),
                    rarityColor.opacity(0.15),
                    Color.clear
                ],
                center: .center,
                startRadius: 10,
                endRadius: 420
            )
            // Subtle radiating streaks
            ForEach(0..<16, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(rarityColor.opacity(0.15))
                    .frame(width: 2, height: 200)
                    .offset(y: -140)
                    .rotationEffect(.degrees(Double(i) * 22.5))
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button { onDismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Close celebration")
            Spacer()
            Text("SESSION COMPLETE")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color.dsAccentOrange)
            Spacer()
            Color.clear.frame(width: 32, height: 32)
        }
    }

    // MARK: - XP badge

    private var xpBadge: some View {
        HStack(spacing: 10) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 18))
                .foregroundStyle(Color.dsTertiaryContainer)
            Text("+\(xpAwarded) XP")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.dsTertiaryContainer)
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 14)
        .background(Color.dsTertiaryContainer.opacity(0.15))
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(Color.dsTertiaryContainer.opacity(0.4), lineWidth: 1)
        )
        .scaleEffect(xpPulse)
    }

    // MARK: - Loadout row

    private var currentLoadoutRow: some View {
        VStack(spacing: 10) {
            Text("CURRENT LOADOUT")
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color.dsOnSurfaceVariant)
            HStack(spacing: 12) {
                // First slot shows the just-mastered move; the other 3 are empty.
                loadoutSlot(isFilledWithThisMove: true)
                ForEach(0..<3, id: \.self) { _ in
                    loadoutSlot(isFilledWithThisMove: false)
                }
            }
        }
    }

    private func loadoutSlot(isFilledWithThisMove: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.dsSurfaceContainerLow)
                .frame(width: 56, height: 56)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFilledWithThisMove ? rarityColor : Color.white.opacity(0.05), lineWidth: isFilledWithThisMove ? 2 : 1)
                )
            if isFilledWithThisMove {
                Image(systemName: move.iconSymbolName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(rarityColor)
            } else {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.dsOnSurfaceVariant.opacity(0.5))
            }
        }
    }

    // MARK: - Primary CTA

    private var addToCardCTA: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            // For launch, tap just dismisses back to the library; the Player
            // Card editor surfaces the new move automatically on its next load.
            onDismiss()
        } label: {
            Text("ADD TO MY CARD")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color.dsCTALabel)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(DSGradient.primaryCTA)
                .clipShape(Capsule())
                .dsPrimaryShadow()
        }
    }
}

#Preview {
    SignatureMoveUnlockedView(
        move: SignatureMoveRegistry.laCroqueta,
        xpAwarded: 250,
        onDismiss: {}
    )
}
