import SwiftUI

/// Scan & Solve — the coach calls a direction while the ball travels; the
/// first touch has to go there. Calls come as spoken audio (when the voice
/// permission allows), a big visual, and a haptic thump, so the mode works
/// with the phone propped on a bag outdoors.
struct ScanSolveView: View {
    @StateObject private var viewModel: ScanSolveViewModel
    @StateObject private var coachVoice = CoachVoice()
    @Environment(\.dismiss) private var dismiss

    @State private var startedAt: Date?
    @State private var spokenIndex: Int = -1
    @State private var voiceEnabled = false
    @State private var showXPToast = false

    init(childId: String) {
        _viewModel = StateObject(wrappedValue: ScanSolveViewModel(childId: childId))
    }

    var body: some View {
        ZStack {
            Color.dsBackground.ignoresSafeArea()

            switch viewModel.phase {
            case .intro: intro
            case .playing: playing
            case .report: report
            case .done: done
            }
        }
        .overlay(alignment: .top) {
            XPEarnedToast(amount: viewModel.xpEarned, isPresented: $showXPToast)
                .padding(.top, 60)
        }
        .task {
            await viewModel.loadBest()
            await loadVoiceSetting()
        }
    }

    private func loadVoiceSetting() async {
        let apiClient: APIClientProtocol = APIClient.shared
        if let profile: ChildProfileDetail = try? await apiClient.request(APIRouter.getProfile(childId: viewModel.childId)) {
            voiceEnabled = profile.voiceEnabled
        }
    }

    // MARK: - Intro

    private var intro: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            Image(systemName: "eye.trianglebadge.exclamationmark")
                .font(.system(size: 44))
                .foregroundStyle(Color.dsAccentOrange)

