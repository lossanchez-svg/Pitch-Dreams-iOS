import SwiftUI

struct ProgramPickerView: View {
    @Binding var selectedProgramId: String?
    let programs: [Program]
    let isLoading: Bool
    var onCreate: (String, String) async -> Void

    @State private var showAddForm = false
    @State private var newName = ""
    @State private var newType = "club"
    @State private var isCreating = false

    private let programTypes = ["club", "academy", "school", "camp", "private"]

    var body: some View {
        Section("Program") {
            if isLoading && programs.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if programs.isEmpty && !showAddForm {
                Text("No saved programs")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(programs) { program in
                    Button {
                        if selectedProgramId == program.id {
                            selectedProgramId = nil
                        } else {
                            selectedProgramId = program.id
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(program.name)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                Text(program.type.capitalized)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if selectedProgramId == program.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }
            }

            if showAddForm {
                VStack(spacing: 8) {
                    TextField("Program name", text: $newName)
                        .textInputAutocapitalization(.words)
                    Picker("Type", selection: $newType) {
                        ForEach(programTypes, id: \.self) { type in
                            Text(type.capitalized).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    HStack {
                        Button("Cancel") {
                            showAddForm = false
                            newName = ""
                            newType = "club"
                        }
                        Spacer()
                        Button {
                            guard !newName.isEmpty else { return }
                            isCreating = true
                            Task {
                                await onCreate(newName, newType)
                                newName = ""
                                newType = "club"
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
                        .disabled(newName.isEmpty || isCreating)
                    }
                }
            } else {
                Button {
                    showAddForm = true
                } label: {
                    Label("Add Program", systemImage: "plus.circle")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                }
            }
        }
    }
}
