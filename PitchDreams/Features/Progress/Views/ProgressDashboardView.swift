import SwiftUI

struct ProgressDashboardView: View {
    let childId: String

    var body: some View {
        ZStack {
            Color.hudBackground
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.cyan)

                Text("Progress Dashboard")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Coming Soon")
                    .font(.headline)
                    .foregroundColor(.cyan)

                Text("Visualize your growth and achievements.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension Color {
    static let hudBackground = Color(red: 0.05, green: 0.05, blue: 0.12)
}

#Preview {
    NavigationStack {
        ProgressDashboardView(childId: "preview-child")
    }
}
