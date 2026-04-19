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
        let showFounders = !entitlementStore.foundersCohort || isFoundersAvailable
        showFoundersBadge = showFounders

        let visible = showFounders ? products : products.filter {
            $0.tier != .foundersMonthly && $0.tier != .foundersYearly
        }

        monthlyOptions = visible.filter { $0.period == .monthly }
        yearlyOptions = visible.filter { $0.period == .yearly }

        // Default selection: yearly premium if available (best value positioning).
        if selectedProduct == nil {
            selectedProduct = yearlyOptions.first { $0.tier == .premiumYearly }
                ?? yearlyOptions.first
                ?? monthlyOptions.first
        }
    }

    /// Placeholder until the backend exposes the founders-remaining count.
    /// When wired, this becomes a server check ("has the founders bucket
    /// been exhausted?") to prevent giving founders pricing past the cap.
    private var isFoundersAvailable: Bool {
        // TODO: replace with server-reported remaining founders slots
        true
    }
}

/// Where the paywall was surfaced from. Used to pick headline copy and
/// decide which features to lead with — per the plan's "never paywall the
/// kid during training, paywall parents in parent contexts" principle.
enum PaywallContext: String, Equatable {
    /// Surfaced after a 7-day streak milestone — the "you're committed" moment.
    case streakMilestone

    /// Surfaced when a parent first opens the dashboard.
    case parentDashboard

    /// Surfaced when a kid tries to pick a locked avatar.
    case avatarPicker

    /// Surfaced when a kid tries to share a weekly recap.
    case weeklyRecapShare

    /// Surfaced from Settings as a browse-the-tiers view.
    case settingsBrowse
}
