import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel: OnboardingViewModel
    @EnvironmentObject var authManager: AuthManager

    init(authManager: AuthManager) {
        _viewModel = StateObject(wrappedValue: OnboardingViewModel(authManager: authManager))
    }

    var body: some View {
        ZStack {
            Color.dsBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator (5 steps)
                HStack(spacing: 6) {
                    ForEach(0..<5, id: \.self) { index in
                        Capsule()
                            .fill(index <= viewModel.step ? Color.dsSecondary : Color.dsSurfaceContainerHighest)
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)

                // Step title + subtitle (only for non-avatar steps)
                if viewModel.step != 1 {
                    Text(stepTitle)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.dsOnSurface)
                        .padding(.top, 16)
                        .padding(.bottom, 4)

                    Text(stepSubtitle)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Content — no swipe, step changes only via CTA buttons
                Group {
                    switch viewModel.step {
                    case 0: SignupStepView(viewModel: viewModel)
                    case 1: AvatarSelectionStepView(viewModel: viewModel)
                    case 2: ChildProfileStepView(viewModel: viewModel)
                    case 3: PermissionsStepView(viewModel: viewModel)
                    case 4: PinSetupStepView(viewModel: viewModel)
                    default: EmptyView()
                    }
                }
                .animation(.dsSpring, value: viewModel.step)
                .transition(.slide)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(Color.dsError)
                        .font(.system(size: 13))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)
                }
            }
        }
        .loadingOverlay(viewModel.isLoading)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.dsBackground, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if viewModel.step > 0 {
                    Button {
                        viewModel.previousStep()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                    }
                }
            }
        }
    }

    private var stepTitle: String {
        switch viewModel.step {
        case 0: return "Create Account"
        case 1: return "" // Avatar selection has its own header
        case 2: return "Player Profile"
        case 3: return "Permissions"
        case 4: return "Set a PIN"
        default: return ""
        }
    }

    private var stepSubtitle: String {
        switch viewModel.step {
        case 0: return "Sign up as a parent to get started."
        case 1: return ""
        case 2: return "Tell us about your young player."
        case 3: return "Configure content and training settings."
        case 4: return "Create a PIN for your child to log in."
        default: return ""
        }
    }
}
