import SwiftUI

/// Container for the drill-player screen — routes to one of four variants
/// based on `drill.type`. Header and "I'm done" CTA are shared; each variant
/// defines its own middle content.
struct SignatureMoveDrillPlayerView: View {
    @ObservedObject var viewModel: SignatureMoveLearningViewModel
    let stage: Int
    let drillId: String

    private var drill: MoveDrill? {
        viewModel.move.stages.first { $0.order == stage }?.drills.first { $0.id == drillId }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, Spacing.xl)
                .padding(.top, 4)

            if let drill = drill {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.xl) {
                        // Variant-specific content
                        switch drill.type {
                        case .watch:
                            WatchDrillContent(viewModel: viewModel, drill: drill)
                        case .mimic:
                            MimicDrillContent(viewModel: viewModel, drill: drill)
                        case .withBall:
                            WithBallDrillContent(viewModel: viewModel, drill: drill)
                        case .challenge:
                            ChallengeDrillContent(viewModel: viewModel, drill: drill)
                        }

                        // Rotating common mistake card (if drill has any)
                        if let mistake = viewModel.currentMistake(for: drill) {
                            commonMistakeCard(mistake)
                                .padding(.horizontal, Spacing.xl)
                        }
                        Color.clear.frame(height: 110)
                    }
                    .padding(.top, 12)
                }
            }
        }
        .overlay(alignment: .bottom) {
            if drill != nil {
                doneCTA
                    .padding(.horizontal, Spacing.xl)
                    .padding(.bottom, 16)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                viewModel.currentStep = .stageIntro(stage: stage)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
            }
            .accessibilityLabel("Back to stage")
            Spacer()
            Text("SIGNATURE DRILL")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color.dsAccentOrange)
            Spacer()
            Color.clear.frame(width: 32, height: 32)
        }
    }

    private func commonMistakeCard(_ mistake: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.dsAccentOrange)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                Text("COMMON MISTAKE")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color.dsAccentOrange)
                Text(mistake)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.dsOnSurface)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(Color(hex: "#2A1410"))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(Color.dsAccentOrange.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Done CTA

    @ViewBuilder
    private var doneCTA: some View {
        if let drill = drill {
            let target = drill.targetReps
            let enabled = viewModel.currentDrillReps >= target || drill.type == .watch
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                Task { await viewModel.completeDrill() }
            } label: {
                Text(drill.type == .watch ? "I'VE WATCHED THIS" : "I'M DONE")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(enabled ? Color.dsCTALabel : Color.dsOnSurfaceVariant)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(enabled ? AnyShapeStyle(DSGradient.primaryCTA) : AnyShapeStyle(Color.dsSurfaceContainerHigh))
                    .clipShape(Capsule())
                    .dsPrimaryShadow()
            }
            .disabled(!enabled)
        }
    }
}

// MARK: - Variant: Watch

private struct WatchDrillContent: View {
    @ObservedObject var viewModel: SignatureMoveLearningViewModel
    let drill: MoveDrill

    var body: some View {
        VStack(spacing: Spacing.xl) {
            // Video player placeholder — asset loader hooks in here later.
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(
                        LinearGradient(colors: [Color(hex: "#0F1F32"), Color.black], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(height: 240)
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Color.dsAccentOrange)
                    .shadow(color: Color.dsAccentOrange.opacity(0.6), radius: 10)
            }
            .padding(.horizontal, Spacing.xl)

            // Age-adapted instructions
            Text(viewModel.instructions(for: drill))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.dsOnSurface)
                .lineSpacing(3)
                .padding(.horizontal, Spacing.xl)
                .fixedSize(horizontal: false, vertical: true)

            // Coach cue card
            if let cue = viewModel.currentCue {
                coachCueCard(cue)
                    .padding(.horizontal, Spacing.xl)
            }
        }
    }

    private func coachCueCard(_ cue: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("COACH CUE")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color.dsSecondary)
            Text(cue)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.dsOnSurface)
        }
        .padding(14)
        .background(Color.dsSecondary.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
    }
}

// MARK: - Variant: Mimic

private struct MimicDrillContent: View {
    @ObservedObject var viewModel: SignatureMoveLearningViewModel
    let drill: MoveDrill

