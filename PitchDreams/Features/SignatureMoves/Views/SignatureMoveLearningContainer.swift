import SwiftUI

/// Top-level container for the Signature Move learning flow. Switches
/// between the flow screens driven by `viewModel.currentStep`; each screen
/// is self-contained and only talks to the shared viewModel.
struct SignatureMoveLearningContainer: View {
    let move: SignatureMove
    let childId: String
    let childAge: Int?
    let onDismiss: () -> Void

    @StateObject private var viewModel: SignatureMoveLearningViewModel
    @State private var showConfidenceSheet = false

    init(
        move: SignatureMove,
        childId: String,
        childAge: Int? = nil,
        onDismiss: @escaping () -> Void
    ) {
        self.move = move
        self.childId = childId
        self.childAge = childAge
        self.onDismiss = onDismiss
        _viewModel = StateObject(wrappedValue: SignatureMoveLearningViewModel(
            move: move,
            childId: childId,
            childAge: childAge
        ))
    }

    var body: some View {
        ZStack {
            Color.dsBackground.ignoresSafeArea()

            switch viewModel.currentStep {
            case .overview:
                SignatureMoveOverviewView(viewModel: viewModel, onDismiss: onDismiss)
            case .stageIntro(let stage):
                SignatureMoveStageIntroView(viewModel: viewModel, stage: stage)
            case .drillPlayer(let stage, let drillId):
                SignatureMoveDrillPlayerView(viewModel: viewModel, stage: stage, drillId: drillId)
            case .drillComplete(let stage, let drillId):
                SignatureMoveDrillCompleteView(viewModel: viewModel, stage: stage, drillId: drillId)
            case .stageComplete(let stage, let xpAwarded):
                SignatureMoveStageCompleteView(viewModel: viewModel, stage: stage, xpAwarded: xpAwarded, onDismiss: onDismiss)
            case .recordSelf(let stage):
                SignatureMoveRecordSelfView(viewModel: viewModel, stage: stage)
            case .mastered(let xpAwarded):
                SignatureMoveUnlockedView(move: move, xpAwarded: xpAwarded, onDismiss: onDismiss)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: stepKey(viewModel.currentStep))
        .task { await viewModel.load() }
        .sheet(isPresented: Binding(
            get: { viewModel.pendingStageForConfidence != nil },
            set: { if !$0 { viewModel.pendingStageForConfidence = nil } }
        )) {
            if let stage = viewModel.pendingStageForConfidence {
                SignatureMoveConfidenceSheet(
                    stage: stage,
                    stageName: move.stages.first(where: { $0.order == stage })?.name ?? "",
                    onSubmit: { rating in
                        Task { await viewModel.submitConfidence(rating) }
                    }
                )
                .presentationDetents([.height(420)])
            }
        }
    }

    /// Hashable key so SwiftUI animates step transitions even for cases
    /// with associated values.
    private func stepKey(_ step: SignatureMoveLearningViewModel.FlowStep) -> String {
        switch step {
        case .overview:                       return "overview"
        case .stageIntro(let s):              return "stageIntro-\(s)"
        case .drillPlayer(let s, let d):      return "drill-\(s)-\(d)"
        case .drillComplete(let s, let d):    return "drillComplete-\(s)-\(d)"
        case .stageComplete(let s, _):        return "stageComplete-\(s)"
        case .recordSelf(let s):              return "recordSelf-\(s)"
        case .mastered:                       return "mastered"
        }
    }
}

// MARK: - Confidence Sheet

struct SignatureMoveConfidenceSheet: View {
    let stage: Int
    let stageName: String
    let onSubmit: (Int) -> Void

    @State private var rating: Int = 0

    var body: some View {
        ZStack {
            Color.dsBackground.ignoresSafeArea()
            VStack(spacing: Spacing.xl) {
                VStack(spacing: 6) {
                    Text("STAGE \(stage) COMPLETE")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(Color.dsSecondary)
                    Text(stageName)
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.dsOnSurface)
                }
                .padding(.top, 32)

                Text("How confident are you with this stage?")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                HStack(spacing: 14) {
                    ForEach(1...5, id: \.self) { i in
                        Image(systemName: i <= rating ? "star.fill" : "star")
                            .font(.system(size: 32))
                            .foregroundStyle(i <= rating ? Color.dsTertiaryContainer : Color.dsOnSurfaceVariant.opacity(0.5))
                            .onTapGesture {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                rating = i
                            }
                    }
                }

                Text(confidenceLabel)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color.dsTertiaryContainer)
                    .opacity(rating > 0 ? 1 : 0)

                Spacer()

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onSubmit(rating)
                } label: {
                    Text("SUBMIT")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(Color.dsCTALabel)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(rating > 0 ? AnyShapeStyle(DSGradient.primaryCTA) : AnyShapeStyle(Color.gray.opacity(0.3)))
                        .clipShape(Capsule())
                        .dsPrimaryShadow()
                }
                .disabled(rating == 0)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }

    private var confidenceLabel: String {
        switch rating {
        case 1: return "WOBBLY"
        case 2: return "LEARNING"
        case 3: return "OK"
        case 4: return "GOOD"
        case 5: return "LOCKED IN"
        default: return ""
        }
    }
}
