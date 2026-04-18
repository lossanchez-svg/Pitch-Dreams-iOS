import SwiftUI

struct FirstSessionGuideView: View {
    let childId: String
    let onComplete: () -> Void

    @State private var step = 1
    @State private var tapCount = 0
    @State private var buttonScale: CGFloat = 1.0
    @State private var showCelebration = false
    @State private var isSaving = false

    private let tapTarget = 30
    private let apiClient: APIClientProtocol = APIClient()

    var body: some View {
        ZStack {
            Color.dsSurfaceContainerHighest
                .ignoresSafeArea()

            // Skip button always visible
            VStack {
                HStack {
                    Spacer()
                    Button {
                        onComplete()
                    } label: {
                        Text("Skip")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                }
                .padding(.top, 8)
                .padding(.trailing, 8)
                Spacer()
            }
            .zIndex(1)

            switch step {
            case 1:
                welcomeStep
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case 2:
                drillStep
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case 3:
                celebrationStep
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity
                    ))
            default:
                EmptyView()
            }
        }
        .celebration(isPresented: $showCelebration)
    }

    // MARK: - Step 1: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "soccerball")
                .font(.system(size: 80))
                .foregroundStyle(Color.dsAccentOrange)
                .scaleEffect(1.0)

            VStack(spacing: 12) {
                Text("Welcome to PitchDreams!")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                Text("Let's do your first drill.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                withAnimation(.spring()) {
                    step = 2
                }
            } label: {
                Text("Let's Go!")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DSGradient.orangeAccent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }

    // MARK: - Step 2: Ball Taps Drill

    private var drillStep: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) {
                Text("Ball Taps")
                    .font(.title2.bold())

                Text("Tap for each touch. Try to get \(tapTarget)!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Counter
            ZStack {
                Circle()
                    .stroke(Color.dsAccentOrange.opacity(0.2), lineWidth: 8)
                    .frame(width: 160, height: 160)

                Circle()
                    .trim(from: 0, to: min(1.0, CGFloat(tapCount) / CGFloat(tapTarget)))
                    .stroke(Color.dsAccentOrange, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.dsSnappy, value: tapCount)

                VStack(spacing: 4) {
                    Text("\(tapCount)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                    Text("taps")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // TAP button
            Button {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                    tapCount += 1
                    buttonScale = 1.3
                }
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6).delay(0.1)) {
                    buttonScale = 1.0
                }

                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()

                if tapCount >= tapTarget {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.spring()) {
                            step = 3
                        }
                        showCelebration = true
                        saveSession()
                    }
                }
            } label: {
                Text("TAP")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .frame(width: 140, height: 140)
                    .background(DSGradient.orangeAccent)
                    .foregroundStyle(.white)
                    .clipShape(Circle())
                    .shadow(color: Color.dsAccentOrange.opacity(0.4), radius: 12, y: 6)
            }
            .scaleEffect(buttonScale)

            Spacer()

            if tapCount > 0 && tapCount < tapTarget {
                Text("\(tapTarget - tapCount) more to go!")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 32)
            }
        }
    }

    // MARK: - Step 3: Celebration

    private var celebrationStep: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "trophy.fill")
                .font(.system(size: 64))
                .foregroundStyle(.yellow)
                .scaleEffect(1.0)

            VStack(spacing: 12) {
                Text("You did it!")
                    .font(.largeTitle.bold())

                Text("\(tapCount) ball taps!")
                    .font(.title2)
                    .foregroundStyle(Color.dsAccentOrange)
            }

            Spacer()

            Button {
                onComplete()
            } label: {
                HStack {
                    Image(systemName: "figure.run")
                    Text("Start Training")
                }
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding()
                .background(DSGradient.orangeAccent)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
            .disabled(isSaving)
        }
    }

    // MARK: - Save Session

    private func saveSession() {
        isSaving = true
        Task {
            do {
                let body = CreateSessionBody(
                    activityType: "SELF_TRAINING",
                    effortLevel: 5,
                    mood: "EXCITED",
                    duration: 2,
                    win: "First session completed!",
                    focus: nil
                )
                let _: SessionSaveResult = try await apiClient.request(
                    APIRouter.createSession(childId: childId, body: body)
                )
            } catch {
                print("Failed to save first session: \(error)")
            }
            isSaving = false
        }
    }
}

#Preview {
    FirstSessionGuideView(childId: "preview-child") { }
}
