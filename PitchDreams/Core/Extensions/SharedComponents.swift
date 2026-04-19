import SwiftUI

// MARK: - Hero Glow

/// Atmospheric radial gradient for screen hero sections.
struct HeroGlowView: View {
    var color: Color = .dsAccentOrange
    var height: CGFloat = 120

    var body: some View {
        RadialGradient(
            colors: [
                color.opacity(0.15),
                color.opacity(0.04),
                Color.clear
            ],
            center: .top,
            startRadius: 10,
            endRadius: 250
        )
        .frame(height: height)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Section Header

/// Uppercase tracked section header matching the Starlight Pitch design language.
struct SectionHeaderView: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .heavy, design: .rounded))
            .tracking(3)
            .foregroundStyle(Color.dsOnSurfaceVariant)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Empty State

/// Consistent empty state for screens with no data yet. Supports two modes:
/// - SF Symbol fallback (default): renders an icon in a circle
/// - Avatar illustration (preferred): when `avatarId` is provided, renders
///   the kid's own avatar so empty states feel personal instead of sterile.
///   This is Track B6's "avatar-based empty state" pattern.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var avatarId: String?
    var totalXP: Int = 0
    var avatarTagline: String?

    init(icon: String, title: String, subtitle: String) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
    }

    /// Avatar-based empty state. Falls back to the SF Symbol icon if the
    /// avatar asset can't be resolved, so this variant is always safe.
    init(
        avatarId: String?,
        totalXP: Int = 0,
        icon: String,
        title: String,
        subtitle: String,
        avatarTagline: String? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.avatarId = avatarId
        self.totalXP = totalXP
        self.avatarTagline = avatarTagline
    }

    private var avatarAssetName: String? {
        guard let avatarId else { return nil }
        let name = Avatar.assetName(for: avatarId, totalXP: totalXP)
        return UIImage(named: name) != nil ? name : nil
    }

    var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 40)

            illustration

            if let avatarTagline {
                Text(avatarTagline)
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color.dsAccentOrange)
            }

            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color.dsOnSurface)

            Text(subtitle)
                .font(.system(size: 14))
                .foregroundStyle(Color.dsOnSurfaceVariant)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Spacer(minLength: 40)
        }
    }

    @ViewBuilder
    private var illustration: some View {
        if let assetName = avatarAssetName {
            // Avatar illustration — kid sees their OWN avatar empathizing
            // with the empty state. Subtle cyan glow reads as "ready to go".
            ZStack {
                Circle()
                    .fill(Color.dsSecondary.opacity(0.15))
                    .frame(width: 130, height: 130)
                    .blur(radius: 12)

                Image(assetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 110, height: 110)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(Color.dsSecondary.opacity(0.4), lineWidth: 2)
                    )
            }
        } else {
            ZStack {
                Circle()
                    .fill(Color.dsSurfaceContainer)
                    .frame(width: 100, height: 100)
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
            }
        }
    }
}

// MARK: - Stat Card

/// Reusable stat card for dashboards (icon + large value + small label).
struct StatCardView: View {
    let title: String
    let value: String
    var unit: String = ""
    let icon: String
    var color: Color = .dsSecondary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.dsOnSurface)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                }
            }

            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(1)
                .foregroundStyle(Color.dsOnSurfaceVariant)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .background(Color.dsSurfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .ghostBorder()
    }
}

// MARK: - Error Banner

/// Consistent error display with retry hint for refreshable screens.
struct ErrorBannerView: View {
    let message: String
    var showRetryHint: Bool = true

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(message)
                    .font(.subheadline)
                if showRetryHint {
                    Text("Pull down to try again")
                        .font(.caption)
                        .foregroundStyle(Color.dsError.opacity(0.7))
                }
            }
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
        }
        .foregroundStyle(Color.dsError)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.dsError.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
    }
}
