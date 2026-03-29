import SwiftUI

struct TrainingSessionView: View {
    let childId: String

    var body: some View {
        ZStack {
            Color.hudBackground
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "figure.run")
                    .font(.system(size: 48))
                    .foregroundColor(.cyan)

                Text("Training Session")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Coming Soon")
                    .font(.headline)
                    .foregroundColor(.cyan)

                Text("Guided drills and training sessions.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .navigationTitle("Training")
        .navigationBarTitleDisplayMode(.inline)
    }
}


#Preview {
    NavigationStack {
        TrainingSessionView(childId: "preview-child")
    }
}
