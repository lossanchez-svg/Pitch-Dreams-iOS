import SwiftUI

struct SkeletonView: View {
    var width: CGFloat? = nil
    var height: CGFloat = 16

    @State private var shimmerOffset: CGFloat = -1.0

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.gray.opacity(0.2))
            .frame(width: width, height: height)
            .overlay(
                GeometryReader { geo in
                    let gradientWidth = geo.size.width * 0.6
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .clear,
                            .white.opacity(0.3),
                            .clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: gradientWidth)
                    .offset(x: shimmerOffset * (geo.size.width + gradientWidth) - gradientWidth / 2)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    shimmerOffset = 1.0
                }
            }
    }
}

// MARK: - Skeleton Card

struct SkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SkeletonView(width: 120, height: 14)
            SkeletonView(height: 28)
            SkeletonView(width: 80, height: 12)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Skeleton Stat Grid

struct SkeletonStatGrid: View {
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(0..<4, id: \.self) { _ in
                VStack(spacing: 8) {
                    HStack {
                        SkeletonView(width: 20, height: 20)
                        Spacer()
                    }
                    HStack {
                        SkeletonView(width: 50, height: 24)
                        Spacer()
                    }
                    HStack {
                        SkeletonView(width: 70, height: 12)
                        Spacer()
                    }
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }
}

// MARK: - Skeleton Streak Ring

struct SkeletonStreakRing: View {
    var body: some View {
        VStack(spacing: 16) {
            Circle()
                .stroke(Color.gray.opacity(0.15), lineWidth: 10)
                .frame(width: 120, height: 120)
                .overlay {
                    VStack(spacing: 4) {
                        SkeletonView(width: 28, height: 28)
                        SkeletonView(width: 32, height: 20)
                    }
                }

            HStack(spacing: 24) {
                ForEach(0..<3, id: \.self) { _ in
                    VStack(spacing: 4) {
                        SkeletonView(width: 16, height: 16)
                        SkeletonView(width: 24, height: 16)
                        SkeletonView(width: 40, height: 10)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            SkeletonView(width: 100, height: 14)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Skeleton Quick Actions

struct SkeletonQuickActions: View {
    var body: some View {
        HStack(spacing: 12) {
            SkeletonView(height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            SkeletonView(height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Skeleton Child Row

struct SkeletonChildRow: View {
    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.gray.opacity(0.15))
                .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 4) {
                SkeletonView(width: 100, height: 16)
                SkeletonView(width: 140, height: 12)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Redacted modifier

extension View {
    @ViewBuilder
    func redacted(if condition: Bool) -> some View {
        if condition {
            self
                .hidden()
                .overlay {
                    SkeletonView(height: 16)
                }
        } else {
            self
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            SkeletonStreakRing()
            SkeletonQuickActions()
            SkeletonStatGrid()
            SkeletonCard()
            SkeletonChildRow()
        }
        .padding()
    }
}
