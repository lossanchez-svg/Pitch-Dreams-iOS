import SwiftUI

/// Sheet for parents to set or reset a child's login PIN.
struct PinSetupSheet: View {
    let childId: String
    let childName: String
    @Environment(\.dismiss) private var dismiss

    @State private var pin = ""
    @State private var confirmPin = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var didSave = false

    private let apiClient: APIClientProtocol = APIClient()

    private var isValid: Bool {
        pin.count >= 4 && pin.count <= 6 && pin == confirmPin && pin.allSatisfy(\.isNumber)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dsBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.dsSecondary)
                            .padding(.top, 16)

                        Text("Set PIN for \(childName)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.dsOnSurface)

                        Text("\(childName) will use this PIN to log in independently.")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.dsOnSurfaceVariant)
                            .multilineTextAlignment(.center)

                        VStack(spacing: 14) {
                            SecureField("New PIN (4-6 digits)", text: $pin)
                                .keyboardType(.numberPad)
                                .textContentType(.oneTimeCode)
                                .padding()
                                .foregroundStyle(Color.dsOnSurface)
                                .background(Color.dsSurfaceContainerHighest)
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))

                            SecureField("Confirm PIN", text: $confirmPin)
                                .keyboardType(.numberPad)
                                .textContentType(.oneTimeCode)
                                .padding()
                                .foregroundStyle(Color.dsOnSurface)
                                .background(Color.dsSurfaceContainerHighest)
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))

                            if !confirmPin.isEmpty && pin != confirmPin {
                                Label("PINs do not match", systemImage: "exclamationmark.circle")
                                    .font(.caption)
                                    .foregroundColor(.dsError)
                            }

                            if !pin.isEmpty && (pin.count < 4 || pin.count > 6) {
                                Label("PIN must be 4-6 digits", systemImage: "info.circle")
                                    .font(.caption)
                                    .foregroundColor(.dsAccentOrange)
                            }
                        }

                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(Color.dsError)
                                .multilineTextAlignment(.center)
                        }

                        if didSave {
                            Label("PIN saved successfully!", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.green)
                        }

                        Button {
                            Task { await savePin() }
                        } label: {
                            HStack(spacing: 8) {
                                if isSaving {
                                    ProgressView().tint(Color.dsCTALabel)
                                } else {
                                    Text("SAVE PIN")
                                        .font(.system(size: 14, weight: .black, design: .rounded))
                                        .tracking(2)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                }
                            }
                            .foregroundStyle(Color.dsCTALabel)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(isValid ? DSGradient.primaryCTA : LinearGradient(colors: [Color.dsSurfaceContainerHighest, Color.dsSurfaceContainerHighest], startPoint: .leading, endPoint: .trailing))
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                            .dsPrimaryShadow()
                        }
                        .disabled(!isValid || isSaving)
                        .opacity(isValid ? 1 : 0.5)

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.dsBackground, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                }
            }
        }
    }

    private func savePin() async {
        isSaving = true
        errorMessage = nil
        didSave = false
        do {
            try await apiClient.requestVoid(APIRouter.setChildPin(childId: childId, pin: pin))
            didSave = true
            // Auto-dismiss after a moment
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            dismiss()
        } catch {
            errorMessage = "Failed to save PIN: \(error.localizedDescription)"
        }
        isSaving = false
    }
}