    var body: some View {
        VStack(spacing: Spacing.xl) {
            // Floating coach cue toast top-right
            if let cue = viewModel.currentCue {
                HStack {
                    Spacer()
                    Text(cue)
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.dsAccentOrange)
                        .clipShape(Capsule())
                        .shadow(color: Color.dsAccentOrange.opacity(0.4), radius: 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                .padding(.horizontal, Spacing.xl)
            }

            // Large figure-motion art — SF Symbol at huge scale
            Image(systemName: drill.type.iconSymbol)
                .font(.system(size: 160, weight: .regular))
                .foregroundStyle(Color(hex: "#8B5CF6"))
                .symbolRenderingMode(.hierarchical)
                .frame(height: 240)

            // Tap-to-count rep counter
            repCounterButton
                .padding(.horizontal, Spacing.xl)

            Text("TARGET: \(drill.targetReps) REPS")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color.dsOnSurfaceVariant)

            // Progress bar beneath target
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.dsSurfaceContainerHighest).frame(height: 6)
                    Capsule()
                        .fill(Color.dsSecondary)
                        .frame(
                            width: geo.size.width * CGFloat(min(viewModel.currentDrillReps, drill.targetReps))
                                / CGFloat(max(1, drill.targetReps)),
                            height: 6
                        )
                }
            }
            .frame(height: 6)
            .padding(.horizontal, Spacing.xl * 2)
        }
    }

    private var repCounterButton: some View {
        Button {
            viewModel.incrementRep()
        } label: {
            VStack(spacing: 4) {
                Text("\(viewModel.currentDrillReps)")
                    .font(.system(size: 72, weight: .heavy, design: .rounded).monospacedDigit())
                    .foregroundStyle(Color(hex: "#2A1A08"))
                Text("TAP REPS")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color(hex: "#2A1A08"))
            }
            .frame(width: 220, height: 220)
            .background(Color.dsAccentOrange)
            .clipShape(RoundedRectangle(cornerRadius: 36))
            .shadow(color: Color.dsAccentOrange.opacity(0.5), radius: 20)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Tap to add rep. Current: \(viewModel.currentDrillReps).")
    }
}

// MARK: - Variant: With Ball

private struct WithBallDrillContent: View {
    @ObservedObject var viewModel: SignatureMoveLearningViewModel
    let drill: MoveDrill

    @State private var readyForDrill: Bool = false

    var body: some View {
        VStack(spacing: Spacing.xl) {
            if readyForDrill {
                runningContent
            } else {
                setupCard
            }
        }
    }

    // MARK: Setup

    private var setupCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().fill(Color.dsAccentOrange).frame(width: 54, height: 54)
                Image(systemName: "info")
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundStyle(Color(hex: "#2A1A08"))
            }
            Text("INSTRUCTIONS")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color.dsSecondary)
            Text("SETUP")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.dsOnSurface)
            Text(drill.setupInstructions ?? viewModel.instructions(for: drill))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.dsOnSurfaceVariant)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    readyForDrill = true
                }
            } label: {
                Text("READY")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color(hex: "#06293A"))
                    .padding(.horizontal, 64)
                    .padding(.vertical, 14)
                    .background(Color.dsSecondary)
                    .clipShape(Capsule())
            }
        }
        .padding(26)
        .frame(maxWidth: .infinity)
        .background(Color.dsSurfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xxl))
        .ghostBorder()
        .padding(.horizontal, Spacing.xl)
    }

    // MARK: Running

    private var runningContent: some View {
        VStack(spacing: Spacing.xl) {
            // Demo loop placeholder + coach cue overlay
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(Color.dsSurfaceContainerHigh)
                    .frame(height: 180)
                    .overlay(
                        Image(systemName: "figure.run")
                            .font(.system(size: 72))
                            .foregroundStyle(Color.dsSecondary.opacity(0.5))
                    )

                if let cue = viewModel.currentCue {
                    Text(cue)
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(Color(hex: "#06293A"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.dsSecondary)
                        .clipShape(Capsule())
                        .padding(10)
                }

                VStack {
                    Spacer()
                    HStack {
                        Text("DEMO LOOP")
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .tracking(1)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Capsule())
                        Spacer()
                    }
                }
                .padding(10)
            }
            .padding(.horizontal, Spacing.xl)

            VStack(spacing: 4) {
                Text("TIME ELAPSED")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color.dsOnSurfaceVariant)
                Text(formattedTime)
                    .font(.system(size: 38, weight: .heavy, design: .rounded).monospacedDigit())
                    .foregroundStyle(Color.dsOnSurface)
            }

            Button {
                viewModel.incrementRep()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.dsAccentOrange)
                        .frame(width: 200, height: 200)
                        .shadow(color: Color.dsAccentOrange.opacity(0.5), radius: 20)
                    VStack(spacing: 2) {
                        Text("\(viewModel.currentDrillReps)")
                            .font(.system(size: 64, weight: .heavy, design: .rounded).monospacedDigit())
                            .foregroundStyle(Color(hex: "#2A1A08"))
                        Text("TAP TO REP")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .tracking(2)
                            .foregroundStyle(Color(hex: "#2A1A08"))
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Tap to add rep. Current: \(viewModel.currentDrillReps).")
        }
    }

    private var formattedTime: String {
        let t = viewModel.currentDrillTime
        return String(format: "%02d:%02d", t / 60, t % 60)
    }
}

