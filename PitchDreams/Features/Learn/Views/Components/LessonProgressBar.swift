import SwiftUI

/// Horizontal segmented progress bar with tappable capsule segments.
struct LessonProgressBar: View {
    let totalSteps: Int
    let currentStep: Int
    let trackColor: Color
    var onTapStep: ((Int) -> Void)?

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(fillColor(for: index))
                    .frame(height: 4)
                    .onTapGesture {
                        onTapStep?(index)
                    }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentStep)
    }

    private func fillColor(for index: Int) -> Color {
        if index == currentStep {
            return trackColor
        } else if index < currentStep {
            return trackColor.opacity(0.6)
        } else {
            return trackColor.opacity(0.15)
        }
    }
}
