import SwiftUI

struct AppRouter: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        Group {
            switch authManager.state {
            case .loading:
                LaunchScreenView()
            case .unauthenticated:
                LoginChoiceView()
            case .authenticated(let user):
                if user.isParent {
                    ParentNavigation()
                } else if let childId = user.effectiveChildId {
                    ChildTabNavigation(childId: childId)
                } else {
                    LoginChoiceView()
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.state)
    }
}

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            Color.hudBackground.ignoresSafeArea()
            VStack(spacing: 16) {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                Text("PitchDreams")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                ProgressView()
                    .tint(.hudCyan)
            }
        }
    }
}
