import SwiftUI

struct ParentDashboardView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.12)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.cyan)

                    Text("Parent Dashboard")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Coming Soon")
                        .font(.headline)
                        .foregroundColor(.cyan)

                    Text("Manage your children's accounts and monitor their progress.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    // Children list placeholder
                    VStack(spacing: 12) {
                        Text("Your Children")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                            .frame(height: 80)
                            .overlay(
                                Text("No children added yet")
                                    .foregroundColor(.gray)
                            )
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                }
                .padding(.top, 40)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        authManager.logout()
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.cyan)
                    }
                }
            }
        }
    }
}

#Preview {
    ParentDashboardView()
        .environmentObject(AuthManager())
}
