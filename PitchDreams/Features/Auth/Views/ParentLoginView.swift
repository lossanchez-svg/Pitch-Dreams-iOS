import SwiftUI

struct ParentLoginView: View {
    @ObservedObject var viewModel: ParentLoginViewModel
    @FocusState private var focusedField: Field?

    enum Field { case email, password }

    var body: some View {
        ZStack {
            Color.dsBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.xl) {
                    VStack(spacing: 4) {
                        Text("PARENT LOGIN")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .tracking(3)
                            .foregroundStyle(Color.dsPrimaryPeachDim)
                        Text("Welcome back")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.dsOnSurface)
                    }
                    .padding(.top, 32)

                    VStack(spacing: Spacing.lg) {
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
                                .focused($focusedField, equals: .email)
                                .submitLabel(.next)
                                .onSubmit { focusedField = .password }
                                .foregroundStyle(Color.dsOnSurface)
                        }
                        .padding(Spacing.lg)
                        .background(Color.dsSurfaceContainerHighest)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))

                        HStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.dsOnSurfaceVariant)
                                .frame(width: 20)
                            SecureField("Password", text: $viewModel.password)
                                .textContentType(.password)
                                .focused($focusedField, equals: .password)
                                .foregroundStyle(Color.dsOnSurface)
                        }
                        .padding(Spacing.lg)
                        .background(Color.dsSurfaceContainerHighest)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundStyle(Color.dsError)
                            .font(.system(size: 13))
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        Task { await viewModel.login() }
                    } label: {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView().tint(Color.dsCTALabel)
                            } else {
                                Text("LOG IN")
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                                    .tracking(2)
                            }
                        }
                        .foregroundStyle(Color.dsCTALabel)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(viewModel.isValid ? DSGradient.primaryCTA : LinearGradient(colors: [Color.dsSurfaceContainerHighest, Color.dsSurfaceContainerHighest], startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                        .dsPrimaryShadow()
                    }
                    .disabled(!viewModel.isValid || viewModel.isLoading)
                    .opacity(viewModel.isValid ? 1 : 0.5)

                    NavigationLink {
                        ForgotPasswordView()
                    } label: {
                        Text("Forgot password?")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.dsSecondary)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .loadingOverlay(viewModel.isLoading)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.dsBackground, for: .navigationBar)
    }
}
