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

/// Consistent empty state for screens with no data yet.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 40)

            ZStack {
                Circle()
                    .fill(Color.dsSurfaceContainer)
                    .frame(width: 100, height: 100)
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
            }

            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color.dsOnSurface)

            Text(subtitle)
                .font(.system(size: 14))
                .foregroundStyle(Color.dsOnSurfaceVariant)
                .multilineTextAlignment(.center)

            Spacer(minLength: 40)
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
