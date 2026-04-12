import SwiftUI

struct SignupStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @FocusState private var focusedField: Field?

    enum Field { case email, password, confirmPassword }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 14) {
                    TextField("Email", text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($focusedField, equals: .email)
                        .padding()
                        .background(Color.dsSurfaceContainerHighest)
                        .cornerRadius(10)

                    SecureField("Password (8+ characters)", text: $viewModel.password)
                        .textContentType(.newPassword)
                        .focused($focusedField, equals: .password)
                        .padding()
                        .background(Color.dsSurfaceContainerHighest)
                        .cornerRadius(10)

                    SecureField("Confirm Password", text: $viewModel.confirmPassword)
                        .textContentType(.newPassword)
                        .focused($focusedField, equals: .confirmPassword)
                        .padding()
                        .background(Color.dsSurfaceContainerHighest)
                        .cornerRadius(10)

                    if !viewModel.confirmPassword.isEmpty && viewModel.password != viewModel.confirmPassword {
                        Label("Passwords do not match", systemImage: "exclamationmark.circle")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Toggle(isOn: $viewModel.agreedToTerms) {
                    Text("I agree to the [Terms of Service](https://pitchdreams.soccer/terms) & [Privacy Policy](https://pitchdreams.soccer/privacy)")
                        .font(.callout)
                }
                .toggleStyle(.checkbox)

                Button {
                    Task { await viewModel.signup() }
                } label: {
                    Text("Create Account")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isSignupValid ? Color.dsSecondary : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .font(.headline)
                        .cornerRadius(12)
                }
                .disabled(!viewModel.isSignupValid || viewModel.isLoading)

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
    }
}

// MARK: - Checkbox Toggle Style (iOS 16 compatible)

private struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundStyle(configuration.isOn ? Color.dsSecondary : Color.secondary)
                    .imageScale(.large)
                configuration.label
            }
        }
        .buttonStyle(.plain)
    }
}

extension ToggleStyle where Self == CheckboxToggleStyle {
    static var checkbox: CheckboxToggleStyle { CheckboxToggleStyle() }
}
