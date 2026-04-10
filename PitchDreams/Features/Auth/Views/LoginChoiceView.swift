import SwiftUI

struct LoginChoiceView: View {
    @State private var showParentLogin = false
    @State private var showChildLogin = false
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dsBackground.ignoresSafeArea()

                // Atmospheric glows
                RadialGradient(
                    colors: [Color.dsAccentOrange.opacity(0.08), .clear],
                    center: .init(x: 0.3, y: 0.2),
                    startRadius: 10,
                    endRadius: 250
                )
                .ignoresSafeArea()

                RadialGradient(
                    colors: [Color.dsSecondary.opacity(0.05), .clear],
                    center: .init(x: 0.7, y: 0.8),
                    startRadius: 10,
                    endRadius: 200
                )
                .ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    // Logo
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .shadow(color: Color.dsSecondary.opacity(0.2), radius: 20)

                    VStack(spacing: 8) {
                        Text("PITCH DREAMS")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .italic()
                            .tracking(-0.5)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, Color.dsOnSurfaceVariant],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        Text("Train smarter. Play better.")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.dsOnSurfaceVariant)
                    }

                    Spacer()

                    VStack(spacing: 14) {
                        NavigationLink {
                            ParentLoginView(viewModel: ParentLoginViewModel(authManager: authManager))
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 16))
                                Text("I'M A PARENT")
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                                    .tracking(2)
                            }
                            .foregroundStyle(Color(hex: "#5B1B00"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(DSGradient.primaryCTA)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                            .dsPrimaryShadow()
                        }

                        NavigationLink {
                            ChildLoginView(viewModel: ChildLoginViewModel(authManager: authManager))
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "figure.soccer")
                                    .font(.system(size: 16))
                                Text("I'M A PLAYER")
                                    .font(.system(size: 14, weight: .bold))
                                    .tracking(2)
                            }
                            .foregroundStyle(Color.dsSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.dsSurfaceContainer)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                            .overlay(
                                RoundedRectangle(cornerRadius: CornerRadius.lg)
                                    .stroke(Color.dsSecondary.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 32)

                    NavigationLink {
                        OnboardingView(authManager: authManager)
                    } label: {
                        Text("Create Account")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.dsOnSurfaceVariant)
                    }

                    Spacer().frame(height: 48)
                }
            }
        }
    }
}
