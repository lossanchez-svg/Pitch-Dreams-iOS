import SwiftUI

/// Pre-drill-list screen for a single stage. Shows the phase icon + name,
/// age-adapted description, a numbered list of the stage's drills with
/// progress chips, and a sticky CTA that starts the first incomplete drill.
struct SignatureMoveStageIntroView: View {
    @ObservedObject var viewModel: SignatureMoveLearningViewModel
    let stage: Int

    private var stageDef: MoveStage? {
        viewModel.move.stages.first { $0.order == stage }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, Spacing.xl)
                .padding(.top, 4)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    if let stageDef = stageDef {
                        phaseBlock(stageDef)
                            .padding(.top, 8)

                        drillList(stageDef)

                        Spacer(minLength: 6)

                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            viewModel.currentStep = .overview
                        } label: {
                            Text("REVIEW STAGE \(stage)")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .tracking(2)
                                .foregroundStyle(Color.dsSecondary)
                                .underline()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                    }
                    Color.clear.frame(height: 110)
                }
                .padding(.horizontal, Spacing.xl)
            }
        }
        .overlay(alignment: .bottom) {
            startDrillCTA
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, 16)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                viewModel.currentStep = .overview
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
            }
            .accessibilityLabel("Back to overview")
            Spacer()
            Text("SIGNATURE MOVE")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color.dsAccentOrange)
            Spacer()
            Color.clear.frame(width: 32, height: 32)
        }
    }

    // MARK: - Phase block

    private func phaseBlock(_ stageDef: MoveStage) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            phaseIcon(stageDef.phase)
            Text("STAGE \(stage) · \(stageDef.phase.displayName.uppercased())")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color.dsSecondary)
            Text(stageDef.name)
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.dsOnSurface)
            Text(stageDescription(stageDef))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.dsOnSurfaceVariant)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func phaseIcon(_ phase: LearningPhase) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.dsSurfaceContainer)
                .frame(width: 56, height: 56)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.dsSecondary.opacity(0.3), lineWidth: 1)
                )
            Image(systemName: phase.iconSymbol)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.dsSecondary)
        }
    }

    private func stageDescription(_ stageDef: MoveStage) -> String {
        (viewModel.isYoung ? stageDef.descriptionYoung : stageDef.description) ?? stageDef.description
    }

    // MARK: - Drill list

    private func drillList(_ stageDef: MoveStage) -> some View {
        VStack(spacing: 10) {
            ForEach(Array(stageDef.drills.enumerated()), id: \.element.id) { pair in
                drillRow(index: pair.offset, drill: pair.element)
            }
        }
    }

    private func drillRow(index: Int, drill: MoveDrill) -> some View {
        let status = drillStatus(drill)
        return HStack(spacing: 14) {
            numberBadge(index: index, status: status)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    drillTypeChip(drill.type)
                    statusChip(status)
                }
                Text(drill.title)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.dsOnSurface)
                HStack(spacing: 10) {
                    Image(systemName: "timer")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                    Text("\(drill.durationSeconds)s")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                    repProgress(drill: drill, status: status)
                }
            }
        }
        .padding(14)
        .background(Color.dsSurfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(
                    status == .next ? Color.dsAccentOrange : Color.white.opacity(0.05),
                    lineWidth: status == .next ? 2 : 1
                )
        )
        .opacity(status == .later ? 0.65 : 1)
    }

    private enum DrillStatus { case complete, next, later }

    private func drillStatus(_ drill: MoveDrill) -> DrillStatus {
        if viewModel.progress.completedDrillIds.contains(drill.id) { return .complete }
        guard let stageDef = stageDef else { return .later }
        let firstIncomplete = stageDef.drills.first { !viewModel.progress.completedDrillIds.contains($0.id) }
        if firstIncomplete?.id == drill.id { return .next }
        return .later
    }

    private func numberBadge(index: Int, status: DrillStatus) -> some View {
        let (fill, text): (Color, Color) = {
            switch status {
            case .complete: return (Color.dsTertiaryContainer.opacity(0.3), Color.dsTertiaryContainer)
            case .next:     return (Color.dsAccentOrange.opacity(0.3), Color.dsAccentOrange)
            case .later:    return (Color.dsSurfaceContainerHigh, Color.dsOnSurfaceVariant)
            }
        }()
        return ZStack {
            Circle().fill(fill).frame(width: 44, height: 44)
            Circle()
                .stroke(text.opacity(0.5), lineWidth: 1.5)
                .frame(width: 44, height: 44)
            Text(String(format: "%02d", index + 1))
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(text)
        }
    }

    private func drillTypeChip(_ type: MoveDrillType) -> some View {
        HStack(spacing: 4) {
            Image(systemName: type.iconSymbol)
                .font(.system(size: 9))
            Text(chipLabel(for: type))
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(1)
        }
        .foregroundStyle(Color.dsSecondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.dsSecondary.opacity(0.15))
        .clipShape(Capsule())
    }

    private func chipLabel(for type: MoveDrillType) -> String {
        switch type {
        case .watch:     return "WATCH"
        case .mimic:     return "MIMIC"
        case .withBall:  return "WITH BALL"
        case .challenge: return "CHALLENGE"
        }
    }

    private func statusChip(_ status: DrillStatus) -> some View {
        let (text, color): (String, Color) = {
            switch status {
            case .complete: return ("COMPLETE", Color.dsTertiaryContainer)
            case .next:     return ("NEXT", Color.dsAccentOrange)
            case .later:    return ("LATER", Color.dsOnSurfaceVariant)
            }
        }()
        return Text(text)
            .font(.system(size: 10, weight: .heavy, design: .rounded))
            .tracking(1)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private func repProgress(drill: MoveDrill, status: DrillStatus) -> some View {
        let done = viewModel.progress.drillReps[drill.id] ?? 0
        return HStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.dsSurfaceContainerHighest).frame(height: 4)
                    Capsule()
                        .fill(status == .complete ? Color.dsTertiaryContainer : Color.dsSecondary)
                        .frame(
                            width: geo.size.width * CGFloat(min(done, drill.targetReps))
                                / CGFloat(max(1, drill.targetReps)),
                            height: 4
                        )
                }
            }
            .frame(height: 4)
            Text("\(done)/\(drill.targetReps)")
                .font(.system(size: 10, weight: .bold).monospacedDigit())
                .foregroundStyle(Color.dsOnSurfaceVariant)
            if status == .complete {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.dsTertiaryContainer)
            }
        }
        .padding(.leading, 4)
    }

    // MARK: - Start CTA

    @ViewBuilder
    private var startDrillCTA: some View {
        if let stageDef = stageDef,
           let nextDrill = stageDef.drills.first(where: { !viewModel.progress.completedDrillIds.contains($0.id) }) {
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                viewModel.startDrill(stage: stage, drillId: nextDrill.id)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 12))
                    Text("START DRILL \(drillNumber(nextDrill)) · \(nextDrill.title.uppercased())")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .tracking(1)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .foregroundStyle(Color.dsCTALabel)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(DSGradient.primaryCTA)
                .clipShape(Capsule())
                .dsPrimaryShadow()
            }
        }
    }

    private func drillNumber(_ drill: MoveDrill) -> Int {
        guard let stageDef = stageDef,
              let idx = stageDef.drills.firstIndex(where: { $0.id == drill.id })
        else { return 1 }
        return idx + 1
    }
}
