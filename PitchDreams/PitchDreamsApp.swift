import SwiftUI

@main
struct PitchDreamsApp: App {
    @StateObject private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environmentObject(authManager)
                .task {
                    await authManager.restoreSession()
                }
        }
    }
}
