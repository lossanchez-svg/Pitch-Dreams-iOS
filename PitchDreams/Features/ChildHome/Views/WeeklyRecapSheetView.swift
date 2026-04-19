import SwiftUI

/// In-app weekly recap sheet. Matches `proposals/Stitch/weekly_recap_sheet.png`
/// — a hero-art recap card with motivational headline, two big stats, and a
/// rank-achieved row. The shareable 390x520 `WeeklyRecapCardView` is still the
/// exportable artifact rendered via `ImageRenderer` when the user taps share.
struct WeeklyRecapSheetView: View {
    let childId: String
    @StateObject private var viewModel: WeeklyRecapViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var cardScale: CGFloat = 0.92
    @State private var showCelebration = false

    init(childId: String) {
        self.childId = childId
        _viewModel = StateObject(wrappedValue: WeeklyRecapViewModel(childId: childId))
    }

    var body: some View {
        ZStack {
            Color.dsBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                if viewModel.isLoading {
                    // C11: skeleton stub shaped like the final recap card
                    // so load time doesn't feel like a blank wait.
                    VStack(spacing: 16) {
                        SkeletonView(height: 200)
                        HStack(spacing: 12) {
                            SkeletonView(height: 80)
                            SkeletonView(height: 80)
                        }
                    }
                    .padding(20)
                    Spacer()
                } else if let recap = viewModel.recap {
                    ScrollView {
                        heroCard(recap: recap)
                            .scaleEffect(cardScale)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: cardScale)
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            .padding(.bottom, 20)
                            .onAppear {
                                cardScale = 1.0
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    showCelebration = true
                                }
                            }
                    }

                    bottomBar(recap: recap)
                } else {
                    Spacer()
                    emptyState
                    Spacer()
                }
            }
        }
        .celebration(isPresented: $showCelebration)
        .task { await viewModel.loadRecap() }
    }

    // MARK: - Top bar

    @ViewBuilder
    private var topBar: some View {
        HStack {
            Text("Recap")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color.dsOnSurface)
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
                    .frame(width: 32, height: 32)
                    .background(Color.dsSurfaceContainerHigh)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }

    // MARK: - Hero card

    @ViewBuilder
    private func heroCard(recap: WeeklyRecap) -> some View {
        let assetName = Avatar.assetName(for: recap.avatarId, totalXP: recap.totalXP)
        let headline = motivationalHeadline(for: recap)
        let intensity = intensityPercent(for: recap)

        VStack(alignment: .leading, spacing: 0) {
            // Hero avatar strip (cropped portrait)
            ZStack(alignment: .bottom) {
                if UIImage(named: assetName) != nil {
                    Image(assetName)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .clipped()
                } else {
                    Image(systemName: "figure.soccer")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.dsSecondary.opacity(0.5))
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .background(Color.dsSurfaceContainerHigh)
                }

                // Fade to card background for clean handoff
                LinearGradient(
                    colors: [Color.clear, Color.dsSurfaceContainerLow],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 80)
            }
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: CornerRadius.xl,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: CornerRadius.xl
                )
            )

            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("WEEKLY SUMMARY")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(Color.dsSecondary)

                    Text(headline)
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(Color.dsOnSurface)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }

                HStack(alignment: .top) {
                    bigStat(
                        label: "TOTAL SESSIONS",
                        value: "\(recap.sessionsCompleted)",
                        suffix: nil,
                        trendIcon: recap.sessionsCompleted > 0 ? "chart.line.uptrend.xyaxis" : nil
                    )
                    Spacer()
                    bigStat(
                        label: "INTENSITY",
                        value: "\(intensity)",
                        suffix: "%",
                        trendIcon: nil
                    )
                }

                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 1)

                rankAchievedRow(recap: recap, assetName: assetName)
            }
            .padding(20)
        }
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .fill(Color.dsSurfaceContainerLow)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }

    // MARK: - Rank row

    @ViewBuilder
    private func rankAchievedRow(recap: WeeklyRecap, assetName: String) -> some View {
        let ringColor: Color = {
            switch recap.avatarStage {
            case .rookie: return Color.dsAccentOrange
            case .pro:    return Color.dsSecondary
            case .legend: return Color.dsTertiary
            }
        }()
        let progress = XPCalculator.progressToNextStage(recap.totalXP).progress

        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Color.dsTertiaryContainer.opacity(0.8), lineWidth: 2)
                    .frame(width: 44, height: 44)

                if UIImage(named: assetName) != nil {
                    Image(assetName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 38, height: 38)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "figure.soccer")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.dsSecondary)
                        .frame(width: 38, height: 38)
                        .background(Color.dsSurfaceContainerHigh)
                        .clipShape(Circle())
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("RANK ACHIEVED")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color.dsOnSurfaceVariant)
                Text("\(recap.avatarStage.title.uppercased()) \(Avatar.resolve(recap.avatarId).displayName.uppercased())")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.dsOnSurface)
            }

            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.dsSurfaceContainerHighest, lineWidth: 4)
                    .frame(width: 44, height: 44)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        ringColor,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))
            }
        }
    }

    // MARK: - Big stat

    @ViewBuilder
    private func bigStat(label: String, value: String, suffix: String?, trendIcon: String?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color.dsOnSurfaceVariant)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 34, weight: .black, design: .rounded).monospacedDigit())
                    .foregroundStyle(Color.dsOnSurface)

                if let suffix {
                    Text(suffix)
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.dsSecondary)
                }
                if let trendIcon {
                    Image(systemName: trendIcon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.dsSecondary)
                }
            }
        }
    }

    // MARK: - Bottom bar

    @ViewBuilder
    private func bottomBar(recap: WeeklyRecap) -> some View {
        HStack(spacing: 0) {
            Button {
                dismiss()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.dsSecondary)
                    Text("DONE")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(Color.dsSecondary)
                }
                .frame(maxWidth: .infinity)
            }

            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 1, height: 40)

            Button {
                shareCard(recap: recap)
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.dsCTALabel)
                    .frame(width: 52, height: 52)
                    .background(
                        Circle()
                            .fill(DSGradient.primaryCTA)
                    )
                    .dsPrimaryShadow()
                    .frame(maxWidth: .infinity)
            }
            .accessibilityLabel("Share recap")
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 20)
        .background(
            Color.dsSurfaceContainerLow
                .opacity(0.4)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Empty state

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 40))
                .foregroundStyle(Color.dsOnSurfaceVariant)
            Text("No training data this week")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.dsOnSurfaceVariant)
        }
    }

    // MARK: - Copywriting + derived stats

    private func motivationalHeadline(for recap: WeeklyRecap) -> String {
        switch recap.sessionsCompleted {
        case 0:       return "TAKE A BREAK"
        case 1...2:   return "GOOD START"
        case 3...4:   return "STRONG WEEK"
        case 5...6:   return "ON FIRE"
        default:      return "YOU ARE A BEAST"
        }
    }

    /// Intensity = share of days trained this week (0-100).
    private func intensityPercent(for recap: WeeklyRecap) -> Int {
        let active = recap.weekdayActivity.filter { $0 }.count
        return Int((Double(active) / 7.0 * 100).rounded())
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
