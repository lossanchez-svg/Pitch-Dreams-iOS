import SwiftUI

struct ParentDashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var entitlementStore: EntitlementStore
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var children: [ChildSummary] = []
    @State private var isLoading = true
    @State private var errorText: String?
    @State private var showAddChild = false

    /// Track-D paywall trigger: show the paywall the first time a parent
    /// lands on this dashboard. @AppStorage persists across launches so we
    /// never re-pitch. Paid users skip the pitch entirely.
    @AppStorage("parentDashboardPaywallSeen") private var parentDashboardPaywallSeen = false
    @State private var showFirstVisitPaywall = false

    private let apiClient: APIClientProtocol = APIClient()

    var body: some View {
        ZStack {
            Color.dsBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Greeting
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hey, \(authManager.currentUser?.name ?? authManager.currentUser?.email?.components(separatedBy: "@").first ?? "Parent")")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.dsOnSurfaceVariant)

                        Text("Family")
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.dsOnSurface)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    // Children list
                    if isLoading {
                        VStack(spacing: 16) {
                            ForEach(0..<2, id: \.self) { _ in
                                SkeletonCard()
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                    } else if let errorText {
                        Text("Error: \(errorText)")
                            .foregroundStyle(Color.dsError)
                            .font(.caption)
                            .padding(24)
                    } else if children.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(Color.dsOnSurfaceVariant)
                            Text("No children added yet")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color.dsOnSurface)
                            Text("Add a child at pitchdreams.soccer")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.dsOnSurfaceVariant)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    } else {
                        VStack(spacing: 20) {
                            ForEach(children) { child in
                                NavigationLink(value: child) {
                                    childCard(child)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                    }

                    // Actions
                    HStack(spacing: 16) {
                        Button {
                            showAddChild = true
                        } label: {
                            actionButton(
                                icon: "plus.circle.fill",
                                label: "Add Child",
                                color: .parentGold
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            ParentControlsView(
                                childId: children.first?.id ?? "",
                                childName: children.first?.nickname ?? ""
                            )
                        } label: {
                            actionButton(
                                icon: "gearshape.fill",
                                label: "Parent Controls",
                                color: .dsSecondary
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)

                    Spacer(minLength: 80)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: ChildSummary.self) { child in
            ChildDetailView(child: child)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    authManager.logout()
                } label: {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                }
            }
        }
        .toolbarBackground(Color.dsBackground, for: .navigationBar)
        .sheet(isPresented: $showAddChild) {
            AddChildView(authManager: authManager) {
                Task { await loadChildren() }
            }
        }
        .sheet(isPresented: $showFirstVisitPaywall) {
            PaywallView(
                manager: subscriptionManager,
                entitlementStore: entitlementStore,
                context: .parentDashboard
            )
        }
        .refreshable {
            await loadChildren()
        }
        .task {
            await loadChildren()
            maybePresentFirstVisitPaywall()
        }
    }

    /// Show the parent-dashboard paywall exactly once per account.
    /// Guard conditions (all must pass):
    /// - Not already seen (sticky @AppStorage flag)
    /// - User is not already paid — paid users don't need the pitch
    /// - User has at least one child — without one there's nothing to pitch
    /// - App is online — the paywall needs StoreKit product data
    ///
    /// Uses a short delay so the dashboard renders first; the parent sees
    /// their kid's progress before the pitch arrives, making the emotional
    /// moment land instead of feeling like a blocker.
    private func maybePresentFirstVisitPaywall() {
        guard !parentDashboardPaywallSeen else { return }
        guard !entitlementStore.isPaid else {
            // Mark seen so we don't pitch paid users later if they ever
            // downgrade to free — they've already been through this moment.
            parentDashboardPaywallSeen = true
            return
        }
        guard !children.isEmpty else { return }

        parentDashboardPaywallSeen = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(800))
            showFirstVisitPaywall = true
        }
    }

    // MARK: - Child Card

    private func childCard(_ child: ChildSummary) -> some View {
        VStack(spacing: 0) {
            // Hero section with avatar
            ZStack(alignment: .topLeading) {
                // Avatar
                childAvatarHero(child: child)
                    .frame(height: 160)
                    .frame(maxWidth: .infinity)
                    .background(Color.dsSurfaceContainerLowest)
                    .clipShape(
                        RoundedRectangle(cornerRadius: CornerRadius.lg)
                    )

                // Nickname badge
                Text(child.nickname)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1)
                    .textCase(.uppercase)
                    .foregroundStyle(Color(hex: "#251A00"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.parentGold)
                    .clipShape(Capsule())
                    .shadow(color: Color.parentGold.opacity(0.3), radius: 8, y: 4)
                    .padding(16)
            }

            // Stats section
            VStack(spacing: 12) {
                // Quick stat pills
                HStack(spacing: 12) {
                    statPill(icon: "flame.fill", label: "Consistent", color: .dsAccentOrange)
                    statPill(icon: "calendar", label: "This Week", color: .dsSecondary)
                }

                // Info
                HStack {
                    Text("Age \(child.age)")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                    if let position = child.position {
                        Text("  \(position)")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.dsOnSurfaceVariant)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                }
            }
            .padding(16)
        }
        .background(Color.dsSurfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xxl))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.xxl)
                .stroke(Color.parentGold.opacity(0.15), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func childAvatarHero(child: ChildSummary) -> some View {
        let assetName = Avatar.assetName(for: child.avatarId, totalXP: 0)
        ZStack {
            // Ambient glow
            RadialGradient(
                colors: [Color.dsSecondary.opacity(0.1), .clear],
                center: .center,
                startRadius: 10,
                endRadius: 100
            )

            if UIImage(named: assetName) != nil {
                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 130)
                    .shadow(color: Color.dsSecondary.opacity(0.2), radius: 12)
            } else {
                Image(systemName: "figure.soccer")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.dsSecondary)
            }
        }
    }

    private func statPill(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.dsOnSurfaceVariant)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.dsSurfaceContainerHigh)
        .clipShape(Capsule())
    }

    // MARK: - Action Buttons

    private func actionButton(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
            Text(label)
                .font(.system(size: 13, weight: .bold))
        }
        .foregroundStyle(color)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.dsSurfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Data

    private func loadChildren() async {
        isLoading = true
        errorText = nil
        do {
            children = try await apiClient.request(APIRouter.listChildren)
        } catch {
            errorText = "\(error)"
            Log.api.error("Failed to load children: \(error)")
        }
        isLoading = false
    }
}

#Preview {
    NavigationStack {
        ParentDashboardView()
            .environmentObject(AuthManager())
    }
}
