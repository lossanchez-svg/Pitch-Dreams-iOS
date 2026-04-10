import SwiftUI

extension Color {
    /// Legacy HUD aliases — map to new design tokens for backward compatibility.
    static let hudCyan = Color.dsSecondary
    static let hudLime = Color(red: 0.65, green: 0.93, blue: 0.31)
    static let hudMagenta = Color(red: 0.93, green: 0.31, blue: 0.65)
    static let hudBackground = Color.dsBackground
    static let hudCardBackground = Color.dsSurfaceContainer
}