// MARK: - Variant: Challenge

private struct ChallengeDrillContent: View {
    @ObservedObject var viewModel: SignatureMoveLearningViewModel
    let drill: MoveDrill

    @State private var countdownRemaining = 3

    var body: some View {
        VStack(spacing: Spacing.xl) {
            if countdownRemaining > 0 {
                countdownView
            } else {
                runningView
            }
        }
        .onAppear {
            startCountdown()
        }
    }

    // MARK: Countdown

    private var countdownView: some View {
        VStack(spacing: 40) {
            challengeTypeChip

            Text(drill.title.uppercased())
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color.dsOnSurface)

            Spacer().frame(height: 40)

            Text(countdownText)
                .font(.system(size: 68, weight: .heavy, design: .rounded).italic())
                .foregroundStyle(Color.dsSecondary)
                .shadow(color: Color.dsSecondary.opacity(0.6), radius: 16)
                .id(countdownRemaining) // restart any transition on change
        }
    }

    private var countdownText: String {
        countdownRemaining == 0 ? "GO!" : "\(countdownRemaining)..."
    }

    private func startCountdown() {
        Task {
            while countdownRemaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                await MainActor.run {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        countdownRemaining -= 1
                    }
                }
            }
        }
    }

    // MARK: Running

    private var runningView: some View {
        VStack(spacing: Spacing.xl) {
            if let cue = viewModel.currentCue {
                Text(cue.uppercased())
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(Color(hex: "#06293A"))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Color.dsSecondary)
                    .clipShape(Capsule())
                    .shadow(color: Color.dsSecondary.opacity(0.4), radius: 8)
            }

            HStack(alignment: .center, spacing: 14) {
                challengeTypeChip
                Text(drill.title.uppercased())
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(Color.dsOnSurface)
                Spacer()
                countdownRing
            }
            .padding(.horizontal, Spacing.xl)

            VStack(spacing: 4) {
                Text("CURRENT PROGRESS")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color.dsSecondary)
                HStack(spacing: 6) {
                    Text("\(viewModel.currentDrillReps)")
                        .font(.system(size: 60, weight: .heavy, design: .rounded).monospacedDigit())
                        .foregroundStyle(Color.dsOnSurface)
                    Text("/ \(drill.targetReps) REPS")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                }
            }

            Button {
                viewModel.incrementRep()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Color.dsAccentOrange)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Log one rep")
        }
    }

    private var challengeTypeChip: some View {
        HStack(spacing: 6) {
            Circle().fill(Color.dsSecondary).frame(width: 6, height: 6)
            Text("TIMED")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(2)
        }
        .foregroundStyle(Color.dsSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.dsSurfaceContainerLow)
        .clipShape(Capsule())
    }

    private var countdownRing: some View {
        let total = CGFloat(drill.durationSeconds)
        let elapsed = CGFloat(min(viewModel.currentDrillTime, drill.durationSeconds))
        let remaining = max(0, drill.durationSeconds - viewModel.currentDrillTime)
        return ZStack {
            Circle()
                .stroke(Color.dsSurfaceContainerHighest, lineWidth: 4)
                .frame(width: 58, height: 58)
            Circle()
                .trim(from: 0, to: 1 - (elapsed / max(total, 1)))
                .stroke(Color.dsAccentOrange, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 58, height: 58)
            Text(formatTime(remaining))
                .font(.system(size: 13, weight: .heavy, design: .rounded).monospacedDigit())
                .foregroundStyle(Color.dsAccentOrange)
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
