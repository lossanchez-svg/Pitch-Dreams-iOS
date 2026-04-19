import SwiftUI

/// 5-minute guided stretching routine with 5 light-movement steps, each 60s.
/// Completion records a "recovery" quick-session on the backend (keeps the
/// streak alive) and awards a reduced 20 XP locally.
struct StretchingRoutineView: View {
    let childId: String

    @StateObject private var viewModel: StretchingRoutineViewModel
    @Environment(\.dismiss) private var dismiss

    init(childId: String) {
        self.childId = childId
        _viewModel = StateObject(wrappedValue: StretchingRoutineViewModel(childId: childId))
    }

    var body: some View {
        ZStack {
            Color.dsBackground.ignoresSafeArea()

            switch viewModel.phase {
            case .intro:
                introContent
            case .running(let step):
                stepContent(step)
            case .complete:
                completeContent
            }
        }
        .navigationTitle("Rest Day")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.dsBackground, for: .navigationBar)
    }

    // MARK: - Intro

    private var introContent: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            Image(systemName: "leaf.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color(hex: "#8B5CF6"))

            VStack(spacing: 8) {
                Text("5-Minute Reset")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.dsOnSurface)
                Text("Five light moves, one minute each. Go slow. Breathe deep. No intensity today — just movement.")
                    .font(.system(size: 14))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.dsOnSurfaceVariant)
                    .padding(.horizontal)
            }

            Spacer()

            Button {
                viewModel.start()
            } label: {
                HStack(spacing: 8) {
                    Text("BEGIN")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .tracking(2)
                    Image(systemName: "play.fill")
                }
                .foregroundStyle(Color.dsCTALabel)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(DSGradient.primaryCTA)
                .clipShape(Capsule())
                .dsPrimaryShadow()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Running

    private func stepContent(_ step: StretchStep) -> some View {
        VStack(spacing: Spacing.xl) {
            // Progress across steps
            HStack(spacing: 6) {
                ForEach(0..<StretchStep.all.count, id: \.self) { i in
                    Capsule()
                        .fill(i <= step.index ? Color.dsSecondary : Color.dsSurfaceContainerHighest)
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, Spacing.md)

            Spacer()

            Image(systemName: step.symbol)
                .font(.system(size: 120))
                .foregroundStyle(Color(hex: "#8B5CF6"))
                .symbolRenderingMode(.hierarchical)
                .frame(width: 220, height: 220)

            VStack(spacing: 8) {
                Text(step.title)
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.dsOnSurface)
                Text(step.description)
                    .font(.system(size: 14))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.dsOnSurfaceVariant)
                    .padding(.horizontal, 32)
            }

            // Timer
            VStack(spacing: 4) {
                Text("\(viewModel.secondsRemaining)")
                    .font(.system(size: 56, weight: .heavy, design: .rounded).monospacedDigit())
                    .foregroundStyle(Color.dsOnSurface)
                    .contentTransition(.numericText())
                Text("SECONDS")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(Color.dsOnSurfaceVariant)
            }

            Spacer()

            Button {
                viewModel.skipToNext()
            } label: {
                Text("SKIP")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(Color.dsOnSurfaceVariant)
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Complete

    private var completeContent: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 72))
                .foregroundStyle(Color.dsSecondary)

            Text("Done.")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.dsOnSurface)

            Text("That was smart. Streak alive, body reset.\n+20 XP earned.")
                .font(.system(size: 15))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.dsOnSurfaceVariant)
                .padding(.horizontal)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("BACK HOME")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color.dsCTALabel)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(DSGradient.primaryCTA)
                    .clipShape(Capsule())
                    .dsPrimaryShadow()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Steps

struct StretchStep: Equatable {
    let index: Int
    let title: String
    let description: String
    let symbol: String
    let seconds: Int

    static let all: [StretchStep] = [
        StretchStep(
            index: 0,
            title: "Calf Reach",
            description: "Stand tall. Step one foot back, heel down. Lean forward into the front foot. 30s each side.",
            symbol: "figure.walk",
            seconds: 60
        ),
        StretchStep(
            index: 1,
            title: "Hip Opener",
            description: "Seated butterfly: soles of feet together, knees fall open. Hinge forward slowly. Breathe.",
            symbol: "figure.cooldown",
            seconds: 60
        ),
        StretchStep(
            index: 2,
            title: "Quad Stretch",
            description: "Stand on one leg, grab the opposite foot behind you. Knees close. 30s each side.",
            symbol: "figure.flexibility",
            seconds: 60
        ),
        StretchStep(
            index: 3,
            title: "Light Twist",
            description: "Sit tall, one leg out. Rotate gently toward the extended leg. Controlled breathing.",
            symbol: "figure.yoga",
            seconds: 60
        ),
        StretchStep(
            index: 4,
            title: "Forward Fold",
            description: "Stand, feet hip-width. Hinge from the hips, let your head hang heavy. No bouncing.",
            symbol: "figure.mind.and.body",
            seconds: 60
        ),
    ]
}

// MARK: - ViewModel

@MainActor
final class StretchingRoutineViewModel: ObservableObject {
    enum Phase: Equatable {
        case intro
        case running(StretchStep)
        case complete
    }

    @Published var phase: Phase = .intro
    @Published var secondsRemaining: Int = 0

    let childId: String
    private let apiClient: APIClientProtocol
    private let xpStore: XPStore
    private var timer: Timer?

    init(
        childId: String,
        apiClient: APIClientProtocol = APIClient(),
        xpStore: XPStore = XPStore()
    ) {
        self.childId = childId
        self.apiClient = apiClient
        self.xpStore = xpStore
    }

    deinit {
        timer?.invalidate()
    }

    func start() {
        guard let first = StretchStep.all.first else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        phase = .running(first)
        secondsRemaining = first.seconds
        scheduleTimer()
    }

    func skipToNext() {
        timer?.invalidate()
        guard case .running(let current) = phase else { return }
        advanceAfter(current)
    }

    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func tick() {
        guard case .running(let step) = phase else { return }
        secondsRemaining -= 1
        if secondsRemaining <= 0 {
            advanceAfter(step)
        }
    }

    private func advanceAfter(_ step: StretchStep) {
        let nextIndex = step.index + 1
        if nextIndex < StretchStep.all.count {
            let next = StretchStep.all[nextIndex]
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            phase = .running(next)
            secondsRemaining = next.seconds
            scheduleTimer()
        } else {
            timer?.invalidate()
            timer = nil
            Task { await completeRoutine() }
        }
    }

    private func completeRoutine() async {
        // Log a recovery quick session so the streak stays alive server-side.
        // Uses "recovery" as the activity type so it doesn't distort training stats.
        let body = QuickSessionBody(type: "recovery", duration: 5, effort: 1)
        do {
            let _: SessionSaveResult = try await apiClient.request(
                APIRouter.createQuickSession(childId: childId, body: body)
            )
        } catch APIError.network {
            await SessionSyncQueue.shared.enqueueQuickSession(childId: childId, body: body)
        } catch {
            // Non-fatal — local XP still awarded below so the kid feels credited.
            Log.api.error("Recovery session log failed for child \(self.childId): \(error)")
        }

        // Reduced XP award (20) so rest feels valued but doesn't out-earn real training.
        _ = await xpStore.addXP(20, childId: childId)
        await xpStore.recordXPEntry(
            XPEntry(amount: 20, source: "rest_day", date: Date()),
            childId: childId
        )

        MissionsViewModel.shared.recordEvent(.sessionLogged, childId: childId)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        phase = .complete
    }
}

#Preview {
    NavigationStack {
        StretchingRoutineView(childId: "preview")
    }
}
