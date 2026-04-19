import SwiftUI

/// Full-screen Player Card experience. Wraps the renderable `PlayerCardView`
/// with navigation (back + share), the "Long-press to AirDrop. Tap to edit."
/// helper, and the gradient "UPDATE PLAYER STYLE" CTA that opens the editor.
struct PlayerCardScreen: View {
    let childId: String
    @StateObject private var viewModel: PlayerCardViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showEditor = false
    @State private var showShareSheet = false

    init(childId: String) {
        self.childId = childId
        _viewModel = StateObject(wrappedValue: PlayerCardViewModel(childId: childId))
    }

    var body: some View {
        ZStack {
            Color.dsBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.xl) {
                    PlayerCardView(
                        card: viewModel.card,
                        stats: viewModel.stats,
                        overallRating: viewModel.overallRating,
                        avatarAssetName: viewModel.avatarAssetName,
                        avatarStage: viewModel.avatarStage,
                        position: viewModel.position.isEmpty ? "PLAYER" : viewModel.position
                    )
                    // Long-press anywhere on the card triggers the share flow,
                    // mirroring the helper copy beneath it.
                    .onLongPressGesture(minimumDuration: 0.4) {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        showShareSheet = true
                    }
                    .onTapGesture {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showEditor = true
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    Text("Long-press to AirDrop. Tap to edit.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.dsSecondary.opacity(0.9))

                    updateStyleButton
                        .padding(.horizontal, 28)

                    Spacer(minLength: 40)
                }
                .padding(.top, 8)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .accessibilityLabel("Back")
            }
            ToolbarItem(placement: .principal) {
                Text("MY CARD")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color.dsAccentOrange)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .accessibilityLabel("Share card")
            }
        }
        .toolbarBackground(Color.dsBackground, for: .navigationBar)
        .task {
            await viewModel.load()
        }
        .sheet(isPresented: $showEditor) {
            PlayerCardEditorView(viewModel: viewModel, onDismiss: {
                showEditor = false
            })
        }
        .sheet(isPresented: $showShareSheet) {
            PlayerCardShareSheet(viewModel: viewModel, onDismiss: {
                showShareSheet = false
            })
        }
    }

    // MARK: - Update CTA

    private var updateStyleButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            showEditor = true
        } label: {
            HStack(spacing: 8) {
                Text("UPDATE PLAYER STYLE")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .tracking(2)
            }
            .foregroundStyle(Color.dsCTALabel)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(DSGradient.primaryCTA)
            .clipShape(Capsule())
            .dsPrimaryShadow()
        }
        .accessibilityHint("Opens the card editor")
    }
}

#Preview {
    NavigationStack {
        PlayerCardScreen(childId: "preview-child")
    }
}
