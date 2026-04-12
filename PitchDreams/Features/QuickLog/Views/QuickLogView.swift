import SwiftUI

struct QuickLogView: View {
    let childId: String
    @StateObject private var viewModel: QuickLogViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showSuccessCheckmark = false

    init(childId: String) {
        self.childId = childId
        _viewModel = StateObject(wrappedValue: QuickLogViewModel(childId: childId))
    }

    var body: some View {
        Form {
            Section("What did you do?") {
                ForEach(QuickLogViewModel.sessionTypes, id: \.key) { type in
                    Button {
                        viewModel.selectedType = type.key
                    } label: {
                        HStack {
                            Image(systemName: type.icon)
                                .font(.title3)
                                .foregroundStyle(Color.dsAccentOrange)
                                .frame(width: 28)
                            Text(type.label)
                                .foregroundStyle(.primary)
                            Spacer()
                            if viewModel.selectedType == type.key {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.dsAccentOrange)
                            }
                        }
                    }
                }
            }

            Section("Duration") {
                Stepper(value: $viewModel.duration, in: 5...120, step: 5) {
                    HStack {
                        Text("Time")
                        Spacer()
                        Text("\(viewModel.duration) min")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("How hard was it?") {
                ForEach(QuickLogViewModel.effortLabels, id: \.value) { item in
                    Button {
                        viewModel.effort = item.value
                    } label: {
                        HStack {
                            Text(item.emoji)
                                .font(.title3)
                            Text(item.label)
                                .foregroundStyle(.primary)
                            Spacer()
                            if viewModel.effort == item.value {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.dsAccentOrange)
                            }
                        }
                    }
                }
            }

            Section {
                Button {
                    Task {
                        await viewModel.save()
                        if viewModel.saveSuccess {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                showSuccessCheckmark = true
                            }
                        }
                    }
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isSaving {
                            ProgressView()
                                .tint(.white)
                        } else if viewModel.saveSuccess {
                            Label("Nice one!", systemImage: "checkmark.circle.fill")
                        } else {
                            Label("Log It", systemImage: "plus.circle.fill")
                        }
                        Spacer()
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding()
                    .background(viewModel.saveSuccess ? DSGradient.secondaryCTA : DSGradient.orangeAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .animation(.easeInOut, value: viewModel.saveSuccess)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isSaving)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            if viewModel.saveSuccess {
                Section {
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.green)
                            .scaleEffect(showSuccessCheckmark ? 1.0 : 0.0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showSuccessCheckmark)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)

                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Session saved")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.green)
                    }
                }
            }

            if let error = viewModel.errorMessage {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.dsError)
                        .font(.subheadline)
                }
            }
        }
        .navigationTitle("Quick Log")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        QuickLogView(childId: "preview-child")
    }
}
