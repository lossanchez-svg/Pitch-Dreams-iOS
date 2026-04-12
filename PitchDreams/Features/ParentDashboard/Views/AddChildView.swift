import SwiftUI

/// Simplified flow for adding another child when parent is already logged in.
/// Reuses the same step views from onboarding but skips signup.
/// Steps: Avatar Selection → Profile → Permissions → PIN
struct AddChildView: View {
    @StateObject private var viewModel: OnboardingViewModel
    @Environment(\.dismiss) private var dismiss
    let onChildAdded: () -> Void

    init(authManager: AuthManager, onChildAdded: @escaping () -> Void) {
        // Start in "add child" mode — parent already logged in, use authenticated endpoint
        let vm = OnboardingViewModel(authManager: authManager)
        vm.isAddChildMode = true
        vm.step = 0
        _viewModel = StateObject(wrappedValue: vm)
        self.onChildAdded = onChildAdded
    }

    /// Local step count: 0=Avatar, 1=Profile, 2=Permissions, 3=PIN
    private var localStep: Int { viewModel.step }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dsBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress indicator (4 steps)
                    HStack(spacing: 6) {
                        ForEach(0..<4, id: \.self) { index in
                            Capsule()
                                .fill(index <= localStep ? Color.dsSecondary : Color.dsSurfaceContainerHighest)
                                .frame(height: 4)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)

                    // Step title (for non-avatar steps)
                    if localStep != 0 {
                        Text(stepTitle)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.dsOnSurface)
                            .padding(.top, 16)
                            .padding(.bottom, 4)

                        Text(stepSubtitle)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.dsOnSurfaceVariant)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    // Content
                    Group {
                        switch localStep {
                        case 0: AvatarSelectionStepView(viewModel: viewModel)
                        case 1: ChildProfileStepView(viewModel: viewModel)
                        case 2: addChildPermissionsView
                        case 3: addChildPinView
                        default: EmptyView()
                        }
                    }
                    .animation(.easeInOut, value: localStep)

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundStyle(Color.dsError)
                            .font(.system(size: 13))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 8)
                    }
                }
            }
            .loadingOverlay(viewModel.isLoading)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.dsBackground, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if localStep > 0 {
                        Button {
                            viewModel.previousStep()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .foregroundStyle(Color.dsOnSurfaceVariant)
                        }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    if localStep == 0 {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                    }
                }
            }
            .onChange(of: viewModel.step) { newStep in
                // When PIN step completes (step advances past 3), we're done
                if newStep > 3 {
                    onChildAdded()
                    dismiss()
                }
            }
        }
    }

    // MARK: - Permissions (restyled for dark theme)

    private var addChildPermissionsView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Free text toggle
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(isOn: $viewModel.freeTextEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Allow Free-Text Notes")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.dsOnSurface)
                            Text("Let your player type notes during sessions. Recommended for ages 14+.")
                                .font(.caption)
                                .foregroundStyle(Color.dsOnSurfaceVariant)
                        }
                    }
                    .tint(Color.dsSecondary)

                    if viewModel.age < 14 && viewModel.freeTextEnabled {
                        Label("Player is under 14. Consider keeping this off.", systemImage: "info.circle")
                            .font(.caption)
                            .foregroundColor(.dsAccentOrange)
                    }
                }
                .padding()
                .background(Color.dsSurfaceContainer)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                .ghostBorder()

                // Training window
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: $viewModel.trainingWindowEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Set Training Window")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.dsOnSurface)
                            Text("Limit when training sessions can be started.")
                                .font(.caption)
                                .foregroundStyle(Color.dsOnSurfaceVariant)
                        }
                    }
                    .tint(Color.dsSecondary)

                    if viewModel.trainingWindowEnabled {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Start")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(Color.dsOnSurfaceVariant)
                                TextField("08:00", text: $viewModel.windowStart)
                                    .keyboardType(.numbersAndPunctuation)
                                    .padding(10)
                                    .foregroundStyle(Color.dsOnSurface)
                                    .background(Color.dsSurfaceContainerHighest)
                                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("End")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(Color.dsOnSurfaceVariant)
                                TextField("20:00", text: $viewModel.windowEnd)
                                    .keyboardType(.numbersAndPunctuation)
                                    .padding(10)
                                    .foregroundStyle(Color.dsOnSurface)
                                    .background(Color.dsSurfaceContainerHighest)
                                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                            }
                        }
                    }
                }
                .padding()
                .background(Color.dsSurfaceContainer)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                .ghostBorder()

                // Next button
                Button {
                    viewModel.completePermissionsStep()
                } label: {
                    Text("NEXT")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(Color(hex: "#5B1B00"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(DSGradient.primaryCTA)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                        .dsPrimaryShadow()
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
    }

    // MARK: - PIN Setup (restyled for dark theme)

    private var addChildPinView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.dsSecondary)

                Text("Set a PIN for \(viewModel.nickname.isEmpty ? "your player" : viewModel.nickname)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.dsOnSurface)
                    .multilineTextAlignment(.center)

                Text("Your child will use this PIN to log in on their own.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
                    .multilineTextAlignment(.center)

                VStack(spacing: 14) {
                    SecureField("PIN (4-6 digits)", text: $viewModel.pin)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .padding()
                        .foregroundStyle(Color.dsOnSurface)
                        .background(Color.dsSurfaceContainerHighest)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))

                    SecureField("Confirm PIN", text: $viewModel.confirmPin)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .padding()
                        .foregroundStyle(Color.dsOnSurface)
                        .background(Color.dsSurfaceContainerHighest)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))

                    if !viewModel.confirmPin.isEmpty && viewModel.pin != viewModel.confirmPin {
                        Label("PINs do not match", systemImage: "exclamationmark.circle")
                            .font(.caption)
                            .foregroundColor(.dsError)
                    }

                    if !viewModel.pin.isEmpty && (viewModel.pin.count < 4 || viewModel.pin.count > 6) {
                        Label("PIN must be 4-6 digits", systemImage: "info.circle")
                            .font(.caption)
                            .foregroundColor(.dsAccentOrange)
                    }
                }

                Button {
                    Task { await setChildPin() }
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isLoading {
                            ProgressView().tint(Color(hex: "#5B1B00"))
                        } else {
                            Text("ADD PLAYER")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .tracking(2)
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                        }
                    }
                    .foregroundStyle(Color(hex: "#5B1B00"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(viewModel.isPinValid ? DSGradient.primaryCTA : LinearGradient(colors: [Color.dsSurfaceContainerHighest, Color.dsSurfaceContainerHighest], startPoint: .leading, endPoint: .trailing))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                    .dsPrimaryShadow()
                }
                .disabled(!viewModel.isPinValid || viewModel.isLoading)
                .opacity(viewModel.isPinValid ? 1 : 0.5)

                Button {
                    Task { await skipAndFinish() }
                } label: {
                    Text("Skip for now")
                        .font(.callout)
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
    }

    // MARK: - Actions

    private func setChildPin() async {
        guard let cid = viewModel.childId else { return }
        guard viewModel.isPinValid else {
            viewModel.errorMessage = "PIN must be 4-6 digits and both entries must match."
            return
        }
        viewModel.isLoading = true
        viewModel.errorMessage = nil
        do {
            let apiClient: APIClientProtocol = APIClient()
            try await apiClient.requestVoid(APIRouter.setChildPin(childId: cid, pin: viewModel.pin))
            onChildAdded()
            dismiss()
        } catch {
            viewModel.errorMessage = "Failed to set PIN: \(error.localizedDescription)"
            viewModel.isLoading = false
        }
    }

    private func skipAndFinish() async {
        onChildAdded()
        dismiss()
    }

    // MARK: - Text

    private var stepTitle: String {
        switch localStep {
        case 0: return ""
        case 1: return "Player Profile"
        case 2: return "Permissions"
        case 3: return "Set a PIN"
        default: return ""
        }
    }

    private var stepSubtitle: String {
        switch localStep {
        case 0: return ""
        case 1: return "Tell us about your young player."
        case 2: return "Configure content and training settings."
        case 3: return "Create a PIN for your child to log in."
        default: return ""
        }
    }
}
