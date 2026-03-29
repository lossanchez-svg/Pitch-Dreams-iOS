import SwiftUI

struct ChildHomeView: View {
    let childId: String

    var body: some View {
        ZStack {
            Color.hudBackground
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "house.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.cyan)

                Text("Home")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Coming Soon")
                    .font(.headline)
                    .foregroundColor(.cyan)

                Text("Your personalized training hub.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension Color {
    static let hudBackground = Color(red: 0.05, green: 0.05, blue: 0.12)
}

#Preview {
    NavigationStack {
        ChildHomeView(childId: "preview-child")
    }
}
