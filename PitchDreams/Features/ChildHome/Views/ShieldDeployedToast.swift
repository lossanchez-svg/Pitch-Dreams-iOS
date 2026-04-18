import SwiftUI

/// Toast overlay shown when a streak freeze is auto-applied.
struct ShieldDeployedToast: View {
    let streakDays: Int
    @Binding var isPresented: Bool

    @State private var offset: CGFloat = -80

    var body: some View {
        if isPresented {
            HStack(spacing: 10) {
                Image(systemName: "shield.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.dsSecondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Streak Shield Deployed!")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.dsOnSurface)
                    Text("Your \(streakDays)-day streak is safe.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.dsSecondary.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(Color.dsSecondary.opacity(0.3), lineWidth: 1)
            )
            .offset(y: offset)
            .onAppear {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    offset = 0
                }
                // Auto-dismiss after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation(.easeIn(duration: 0.3)) {
                        offset = -80
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isPresented = false
                    }
                }
            }
        }
    }
}

#Preview {
    ZStack(alignment: .top) {
        Color.dsBackground.ignoresSafeArea()
        ShieldDeployedToast(streakDays: 12, isPresented: .constant(true))
            .padding(.top, 60)
    }
}
