import SwiftUI

/// Speech bubble with rounded rect and tail triangle, positioned above the coach character.
struct CoachBubbleView: View {
    let text: String

    var body: some View {
        VStack(spacing: 0) {
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white)
                .lineLimit(4)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.dsSurfaceContainerHighest.opacity(0.95))
                )

            // Tail triangle pointing down
            Triangle()
                .fill(Color.dsSurfaceContainerHighest.opacity(0.95))
                .frame(width: 12, height: 6)
        }
        .frame(maxWidth: 220)
    }
}

// MARK: - Triangle Shape

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}
