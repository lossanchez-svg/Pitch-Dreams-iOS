import SwiftUI

struct ForgotPasswordView: View {
    @StateObject private var viewModel = ForgotPasswordViewModel()
    @FocusState private var emailFocused: Bool

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "envelope.badge.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.accentColor)
                        .padding(.top, 32)

                    if viewModel.emailSent {
                        successContent
                    } else {
                        formContent
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationTitle("Reset Password")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Form

    private var formContent: some View {
        VStack(spacing: 20) {
            Text("Forgot your password?")
                .font(.title2.bold())

            Text("Enter your email and we'll send you a link to reset your password.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            TextField("Email", text: $viewModel.email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($emailFocused)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)

            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.callout)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await viewModel.sendResetLink() }
            } label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Send Reset Link")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.isValid ? Color.accentColor : Color.gray.opacity(0.3))
                .foregroundColor(.white)
                .font(.headline)
                .cornerRadius(12)
            }
            .disabled(!viewModel.isValid || viewModel.isLoading)
        }
    }

    // MARK: - Success

    private var successContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)

            Text("Check Your Email")
                .font(.title2.bold())

            Text("We sent a password reset link to \(viewModel.email). Check your inbox and follow the instructions.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text("Didn't get the email? Check your spam folder or try again.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)

            Button {
                viewModel.emailSent = false
            } label: {
                Text("Try Again")
                    .font(.callout)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ForgotPasswordView()
    }
}
