import SwiftUI

/// The "you're ready" screen — renders the player's evidence as short
/// narrative proof lines. Surfaced from a card on Home; designed to be read
/// in under a minute before a match or a hard session.
struct EvidenceBankView: View {
    @StateObject private var viewModel: ConfidenceViewModel
    @Environment(\.dismiss) private var dismiss

    init(childId: String) {
        _viewModel = StateObject(wrappedValue: ConfidenceViewModel(childId: childId))
    }

    var body: some View {
        ZStack {
            Color.dsBackground.ignoresSafeArea()

            RadialGradient(
                colors: [Color.dsTertiary.opacity(0.08), .clear],
                center: .init(x: 0.5, y: 0.1),
                startRadius: 20,
                endRadius: 320
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.xl) {
                    header

                    if viewModel.isLoading {
                        VStack(spacing: 14) {
                            SkeletonCard()
                            SkeletonCard()
                            SkeletonCard()
                        }
                        .padding(.horizontal, Spacing.xl)
                    } else {
                        VStack(spacing: 14) {
                            ForEach(viewModel.snapshot.evidenceLines) { line in
                                evidenceRow(line)
                            }
                        }
                        .padding(.horizontal, Spacing.xl)

                        closer
                    }

                    Spacer(minLength: 24)

                    Button {
                        dismiss()
                    } label: {
                        Text("GO SHOW THEM")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .tracking(2)
                            .foregroundStyle(Color.dsCTALabel)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(DSGradient.primaryCTA)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                            .dsPrimaryShadow()
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.bottom, 24)
                }
                .padding(.top, Spacing.xl)
            }
        }
        .task { await viewModel.load() }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 40))
                .foregroundStyle(Color.dsTertiary)
                .shadow(color: Color.dsTertiary.opacity(0.4), radius: 12)

            Text("THE PROOF")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(3)
                .foregroundStyle(Color.dsTertiary)

            Text("You've already done\nthe hard part.")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.dsOnSurface)
                .multilineTextAlignment(.center)

            Text("This isn't hype. It's your own record.")
                .font(.system(size: 13))
                .foregroundStyle(Color.dsOnSurfaceVariant)
        }
        .padding(.horizontal, Spacing.xl)
    }

    private func evidenceRow(_ line: EvidenceLine) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: line.icon)
                .font(.system(size: 18))
                .foregroundStyle(Color.dsTertiary)
                .frame(width: 28)

            Text(line.text)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.dsOnSurface)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Spacing.lg)
        .background(Color.dsSurfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .ghostBorder()
    }

    @ViewBuilder
    private var closer: some View {
        if !viewModel.snapshot.evidenceLines.isEmpty {
            Text("Nobody can take any of that away from you.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.dsOnSurfaceVariant)
                .padding(.top, 4)
        }
    }
}

#Preview {
    EvidenceBankView(childId: "preview")
}
