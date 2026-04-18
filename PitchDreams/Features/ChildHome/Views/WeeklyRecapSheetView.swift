import SwiftUI

/// Full-screen sheet presenting the weekly recap card with share button.
struct WeeklyRecapSheetView: View {
    let childId: String
    @StateObject private var viewModel: WeeklyRecapViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var cardScale: CGFloat = 0.8
    @State private var showCelebration = false

    init(childId: String) {
        self.childId = childId
        _viewModel = StateObject(wrappedValue: WeeklyRecapViewModel(childId: childId))
    }

    var body: some View {
        ZStack {
            Color.dsBackground
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Dismiss button
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.dsOnSurfaceVariant)
                            .frame(width: 32, height: 32)
                            .background(Color.dsSurfaceContainerHigh)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer()

                if viewModel.isLoading {
                    ProgressView()
                        .tint(Color.dsSecondary)
                } else if let recap = viewModel.recap {
                    // Card
                    WeeklyRecapCardView(recap: recap)
                        .scaleEffect(cardScale)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: cardScale)
                        .onAppear {
                            cardScale = 1.0
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showCelebration = true
                            }
                        }

                    // Share button
                    Button {
                        shareCard(recap: recap)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 14, weight: .bold))
                            Text("SHARE")
                                .font(.system(size: 14, weight: .heavy, design: .rounded))
                                .tracking(2)
                        }
                        .foregroundStyle(Color.dsCTALabel)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(DSGradient.primaryCTA)
                        .clipShape(Capsule())
                        .dsPrimaryShadow()
                    }
                    .padding(.horizontal, 40)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.dsOnSurfaceVariant)
                        Text("No training data this week")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.dsOnSurfaceVariant)
                    }
                }

                Spacer()
            }
        }
        .celebration(isPresented: $showCelebration)
        .task {
            await viewModel.loadRecap()
        }
    }

    // MARK: - Share

    @MainActor
    private func shareCard(recap: WeeklyRecap) {
        let renderer = ImageRenderer(content:
            WeeklyRecapCardView(recap: recap)
                .frame(width: 390, height: 520)
        )
        renderer.scale = UIScreen.main.scale
        guard let image = renderer.uiImage else { return }

        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = windowScene.windows.first?.rootViewController else { return }

        // Handle iPad popover
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = root.view
            popover.sourceRect = CGRect(x: root.view.bounds.midX, y: root.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        root.present(activityVC, animated: true)
    }
}

#Preview {
    WeeklyRecapSheetView(childId: "preview-child")
}
