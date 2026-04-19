import SwiftUI

struct SessionCompleteView: View {
    @ObservedObject var viewModel: ActiveTrainingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            Color.dsBackground
                .ignoresSafeArea()

            // Atmospheric glow
            RadialGradient(
                colors: [
                    Color.dsSecondary.opacity(0.18),
                    Color.dsSecondary.opacity(0.05),
                    Color.clear
                ],
                center: .center,
                startRadius: 10,
                endRadius: 300
            )
            .ignoresSafeArea()

            VStack(spacing: Spacing.xxl) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.dsSecondary.opacity(0.1))
                        .frame(width: 120, height: 120)
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(Color.dsSecondary)
                        .scaleEffect(viewModel.sessionSaved ? 1.0 : 0.5)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: viewModel.sessionSaved)
                }
                .dsSecondaryShadow()

                VStack(spacing: 8) {
                    Text("SESSION COMPLETE")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .tracking(3)
                        .foregroundStyle(Color.dsSecondary)

                    Text("Great work out there!")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                }

                // XP Earned
                if viewModel.xpEarned > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.fill")
                            .foregroundStyle(Color.dsAccentOrange)
                        Text("+\(viewModel.xpEarned) XP")
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.dsAccentOrange)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.dsAccentOrange.opacity(0.15))
                    .clipShape(Capsule())
                }

                // Summary card
                VStack(spacing: 0) {
                    summaryRow(icon: "clock.fill", label: "Duration", value: "\(viewModel.sessionDurationMinutes) min", color: .dsSecondary)
                    Divider().background(Color.dsSurfaceContainerHighest)
                    summaryRow(icon: "figure.run", label: "Drills", value: "\(viewModel.totalDrills)", color: .dsAccentOrange)
                    Divider().background(Color.dsSurfaceContainerHighest)
                    summaryRow(icon: "flame.fill", label: "Effort (RPE)", value: "\(viewModel.reflectionRPE) / 10", color: .dsTertiaryContainer)
                }
                .padding(Spacing.lg)
                .background(Color.dsSurfaceContainer)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                .ghostBorder()
                .padding(.horizontal, Spacing.xl)

                // Signature move progress credit — silent ambient reinforcement
                // from TrainingMoveLink mapping, shown as chip pills so the
                // kid sees the connection between today's drills and their moves.
                if !viewModel.creditedMoveNames.isEmpty {
                    signatureMoveCredit
                        .padding(.horizontal, Spacing.xl)
                }

                Spacer()

                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "house.fill")
                        Text("BACK TO HOME")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .tracking(2)
                    }
                    .foregroundStyle(Color.dsCTALabel)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(DSGradient.primaryCTA)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                    .dsPrimaryShadow()
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, 32)
            }
        }
        .celebration(isPresented: $showConfetti)
        .onAppear {
            if viewModel.sessionSaved {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showConfetti = true
                }
            }
        }
        .onChange(of: viewModel.sessionSaved) { saved in
            if saved {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showConfetti = true
                }
            }
        }
    }

    private var signatureMoveCredit: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "scissors")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(Color.dsTertiaryContainer)
                Text("MOVE PROGRESS")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color.dsTertiaryContainer)
            }
            Text("This session pushed you forward on:")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.dsOnSurfaceVariant)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(viewModel.creditedMoveNames, id: \.self) { name in
                        Text(name)
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .tracking(1)
                            .foregroundStyle(Color.dsTertiaryContainer)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.dsTertiaryContainer.opacity(0.18))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.dsTertiaryContainer.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(Color.dsTertiaryContainer.opacity(0.3), lineWidth: 1)
        )
    }

    private func summaryRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(label.uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(1)
                .foregroundStyle(Color.dsOnSurfaceVariant)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color.dsOnSurface)
        }
        .padding(.vertical, 12)
    }
}
