import SwiftUI

struct ParentDashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var children: [ChildSummary] = []
    @State private var isLoading = true
    @State private var errorText: String?

    private let apiClient: APIClientProtocol = APIClient()

    var body: some View {
        List {
            Section {
                if isLoading {
                    ForEach(0..<3, id: \.self) { _ in
                        SkeletonChildRow()
                    }
                    .listRowBackground(Color.clear)
                } else if let errorText {
                    Text("Error: \(errorText)")
                        .foregroundStyle(.red)
                        .font(.caption)
                        .padding(.vertical, 24)
                } else if children.isEmpty {
                    Text("No children added yet.\nAdd a child at pitchdreams.soccer")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                } else {
                    ForEach(children) { child in
                        NavigationLink(value: child) {
                            HStack(spacing: 14) {
                                Image(systemName: "figure.soccer")
                                    .font(.title2)
                                    .foregroundStyle(.cyan)
                                    .frame(width: 40, height: 40)
                                    .background(.cyan.opacity(0.12))
                                    .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(child.nickname)
                                        .font(.headline)
                                    Text("Age \(child.age)\(child.position.map { " \u{2022} \($0)" } ?? "")")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            } header: {
                Text("Your Children")
            }
        }
        .navigationTitle("Dashboard")
        .navigationDestination(for: ChildSummary.self) { child in
            ChildDetailView(child: child)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    authManager.logout()
                } label: {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .refreshable {
            await loadChildren()
        }
        .task {
            await loadChildren()
        }
    }

    private func loadChildren() async {
        isLoading = true
        errorText = nil
        do {
            children = try await apiClient.request(APIRouter.listChildren)
        } catch {
            errorText = "\(error)"
            print("Failed to load children: \(error)")
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
