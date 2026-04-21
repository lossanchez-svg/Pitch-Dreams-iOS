import SwiftUI

/// Overview page for a single Signature Move — the hero demo area, move
/// title + rarity + difficulty pills, age-adaptive description, 3-stage
/// vertical stepper, coach tip card, and the primary CTA to start (or
/// continue) the active stage.
///
/// Matches `proposals/Stitch/signature_move_overview.png`.
struct SignatureMoveOverviewView: View {
    @ObservedObject var viewModel: SignatureMoveLearningViewModel
    let onDismiss: () -> Void

    @State private var youngMode: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    heroPlayer
                        .padding(.horizontal, Spacing.xl)
                        .padding(.top, 4)

                    titleBlock
                        .padding(.horizontal, Spacing.xl)

                    descriptionCard
                        .padding(.horizontal, Spacing.xl)

                    stageStepper
                        .padding(.horizontal, Spacing.xl)

                    coachTipCard
                        .padding(.horizontal, Spacing.xl)

                    Color.clear.frame(height: 100) // leave room for sticky CTA
                }
                .padding(.top, 8)
            }
        }
        .overlay(alignment: .bottom) {
            continueCTA
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, 16)
        }
    }

    // MARK: - Derived content

    /// `descriptionYoung` when in young mode, standard otherwise.
    private var activeDescription: String {
        (youngMode ? viewModel.move.descriptionYoung : viewModel.move.description) ?? viewModel.move.description
    }

    private var activeCoachTip: String {
        youngMode ? viewModel.move.coachTipYoung : viewModel.move.coachTip
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button { onDismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
            }
            .accessibilityLabel("Close move")
            Spacer()
            Text("SIGNATURE MOVE")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color.dsAccentOrange)
            Spacer()
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
            }
            .accessibilityLabel("Share move")
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.top, 4)
    }

    // MARK: - Hero player

    /// Resolves the move's `heroDemoAsset` slot via the animation registry.
    /// When a `.riv` file is bundled for the resolved animation, render
    /// Rive-native; otherwise fall through to the play-button placeholder
    /// the app has shipped historically.
    @ViewBuilder
    private var heroPlayer: some View {
        if let heroAssetId = viewModel.move.heroDemoAsset,
           let anim = TechniqueAnimationRegistry.animation(for: heroAssetId),
           let riveAsset = anim.riveAssetName,
           let riveView = RiveTechniqueView(assetName: riveAsset) {
            riveView
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
                .accessibilityLabel("Hero demo animation for \(viewModel.move.name)")
        } else {
            heroPlayerPlaceholder
        }
    }

    private var heroPlayerPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#0F1F32"), Color(hex: "#050A14")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 220)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )

            // Radial sports-light glow behind the play button
            Circle()
                .fill(Color.dsAccentOrange.opacity(0.25))
                .frame(width: 200, height: 200)
                .blur(radius: 40)

            Image(systemName: "play.circle.fill")
                .font(.system(size: 58, weight: .medium))
                .foregroundStyle(Color.dsAccentOrange)
                .shadow(color: Color.dsAccentOrange.opacity(0.5), radius: 12)

            VStack {
                HStack {
                    Spacer()
                    Text("0.5X")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(Color.dsSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Capsule())
                }
                Spacer()
            }
            .padding(12)
        }
        .accessibilityLabel("Hero demo video")
    }

    // MARK: - Title block

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.move.name)
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.dsOnSurface)

            HStack(spacing: 8) {
                pill(text: viewModel.move.rarity.displayName, color: Color(hex: viewModel.move.rarity.accentColorHex))
                pill(text: viewModel.move.difficulty.displayName, color: Color.dsSecondary)
            }

            Text("\u{201C}\(viewModel.move.famousFor)\u{201D}")
                .font(.system(size: 13, weight: .medium))
                .italic()
                .foregroundStyle(Color.dsOnSurfaceVariant)
        }
    }

    private func pill(text: String, color: Color) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .heavy, design: .rounded))
            .tracking(1)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }

    // MARK: - Description card

    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(activeDescription)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.dsOnSurface)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            if viewModel.move.descriptionYoung != nil {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("YOUNG MODE")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .tracking(1)
                            .foregroundStyle(Color.dsSecondary)
                        Text("For kids \u{2264} 11")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.dsOnSurfaceVariant)
                    }
                    Spacer()
                    Toggle("", isOn: $youngMode)
                        .tint(Color.dsSecondary)
                        .labelsHidden()
                }
                .padding(.top, 6)
            }
        }
        .padding(18)
        .background(Color.dsSurfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .ghostBorder()
    }

    // MARK: - Stage stepper

    private var stageStepper: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.move.stages, id: \.order) { stage in
                stageRow(stage)
            }
        }
    }

    private func stageRow(_ stage: MoveStage) -> some View {
        let status = stageStatus(for: stage)
        return HStack(alignment: .top, spacing: 14) {
            stagePhaseIcon(phase: stage.phase, status: status)
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(stagePhaseLabel(stage.phase))
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(Color.dsSecondary)
                    Spacer()
                    statusChip(status, drillCount: stage.drills.count)
                }
                Text(stage.name)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(status == .locked ? Color.dsOnSurfaceVariant : Color.dsOnSurface)
                stageProgressIndicator(stage: stage, status: status)
            }
        }
        .padding(14)
        .background(Color.dsSurfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(
                    status == .inProgress ? Color.dsSecondary : Color.white.opacity(0.05),
                    lineWidth: status == .inProgress ? 2 : 1
                )
        )
        .opacity(status == .locked ? 0.6 : 1)
    }

    private enum StageStatus { case complete, inProgress, locked }

    private func stageStatus(for stage: MoveStage) -> StageStatus {
        if stage.order < viewModel.progress.currentStage { return .complete }
        if stage.order == viewModel.progress.currentStage { return .inProgress }
        return .locked
    }

    private func stagePhaseLabel(_ phase: LearningPhase) -> String {
        phase.displayName.uppercased()
    }

    private func stagePhaseIcon(phase: LearningPhase, status: StageStatus) -> some View {
        ZStack {
            Circle()
                .fill(Color.dsSurfaceContainer)
                .frame(width: 36, height: 36)
                .overlay(
                    Circle().stroke(
                        status == .complete ? Color.dsTertiaryContainer : Color.dsSecondary.opacity(status == .inProgress ? 1 : 0.35),
                        lineWidth: 1.5
                    )
                )
            if status == .complete {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(Color.dsTertiaryContainer)
            } else if status == .locked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
            } else {
                Image(systemName: phase.iconSymbol)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.dsSecondary)
            }
        }
    }

    private func statusChip(_ status: StageStatus, drillCount: Int) -> some View {
        let (text, color): (String, Color) = {
            switch status {
            case .complete:   return ("\(drillCount) DRILLS · COMPLETE", Color.dsTertiaryContainer)
            case .inProgress: return ("IN PROGRESS", Color.dsSecondary)
            case .locked:     return ("LOCKED", Color.dsOnSurfaceVariant)
            }
        }()
        return Text(text)
            .font(.system(size: 9, weight: .heavy, design: .rounded))
            .tracking(1)
            .foregroundStyle(color)
    }

    @ViewBuilder
    private func stageProgressIndicator(stage: MoveStage, status: StageStatus) -> some View {
        switch status {
        case .complete:
            HStack(spacing: 4) {
                Text("\(stage.drills.count) drills")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
                Spacer()
                Text("\u{2713} complete")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.dsTertiaryContainer)
            }
        case .inProgress:
            let completedCount = stage.drills.filter { viewModel.progress.completedDrillIds.contains($0.id) }.count
            let totalReps = stage.drills.reduce(0) { $0 + (viewModel.progress.drillReps[$1.id] ?? 0) }
            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.dsSurfaceContainerHighest).frame(height: 6)
                        Capsule()
                            .fill(Color.dsSecondary)
                            .frame(
                                width: geo.size.width * CGFloat(min(totalReps, stage.masteryCriteria.minTotalReps))
                                    / CGFloat(max(1, stage.masteryCriteria.minTotalReps)),
                                height: 6
                            )
                    }
                }
                .frame(height: 6)
                Text("\(completedCount)/\(stage.masteryCriteria.requiredDrillsCompleted) drills · \(totalReps)/\(stage.masteryCriteria.minTotalReps) reps")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
            }
        case .locked:
            Text("Complete previous stage to unlock.")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.dsOnSurfaceVariant)
        }
    }

    // MARK: - Coach tip

    private var coachTipCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("COACH TIP")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color.dsSecondary)
            Text(activeCoachTip)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.dsOnSurface)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color.dsSurfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .ghostBorder()
    }

    // MARK: - Continue CTA

    private var continueCTA: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            viewModel.beginStage(viewModel.progress.currentStage)
        } label: {
            HStack(spacing: 8) {
                Text(ctaLabel)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .tracking(2)
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundStyle(Color.dsCTALabel)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(DSGradient.primaryCTA)
            .clipShape(Capsule())
            .dsPrimaryShadow()
        }
        .opacity(viewModel.progress.isMastered ? 0.5 : 1)
        .disabled(viewModel.progress.isMastered)
    }

    private var ctaLabel: String {
        if viewModel.progress.isMastered { return "MASTERED" }
        let s = viewModel.progress.currentStage
        if s == 1 { return "BEGIN STAGE 1" }
        return "CONTINUE STAGE \(s)"
    }
}
