import Foundation
import Combine

/// Presentation layer for the paywall. Converts the raw `SubscriptionProduct`
/// list from StoreKit into UI-ready groupings (monthly vs yearly, founders
/// vs standard, family vs solo) and drives the purchase flow.
@MainActor
final class PaywallViewModel: ObservableObject {
    @Published var selectedProduct: SubscriptionProduct?
    @Published private(set) var monthlyOptions: [SubscriptionProduct] = []
    @Published private(set) var yearlyOptions: [SubscriptionProduct] = []
    @Published private(set) var showFoundersBadge: Bool = false
    @Published private(set) var purchaseInFlight: Bool = false
    @Published private(set) var lastError: String?

    /// Entry-point context that triggered the paywall. Drives copy and
    /// which features get top billing in the pitch.
    let context: PaywallContext

    private let manager: SubscriptionManager
    private let entitlementStore: EntitlementStore
    private var cancellables: Set<AnyCancellable> = []

    init(
        manager: SubscriptionManager,
        entitlementStore: EntitlementStore,
        context: PaywallContext
    ) {
        self.manager = manager
        self.entitlementStore = entitlementStore
        self.context = context

        manager.$products
            .receive(on: DispatchQueue.main)
            .sink { [weak self] products in
                self?.partition(products)
            }
            .store(in: &cancellables)

        manager.$purchaseInFlight
            .receive(on: DispatchQueue.main)
            .assign(to: &$purchaseInFlight)

        manager.$lastError
            .receive(on: DispatchQueue.main)
            .assign(to: &$lastError)
    }

    func onAppear() async {
        if manager.products.isEmpty {
            await manager.loadProducts()
        }
    }

    func purchaseSelected() async -> Bool {
        guard let product = selectedProduct else { return false }
        return await manager.purchase(product)
    }

    func restorePurchases() async {
        await manager.restorePurchases()
    }

    // MARK: - Partitioning

    private func partition(_ products: [SubscriptionProduct]) {
        // Founders products are only shown to users still inside the founders
        // window. Track-D open question #2 answers "N" — until then we expose
        // them unconditionally so you can validate the purchase flow; wire
        // this to a `foundersAvailable` check once the backend reports it.
        let showFounders = !entitlementStore.foundersCohort || Self.isFoundersAvailable
        showFoundersBadge = showFounders

        let result = Self.partitioned(products: products, showFounders: showFounders)
        monthlyOptions = result.monthly
        yearlyOptions = result.yearly
        if selectedProduct == nil {
            selectedProduct = result.defaultSelection
        }
    }

    /// Pure partitioning logic — split out as a static for unit testing.
    /// Given a product catalog and a founders visibility decision, returns
    /// the monthly / yearly groupings plus the preselected product (yearly
    /// premium if available, else any yearly, else any monthly, else nil).
    ///
    /// Marked `nonisolated` so tests (and anything else off the main actor)
    /// can call it without an actor hop. Pure function — no shared state.
    nonisolated static func partitioned(
        products: [SubscriptionProduct],
        showFounders: Bool
    ) -> (monthly: [SubscriptionProduct], yearly: [SubscriptionProduct], defaultSelection: SubscriptionProduct?) {
        let visible = showFounders ? products : products.filter { $0.tier != .founders }
        let monthly = visible.filter { $0.period == .monthly }
        let yearly = visible.filter { $0.period == .yearly }
        let defaultSelection = yearly.first { $0.tier == .premiumYearly }
            ?? yearly.first
            ?? monthly.first
        return (monthly: monthly, yearly: yearly, defaultSelection: defaultSelection)
    }

    /// Placeholder until the backend exposes the founders-remaining count.
    /// When wired, this becomes a server check ("has the founders bucket
    /// been exhausted?") to prevent giving founders pricing past the cap.
    nonisolated static let isFoundersAvailable: Bool = true
}

/// Where the paywall was surfaced from. Used to pick headline copy and
/// decide which features to lead with. Model 1 principle: NEVER paywall the
/// kid during training. All contexts here are parent-facing.
enum PaywallContext: String, Equatable {
    /// Triggered after the child hits a 7-day streak. Parent sees the
    /// celebration in their dashboard and is pitched on seeing the full
    /// development picture.
    case streakMilestone

    /// Parent's first visit to the parent dashboard after signup.
    case parentDashboard

    /// Parent tries to view training history beyond the last 30 days.
    case historyHorizon

    /// Parent taps into a locked analytics chart.
    case advancedAnalytics

    /// Parent tries to open the Development Profile PDF export.
    case developmentReport

    /// Parent tries to add a second child to the account (family tier).
    case addSecondChild

    /// Surfaced from Settings as a browse-the-tiers view.
    case settingsBrowse

    /// Parent opens the "advanced drills" footer from the child's space-
    /// selection screen. Framed as expanding the kid's development path —
    /// kid never sees the paywall itself.
    case advancedDrills
}
