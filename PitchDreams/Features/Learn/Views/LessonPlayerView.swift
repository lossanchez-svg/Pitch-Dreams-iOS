import SwiftUI

/// Full-screen step-by-step lesson experience with coach + animated pitch + narration.
struct LessonPlayerView: View {
    @StateObject private var viewModel: LessonPlayerViewModel
    @StateObject private var coachVM = CoachCharacterViewModel()
    @StateObject private var interactiveVM = InteractivePitchViewModel()
    @Environment(\.dismiss) private var dismiss

    private let trackColor: Color

    init(lesson: AnimatedTacticalLesson, voice: CoachVoiceProtocol? = nil) {
        let vm = LessonPlayerViewModel(lesson: lesson, voice: voice)
        _viewModel = StateObject(wrappedValue: vm)
        trackColor = Self.color(for: lesson.track)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Navigation bar
            navBar

            // Progress bar
            LessonProgressBar(
                totalSteps: viewModel.totalSteps,
                currentStep: viewModel.currentStepIndex,
                trackColor: trackColor,
                onTapStep: { viewModel.goToStep($0) }
            )
            .padding(.horizontal)
            .padding(.top, 4)

            if viewModel.isCompleted {
                completionView
            } else {
                stepContent
            }
        }
        .background(Color(.systemBackground))
        .onAppear {
            viewModel.onAppear()
            coachVM.speak(viewModel.currentStep.narration)
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        .onChange(of: viewModel.currentStepIndex) { _ in
            coachVM.speak(viewModel.currentStep.narration)
        }
        .onChange(of: viewModel.isCompleted) { _ in
            if viewModel.isCompleted {
                coachVM.setMood(.celebrating, duration: 5)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.width < -50 {
                        viewModel.goToNext()
                    } else if value.translation.width > 50 {
                        viewModel.goToPrevious()
                    }
                }
        )
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
            }

            Spacer()

            Text("Step \(viewModel.currentStepIndex + 1) of \(viewModel.totalSteps)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Spacer()

            // Spacer for symmetry
            Color.clear.frame(width: 32, height: 32)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Step Content

    private var stepContent: some View {
        VStack(spacing: 12) {
            // Animated pitch diagram with interactive tap targets
            ZStack {
                AnimatedTacticalPitchView(
                    diagram: viewModel.currentStep.diagram,
                    stepIndex: viewModel.currentStepIndex,
                    onPlayerTap: { player, pos in
                        interactiveVM.tapPlayer(player, at: pos)
                    },
                    onArrowTap: { arrow, pos in
                        interactiveVM.tapArrow(arrow, at: pos)
                    },
                    onZoneTap: { zone, pos in
                        interactiveVM.tapZone(zone, at: pos)
                    }
                )

                // Element popover overlay
                if interactiveVM.selectedElementId != nil {
                    PitchElementPopover(
                        text: interactiveVM.popoverText,
                        position: interactiveVM.popoverPosition,
                        onDismiss: { interactiveVM.dismiss() }
                    )
                }
            }
            .padding(.horizontal)

            // Coach character with speech bubble
            CoachCharacterView(viewModel: coachVM, size: .sm)
                .padding(.horizontal)

            Spacer()

            // Bottom controls
            bottomControls
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        HStack(spacing: 20) {
            // Previous
            Button {
                viewModel.goToPrevious()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .disabled(viewModel.currentStepIndex == 0)
            .opacity(viewModel.currentStepIndex == 0 ? 0.3 : 1)

            // Voice toggle
            Button {
                viewModel.toggleVoice()
            } label: {
                Image(systemName: viewModel.voiceEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .font(.body)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }

            // Auto-play toggle
            Button {
                viewModel.toggleAutoAdvance()
            } label: {
                Image(systemName: viewModel.isAutoAdvancing ? "pause.fill" : "play.fill")
                    .font(.body)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }

            // Next / Finish
            Button {
                viewModel.goToNext()
            } label: {
                HStack(spacing: 6) {
                    Text(viewModel.currentStepIndex == viewModel.totalSteps - 1 ? "Finish" : "Next")
                        .font(.headline)
                    Image(systemName: viewModel.currentStepIndex == viewModel.totalSteps - 1 ? "checkmark" : "chevron.right")
                        .font(.body.weight(.semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .frame(height: 44)
                .background(trackColor.gradient)
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 16)
    }

    // MARK: - Completion View

    private var completionView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(trackColor)

            Text("Lesson Complete!")
                .font(.title.bold())

            Text(viewModel.lesson.title)
                .font(.headline)
                .foregroundStyle(.secondary)

            CoachCharacterView(viewModel: coachVM, size: .md)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(trackColor.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Helpers

    private static func color(for track: String) -> Color {
        switch track {
        case "scanning": return .cyan
        case "decision_chain": return .purple
        case "tempo": return .orange
        default: return .blue
        }
    }
}
