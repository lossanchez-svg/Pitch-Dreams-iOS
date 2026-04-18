import SwiftUI

/// Shown immediately after a drill is marked done. Surfaces the reps + time
/// stats and asks for a 1-5 confidence rating. The rating only affects
/// stage-advancement math when all drills in the stage are done — here it's
/// captured just for analytic / motivation value.
///
/// Matches `proposals/Stitch/signature_move_drill_complete.png`.
struct SignatureMoveDrillCompleteView: View {
    @ObservedObject var viewModel: SignatureMoveLearningViewModel
    let stage: Int
    let drillId: String

    @State private var rating: Int = 0
    @State private var showCelebration = false

    private var drill: MoveDrill? {
        viewModel.move.stages.first { $0.order == stage }?.drills.first { $0.id == drillId }
    }

    private var isLastDrillInStage: Bool {
        guard let stageDef = viewModel.move.stages.first(where: { $0.order == stage }) else { return false }
        return stageDef.drills.last?.id == drillId
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, Spacing.xl)
                .padding(.top, 4)

            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.xl) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 88))
                        .foregroundStyle(Color.dsSecondary)
                        .shadow(color: Color.dsSecondary.opacity(0.5), radius: 18)
                        .padding(.top, 20)

                    VStack(spacing: 8) {
                        Text("Drill Complete!")
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.dsOnSurface)
                        Text(drill?.title ?? "")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Color.dsOnSurfaceVariant)
                    }

                    statsRow

                    confidenceStars
                        .padding(.top, 10)

                    primaryCTA
                        .padding(.horizontal, Spacing.xl)

                    secondaryLink
                        .padding(.bottom, 30)
                }
                .padding(.horizontal, Spacing.xl)
            }
        }
        .celebration(isPresented: $showCelebration)
        .onAppear {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            showCelebration = true
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button {
                viewModel.finishAndReturnToOverview()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.dsAccentOrange)
                    .frame(width: 32, height: 32)
            }
            .accessibilityLabel("Exit to overview")
            Spacer()
            Text("DRILL COMPLETE")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color.dsAccentOrange)
            Spacer()
            Color.clear.frame(width: 32, height: 32)
        }
    }

    // MARK: - Stats row

    private var statsRow: some View {
        HStack(spacing: 14) {
            statTile(label: "REPS", value: "\(viewModel.currentDrillReps)")
            statTile(label: "TIME", value: formattedTime(viewModel.currentDrillTime))
        }
    }

    private func statTile(label: String, value: String) -> some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color.dsOnSurfaceVariant)
            Text(value)
                .font(.system(size: 34, weight: .heavy, design: .rounded).monospacedDigit())
                .foregroundStyle(Color.dsOnSurface)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(Color.dsSurfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .ghostBorder()
    }

    private func formattedTime(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    // MARK: - Confidence stars

    private var confidenceStars: some View {
        VStack(spacing: 12) {
            Text("How did that feel?")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.dsOnSurface)

            HStack(spacing: 18) {
                ForEach(1...5, id: \.self) { i in
                    Image(systemName: i <= rating ? "star.fill" : "star")
                        .font(.system(size: 28))
                        .foregroundStyle(i <= rating ? Color.dsTertiaryContainer : Color.dsOnSurfaceVariant.opacity(0.5))
                        .onTapGesture {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            rating = i
                        }
                }
            }

            Text(ratingLabel)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color.dsTertiaryContainer)
                .opacity(rating > 0 ? 1 : 0)
        }
    }

    private var ratingLabel: String {
        switch rating {
        case 1: return "WOBBLY"
        case 2: return "LEARNING"
        case 3: return "OK"
        case 4: return "GOOD"
        case 5: return "LOCKED IN"
        default: return ""
        }
    }

    // MARK: - CTA

    private var primaryCTA: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            viewModel.continueAfterDrillComplete()
        } label: {
            Text(primaryLabel)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(Color.dsCTALabel)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(DSGradient.primaryCTA)
                .clipShape(Capsule())
                .dsPrimaryShadow()
        }
    }

    private var primaryLabel: String {
        if isLastDrillInStage { return "COMPLETE STAGE" }
        let nextTitle = nextDrillTitle ?? ""
        return "NEXT DRILL · \(nextTitle.uppercased())"
    }

    private var nextDrillTitle: String? {
        guard let stageDef = viewModel.move.stages.first(where: { $0.order == stage }),
              let idx = stageDef.drills.firstIndex(where: { $0.id == drillId })
        else { return nil }
        let nextIdx = idx + 1
        return nextIdx < stageDef.drills.count ? stageDef.drills[nextIdx].title : nil
    }

    private var secondaryLink: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            viewModel.startDrill(stage: stage, drillId: drillId)
        } label: {
            Text("TRY AGAIN")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color.dsSecondary)
                .underline()
        }
    }
}
