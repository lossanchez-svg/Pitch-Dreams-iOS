import SwiftUI

/// Floating card near a tapped pitch element showing its role description.
/// Dismiss on tap outside or after 4 seconds.
struct PitchElementPopover: View {
    let text: String
    let position: CGPoint
    let onDismiss: () -> Void

    @State private var appeared = false

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.85))
            )
            .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
            .position(
                x: position.x,
                y: max(30, position.y - 30)  // offset above, clamp to top
            )
            .scaleEffect(appeared ? 1.0 : 0.7)
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    appeared = true
                }
                // Auto-dismiss after 4 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    onDismiss()
                }
            }
            .onTapGesture {
                onDismiss()
            }
    }
}
