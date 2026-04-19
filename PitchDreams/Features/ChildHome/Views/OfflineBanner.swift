import SwiftUI

/// Persistent banner shown when the device loses network connectivity.
///
/// Intended to be attached at the top of primary screens via an overlay or
/// safe-area inset so users see it regardless of where they are in the app.
struct OfflineBanner: View {
    let isOffline: Bool

    var body: some View {
        if isOffline {
            HStack(spacing: 10) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.dsError)

                VStack(alignment: .leading, spacing: 2) {
                    Text("You're offline")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.dsOnSurface)
                    Text("Training will sync when you're back online.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Color.dsSurfaceContainerHigh)
            .overlay(
                Rectangle()
                    .fill(Color.dsError.opacity(0.4))
                    .frame(height: 2),
                alignment: .bottom
            )
            .transition(.move(edge: .top).combined(with: .opacity))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("You're offline. Training will sync when you're back online.")
        }
    }
}

#Preview {
    VStack {
        OfflineBanner(isOffline: true)
        Spacer()
    }
    .background(Color.dsBackground)
}
