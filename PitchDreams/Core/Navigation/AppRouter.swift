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
                Image(systemName: "sportscourt.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.hudCyan)
                Text("PitchDreams")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                ProgressView()
                    .tint(.hudCyan)
            }
        }
    }
}
