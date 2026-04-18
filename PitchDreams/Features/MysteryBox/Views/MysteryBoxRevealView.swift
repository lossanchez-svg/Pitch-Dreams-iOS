import SwiftUI

/// Reward-reveal screen. Style + copy shift by rarity tier so common drops
/// feel small-but-nice, rare drops feel earned, and legendary drops feel
/// jackpot-y. The mockup composite has all three variants; here we render
/// the one matching the given reward.
///
/// Matches `proposals/Stitch/mystery_box_reveal.png`.
struct MysteryBoxRevealView: View {
    let reward: MysteryReward
    var onDismiss: () -> Void

    private var rarityColor: Color { Color(hex: reward.type.rarity.accentColorHex) }

    var body: some View {
        ZStack {
            // Dark base + rarity-tinted radial burst
            Color.dsBackground.ignoresSafeArea()
            RadialGradient(
                colors: [rarityColor.opacity(0.45), rarityColor.opacity(0.1), Color.clear],
                center: .init(x: 0.5, y: 0.38),
                startRadius: 10,
                endRadius: 360
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, 8)

                Spacer()

                content
                    .padding(.horizontal, Spacing.xl)

                Spacer()

                ctas
                    .padding(.horizontal, Spacing.xl)
                    .padding(.bottom, 32)
            }
        }
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
            .accessibilityLabel("Close reveal")
            Spacer()
            Text("REWARD REVEAL")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color.dsAccentOrange)
            Spacer()
            Color.clear.frame(width: 32, height: 32)
        }
    }

    // MARK: - Content (rarity-specific)

    @ViewBuilder
    private var content: some View {
        switch reward.type {
        case .smallXP, .mediumXP:
            xpDropVariant
        case .bonusShield:
            shieldDropVariant
        case .feverTime:
            feverTimeVariant
        case .cosmeticDrop:
            cosmeticVariant
        case .moveAttempt:
            moveAttemptVariant
        case .mysteryReward:
            mysteryRewardVariant
        case .legendaryDrop:
            legendaryVariant
        }
    }

    // MARK: - Variants

    private var xpDropVariant: some View {
        VStack(spacing: 20) {
            glowingIconCircle(symbol: "bolt.fill", size: 86, iconSize: 32, color: rarityColor)
            Text("COMMON DROP")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color.dsOnSurfaceVariant)
            Text("+\(reward.xpAmount ?? 0) XP")
                .font(.system(size: 64, weight: .heavy, design: .rounded).monospacedDigit())
                .foregroundStyle(Color.dsAccentOrange)
                .shadow(color: Color.dsAccentOrange.opacity(0.4), radius: 12)
            Text("Small bonus. Keep the streak alive.")
                .font(.system(size: 13, weight: .medium))
                .italic()
                .foregroundStyle(Color.dsSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var shieldDropVariant: some View {
        VStack(spacing: 20) {
            glowingIconCircle(symbol: "shield.fill", size: 110, iconSize: 44, color: rarityColor)
            Text("STREAK SHIELD")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color.dsOnSurfaceVariant)
            Text("BONUS SHIELD")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.dsSecondary)
            Text("One extra save for your streak — use it when you miss a day.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.dsOnSurfaceVariant)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
    }

    private var feverTimeVariant: some View {
        VStack(spacing: 20) {
            glowingIconCircle(symbol: "flame.fill", size: 110, iconSize: 44, color: Color.dsAccentOrange)
            Text("RARE DROP")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color.dsAccentOrange)
            Text("FEVER TIME")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Text("3× XP for the next 15 minutes. Train now to stack it.")
                .font(.system(size: 13, weight: .medium))
                .italic()
                .foregroundStyle(Color.dsOnSurfaceVariant)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
    }

    private var cosmeticVariant: some View {
        VStack(spacing: 20) {
            glowingIconCircle(symbol: "paintpalette.fill", size: 110, iconSize: 44, color: rarityColor)
            Text("RARE DROP")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(rarityColor)
            Text("COSMETIC UNLOCK")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Text("A new style for your Player Card. Try it from the editor.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.dsOnSurfaceVariant)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
    }

    private var moveAttemptVariant: some View {
        VStack(spacing: 18) {
            // Cyan box icon matching the mockup
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [Color.dsSecondary.opacity(0.4), Color.dsSecondary.opacity(0.15)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 140, height: 140)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.dsSecondary.opacity(0.5), lineWidth: 2)
                    )
                Image(systemName: iconSymbol(forMoveId: reward.moveAttemptMoveId))
                    .font(.system(size: 56, weight: .medium))
                    .foregroundStyle(Color.dsSecondary)
                    .shadow(color: Color.dsSecondary.opacity(0.6), radius: 16)
            }
            Text("RARE DROP")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color.dsOnSurfaceVariant)
            Text("FREE MOVE ATTEMPT")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Text(moveName(forMoveId: reward.moveAttemptMoveId).uppercased())
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .tracking(1)
                .foregroundStyle(Color.dsSecondary)
            Text("Try this locked move's drill free today.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.dsOnSurfaceVariant)
        }
    }

    private var mysteryRewardVariant: some View {
        VStack(spacing: 20) {
            glowingIconCircle(symbol: "sparkles", size: 110, iconSize: 46, color: Color(hex: "#A855F7"))
            Text("EPIC DROP")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color(hex: "#D8B4FE"))
            Text("+\(reward.xpAmount ?? 0) XP")
                .font(.system(size: 54, weight: .heavy, design: .rounded).monospacedDigit())
                .foregroundStyle(Color(hex: "#D8B4FE"))
            Text("Something big. Keep it going.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.dsOnSurfaceVariant)
        }
    }

    private var legendaryVariant: some View {
        VStack(spacing: 18) {
            // Stylized card-frame preview in gold
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        LinearGradient(
                            colors: [Color.dsTertiary, Color.dsTertiaryContainer, Color.dsTertiary],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 150, height: 190)

                Image(systemName: "crown.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.dsTertiaryContainer)
                    .shadow(color: Color.dsTertiaryContainer.opacity(0.7), radius: 24)
            }

            Text("LEGENDARY DROP")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color.dsTertiaryContainer)

            Text("PLATINUM FRAME")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            Text("Ultra-rare frame for your Player Card.")
                .font(.system(size: 13, weight: .medium))
                .italic()
                .foregroundStyle(Color.dsOnSurfaceVariant)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - CTAs

    @ViewBuilder
    private var ctas: some View {
        switch reward.type {
        case .moveAttempt:
            twoActionStack(primary: "TRY IT NOW", secondary: "SAVE FOR LATER")
        case .legendaryDrop:
            twoActionStack(primary: "EQUIP NOW", secondary: "VIEW COLLECTION")
        case .feverTime:
            twoActionStack(primary: "START TRAINING", secondary: "MAYBE LATER")
        default:
            singleCTA(label: "GOT IT", filled: true)
        }
    }

    private func singleCTA(label: String, filled: Bool) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onDismiss()
        } label: {
            Text(label)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(filled ? Color.dsCTALabel : Color.dsSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    filled ? AnyShapeStyle(DSGradient.primaryCTA) : AnyShapeStyle(Color.clear)
                )
                .overlay(
                    Capsule().stroke(filled ? Color.clear : Color.dsSecondary, lineWidth: 2)
                )
                .clipShape(Capsule())
                .dsPrimaryShadow()
        }
    }

    private func twoActionStack(primary: String, secondary: String) -> some View {
        VStack(spacing: 10) {
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onDismiss()
            } label: {
                Text(primary)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color.dsCTALabel)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(DSGradient.primaryCTA)
                    .clipShape(Capsule())
                    .dsPrimaryShadow()
            }
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onDismiss()
            } label: {
                Text(secondary)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color.dsSecondary)
            }
        }
    }

    // MARK: - Helpers

    private func glowingIconCircle(symbol: String, size: CGFloat, iconSize: CGFloat, color: Color) -> some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: size, height: size)
            Circle()
                .stroke(color.opacity(0.4), lineWidth: 1.5)
                .frame(width: size, height: size)
            Image(systemName: symbol)
                .font(.system(size: iconSize, weight: .bold))
                .foregroundStyle(color)
                .shadow(color: color.opacity(0.7), radius: 16)
        }
    }

    private func iconSymbol(forMoveId moveId: String?) -> String {
        guard let moveId, let move = SignatureMoveRegistry.move(id: moveId) else {
            return "soccerball"
        }
        return move.iconSymbolName
    }

    private func moveName(forMoveId moveId: String?) -> String {
        guard let moveId, let move = SignatureMoveRegistry.move(id: moveId) else {
            return "Mystery Move"
        }
        return move.name
    }
}
