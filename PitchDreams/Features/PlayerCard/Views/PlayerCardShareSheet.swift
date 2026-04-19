import SwiftUI

/// Share-sheet presentation for the Player Card. Renders the card as a
/// 1080×1440 UIImage via SwiftUI's `ImageRenderer`, then hands it to
/// `UIActivityViewController` so the system provides AirDrop / Messages /
/// Save-to-Photos / Instagram and friends.
struct PlayerCardShareSheet: View {
    @ObservedObject var viewModel: PlayerCardViewModel
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.dsBackground.ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                header
                    .padding(.top, 16)

                // Shrunk live preview — this is what we'll render for export.
                PlayerCardView(
                    card: viewModel.card,
                    stats: viewModel.stats,
                    overallRating: viewModel.overallRating,
                    avatarAssetName: viewModel.avatarAssetName,
                    avatarStage: viewModel.avatarStage,
                    position: viewModel.position.isEmpty ? "PLAYER" : viewModel.position
                )
                .padding(.horizontal, 32)

                Spacer()

                actionsRow

                Text("The card is saved locally. Sharing sends the image only — no account info.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Button {
                    onDismiss()
                } label: {
                    Text("DONE")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(Color.dsAccentOrange)
                }
                .padding(.bottom, 24)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
                    .frame(width: 32, height: 32)
                    .background(Color.dsSurfaceContainerHigh)
                    .clipShape(Circle())
            }
            Spacer()
            Text("SHARE MOMENT")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color.dsAccentOrange)
            Spacer()
            Color.clear.frame(width: 32, height: 32)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Actions row

    private var actionsRow: some View {
        HStack(spacing: 20) {
            actionTile(icon: "airplayaudio", label: "AIRDROP") { present() }
            actionTile(icon: "message.fill", label: "MESSAGES") { present() }
            actionTile(icon: "camera.fill", label: "INSTAGRAM") { present() }
            actionTile(icon: "square.and.arrow.down", label: "SAVE") { present() }
            actionTile(icon: "link", label: "LINK") { present() }
        }
    }

    private func actionTile(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(Color.dsSurfaceContainerHigh)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                Text(label)
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(Color.dsOnSurfaceVariant)
            }
        }
    }

    // MARK: - Rendering

    /// Render the card at share dimensions (1080×1440) and hand off to the
    /// system share sheet. We use a larger PlayerCardView in `.share` mode so
    /// the proportions hold up at Instagram-story scale.
    @MainActor
    private func present() {
        let renderer = ImageRenderer(content:
            PlayerCardView(
                card: viewModel.card,
                stats: viewModel.stats,
                overallRating: viewModel.overallRating,
                avatarAssetName: viewModel.avatarAssetName,
                avatarStage: viewModel.avatarStage,
                position: viewModel.position.isEmpty ? "PLAYER" : viewModel.position,
                renderMode: .share
            )
            .frame(width: 1080, height: 1440)
        )
        renderer.scale = 1.0
        guard let image = renderer.uiImage else { return }

        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )

        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }

        // iPad requires a source anchor for the popover presentation.
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = root.view
            popover.sourceRect = CGRect(x: root.view.bounds.midX, y: root.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        // Top-most presenter so we layer above the in-flight share sheet view.
        var presenter = root
        while let top = presenter.presentedViewController {
            presenter = top
        }
        presenter.present(activityVC, animated: true)
    }
}
