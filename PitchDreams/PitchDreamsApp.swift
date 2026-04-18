import SwiftUI

@main
struct PitchDreamsApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environmentObject(authManager)
                .environmentObject(networkMonitor)
                .task {
                    networkMonitor.start()
                    authManager.restoreSession()
                    // Try to drain any sessions queued during a prior offline run.
                    await SessionSyncQueue.shared.flush()
                }
                .onChange(of: networkMonitor.reconnectedAt) { newValue in
                    guard newValue != nil else { return }
                    Task { await SessionSyncQueue.shared.flush() }
                }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                Task { await SessionSyncQueue.shared.flush() }
            }
        }
    }
}
