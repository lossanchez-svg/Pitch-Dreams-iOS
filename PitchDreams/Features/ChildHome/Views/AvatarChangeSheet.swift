import SwiftUI

/// Sheet allowing the player to change their avatar at any time.
/// Calls PATCH /children/:id/profile with the new avatarId.
struct AvatarChangeSheet: View {
    let childId: String
    let onDismiss: () -> Void

    @State private var selectedIndex: Int = 0
    @State private var isSaving = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    private let avatarOptions: [Avatar] = [.wolf, .lion, .eagle, .fox, .shark, .panther, .bear, .default]
    private let apiClient: APIClientProtocol = APIClient()

    private var selectedAvatar: Avatar {
        avatarOptions[selectedIndex]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dsBackground
                    .ignoresSafeArea()

                // Glow
                RadialGradient(
                    colors: [avatarGlowColor.opacity(0.15), .clear],
                    center: .init(x: 0.5, y: 0.3),
                    startRadius: 10,
                    endRadius: 250
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.xl) {
                        // Header
                        VStack(spacing: 8) {
                            Text("CHANGE LEGEND")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(3)
                                .foregroundStyle(Color.dsSecondary)
                            Text("Pick your\nnew avatar")
                                .font(.system(size: 28, weight: .heavy, design: .rounded))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Color.dsOnSurface)
                        }

                        // Hero avatar
                        ZStack {
                            RadialGradient(
                                colors: [avatarGlowColor.opacity(0.2), .clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 150
                            )
                            .frame(width: 280, height: 280)

                            heroImage
                                .frame(width: 220, height: 220)
                        }

                        // Character name
                        Text(selectedAvatar.displayName.uppercased())
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .italic()
                            .foregroundStyle(Color.dsPrimaryPeach)

                        // Thumbnail row
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(avatarOptions.enumerated()), id: \.offset) { index, avatar in
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedIndex = index
                                        }
                                    } label: {
                                        thumbnailView(avatar, isSelected: index == selectedIndex)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, Spacing.xl)
                        }

                        if let error = errorMessage {
                            Text(error)
                                .font(.system(size: 13))
                                .foregroundStyle(Color.dsError)
                        }

                        // Save CTA
                        Button {
                            Task { await saveAvatar() }
                        } label: {
                            HStack(spacing: 8) {
                                if isSaving {
                                    ProgressView().tint(Color(hex: "#5B1B00"))
                                } else {
                                    Text("SAVE \(selectedAvatar.displayName.uppercased())")
                                        .font(.system(size: 14, weight: .black, design: .rounded))
                                        .tracking(2)
                                }
                            }
                            .foregroundStyle(Color(hex: "#5B1B00"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(DSGradient.primaryCTA)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                            .dsPrimaryShadow()
                        }
                        .disabled(isSaving)
                        .padding(.horizontal, Spacing.xl)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.dsBackground, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .foregroundStyle(Color.dsOnSurfaceVariant)
                    }
                }
            }
        }
    }

    // MARK: - Hero Image

    @ViewBuilder
    private var heroImage: some View {
        let assetName = selectedAvatar.assetName(stage: .rookie)
        if UIImage(named: assetName) != nil {
            Image(assetName)
                .resizable()
                .scaledToFit()
                .shadow(color: avatarGlowColor.opacity(0.3), radius: 20)
        } else {
            ZStack {
                Circle()
                    .fill(Color.dsSurfaceContainerHigh)
                Image(systemName: "figure.soccer")
                    .font(.system(size: 50))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
            }
        }
    }

    // MARK: - Thumbnail

    private func thumbnailView(_ avatar: Avatar, isSelected: Bool) -> some View {
        let assetName = avatar.assetName(stage: .rookie)
        return ZStack {
            Circle()
                .fill(isSelected ? Color.dsSurfaceContainerHigh : Color.dsSurfaceContainerLowest)
                .frame(width: 56, height: 56)
            if UIImage(named: assetName) != nil {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                    .grayscale(isSelected ? 0 : 0.8)
                    .opacity(isSelected ? 1.0 : 0.4)
            } else {
                Image(systemName: "figure.soccer")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
            }
        }
        .overlay(
            Circle()
                .stroke(isSelected ? Color.dsSecondary : .clear, lineWidth: 2)
                .frame(width: 56, height: 56)
        )
    }

    // MARK: - Save

    private func saveAvatar() async {
        isSaving = true
        errorMessage = nil
        do {
            let _: ChildProfileDetail = try await apiClient.request(
                APIRouter.updateAvatar(childId: childId, avatarId: selectedAvatar.rawValue)
            )
            onDismiss()
        } catch {
            // If the API doesn't support this endpoint yet, just dismiss — the avatar
            // will update next time the profile is loaded after server-side support is added.
            Log.api.error("Avatar update failed: \(error)")
            errorMessage = "Couldn't save right now. Try again later."
        }
        isSaving = false
    }

    private var avatarGlowColor: Color {
        switch selectedAvatar {
        case .panther: return Color(hex: "#8B5CF6")
        case .wolf: return Color.dsSecondary
        case .lion: return Color.dsAccentOrange
        case .eagle: return Color.dsSecondary
        case .fox: return Color.dsAccentOrange
        case .shark: return Color.dsSecondary
        case .bear: return Color.dsTertiaryContainer
        case .default: return Color.dsSecondary
        }
    }
}
