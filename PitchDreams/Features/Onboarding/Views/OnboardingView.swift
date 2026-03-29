import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel: OnboardingViewModel
    @EnvironmentObject var authManager: AuthManager

    init(authManager: AuthManager) {
        _viewModel = StateObject(wrappedValue: OnboardingViewModel(authManager: authManager))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { index in
                    Capsule()
                        .fill(index <= viewModel.step ? Color.accentColor : Color(.systemGray4))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)

            // Step title
            Text(stepTitle)
                .font(.title2.bold())
                .padding(.top, 16)
                .padding(.bottom, 4)

            Text(stepSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            // Content
            TabView(selection: $viewModel.step) {
                SignupStepView(viewModel: viewModel)
                    .tag(0)
                ChildProfileStepView(viewModel: viewModel)
                    .tag(1)
                PermissionsStepView(viewModel: viewModel)
                    .tag(2)
                PinSetupStepView(viewModel: viewModel)
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: viewModel.step)

            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
            }
        }
        .loadingOverlay(viewModel.isLoading)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if viewModel.step > 0 {
                    Button("Back") {
                        viewModel.previousStep()
                    }
                }
            }
        }
    }

    private var stepTitle: String {
        switch viewModel.step {
        case 0: return "Create Account"
        case 1: return "Player Profile"
        case 2: return "Permissions"
        case 3: return "Set a PIN"
        default: return ""
        }
    }

    private var stepSubtitle: String {
        switch viewModel.step {
        case 0: return "Sign up as a parent to get started."
        case 1: return "Tell us about your young player."
        case 2: return "Configure content and training settings."
        case 3: return "Create a PIN for your child to log in."
        default: return ""
        }
    }
}
