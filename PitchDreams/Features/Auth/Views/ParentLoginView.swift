import SwiftUI

struct ParentLoginView: View {
    @ObservedObject var viewModel: ParentLoginViewModel
    @FocusState private var focusedField: Field?

    enum Field { case email, password }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Text("Parent Login")
                        .font(.title.bold())
                        .padding(.top, 32)

                    VStack(spacing: 16) {
                        TextField("Email", text: $viewModel.email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .focused($focusedField, equals: .email)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)

                        SecureField("Password", text: $viewModel.password)
                            .textContentType(.password)
                            .focused($focusedField, equals: .password)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.callout)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        Task { await viewModel.login() }
                    } label: {
                        Text("Log In")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.isValid ? Color.accentColor : Color.gray.opacity(0.3))
                            .foregroundColor(.white)
                            .font(.headline)
                            .cornerRadius(12)
                    }
                    .disabled(!viewModel.isValid || viewModel.isLoading)

                    NavigationLink {
                        ForgotPasswordView()
                    } label: {
                        Text("Forgot password?")
                            .font(.callout)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .loadingOverlay(viewModel.isLoading)
        .navigationBarTitleDisplayMode(.inline)
    }
}
