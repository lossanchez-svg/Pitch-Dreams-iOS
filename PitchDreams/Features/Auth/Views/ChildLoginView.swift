import SwiftUI

struct ChildLoginView: View {
    @ObservedObject var viewModel: ChildLoginViewModel
    @FocusState private var focusedField: Field?

    enum Field { case email, nickname, pin }

    var body: some View {
        ZStack {
            Color.hudBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "figure.soccer")
                        .font(.system(size: 48))
                        .foregroundColor(.hudCyan)
                        .padding(.top, 32)

                    Text("Player Login")
                        .font(.title.bold())
                        .foregroundColor(.white)

                    VStack(spacing: 16) {
                        TextField("Parent's email", text: $viewModel.parentEmail)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .focused($focusedField, equals: .email)
                            .padding()
                            .background(Color.hudCardBackground)
                            .foregroundColor(.white)
                            .cornerRadius(10)

                        TextField("Your nickname", text: $viewModel.nickname)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .nickname)
                            .padding()
                            .background(Color.hudCardBackground)
                            .foregroundColor(.white)
                            .cornerRadius(10)

                        SecureField("PIN (4-6 digits)", text: $viewModel.pin)
                            .keyboardType(.numberPad)
                            .focused($focusedField, equals: .pin)
                            .padding()
                            .font(.title2)
                            .background(Color.hudCardBackground)
                            .foregroundColor(.white)
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
                        Text("Let's Go!")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.isValid ? Color.hudCyan : Color.gray.opacity(0.3))
                            .foregroundColor(.black)
                            .font(.headline.bold())
                            .cornerRadius(12)
                    }
                    .disabled(!viewModel.isValid || viewModel.isLoading)
                }
                .padding(.horizontal, 24)
            }
        }
        .loadingOverlay(viewModel.isLoading)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
