import SwiftUI

struct SessionCompleteView: View {
    @ObservedObject var viewModel: ActiveTrainingViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green)
                .scaleEffect(viewModel.sessionSaved ? 1.0 : 0.5)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: viewModel.sessionSaved)

            Text("Session Complete!")
                .font(.largeTitle.bold())

            Text("Great work out there.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Summary card
            VStack(spacing: 12) {
                summaryRow(icon: "clock.fill", label: "Duration", value: "\(viewModel.sessionDurationMinutes) min")
                Divider()
                summaryRow(icon: "figure.run", label: "Drills", value: "\(viewModel.totalDrills)")
                Divider()
                summaryRow(icon: "flame.fill", label: "Effort (RPE)", value: "\(viewModel.reflectionRPE) / 10")
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)

            Spacer()

            Button {
                dismiss()
            } label: {
                Label("Back to Home", systemImage: "house.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.orange.gradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
    }

    private func summaryRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.orange)
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
    }
}
