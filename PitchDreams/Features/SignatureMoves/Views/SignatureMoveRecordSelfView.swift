import SwiftUI

/// Optional capstone at the end of the final stage. User records a 10-sec
/// clip of their best attempt. For launch, the recording UI is a stubbed
/// camera preview — real AVCaptureSession wiring follows post-launch once
/// we have photo-library + camera permissions flows spec'd.
///
/// Matches `proposals/Stitch/signature_move_record_self.png`.
struct SignatureMoveRecordSelfView: View {
    @ObservedObject var viewModel: SignatureMoveLearningViewModel
    let stage: Int

    enum Phase: Equatable {
        case intro
        case countdown(Int)
        case recording(Int)    // seconds elapsed 0-10
        case review
    }

    @State private var phase: Phase = .intro

    var body: some View {
        ZStack {
            Color.dsBackground.ignoresSafeArea()

            switch phase {
            case .intro:     introView
            case .countdown: countdownView
            case .recording: recordingView
            case .review:    reviewView
            }
        }
    }

    // MARK: - Intro

    private var introView: some View {
        VStack(spacing: Spacing.xl) {
            headerRow(title: "FILM YOURSELF", showClose: true)

            Spacer().frame(height: 4)

            Image(systemName: "camera.fill")
                .font(.system(size: 72))
                .foregroundStyle(Color.dsAccentOrange)
                .shadow(color: Color.dsAccentOrange.opacity(0.4), radius: 12)

            VStack(spacing: 10) {
                Text("Film Yourself")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.dsOnSurface)
                Text("10 seconds of your best attempt. We'll save it to your Journey. Only you and your parents can see it.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 32)
            }

            Spacer()

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                phase = .countdown(3)
                startCountdown()
            } label: {
                Text("OPEN CAMERA")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color.dsCTALabel)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(DSGradient.primaryCTA)
                    .clipShape(Capsule())
                    .dsPrimaryShadow()
            }
            .padding(.horizontal, Spacing.xl)

            Button {
                Task { await viewModel.finishRecording(videoPath: nil) }
            } label: {
                Text("SKIP THIS")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color.dsSecondary)
                    .underline()
            }
            .padding(.bottom, 30)
        }
    }

    // MARK: - Countdown / Recording

    @ViewBuilder
    private var countdownView: some View {
        ZStack {
            cameraPreviewPlaceholder

            VStack(spacing: Spacing.xl) {
                headerRow(title: "READY", showClose: false, dark: true)

                Spacer()

                if case let .countdown(value) = phase {
                    Text("\(value)")
                        .font(.system(size: 120, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.8), radius: 8)
                        .id(value)
                        .transition(.scale.combined(with: .opacity))
                }

                Spacer()
            }
            .padding(.horizontal, Spacing.xl)
        }
    }

    @ViewBuilder
    private var recordingView: some View {
        ZStack {
            cameraPreviewPlaceholder

            VStack(spacing: Spacing.xl) {
                headerRow(title: "RECORDING", showClose: false, dark: true, recording: true)

                Spacer()

                if case let .recording(elapsed) = phase {
                    VStack(spacing: 10) {
                        Text(String(format: "00:%02d", elapsed))
                            .font(.system(size: 48, weight: .heavy, design: .rounded).monospacedDigit())
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.8), radius: 6)

                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 3)
                                .frame(width: 78, height: 78)
                            Circle()
                                .trim(from: 0, to: CGFloat(elapsed) / 10.0)
                                .stroke(Color.red, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .frame(width: 78, height: 78)
                            Circle()
                                .fill(Color.red)
                                .frame(width: 58, height: 58)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.white.opacity(0.7), lineWidth: 2)
                                        .frame(width: 16, height: 16)
                                )
                                .shadow(color: Color.red.opacity(0.5), radius: 10)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .padding(.horizontal, Spacing.xl)
        }
    }

    private var cameraPreviewPlaceholder: some View {
        LinearGradient(colors: [Color(hex: "#10151F"), Color.black], startPoint: .top, endPoint: .bottom)
            .overlay(
                Image(systemName: "figure.run.square.stack.fill")
                    .font(.system(size: 120))
                    .foregroundStyle(.white.opacity(0.08))
            )
            .ignoresSafeArea()
    }

    // MARK: - Review

    private var reviewView: some View {
        VStack(spacing: Spacing.xl) {
            headerRow(title: "REVIEW", showClose: true)

            Spacer().frame(height: 6)

            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color.dsSurfaceContainerHigh)
                .frame(height: 280)
                .overlay(
                    VStack(spacing: 10) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(Color.dsAccentOrange)
                        Text("Your clip is ready.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.dsOnSurfaceVariant)
                    }
                )
                .padding(.horizontal, Spacing.xl)

            Spacer()

            // Saved on-device note
            Text("Saved on this device only.")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.dsOnSurfaceVariant)

            VStack(spacing: 12) {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    // Launch stub: persists a placeholder path. Real clip
                    // handoff comes when we wire AVCaptureSession + Documents.
                    let path = "recorded_moves/\(viewModel.move.id)_\(Int(Date().timeIntervalSince1970)).mp4"
                    Task { await viewModel.finishRecording(videoPath: path) }
                } label: {
                    Text("SAVE")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(Color.dsCTALabel)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(DSGradient.primaryCTA)
                        .clipShape(Capsule())
                        .dsPrimaryShadow()
                }

                HStack(spacing: 16) {
                    Button {
                        phase = .intro
                    } label: {
                        Text("RETAKE")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .tracking(2)
                            .foregroundStyle(Color.dsSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.dsSurfaceContainerLow)
                            .clipShape(Capsule())
                    }
                    Button {
                        Task { await viewModel.finishRecording(videoPath: nil) }
                    } label: {
                        Text("SKIP THIS")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .tracking(2)
                            .foregroundStyle(Color.dsOnSurfaceVariant)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.dsSurfaceContainerLow)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Shared header

    private func headerRow(title: String, showClose: Bool, dark: Bool = false, recording: Bool = false) -> some View {
        HStack {
            if showClose {
                Button {
                    Task { await viewModel.finishRecording(videoPath: nil) }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(dark ? .white : Color.dsAccentOrange)
                        .frame(width: 32, height: 32)
                }
                .accessibilityLabel("Skip recording")
            } else {
                Color.clear.frame(width: 32, height: 32)
            }
            Spacer()
            HStack(spacing: 6) {
                if recording {
                    Circle().fill(Color.red).frame(width: 8, height: 8)
                }
                Text(title)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(dark ? .white : Color.dsAccentOrange)
            }
            Spacer()
            Button {
                // Camera flip placeholder — no-op until AVCapture wiring lands.
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath.camera")
                    .font(.system(size: 16))
                    .foregroundStyle(dark ? .white : Color.dsAccentOrange)
                    .frame(width: 32, height: 32)
            }
            .accessibilityHidden(true)
            .opacity(dark ? 1 : 0)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.top, 8)
    }

    // MARK: - Timers

    private func startCountdown() {
        Task {
            for remaining in [3, 2, 1] {
                try? await Task.sleep(for: .seconds(1))
                await MainActor.run {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                        if remaining > 1 {
                            phase = .countdown(remaining - 1)
                        } else {
                            phase = .recording(0)
                        }
                    }
                }
            }
            await startRecording()
        }
    }

    private func startRecording() async {
        for elapsed in 1...10 {
            try? await Task.sleep(for: .seconds(1))
            if case .recording = phase {
                await MainActor.run { phase = .recording(elapsed) }
            } else {
                return
            }
        }
        await MainActor.run {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                phase = .review
            }
        }
    }
}
