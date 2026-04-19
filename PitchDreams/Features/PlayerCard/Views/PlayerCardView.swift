import SwiftUI

/// The canonical Player Card visual — renderable both in-app and as a 1080×1440
/// image for social export via `ImageRenderer`. Takes every display input as
/// a parameter so it stays stateless and can be rendered off-screen.
///
/// Matches `proposals/stitch/player_card_front.png` pixel-faithfully:
///  - Archetype-gradient card surface (orange/amber for Speedster, cyan for
///    Playmaker, etc. — driven by `archetype.accentColorHex`)
///  - Square orange-gold crest tile top-left with SF Symbol
///  - OVR rating display (huge white number + "OVR" micro-label) top-right
///  - Avatar in a rounded-square inner dark frame
///  - Cyan position chip beneath the avatar
///  - Orange archetype heading
///  - 2×2 stat grid with icon + value + 3-letter label per cell
///  - Subtle PITCHDREAMS wordmark watermark
struct PlayerCardView: View {

    /// Rendering mode for the card — `.inApp` is the on-screen treatment
    /// (fits the screen width); `.share` uses fixed 1080×1440 for social export.
    enum RenderMode {
        case inApp
        case share
    }

    let card: PlayerCard
    let stats: CardStats
    let overallRating: Int
    let avatarAssetName: String
    let avatarStage: AvatarStage
    let position: String
    let renderMode: RenderMode

    init(
        card: PlayerCard,
        stats: CardStats,
        overallRating: Int,
        avatarAssetName: String,
        avatarStage: AvatarStage = .rookie,
        position: String = "MID",
        renderMode: RenderMode = .inApp
    ) {
        self.card = card
        self.stats = stats
        self.overallRating = overallRating
        self.avatarAssetName = avatarAssetName
        self.avatarStage = avatarStage
        self.position = position
        self.renderMode = renderMode
    }

    // MARK: - Derived styling

    private var accentColor: Color { Color(hex: card.archetype.accentColorHex) }

    /// Radial gradient fill for the card surface — archetype accent at the
    /// center-top warming into a deep charcoal at the edges.
    private var cardGradient: RadialGradient {
        RadialGradient(
            colors: [
                accentColor.opacity(0.55),
                accentColor.opacity(0.25),
                Color(hex: "#2A1808"),
                Color(hex: "#0C1322")
            ],
            center: .init(x: 0.5, y: 0.35),
            startRadius: 20,
            endRadius: 400
        )
    }

    /// Corner radius + outer padding scale with render mode so the share
    /// export doesn't look cramped at 1080×1440.
    private var cardCornerRadius: CGFloat { renderMode == .share ? 40 : 24 }
    private var cardPadding: CGFloat { renderMode == .share ? 40 : 20 }

