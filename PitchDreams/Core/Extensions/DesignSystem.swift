import SwiftUI

// MARK: - Color Hex Init

extension Color {
    /// Initialize a Color from a hex string (e.g. "#FF6B2C" or "FF6B2C").
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch hex.count {
        case 6:
            (r, g, b, a) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF, 255)
        case 8:
            (r, g, b, a) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (0, 0, 0, 255)
        }
        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Starlight Pitch Palette (Child-Facing)

extension Color {
    // Surfaces
    static let dsBackground = Color(hex: "#0C1322")
    static let dsSurfaceContainerLowest = Color(hex: "#070E1D")
    static let dsSurfaceContainerLow = Color(hex: "#151B2B")
    static let dsSurfaceContainer = Color(hex: "#191F2F")
    static let dsSurfaceContainerHigh = Color(hex: "#232A3A")
    static let dsSurfaceContainerHighest = Color(hex: "#2E3545")
    static let dsSurfaceBright = Color(hex: "#32394A")

    // Text
    static let dsOnSurface = Color(hex: "#DCE2F8")
    static let dsOnSurfaceVariant = Color(hex: "#BBC9CB")

    // Primary (Peach/Orange)
    static let dsPrimaryPeach = Color(hex: "#FFE6DE")
    static let dsPrimaryPeachDim = Color(hex: "#FFB59A")
    static let dsPrimaryContainer = Color(hex: "#FFC1AA")
    static let dsAccentOrange = Color(hex: "#FF6B2C")

    // Secondary (Cyan)
    static let dsSecondary = Color(hex: "#46E5F8")
    static let dsSecondaryContainer = Color(hex: "#00C9DB")

    // Tertiary (Gold)
    static let dsTertiary = Color(hex: "#FFE9BD")
    static let dsTertiaryContainer = Color(hex: "#F6C95F")
    static let dsTertiaryDim = Color(hex: "#EDC157")

    // Utility
    static let dsOutlineVariant = Color(hex: "#3C494B")
    static let dsError = Color(hex: "#FFB4AB")

    // CTA Label (text on peach/orange gradient buttons)
    static let dsCTALabel = Color(hex: "#5B1B00")
}

// MARK: - Legacy Palette (Parent Dashboard)

extension Color {
    static let parentPrimary = Color(hex: "#FFF2DC")
    static let parentGold = Color(hex: "#FFD166")
    static let parentGoldDim = Color(hex: "#EDC157")
}

// MARK: - Gradient Definitions

enum DSGradient {
    /// Primary CTA gradient: peach to warm container (135 deg)
    static let primaryCTA = LinearGradient(
        colors: [Color.dsPrimaryPeach, Color.dsPrimaryContainer],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Secondary CTA gradient: cyan range
    static let secondaryCTA = LinearGradient(
        colors: [Color.dsSecondary, Color.dsSecondaryContainer],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Orange accent gradient for +1 REP / timer ring
    static let orangeAccent = LinearGradient(
        colors: [Color.dsAccentOrange, Color(hex: "#9D3500")],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Gold gradient for parent CTAs
    static let parentGoldCTA = LinearGradient(
        colors: [Color.parentGoldDim, Color.parentGold],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Shadow Definitions

extension View {
    /// Primary peach bloom shadow
    func dsPrimaryShadow() -> some View {
        self.shadow(color: Color(hex: "#FFB59A").opacity(0.3), radius: 15, x: 0, y: 10)
    }

    /// Secondary cyan bloom shadow
    func dsSecondaryShadow() -> some View {
        self.shadow(color: Color(hex: "#46E5F8").opacity(0.3), radius: 15, x: 0, y: 0)
    }

    /// Tertiary gold bloom shadow
    func dsTertiaryShadow() -> some View {
        self.shadow(color: Color(hex: "#EDC157").opacity(0.15), radius: 30, x: 0, y: 0)
    }
}

// MARK: - Typography Helpers

enum DSFont {
    /// Rounded headline font — closest to Plus Jakarta Sans Rounded
    static func headline(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    /// Display stat font — massive numbers
    static func display(_ size: CGFloat = 56) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }

    /// Uppercase label with tracking
    static let label: Font = .system(.caption, design: .rounded).weight(.bold)
}

// MARK: - Label Style Modifier

struct DSLabelStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(.caption, design: .rounded).weight(.bold))
            .textCase(.uppercase)
            .tracking(2)
    }
}

extension View {
    /// Applies the signature uppercase label style with wide tracking.
    func dsLabel() -> some View {
        modifier(DSLabelStyle())
    }
}

// MARK: - Spacing

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48
}

// MARK: - Corner Radius

enum CornerRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 32
    static let hero: CGFloat = 48
}

// MARK: - Track Colors (backward compat)

extension Color {
    static let trackScanning = Color.dsSecondary
    static let trackDecisionChain = Color.purple
    static let trackTempo = Color.dsAccentOrange
}

// MARK: - Card Style (updated for new design system)

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.dsSurfaceContainer)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

// MARK: - Badge Style

struct BadgeStyle: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

extension View {
    func badge(color: Color) -> some View {
        modifier(BadgeStyle(color: color))
    }
}

// MARK: - Ghost Border Modifier

struct GhostBorder: ViewModifier {
    var opacity: Double = 0.1

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(Color.white.opacity(opacity), lineWidth: 1)
            )
    }
}

extension View {
    func ghostBorder(opacity: Double = 0.1) -> some View {
        modifier(GhostBorder(opacity: opacity))
    }
}

// MARK: - API String Formatting

/// Converts raw API strings (e.g. "SELF_TRAINING", "small_indoor") to title case ("Self Training", "Small Indoor").
func formatAPIString(_ raw: String) -> String {
    raw.replacingOccurrences(of: "_", with: " ")
       .replacingOccurrences(of: "-", with: " ")
       .split(separator: " ")
       .map { word in
           let lower = word.lowercased()
           return lower.prefix(1).uppercased() + lower.dropFirst()
       }
       .joined(separator: " ")
}

// MARK: - Glass Background Modifier

struct GlassBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
    }
}

extension View {
    func glassBackground() -> some View {
        modifier(GlassBackground())
    }
}
