import SwiftUI

struct ForgotPasswordView: View {
    @StateObject private var viewModel = ForgotPasswordViewModel()
    @FocusState private var emailFocused: Bool

    var body: some View {
        ZStack {
            Color.dsBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.xl) {
                    ZStack {
                        Circle()
                            .fill(Color.dsSecondary.opacity(0.1))
                            .frame(width: 100, height: 100)
                        Image(systemName: "envelope.badge.fill")
                            .font(.system(size: 42))
                            .foregroundStyle(Color.dsSecondary)
                    }
                    .dsSecondaryShadow()
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
        .toolbarBackground(Color.dsBackground, for: .navigationBar)
    }

    // MARK: - Form

    private var formContent: some View {
        VStack(spacing: Spacing.xl) {
            VStack(spacing: 8) {
                Text("Forgot your password?")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.dsOnSurface)

                Text("Enter your email and we'll send you a link to reset your password.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 12) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
                    .frame(width: 20)
                TextField("Email", text: $viewModel.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($emailFocused)
                    .foregroundStyle(Color.dsOnSurface)
            }
            .padding(Spacing.lg)
            .background(Color.dsSurfaceContainerHighest)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))

            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundStyle(Color.dsError)
                    .font(.system(size: 13))
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await viewModel.sendResetLink() }
            } label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView().tint(Color(hex: "#5B1B00"))
                    } else {
                        Text("SEND RESET LINK")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .tracking(2)
                    }
                }
                .foregroundStyle(Color(hex: "#5B1B00"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(viewModel.isValid ? DSGradient.primaryCTA : LinearGradient(colors: [Color.dsSurfaceContainerHighest, Color.dsSurfaceContainerHighest], startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                .dsPrimaryShadow()
            }
            .disabled(!viewModel.isValid || viewModel.isLoading)
            .opacity(viewModel.isValid ? 1 : 0.5)
        }
    }

    // MARK: - Success

    private var successContent: some View {
        VStack(spacing: Spacing.xl) {
            ZStack {
                Circle()
                    .fill(Color.dsSecondary.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.dsSecondary)
            }
            .dsSecondaryShadow()

            VStack(spacing: 8) {
                Text("Check Your Email")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.dsOnSurface)

                Text("We sent a password reset link to \(viewModel.email). Check your inbox and follow the instructions.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
                    .multilineTextAlignment(.center)

                Text("Didn't get the email? Check your spam folder or try again.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.dsOnSurfaceVariant.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }

            Button {
                viewModel.emailSent = false
            } label: {
                Text("Try Again")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.dsSecondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ForgotPasswordView()
    }
}
