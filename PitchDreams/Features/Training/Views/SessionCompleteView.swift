import SwiftUI

struct SessionCompleteView: View {
    @ObservedObject var viewModel: ActiveTrainingViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.dsBackground
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

                    Text("Great work out there.")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.dsOnSurfaceVariant)
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
                    .foregroundStyle(Color(hex: "#5B1B00"))
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
