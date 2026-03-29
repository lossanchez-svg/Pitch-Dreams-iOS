import SwiftUI

struct CelebrationModifier: ViewModifier {
    @Binding var isPresented: Bool
    @State private var showConfetti = false

    func body(content: Content) -> some View {
        content
            .overlay {
                if showConfetti {
                    ConfettiView()
                }
            }
            .onChange(of: isPresented) { newValue in
                guard newValue else { return }
                let generator = UIImpactFeedbackGenerator(style: .heavy)
                generator.impactOccurred()
                withAnimation(.spring()) {
                    showConfetti = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    showConfetti = false
                    isPresented = false
                }
            }
    }
}

extension View {
    func celebration(isPresented: Binding<Bool>) -> some View {
        modifier(CelebrationModifier(isPresented: isPresented))
    }
}
