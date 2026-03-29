import SwiftUI

struct PinSetupStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @FocusState private var focusedField: Field?

    enum Field { case pin, confirmPin }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.accentColor)

                Text("Set a PIN for \(viewModel.nickname.isEmpty ? "your player" : viewModel.nickname)")
                    .font(.headline)
                    .multilineTextAlignment(.center)

                Text("Your child will use this PIN to log in on their own.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: 14) {
                    SecureField("PIN (4-6 digits)", text: $viewModel.pin)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .focused($focusedField, equals: .pin)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)

                    SecureField("Confirm PIN", text: $viewModel.confirmPin)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .focused($focusedField, equals: .confirmPin)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)

                    if !viewModel.confirmPin.isEmpty && viewModel.pin != viewModel.confirmPin {
                        Label("PINs do not match", systemImage: "exclamationmark.circle")
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    if !viewModel.pin.isEmpty && (viewModel.pin.count < 4 || viewModel.pin.count > 6) {
                        Label("PIN must be 4-6 digits", systemImage: "info.circle")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

                Button {
                    Task { await viewModel.setPin() }
                } label: {
                    Text("Set PIN & Continue")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isPinValid && !viewModel.skipPin ? Color.accentColor : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .font(.headline)
                        .cornerRadius(12)
                }
                .disabled((!viewModel.isPinValid || viewModel.skipPin) && !viewModel.isLoading)

                Button {
                    viewModel.skipPin = true
                    Task { await viewModel.setPin() }
                } label: {
                    Text("Skip for now")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
    }
}
