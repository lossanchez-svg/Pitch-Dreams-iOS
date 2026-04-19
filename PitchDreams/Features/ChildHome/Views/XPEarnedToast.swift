import SwiftUI

/// Floating toast shown briefly after earning XP.
struct XPEarnedToast: View {
    let amount: Int
    @Binding var isPresented: Bool

    @State private var displayAmount: Int = 0
    @State private var offset: CGFloat = -80

    var body: some View {
        if isPresented {
            HStack(spacing: 8) {
                Text("+\(displayAmount) XP")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.dsAccentOrange)
                    .contentTransition(.numericText())

                Image(systemName: "bolt.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.dsAccentOrange)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.dsAccentOrange.opacity(0.15))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.dsAccentOrange.opacity(0.3), lineWidth: 1)
            )
            .offset(y: offset)
            .onAppear {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    offset = 0
                }
                // Count-up animation
                withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                    displayAmount = amount
                }
                // Auto-dismiss
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
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
        XPEarnedToast(amount: 45, isPresented: .constant(true))
            .padding(.top, 60)
    }
}
