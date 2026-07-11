import SwiftUI

/// The 90-second pre-match routine: proof → process goal → power cue →
/// one breath cycle ending on the cue. Ends with the kid's job for the day,
/// which stays saved so it can be re-read at halftime.
struct MatchPrepView: View {
    @StateObject private var viewModel: MatchModeViewModel
    @StateObject private var confidence: ConfidenceViewModel
    @Environment(\.dismiss) private var dismiss

    private enum Step {
        case proof, goal, cue, breathe, ready
    }

    @State private var step: Step = .proof
    @State private var breathStartedAt: Date?

    init(childId: String) {
        _viewModel = StateObject(wrappedValue: MatchModeViewModel(childId: childId))
        _confidence = StateObject(wrappedValue: ConfidenceViewModel(childId: childId))
    }

    var body: some View {
        ZStack {
            Color.dsBackground.ignoresSafeArea()

            switch step {
            case .proof: proofStep
            case .goal: goalStep
            case .cue: cueStep
            case .breathe: breatheStep
            case .ready: readyStep
            }
        }
        .task {
            await viewModel.load()
            await confidence.load()
        }
    }

    // MARK: - Step 1: Proof

    private var proofStep: some View {
        VStack(spacing: Spacing.xl) {
            stepHeader("MATCH DAY", title: "First: the facts.")

            if confidence.isLoading {
                SkeletonCard()
            } else {
                VStack(spacing: 12) {
                    ForEach(confidence.snapshot.evidenceLines.prefix(3)) { line in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: line.icon)
                                .font(.system(size: 16))
                                .foregroundStyle(Color.dsTertiary)
                                .frame(width: 24)
                            Text(line.text)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.dsOnSurface)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(Spacing.lg)
                        .background(Color.dsSurfaceContainerLow)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                        .ghostBorder()
                    }
                }
            }

            Text("You didn't get lucky. You trained.")
                .font(.system(size: 13))
                .foregroundStyle(Color.dsOnSurfaceVariant)

            Spacer()

            primaryButton("NEXT: MY JOB TODAY") {
                withAnimation(.dsSnappy) { step = .goal }
            }
        }
        .padding(Spacing.xl)
    }

    // MARK: - Step 2: Process goal

    private var goalStep: some View {
        VStack(spacing: Spacing.xl) {
            stepHeader("MY JOB TODAY", title: "Pick one thing you control.")

            Text("Not goals. Not the score. One brave job that's yours whatever happens.")
                .font(.system(size: 13))
                .foregroundStyle(Color.dsOnSurfaceVariant)
                .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                ForEach(MatchPresets.processGoals, id: \.self) { goal in
                    selectableRow(
                        goal,
                        selected: viewModel.selectedGoal == goal
                    ) {
                        viewModel.selectedGoal = goal
                    }
                }
            }

            Spacer()

            primaryButton("NEXT: MY WORDS", disabled: !viewModel.canSavePrep) {
                withAnimation(.dsSnappy) { step = .cue }
            }
        }
        .padding(Spacing.xl)
    }

    // MARK: - Step 3: Power cue

    private var cueStep: some View {
        VStack(spacing: Spacing.xl) {
            stepHeader("MY WORDS", title: "Pick your power cue.")

            Text("The words you'll say to yourself when it gets hard.")
                .font(.system(size: 13))
                .foregroundStyle(Color.dsOnSurfaceVariant)

            VStack(spacing: 10) {
                ForEach(MatchPresets.powerCues, id: \.self) { cue in
                    selectableRow(cue, selected: viewModel.selectedCue == cue) {
                        viewModel.selectedCue = cue
                    }
                }
            }

            Spacer()

            primaryButton("BREATHE IT IN") {
                Task { await viewModel.savePrep() }
                breathStartedAt = Date()
                withAnimation(.dsSnappy) { step = .breathe }
            }
        }
        .padding(Spacing.xl)
    }

    // MARK: - Step 4: One breath, ending on the cue

    private var breatheStep: some View {
        let routine = ResetRoutine(cueWord: viewModel.selectedCue)

        return TimelineView(.animation) { context in
            let elapsed = context.date.timeIntervalSince(breathStartedAt ?? context.date)

            if let active = routine.phase(at: elapsed) {
                VStack(spacing: Spacing.xl) {
                    Spacer()

                    ZStack {
                        Circle()
                            .fill(Color.dsSecondary.opacity(0.12))
                            .frame(width: 220, height: 220)
                        Circle()
                            .fill(Color.dsSecondary.opacity(0.25))
                            .frame(width: 220 * breathScale(active), height: 220 * breathScale(active))
                        if active.phase.kind == .cue {
                            Text("\u{201C}\(viewModel.selectedCue)\u{201D}")
                                .font(.system(size: 20, weight: .heavy, design: .rounded))
                                .foregroundStyle(Color.dsSecondary)
                        }
                    }

                    Text(active.phase.prompt)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.dsOnSurface)
                        .multilineTextAlignment(.center)
                        .id(active.index)

                    Spacer()
                }
                .padding(Spacing.xl)
            } else {
                Color.clear.onAppear {
                    withAnimation(.dsSnappy) { step = .ready }
                }
            }
        }
    }

    private func breathScale(_ active: (index: Int, phase: ResetRoutine.Phase, progress: Double)) -> Double {
        switch active.phase.kind {
        case .breatheIn: return 0.55 + 0.45 * active.progress
        case .breatheOut: return 1.0 - 0.45 * active.progress
        case .cue: return 0.7
        }
    }

    // MARK: - Step 5: Ready

    private var readyStep: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            Image(systemName: "figure.soccer")
                .font(.system(size: 44))
                .foregroundStyle(Color.dsTertiary)

            Text("You're ready.")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.dsOnSurface)

            VStack(spacing: 12) {
                labeledLine("MY JOB", viewModel.savedPrep?.processGoal ?? viewModel.selectedGoal ?? "")
                labeledLine("MY WORDS", "\u{201C}\(viewModel.savedPrep?.powerCue ?? viewModel.selectedCue)\u{201D}")
            }

            Text("Win, lose, or draw — do your job and you've won your part.")
                .font(.system(size: 13))
                .foregroundStyle(Color.dsOnSurfaceVariant)
                .multilineTextAlignment(.center)

            Spacer()

            primaryButton("GO BE BRAVE") { dismiss() }
        }
        .padding(Spacing.xl)
    }

    private func labeledLine(_ label: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color.dsTertiary)
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color.dsOnSurface)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .background(Color.dsSurfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .ghostBorder()
    }

    // MARK: - Shared bits

    private func stepHeader(_ kicker: String, title: String) -> some View {
        VStack(spacing: 6) {
            Text(kicker)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(3)
                .foregroundStyle(Color.dsTertiary)
            Text(title)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.dsOnSurface)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Spacing.lg)
    }

    private func selectableRow(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(selected ? Color.dsSecondary : Color.dsOnSurface)
                    .multilineTextAlignment(.leading)
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.dsSecondary)
                }
            }
            .padding(Spacing.lg)
            .background(selected ? Color.dsSecondary.opacity(0.12) : Color.dsSurfaceContainer)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(selected ? Color.dsSecondary.opacity(0.35) : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func primaryButton(_ title: String, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color.dsCTALabel)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(DSGradient.primaryCTA)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                .dsPrimaryShadow()
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1)
    }
}

#Preview {
    MatchPrepView(childId: "preview")
}
