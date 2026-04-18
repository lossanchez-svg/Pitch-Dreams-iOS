import SwiftUI

/// Mid-journey celebration shown after finishing a non-final stage.
/// Moderate confetti — the big one is reserved for move mastery
/// (`SignatureMoveUnlockedView`).
struct SignatureMoveStageCompleteView: View {
    @ObservedObject var viewModel: SignatureMoveLearningViewModel
    let stage: Int
    let xpAwarded: Int
    let onDismiss: () -> Void

    @State private var showCelebration = false

    private var stageDef: MoveStage? {
        viewModel.move.stages.first { $0.order == stage }
    }

    private var nextStageDef: MoveStage? {
        viewModel.move.stages.first { $0.order == stage + 1 }
    }

    private var summaryStats: (drills: Int, reps: Int, minutes: Int) {
        guard let stageDef = stageDef else { return (0, 0, 0) }
        let drills = stageDef.drills.filter { viewModel.progress.completedDrillIds.contains($0.id) }.count
        let reps = stageDef.drills.reduce(0) { $0 + (viewModel.progress.drillReps[$1.id] ?? 0) }
        let seconds = stageDef.drills.reduce(0) { $0 + $1.durationSeconds }
        return (drills, reps, seconds / 60)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, Spacing.xl)
                .padding(.top, 4)

            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.xl) {
                    phaseGlyph
                        .padding(.top, 8)

                    VStack(spacing: 6) {
                        if let stageDef = stageDef {
                            Text("STAGE \(stage) · \(stageDef.phase.displayName.uppercased())")
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .tracking(2)
                                .foregroundStyle(Color.dsSecondary)
                        }
                        Text("Stage Complete!")
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.dsOnSurface)
                    }

                    xpBadge

                    summaryTiles

                    if let nextStageDef = nextStageDef {
                        nextStagePreview(nextStageDef)
                    }

                    primaryCTA
                        .padding(.horizontal, Spacing.xl)

                    secondaryCTA
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
            Color.clear.frame(width: 32, height: 32)
            Spacer()
            Text("STADIUM")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color.dsOnSurfaceVariant)
            Spacer()
            Button {
                onDismiss()
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
                    .frame(width: 32, height: 32)
            }
            .accessibilityHidden(true)
        }
    }

    // MARK: - Phase glyph

    private var phaseGlyph: some View {
        ZStack {
            Circle()
                .fill(Color.dsSurfaceContainer)
                .frame(width: 100, height: 100)
                .overlay(
                    Circle()
                        .stroke(Color.dsSecondary.opacity(0.3), lineWidth: 1.5)
                )
            Image(systemName: stageDef?.phase.iconSymbol ?? "checkmark")
                .font(.system(size: 40, weight: .medium))
                .foregroundStyle(Color.dsSecondary)
        }
    }

    // MARK: - XP badge

    private var xpBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.dsSecondary)
            Text("+\(xpAwarded) XP")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.dsSecondary)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 10)
        .background(Color.dsSecondary.opacity(0.15))
        .clipShape(Capsule())
    }

    // MARK: - Summary tiles

    private var summaryTiles: some View {
        HStack(spacing: 10) {
            summaryTile(label: "DRILLS", value: "\(summaryStats.drills) of \(stageDef?.drills.count ?? 0)")
            summaryTile(label: "TOTAL REPS", value: "\(summaryStats.reps)")
            summaryTile(label: "TIME", value: "\(summaryStats.minutes) MIN")
        }
    }

    private func summaryTile(label: String, value: String) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .tracking(1)
                .foregroundStyle(Color.dsOnSurfaceVariant)
            Text(value)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.dsOnSurface)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.dsSurfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
    }

    // MARK: - Next-stage preview

    private func nextStagePreview(_ next: MoveStage) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.dsAccentOrange.opacity(0.2))
                    .frame(width: 44, height: 44)
                Image(systemName: next.phase.iconSymbol)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.dsAccentOrange)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("UP NEXT")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color.dsAccentOrange)
                Text("Stage \(next.order) — \(next.phase.displayName)")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.dsOnSurface)
                Text(nextStageDescription(next))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color.dsSurfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .ghostBorder()
    }

    private func nextStageDescription(_ stage: MoveStage) -> String {
        (viewModel.isYoung ? stage.descriptionYoung : stage.description) ?? stage.description
    }

    // MARK: - CTAs

    private var primaryCTA: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            if nextStageDef != nil {
                viewModel.beginStage(stage + 1)
            } else {
                onDismiss()
            }
        } label: {
            HStack(spacing: 8) {
                Text(nextStageDef != nil ? "BEGIN STAGE \(stage + 1)" : "DONE")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .tracking(2)
                if nextStageDef != nil {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .bold))
                }
            }
            .foregroundStyle(Color.dsCTALabel)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(DSGradient.primaryCTA)
            .clipShape(Capsule())
            .dsPrimaryShadow()
        }
    }

    private var secondaryCTA: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onDismiss()
        } label: {
            Text("FINISH AND RETURN LATER")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color.dsSecondary)
                .underline()
        }
    }
}
