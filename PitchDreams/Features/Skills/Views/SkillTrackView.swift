import SwiftUI

struct SkillTrackView: View {
    let childId: String

    var body: some View {
        ZStack {
            Color.hudBackground
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "star.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.cyan)

                Text("Skill Tracker")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Coming Soon")
                    .font(.headline)
                    .foregroundColor(.cyan)

                Text("Master skills and track your confidence levels.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .navigationTitle("Skills")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension Color {
    static let hudBackground = Color(red: 0.05, green: 0.05, blue: 0.12)
}

#Preview {
    NavigationStack {
        SkillTrackView(childId: "preview-child")
    }
}
