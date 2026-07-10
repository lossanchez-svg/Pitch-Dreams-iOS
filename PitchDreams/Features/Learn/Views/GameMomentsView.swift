import SwiftUI

/// Game Moments — read the pitch, decide before the clock runs out.
/// The freeze-frame reuses `AnimatedTacticalPitchView`; the visible countdown
/// is view-driven and reports expiry to the view model.
struct GameMomentsView: View {
    @StateObject private var viewModel: GameMomentsViewModel
    @Environment(\.dismiss) private var dismiss

    /// Set when the clock starts for the current scenario; drives the ring.
    @State private var clockStartedAt: Date?

    init(childId: String) {
        _viewModel = StateObject(wrappedValue: GameMomentsViewModel(childId: childId))
    }

    var body: some View {
        ZStack {
            Color.dsBackground.ignoresSafeArea()

            switch viewModel.phase {
            case .intro:
                intro
            case .deciding:
                deciding
            case .feedback(let result):
                feedback(result)
            case .summary:
                summary
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.dsBackground, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Text("GAME MOMENTS")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color.dsSecondary)
            }
        }
        .task { await viewModel.loadTotals() }
    }

    // MARK: - Intro

    private var intro: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            Image(systemName: "brain.head.profile")
                .font(.system(size: 44))
                .foregroundStyle(Color.dsSecondary)

            Text("Read the pitch.\nDecide fast.")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.dsOnSurface)
                .multilineTextAlignment(.center)

            Text("A real moment from a match freezes on screen. You get \(Int(viewModel.scenarios.first?.clockSeconds ?? 3)) seconds to pick the best option — because in a game, the clock is always running.")
                .font(.system(size: 15))
                .foregroundStyle(Color.dsOnSurfaceVariant)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if viewModel.lifetimeTotals.answered > 0 {
                HStack(spacing: 20) {
                    statPill(value: "\(viewModel.lifetimeTotals.correct)", label: "SOLVED")
                    if viewModel.lifetimeTotals.bestReactionMs > 0 {
                        statPill(
                            value: String(format: "%.1fs", Double(viewModel.lifetimeTotals.bestReactionMs) / 1000),
                            label: "BEST REACTION"
                        )
                    }
                }
            }

            Spacer()

            Button {
                viewModel.begin()
                clockStartedAt = Date()
            } label: {
                Text("PLAY THE MOMENT")
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
        }
        .padding(Spacing.xl)
    }

    private func statPill(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.dsOnSurface)
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .tracking(1)
                .foregroundStyle(Color.dsOnSurfaceVariant)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(Color.dsSurfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
    }

    // MARK: - Deciding

    @ViewBuilder
    private var deciding: some View {
        if let scenario = viewModel.currentScenario {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    progressHeader

                    Text(scenario.situation)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.dsOnSurface)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, Spacing.lg)

                    AnimatedTacticalPitchView(diagram: scenario.diagram, stepIndex: 0)
                        .aspectRatio(1.4, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))

                    shotClock(scenario)

                    VStack(spacing: 10) {
                        ForEach(scenario.options) { option in
                            Button {
                                viewModel.choose(option.id)
                            } label: {
                                Text(option.label)
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.dsOnSurface)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.dsSurfaceContainerHigh)
                                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                                    .ghostBorder()
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(Spacing.xl)
            }
        }
    }

    private func shotClock(_ scenario: DecisionScenario) -> some View {
        TimelineView(.animation) { context in
            let elapsed = context.date.timeIntervalSince(clockStartedAt ?? context.date)
            let remaining = max(0, scenario.clockSeconds - elapsed)
            let fraction = remaining / scenario.clockSeconds

            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .stroke(Color.dsSurfaceContainerHighest, lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: fraction)
                        .stroke(
                            fraction > 0.4 ? Color.dsSecondary : Color.dsError,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    Text(String(format: "%.0f", ceil(remaining)))
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.dsOnSurface)
                }
                .frame(width: 44, height: 44)

                Text("DECIDE")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(2)
                    .foregroundStyle(Color.dsOnSurfaceVariant)
            }
            .onChange(of: remaining <= 0) { expired in
                if expired { viewModel.timeUp() }
            }
        }
    }

    // MARK: - Feedback

    private func feedback(_ result: DecisionResult) -> some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                progressHeader

                if let scenario = viewModel.currentScenario {
                    Image(systemName: result.correct ? "checkmark.circle.fill" : (result.chosenOptionId == nil ? "clock.badge.exclamationmark.fill" : "xmark.circle.fill"))
                        .font(.system(size: 44))
                        .foregroundStyle(result.correct ? .green : Color.dsAccentOrange)

                    Text(feedbackTitle(result))
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.dsOnSurface)

                    if result.correct {
                        Text(String(format: "Decided in %.1f seconds", Double(result.reactionMs) / 1000))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.dsSecondary)
                    }

                    // Every option, marked, with the rationale for the pick.
                    VStack(spacing: 10) {
                        ForEach(scenario.options) { option in
                            optionResultRow(option, result: result)
                        }
                    }

                    if let explained = explainedOption(scenario, result: result) {
                        Text(explained.rationale)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.dsOnSurfaceVariant)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(Spacing.lg)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.dsSurfaceContainer)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                    }
                }

                Button {
                    viewModel.next()
                    clockStartedAt = Date()
                } label: {
                    Text(viewModel.currentIndex + 1 < viewModel.scenarios.count ? "NEXT MOMENT" : "SEE YOUR ROUND")
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
            }
            .padding(Spacing.xl)
        }
    }

    private func feedbackTitle(_ result: DecisionResult) -> String {
        if result.correct { return "Right ball!" }
        if result.chosenOptionId == nil { return "The moment passed." }
        return "Not that one."
    }

    /// Rationale shown: the kid's pick if wrong (why it fails), best if right or timed out.
    private func explainedOption(_ scenario: DecisionScenario, result: DecisionResult) -> DecisionOption? {
        if result.correct { return scenario.bestOption }
        if let chosen = result.chosenOptionId {
            return scenario.options.first { $0.id == chosen }
        }
        return scenario.bestOption
    }

    private func optionResultRow(_ option: DecisionOption, result: DecisionResult) -> some View {
        let isChosen = option.id == result.chosenOptionId
        let tint: Color = option.isBest ? .green : (isChosen ? Color.dsError : Color.dsOnSurfaceVariant)

        return HStack(spacing: 10) {
            Image(systemName: option.isBest ? "checkmark.circle.fill" : (isChosen ? "xmark.circle.fill" : "circle"))
                .foregroundStyle(tint)
            Text(option.label)
                .font(.system(size: 14, weight: isChosen || option.isBest ? .bold : .regular))
                .foregroundStyle(Color.dsOnSurface)
            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, 10)
        .background((option.isBest ? Color.green : (isChosen ? Color.dsError : Color.clear)).opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
    }

    // MARK: - Summary

    private var summary: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            Text(viewModel.correctCount == viewModel.scenarios.count ? "\u{1F9E0}" : "\u{26BD}")
                .font(.system(size: 52))

            Text("\(viewModel.correctCount) of \(viewModel.scenarios.count) right")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.dsOnSurface)

            if let best = viewModel.bestReactionMsThisRound {
                Text(String(format: "Fastest right call: %.1fs", Double(best) / 1000))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.dsSecondary)
            }

            Text("Decisions get faster the more moments you see. Same as on the pitch.")
                .font(.system(size: 14))
                .foregroundStyle(Color.dsOnSurfaceVariant)
                .multilineTextAlignment(.center)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("DONE")
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
        }
        .padding(Spacing.xl)
    }

    private var progressHeader: some View {
        HStack(spacing: 6) {
            ForEach(0..<viewModel.scenarios.count, id: \.self) { index in
                Capsule()
                    .fill(fillColor(for: index))
                    .frame(height: 4)
            }
        }
    }

    private func fillColor(for index: Int) -> Color {
        if index < viewModel.results.count {
            return viewModel.results[index].correct ? .green : Color.dsError
        }
        return index == viewModel.currentIndex ? Color.dsSecondary : Color.dsSurfaceContainerHighest
    }
}

#Preview {
    NavigationStack {
        GameMomentsView(childId: "preview")
    }
}
