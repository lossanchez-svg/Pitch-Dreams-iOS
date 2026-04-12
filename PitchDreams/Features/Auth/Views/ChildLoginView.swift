import SwiftUI

struct ChildLoginView: View {
    @ObservedObject var viewModel: ChildLoginViewModel
    @FocusState private var focusedField: Field?

    enum Field { case email, nickname, pin }

    var body: some View {
        ZStack {
            Color.dsBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.xl) {
                    ZStack {
                        Circle()
                            .fill(Color.dsSecondary.opacity(0.1))
                            .frame(width: 100, height: 100)
                        Image(systemName: "figure.soccer")
                            .font(.system(size: 42))
                            .foregroundStyle(Color.dsSecondary)
                    }
                    .dsSecondaryShadow()
                    .padding(.top, 32)

                    VStack(spacing: 4) {
                        Text("PLAYER LOGIN")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .tracking(3)
                            .foregroundStyle(Color.dsSecondary)
                        Text("Welcome back!")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.dsOnSurface)
                    }

                    VStack(spacing: Spacing.lg) {
                        loginField(
                            placeholder: "Parent's email",
                            text: $viewModel.parentEmail,
                            icon: "envelope.fill",
                            contentType: .emailAddress,
                            keyboard: .emailAddress,
                            field: .email,
                            nextField: .nickname
                        )

                        loginField(
                            placeholder: "Your nickname",
                            text: $viewModel.nickname,
                            icon: "person.fill",
                            field: .nickname,
                            nextField: .pin
                        )

                        // PIN field
                        HStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.dsOnSurfaceVariant)
                                .frame(width: 20)
                            SecureField("PIN (4-6 digits)", text: $viewModel.pin)
                                .keyboardType(.numberPad)
                                .focused($focusedField, equals: .pin)
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
                        focusedField = nil
                        Task { await viewModel.login() }
                    } label: {
                        HStack(spacing: 8) {
                            if viewModel.isLoading {
                                ProgressView().tint(Color.dsCTALabel)
                            } else {
                                Text("LET'S GO!")
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
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.dsBackground, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
                    .fontWeight(.semibold)
            }
        }
    }

    private func loginField(
        placeholder: String,
        text: Binding<String>,
        icon: String,
        contentType: UITextContentType? = nil,
        keyboard: UIKeyboardType = .default,
        field: Field,
        nextField: Field? = nil
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color.dsOnSurfaceVariant)
                .frame(width: 20)
            TextField(placeholder, text: text)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($focusedField, equals: field)
                .submitLabel(nextField != nil ? .next : .done)
                .onSubmit {
                    if let next = nextField { focusedField = next }
                }
                .foregroundStyle(Color.dsOnSurface)
        }
        .padding(Spacing.lg)
        .background(Color.dsSurfaceContainerHighest)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
    }
}