    var body: some View {
        VStack(spacing: 0) {
            // Header row: crest + OVR
            HStack(alignment: .top) {
                crestTile
                Spacer()
                ovrBlock
            }
            .padding(.horizontal, cardPadding)
            .padding(.top, cardPadding)

            // Avatar in dark inner frame
            avatarTile
                .padding(.top, cardPadding * 0.6)

            // Position chip
            positionChip
                .padding(.top, -14)
                .zIndex(1)

            // Archetype heading
            Text(card.archetype.displayName.uppercased())
                .font(.system(size: renderMode == .share ? 40 : 22, weight: .heavy, design: .rounded))
                .tracking(renderMode == .share ? 6 : 3)
                .foregroundStyle(Color(hex: "#FFB88A"))
                .shadow(color: Color.black.opacity(0.3), radius: 2)
                .padding(.top, 14)

            // 2×2 stat grid
            statGrid
                .padding(.horizontal, cardPadding + 4)
                .padding(.top, 18)
                .padding(.bottom, cardPadding - 4)

            // Wordmark
            Text("PITCHDREAMS")
                .font(.system(size: renderMode == .share ? 16 : 10, weight: .heavy, design: .rounded))
                .tracking(4)
                .foregroundStyle(Color.white.opacity(0.22))
                .padding(.bottom, cardPadding * 0.7)
        }
        .background(cardGradient)
        .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: cardCornerRadius)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.5), radius: 30, y: 20)
    }

    // MARK: - Components

    private var crestTile: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: card.clubCrestDesign.primaryColorHex).opacity(0.9),
                            Color(hex: card.clubCrestDesign.primaryColorHex).opacity(0.55)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(
                    width: renderMode == .share ? 100 : 44,
                    height: renderMode == .share ? 100 : 44
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
            Image(systemName: card.clubCrestDesign.crestSymbolId)
                .font(.system(size: renderMode == .share ? 42 : 18, weight: .bold))
                .foregroundStyle(Color.dsTertiary)
        }
    }

    private var ovrBlock: some View {
        VStack(alignment: .trailing, spacing: renderMode == .share ? 0 : -4) {
            Text("\(overallRating)")
                .font(.system(
                    size: renderMode == .share ? 120 : 48,
                    weight: .heavy,
                    design: .rounded
                ).monospacedDigit())
                .foregroundStyle(.white)
                .shadow(color: Color.black.opacity(0.4), radius: 2, y: 1)
            Text("OVR")
                .font(.system(size: renderMode == .share ? 20 : 11, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color.white.opacity(0.85))
        }
    }

    @ViewBuilder
    private var avatarTile: some View {
        let tileSize: CGFloat = renderMode == .share ? 440 : 168
        let frameCorner: CGFloat = renderMode == .share ? 24 : 16
        ZStack {
            RoundedRectangle(cornerRadius: frameCorner)
                .fill(Color.black.opacity(0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: frameCorner)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .frame(width: tileSize, height: tileSize)

            if UIImage(named: avatarAssetName) != nil {
                Image(avatarAssetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: tileSize * 0.88, height: tileSize * 0.88)
            } else {
                Image(systemName: "figure.soccer")
                    .font(.system(size: tileSize * 0.45))
                    .foregroundStyle(Color.white.opacity(0.35))
            }
        }
    }

    private var positionChip: some View {
        Text(position.uppercased())
            .font(.system(size: renderMode == .share ? 22 : 12, weight: .heavy, design: .rounded))
            .tracking(1)
            .foregroundStyle(Color(hex: "#06293A"))
            .padding(.horizontal, renderMode == .share ? 22 : 14)
            .padding(.vertical, renderMode == .share ? 8 : 5)
            .background(Color.dsSecondary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.black.opacity(0.15), lineWidth: 1)
            )
    }

    private var statGrid: some View {
        let gridSpacing: CGFloat = renderMode == .share ? 24 : 12
        let columns = [GridItem(.flexible(), spacing: gridSpacing), GridItem(.flexible(), spacing: gridSpacing)]
        let statsToShow = card.displayedStats.isEmpty
            ? [CardStat.speed, .touch, .vision, .workRate]
            : card.displayedStats
        return LazyVGrid(columns: columns, spacing: gridSpacing) {
            ForEach(statsToShow.prefix(4), id: \.self) { stat in
                statCell(stat)
            }
        }
    }

    private func statCell(_ stat: CardStat) -> some View {
        let valueSize: CGFloat = renderMode == .share ? 56 : 26
        let labelSize: CGFloat = renderMode == .share ? 18 : 10
        let iconSize: CGFloat = renderMode == .share ? 24 : 12

        return HStack(spacing: renderMode == .share ? 16 : 8) {
            Image(systemName: stat.iconSymbol)
                .font(.system(size: iconSize, weight: .bold))
                .foregroundStyle(iconTint(for: stat))
                .frame(width: iconSize * 1.5, alignment: .leading)
            VStack(alignment: .leading, spacing: -2) {
                Text("\(stats.value(for: stat))")
                    .font(.system(size: valueSize, weight: .heavy, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white)
                Text(stat.displayName)
                    .font(.system(size: labelSize, weight: .heavy, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(Color.white.opacity(0.6))
            }
            Spacer()
        }
    }

    /// Icon tints alternate orange and cyan-ish so the grid doesn't read as
    /// one flat color. Matches the Stitch mockup's per-stat tinting.
    private func iconTint(for stat: CardStat) -> Color {
        switch stat {
        case .speed, .vision, .workRate:
            return Color.dsAccentOrange
        case .touch, .shotPower, .composure:
            return Color(hex: "#FFA86B")
        }
    }
}

// MARK: - Preview

#Preview("In-app card") {
    ZStack {
        Color.dsBackground.ignoresSafeArea()
        PlayerCardView(
            card: PlayerCard(
                childId: "preview",
                archetype: .speedster,
                displayedStats: [.speed, .touch, .vision, .workRate],
                moveLoadout: [],
                clubCrestDesign: .defaultDesign,
                cardFrame: .standard,
                archetypeTagline: nil
            ),
            stats: CardStats(speed: 92, touch: 78, vision: 85, shotPower: 70, workRate: 80, composure: 55),
            overallRating: 87,
            avatarAssetName: "wolf_stage1",
            avatarStage: .rookie,
            position: "MID"
        )
        .padding(.horizontal, 28)
    }
}
