import SwiftUI

struct SignupStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @FocusState private var focusedField: Field?

    enum Field { case email, password, confirmPassword }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Email", text: $viewModel.email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .focused($focusedField, equals: .email)
                            .padding()
                            .background(Color.dsSurfaceContainerHighest)
                            .cornerRadius(10)
                        if let msg = viewModel.emailError {
                            inlineError(msg)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        SecureField("Password (8+ characters)", text: $viewModel.password)
                            .textContentType(.newPassword)
                            .focused($focusedField, equals: .password)
                            .padding()
                            .background(Color.dsSurfaceContainerHighest)
                            .cornerRadius(10)
                        if let msg = viewModel.passwordError {
                            inlineError(msg)
                        } else if !viewModel.password.isEmpty {
                            passwordStrengthMeter(viewModel.passwordStrength)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        SecureField("Confirm Password", text: $viewModel.confirmPassword)
                            .textContentType(.newPassword)
                            .focused($focusedField, equals: .confirmPassword)
                            .padding()
                            .background(Color.dsSurfaceContainerHighest)
                            .cornerRadius(10)
                        if let msg = viewModel.confirmPasswordError {
                            inlineError(msg)
                        }
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

    // MARK: - Inline error / strength components

    private func inlineError(_ msg: String) -> some View {
        Label(msg, systemImage: "exclamationmark.circle")
            .font(.caption)
            .foregroundStyle(Color.dsError)
            .padding(.horizontal, 4)
    }

    private func passwordStrengthMeter(_ score: Int) -> some View {
        let labels = ["Weak", "Weak", "Good", "Strong"]
        let colors: [Color] = [Color.dsError, Color.dsError, Color.dsTertiaryContainer, Color.dsSecondary]
        return HStack(spacing: 6) {
            HStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { i in
                    Capsule()
                        .fill(i < score ? colors[score] : Color.dsSurfaceContainerHighest)
                        .frame(height: 4)
                }
            }
            Text(labels[min(score, labels.count - 1)])
                .font(.caption2.weight(.semibold))
                .foregroundStyle(colors[min(score, colors.count - 1)])
        }
        .padding(.horizontal, 4)
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
