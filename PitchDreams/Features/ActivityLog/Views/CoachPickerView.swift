import SwiftUI

struct CoachPickerView: View {
    @Binding var selectedCoachId: String?
    let coaches: [Coach]
    let isLoading: Bool
    var onCreate: (String) async -> Void

    @State private var showAddForm = false
    @State private var newDisplayName = ""
    @State private var isCreating = false

    var body: some View {
        Section("Coach") {
            if isLoading && coaches.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if coaches.isEmpty && !showAddForm {
                Text("No saved coaches")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(coaches) { coach in
                    Button {
                        if selectedCoachId == coach.id {
                            selectedCoachId = nil
                        } else {
                            selectedCoachId = coach.id
                        }
                    } label: {
                        HStack {
                            Text(coach.displayName)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            Spacer()
                            if selectedCoachId == coach.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }
            }

            if showAddForm {
                VStack(spacing: 8) {
                    TextField("Coach name", text: $newDisplayName)
                        .textInputAutocapitalization(.words)
                    HStack {
                        Button("Cancel") {
                            showAddForm = false
                            newDisplayName = ""
                        }
                        Spacer()
                        Button {
                            guard !newDisplayName.isEmpty else { return }
                            isCreating = true
                            Task {
                                await onCreate(newDisplayName)
                                newDisplayName = ""
                                showAddForm = false
                                isCreating = false
                            }
                        } label: {
                            if isCreating {
                                ProgressView()
                            } else {
                                Text("Add")
                                    .fontWeight(.semibold)
                            }
                        }
                        .disabled(newDisplayName.isEmpty || isCreating)
                    }
                }
            } else {
                Button {
                    showAddForm = true
                } label: {
                    Label("Add Coach", systemImage: "plus.circle")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                }
            }
        }
    }
}
