import SwiftUI

/// Animated coach character with mood-driven animations and speech bubble.
struct CoachCharacterView: View {
    @ObservedObject var viewModel: CoachCharacterViewModel
    var size: CoachSize = .md

    @State private var bobOffset: CGFloat = 0
    @State private var glowScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.15
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 4) {
            // Speech bubble
            if viewModel.isSpeaking && !viewModel.speechText.isEmpty {
                CoachBubbleView(text: viewModel.speechText)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            }

            // Character with glow background
            ZStack {
                // Glow circle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [glowColor.opacity(glowOpacity), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: size.points * 0.7
                        )
                    )
                    .frame(width: size.points * 1.5, height: size.points * 1.5)
                    .scaleEffect(glowScale)

                // Listening ring
                if viewModel.mood == .listening {
                    Circle()
                        .stroke(Color.dsSecondary.opacity(0.6), lineWidth: 2)
                        .frame(width: size.points + 16, height: size.points + 16)
                        .scaleEffect(glowScale)
                        .opacity(2.0 - Double(glowScale))
                }

                // Character avatar
                Image(CoachPersonality.current.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.points, height: size.points)
                    .background(
                        Circle()
                            .fill(Color.dsSecondary.opacity(0.2))
                    )
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(borderColor.opacity(0.4), lineWidth: 2)
                    )
            }
            .offset(y: bobOffset)
            .modifier(MoodAnimationModifier(mood: viewModel.mood, reduceMotion: reduceMotion))
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.isSpeaking)
        .onChange(of: viewModel.mood) { _ in
            updateAnimations(for: viewModel.mood)
        }
        .onAppear {
            updateAnimations(for: viewModel.mood)
        }
    }

    // MARK: - Colors

    private var glowColor: Color {
        switch viewModel.mood {
        case .idle, .speaking, .listening: return Color.dsSecondary
        case .encouraging: return .green
        case .skeptical: return .orange
        case .celebrating: return Color.dsTertiary
        }
    }

    private var borderColor: Color {
        switch viewModel.mood {
        case .idle: return Color.dsSecondary
        case .speaking: return Color.dsSecondary
        case .encouraging: return .green
        case .skeptical: return .orange
        case .celebrating: return Color.dsTertiary
        case .listening: return Color.dsSecondary
        }
    }

    // MARK: - Animation Updates

    private func updateAnimations(for mood: CoachMood) {
        guard !reduceMotion else {
            bobOffset = 0
            glowScale = 1.0
            glowOpacity = 0.2
            return
        }

        switch mood {
        case .idle:
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                bobOffset = -3
                glowScale = 1.05
                glowOpacity = 0.25
            }
        case .speaking:
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                bobOffset = -4
                glowScale = 1.1
                glowOpacity = 0.4
            }
        case .encouraging:
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                bobOffset = -2
                glowScale = 1.15
                glowOpacity = 0.4
            }
        case .celebrating:
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                bobOffset = -8
                glowScale = 1.3
                glowOpacity = 0.5
            }
        case .listening:
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                bobOffset = -2
                glowScale = 1.2
                glowOpacity = 0.3
            }
        case .skeptical:
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                bobOffset = 0
                glowScale = 1.05
                glowOpacity = 0.3
            }
        }
    }
}

// MARK: - Mood Animation Modifier

private struct MoodAnimationModifier: ViewModifier {
    let mood: CoachMood
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        content
            .scaleEffect(scaleForMood)
            .rotationEffect(rotationForMood)
    }

    private var scaleForMood: CGFloat {
        guard !reduceMotion else { return 1.0 }
        switch mood {
        case .celebrating: return 1.08
        case .encouraging: return 1.05
        case .listening: return 1.02
        case .skeptical: return 0.97
        default: return 1.0
        }
    }

    private var rotationForMood: Angle {
        guard !reduceMotion else { return .zero }
        switch mood {
        case .encouraging: return .degrees(-2)
        case .listening: return .degrees(-3)
        default: return .zero
        }
    }
}
