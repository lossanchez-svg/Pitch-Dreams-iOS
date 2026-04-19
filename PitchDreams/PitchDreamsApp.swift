import SwiftUI

@main
struct PitchDreamsApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var entitlementStore = EntitlementStore()
    @StateObject private var subscriptionManager: SubscriptionManager
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let store = EntitlementStore()
        _entitlementStore = StateObject(wrappedValue: store)
        _subscriptionManager = StateObject(wrappedValue: SubscriptionManager(entitlementStore: store))
    }

    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environmentObject(authManager)
                .environmentObject(networkMonitor)
                .environmentObject(entitlementStore)
                .environmentObject(subscriptionManager)
                .task {
                    networkMonitor.start()
                    authManager.restoreSession()
                    // Try to drain any sessions queued during a prior offline run.
                    await SessionSyncQueue.shared.flush()
                    // Warm StoreKit: fetch product catalog + recompute active
                    // tier from existing transactions so paid users don't see
                    // a free-tier flash before the handshake completes.
                    await subscriptionManager.loadProducts()
                    await subscriptionManager.refreshEntitlements()
                }
                .onChange(of: networkMonitor.reconnectedAt) { newValue in
                    guard newValue != nil else { return }
                    Task { await SessionSyncQueue.shared.flush() }
                }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                Task {
                    await SessionSyncQueue.shared.flush()
                    // Re-check entitlements on foreground in case the user
                    // subscribed / unsubscribed while backgrounded.
                    await subscriptionManager.refreshEntitlements()
                }
            }
        }
    }
}
