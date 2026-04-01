import SwiftUI

struct ActiveDrillView: View {
    let childId: String
    @StateObject private var viewModel: ActiveTrainingViewModel
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var lastVoiceCommand: String?
    @Environment(\.dismiss) private var dismiss

    init(childId: String, drills: [DrillDefinition], spaceType: String) {
        self.childId = childId
        _viewModel = StateObject(wrappedValue: ActiveTrainingViewModel(
            childId: childId, drills: drills, spaceType: spaceType
        ))
    }

    var body: some View {
        Group {
            switch viewModel.phase {
            case .drilling:
                drillContent
            case .repConfirm:
                repConfirmContent
            case .reflection:
                ReflectionView(viewModel: viewModel, speechRecognizer: speechRecognizer)
            case .complete:
                SessionCompleteView(viewModel: viewModel)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if speechRecognizer.isListening {
                VoiceCommandBar(speechRecognizer: speechRecognizer, lastCommand: $lastVoiceCommand)
            }
        }
        .navigationTitle("Training")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await speechRecognizer.toggleListening() }
                } label: {
                    Image(systemName: speechRecognizer.isListening ? "mic.fill" : "mic")
                        .foregroundStyle(speechRecognizer.isListening ? .red : .cyan)
                }
            }
        }
        .onChange(of: speechRecognizer.transcript) { newTranscript in
            guard !newTranscript.isEmpty else { return }
            processDrillVoiceCommand(newTranscript)
        }
    }

    // MARK: - Voice Commands

    private func processDrillVoiceCommand(_ transcript: String) {
        let commands: [VoiceCommand] = [
            VoiceCommand(label: "Pause", phrases: ["pause", "hold", "wait"]) {
                if viewModel.isTimerRunning {
                    viewModel.pauseTimer()
                }
            },
            VoiceCommand(label: "Resume", phrases: ["resume", "restart", "continue", "start"]) {
                if !viewModel.isTimerRunning && viewModel.phase == .drilling {
                    viewModel.startDrill()
                }
            },
            VoiceCommand(label: "Done", phrases: ["done", "finish", "complete"]) {
                viewModel.completeDrill()
            },
            VoiceCommand(label: "Next", phrases: ["next", "skip"]) {
                viewModel.confirmReps()
            },
            VoiceCommand(label: "Cancel", phrases: ["cancel", "stop", "quit"]) {
                dismiss()
            },
            VoiceCommand(label: "Mic Off", phrases: ["mic off", "stop listening", "mute mic"]) {
                speechRecognizer.stopListening()
            },
        ]

        if let matched = VoiceCommandMatcher.match(transcript: transcript, commands: commands) {
            lastVoiceCommand = matched.label
            matched.action()
            return
        }

        // Try number extraction for rep count
        if let number = VoiceCommandMatcher.extractNumber(from: transcript) {
            lastVoiceCommand = "\(number) reps"
            viewModel.repCount = number
        }
    }

    // MARK: - Drill Phase

    private var drillContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Progress
                HStack {
                    Text("Drill \(viewModel.drillProgress)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(viewModel.currentDrill?.category ?? "")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.orange.opacity(0.12))
                        .foregroundStyle(.orange)
                        .clipShape(Capsule())
                }

                if let drill = viewModel.currentDrill {
                    // Drill info
                    VStack(spacing: 8) {
                        Text(drill.name)
                            .font(.title.bold())
                        Text(drill.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    // Timer
                    ZStack {
                        Circle()
                            .stroke(Color(.systemGray5), lineWidth: 8)
                            .frame(width: 180, height: 180)
                        Circle()
                            .trim(from: 0, to: timerProgress(drill))
                            .stroke(.orange, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 180, height: 180)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: viewModel.timeRemaining)

                        VStack(spacing: 4) {
                            Text(formattedTime)
                                .font(.system(size: 48, weight: .bold, design: .monospaced))
                            Text("remaining")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Rep counter
                    HStack(spacing: 20) {
                        VStack(spacing: 4) {
                            Text("Reps")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                            Text("\(viewModel.repCount)")
                                .font(.title2.bold())
                        }

                        Button {
                            viewModel.incrementReps()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(.orange)
                        }
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    // Coach tip
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.yellow)
                        Text(drill.coachTip)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Controls
                    HStack(spacing: 16) {
                        if viewModel.isTimerRunning {
                            Button {
                                viewModel.pauseTimer()
                            } label: {
                                Label("Pause", systemImage: "pause.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(.regularMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button {
                                viewModel.startDrill()
                            } label: {
                                Label("Start", systemImage: "play.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(.orange.gradient)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }

                        Button {
                            viewModel.completeDrill()
                        } label: {
                            Label("Done", systemImage: "checkmark")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.regularMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                }

                if let error = viewModel.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            }
            .padding()
        }
    }

    // MARK: - Rep Confirm

    private var repConfirmContent: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("Drill Complete!")
                .font(.title2.bold())

            if let drill = viewModel.currentDrill {
                Text(drill.name)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 8) {
                Text("Reps completed: \(viewModel.repCount)")
                    .font(.subheadline)
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Button {
                viewModel.confirmReps()
            } label: {
                Text(viewModel.isLastDrill ? "Go to Reflection" : "Next Drill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.orange.gradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
    }

    // MARK: - Helpers

    private func timerProgress(_ drill: DrillDefinition) -> Double {
        guard drill.duration > 0 else { return 0 }
        return Double(viewModel.timeRemaining) / Double(drill.duration)
    }

    private var formattedTime: String {
        let minutes = viewModel.timeRemaining / 60
        let seconds = viewModel.timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
