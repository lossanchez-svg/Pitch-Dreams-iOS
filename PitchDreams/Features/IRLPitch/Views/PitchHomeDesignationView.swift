import SwiftUI
import CoreLocation

/// Two-frame flow for IRL Pitch Layer:
///  1. **First detection** — GPS dwelled at an unknown location long enough
///     to be a real pitch. Prompts for a nickname + home-pitch flag.
///  2. **Saved pitches list** — browse, swipe-delete, set home.
///
/// Presented as a sheet from the home dashboard when
/// `detector.pendingNewLocation != nil`, or opened manually from the
/// saved-pitches link on the location banner.
///
/// Matches `proposals/Stitch/pitch_home_designation.png`.
struct PitchHomeDesignationView: View {
    @ObservedObject var viewModel: IRLPitchViewModel
    var onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dsBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: Spacing.xl) {
                        if viewModel.detector.pendingNewLocation != nil {
                            firstDetectionSection
                        }
                        savedPitchesSection
                        addManualLink
                        Color.clear.frame(height: 40)
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("My Pitches")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { onDismiss() }
                }
            }
            .task { await viewModel.loadPitches() }
        }
    }

    // MARK: - First detection

    private var firstDetectionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            mapThumbnail

            Text("We spotted you at a new pitch")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.dsOnSurface)

            VStack(alignment: .leading, spacing: 6) {
                Text("PITCH NAME")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color.dsOnSurfaceVariant)
                TextField("Home Pitch", text: $viewModel.draftNickname)
                    .font(.system(size: 15, weight: .semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.dsSurfaceContainerLow)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            }

            markHomeToggle

            HStack(spacing: 10) {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    Task { await viewModel.saveDesignation() }
                } label: {
                    Text("SAVE")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(Color.dsCTALabel)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(DSGradient.primaryCTA)
                        .clipShape(Capsule())
                        .dsPrimaryShadow()
                }
                .disabled(viewModel.isSaving)
            }

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                viewModel.dismissDesignation()
            } label: {
                Text("NOT A PITCH")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color.dsSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
        }
        .padding(Spacing.lg)
        .background(Color.dsSurfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xxl))
        .ghostBorder()
    }

    private var mapThumbnail: some View {
        RoundedRectangle(cornerRadius: CornerRadius.lg)
            .fill(
                LinearGradient(
                    colors: [Color(hex: "#1A2E1F"), Color(hex: "#0F1A12")],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: 160)
            .overlay(
                ZStack {
                    // Stylized pitch outline — we're not rendering real MKMap
                    // here (keeps the flow lightweight at launch). Post-launch
                    // swap for MapKit snapshot with the dwell coordinate.
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.dsSecondary.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 160, height: 90)
                    Circle()
                        .stroke(Color.dsSecondary.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 30, height: 30)
                    // Radial glow + orange pin at center
                    Circle()
                        .fill(Color.dsAccentOrange.opacity(0.25))
                        .frame(width: 70, height: 70)
                        .blur(radius: 12)
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.dsAccentOrange)
                        .shadow(color: Color.dsAccentOrange.opacity(0.5), radius: 8)
                }
            )
    }

    private var markHomeToggle: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Mark as my home pitch")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.dsOnSurface)
                Text("SETS AS PRIMARY LOCATION")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(Color.dsOnSurfaceVariant)
            }
            Spacer()
            Toggle("", isOn: $viewModel.draftMarkAsHome)
                .tint(Color.dsAccentOrange)
                .labelsHidden()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.dsSurfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
    }

    // MARK: - Saved list

    private var savedPitchesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !viewModel.pitches.isEmpty {
                HStack {
                    Text("MY PITCHES · \(viewModel.pitches.count)")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                    Spacer()
                }

                ForEach(viewModel.pitches) { pitch in
                    pitchRow(pitch)
                }
            } else if viewModel.detector.pendingNewLocation == nil {
                VStack(spacing: 8) {
                    Image(systemName: "mappin.slash")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                    Text("No saved pitches yet")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.dsOnSurface)
                    Text("When you train at the same place for a few minutes, we'll offer to save it here.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
        }
    }

    private func pitchRow(_ pitch: TrainingPitch) -> some View {
        HStack(spacing: 12) {
            if pitch.isHomePitch {
                Label("HOME", systemImage: "house.fill")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(Color.dsTertiaryContainer)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.dsTertiaryContainer.opacity(0.18))
                    .clipShape(Capsule())
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(pitch.displayName)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.dsOnSurface)
                Text("EST. \(shortDate(pitch.firstVisitedAt))")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(Color.dsOnSurfaceVariant)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 0) {
                Text("\(pitch.visitCount)")
                    .font(.system(size: 20, weight: .heavy, design: .rounded).monospacedDigit())
                    .foregroundStyle(Color.dsSecondary)
                Text("VISITS")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(Color.dsOnSurfaceVariant)
            }
        }
        .padding(14)
        .background(Color.dsSurfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .contextMenu {
            if !pitch.isHomePitch {
                Button {
                    Task { await viewModel.setHome(pitch) }
                } label: {
                    Label("Set as Home Pitch", systemImage: "house.fill")
                }
            }
            Button(role: .destructive) {
                Task { await viewModel.deletePitch(pitch) }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var addManualLink: some View {
        Button {
            // Manual add isn't wired to CoreLocation — user would enter lat/lon
            // manually which is terrible UX. Instead we surface a note and
            // let them drive detection by training at the place.
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 14))
                Text("TRAIN AT A NEW PITCH TO ADD IT")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1)
            }
            .foregroundStyle(Color.dsSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .disabled(true)
        .opacity(0.6)
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date).uppercased()
    }
}