            Text("Scan & Solve")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.dsOnSurface)

            Text("Keep a wall-ball rhythm going the whole round — don't stop passing. When the coach calls LEFT, RIGHT, TURN, or STOP, your very next first touch goes there, then straight back to your rhythm. \(viewModel.commandCount) calls, random timing. Stay listening.")
                .font(.system(size: 15))
                .foregroundStyle(Color.dsOnSurfaceVariant)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                ForEach(ScanCommand.allCases, id: \.self) { command in
                    VStack(spacing: 6) {
                        Image(systemName: command.icon)
                            .font(.system(size: 18, weight: .bold))
                        Text(command.display)
                            .font(.system(size: 9, weight: .heavy))
                            .tracking(1)
                    }
                    .foregroundStyle(Color.dsAccentOrange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.dsAccentOrange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("PACE")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(Color.dsOnSurfaceVariant)

                HStack(spacing: 8) {
                    ForEach(ScanPace.allCases, id: \.self) { pace in
                        let isSelected = viewModel.pace == pace
                        Button {
                            viewModel.pace = pace
                        } label: {
                            VStack(spacing: 3) {
                                Text(pace.label)
                                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                                    .tracking(1)
                                Text(pace.hint)
                                    .font(.system(size: 9))
                            }
                            .foregroundStyle(isSelected ? Color.dsAccentOrange : Color.dsOnSurfaceVariant)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(isSelected ? Color.dsAccentOrange.opacity(0.15) : Color.dsSurfaceContainerHighest)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: CornerRadius.md)
                                    .stroke(isSelected ? Color.dsAccentOrange.opacity(0.35) : .clear, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if viewModel.bestClean > 0 {
                Text("Your best: \(viewModel.bestClean)/\(viewModel.commandCount) clean")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.dsSecondary)
            }

            Spacer()

            Button {
                viewModel.start()
                startedAt = Date()
                spokenIndex = -1
            } label: {
                Text("START THE CALLS")
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

    // MARK: - Playing

    @ViewBuilder
    private var playing: some View {
        if let round = viewModel.round {
            TimelineView(.periodic(from: .now, by: 0.1)) { context in
                let elapsed = context.date.timeIntervalSince(startedAt ?? context.date)

                switch round.moment(at: elapsed) {
                case .leadIn(let remaining):
                    VStack(spacing: Spacing.xl) {
                        Spacer()
                        Text("GET YOUR RHYTHM GOING")
                            .font(.system(size: 14, weight: .heavy))
                            .tracking(3)
                            .foregroundStyle(Color.dsOnSurfaceVariant)
                        Text("Start passing the wall — calls are coming.")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.dsOnSurfaceVariant)
                        Text("\(Int(ceil(remaining)))")
                            .font(.system(size: 96, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.dsAccentOrange)
                            .contentTransition(.numericText())
                        Spacer()
                        cancelButton
                    }
                    .padding(Spacing.xl)

                case .rhythm(let nextIndex):
                    VStack(spacing: Spacing.xl) {
                        HStack(spacing: 6) {
                            ForEach(0..<round.commands.count, id: \.self) { i in
                                Capsule()
                                    .fill(i < nextIndex ? Color.dsAccentOrange : Color.dsSurfaceContainerHighest)
                                    .frame(height: 4)
                            }
                        }

                        Spacer()

                        Text("KEEP THE RHYTHM")
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.dsOnSurfaceVariant)

                        Text("Ears open — the next call comes when it comes.")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.dsOnSurfaceVariant.opacity(0.8))

                        Spacer()
                        cancelButton
                    }
                    .padding(Spacing.xl)

                case .command(let index, let command):
                    VStack(spacing: Spacing.xl) {
                        HStack(spacing: 6) {
                            ForEach(0..<round.commands.count, id: \.self) { i in
                                Capsule()
                                    .fill(i <= index ? Color.dsAccentOrange : Color.dsSurfaceContainerHighest)
                                    .frame(height: 4)
                            }
                        }

                        Spacer()

                        Image(systemName: command.icon)
                            .font(.system(size: 90, weight: .heavy))
                            .foregroundStyle(Color.dsAccentOrange)
                            .id("icon-\(index)")
                            .transition(.scale.combined(with: .opacity))

                        Text(command.display)
                            .font(.system(size: 44, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.dsOnSurface)
                            .id("label-\(index)")

                        Text("Call \(index + 1) of \(round.commands.count)")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.dsOnSurfaceVariant)

                        Spacer()
                        cancelButton
                    }
                    .padding(Spacing.xl)
                    .onChange(of: index) { newIndex in
                        announce(round.commands[newIndex], index: newIndex)
                    }
                    .onAppear {
                        // First command lands via onAppear, not onChange.
                        if spokenIndex < index {
                            announce(command, index: index)
                        }
                    }

                case .finished:
                    Color.clear.onAppear {
                        viewModel.finishRound()
                    }
                }
            }
        }
    }

    private func announce(_ command: ScanCommand, index: Int) {
        guard spokenIndex != index else { return }
        spokenIndex = index
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        if voiceEnabled {
            coachVoice.speak(command.spoken, personality: CoachPersonality.current.rawValue)
        }
    }

    private var cancelButton: some View {
        Button {
            viewModel.cancel()
        } label: {
            Text("Cancel")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.dsOnSurfaceVariant)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Report

    private var report: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            Text("How many touches went\nwhere the coach called?")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.dsOnSurface)
                .multilineTextAlignment(.center)

            Text("Be honest — that number is the one that improves.")
                .font(.system(size: 13))
                .foregroundStyle(Color.dsOnSurfaceVariant)

            HStack(spacing: Spacing.xl) {
                stepButton("minus") { viewModel.cleanCount = max(0, viewModel.cleanCount - 1) }

                Text("\(viewModel.cleanCount)")
                    .font(.system(size: 80, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.dsAccentOrange)
                    .frame(minWidth: 110)
                    .contentTransition(.numericText())

                stepButton("plus") { viewModel.cleanCount = min(viewModel.commandCount, viewModel.cleanCount + 1) }
            }

            Text("out of \(viewModel.commandCount) calls")
                .font(.system(size: 14))
                .foregroundStyle(Color.dsOnSurfaceVariant)

            Spacer()

            Button {
                Task {
                    await viewModel.save()
                    if viewModel.phase == .done {
                        showXPToast = true
                    }
                }
            } label: {
                Group {
                    if viewModel.isSaving {
                        ProgressView().tint(Color.dsCTALabel)
                    } else {
                        Text("SAVE MY ROUND")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .tracking(2)
                    }
                }
                .foregroundStyle(Color.dsCTALabel)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(DSGradient.primaryCTA)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                .dsPrimaryShadow()
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isSaving)

            if let error = viewModel.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color.dsError)
            }
        }
        .padding(Spacing.xl)
    }

    private func stepButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.dsOnSurface)
                .frame(width: 56, height: 56)
                .background(Color.dsSurfaceContainerHigh)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Done

    private var done: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            Image(systemName: viewModel.isNewPersonalBest ? "trophy.fill" : "checkmark.circle.fill")
                .font(.system(size: 52))
                .foregroundStyle(viewModel.isNewPersonalBest ? Color.dsTertiaryContainer : .green)

            Text(viewModel.isNewPersonalBest ? "New record!" : "Round banked.")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.dsOnSurface)

            Text("\(viewModel.cleanCount)/\(viewModel.commandCount) touches went where the game asked. That's scanning — the real thing.")
                .font(.system(size: 14))
                .foregroundStyle(Color.dsOnSurfaceVariant)
                .multilineTextAlignment(.center)

            Spacer()

            Button {
                viewModel.start()
                startedAt = Date()
                spokenIndex = -1
            } label: {
                Text("ANOTHER ROUND")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(Color.dsOnSurface)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.dsSurfaceContainerHigh)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                    .ghostBorder()
            }
            .buttonStyle(.plain)

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
}

#Preview {
    NavigationStack {
        ScanSolveView(childId: "preview")
    }
}
