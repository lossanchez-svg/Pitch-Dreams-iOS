import SwiftUI

struct LoginChoiceView: View {
    @State private var showParentLogin = false
    @State private var showChildLogin = false
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        NavigationStack {
            ZStack {
                Color.hudBackground.ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)

                    VStack(spacing: 8) {
                        Text("PitchDreams")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                        Text("Train smarter. Play better.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    VStack(spacing: 16) {
                        NavigationLink {
                            ParentLoginView(viewModel: ParentLoginViewModel(authManager: authManager))
                        } label: {
                            Label("I'm a Parent", systemImage: "person.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.hudCyan)
                                .foregroundColor(.black)
                                .font(.headline)
                                .cornerRadius(12)
                        }

                        NavigationLink {
                            ChildLoginView(viewModel: ChildLoginViewModel(authManager: authManager))
                        } label: {
                            Label("I'm a Player", systemImage: "figure.soccer")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.hudCardBackground)
                                .foregroundColor(.hudCyan)
                                .font(.headline)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.hudCyan, lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, 32)

                    Spacer().frame(height: 48)
                }
            }
        }
    }
}
