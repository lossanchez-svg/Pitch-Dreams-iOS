import SwiftUI

/// Presentation wrapper for the Mystery Box opening flow. Owns the internal
/// transition from opening animation → reveal screen, so callers just
/// present this once and dismiss once.
struct MysteryBoxFlowView: View {
    @ObservedObject var viewModel: MysteryBoxViewModel
    var onDismiss: () -> Void

    @State private var phase: Phase = .opening

    private enum Phase: Equatable { case opening, reveal }

    var body: some View {
        ZStack {
            Color.dsBackground.ignoresSafeArea()

            if let reward = viewModel.revealedReward {
                switch phase {
                case .opening:
                    MysteryBoxOpeningView(reward: reward) {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            phase = .reveal
                        }
                    }
                case .reveal:
                    MysteryBoxRevealView(reward: reward) {
                        viewModel.dismissReveal()
                        onDismiss()
                    }
                }
            } else {
                ProgressView()
                    .tint(Color.dsSecondary)
            }
        }
        .task {
            if viewModel.revealedReward == nil {
                await viewModel.openBox()
            }
        }
    }
}
