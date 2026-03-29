import SwiftUI

struct FacilityPickerView: View {
    @Binding var selectedFacilityId: String?
    let facilities: [Facility]
    let isLoading: Bool
    var onCreate: (String, String?) async -> Void

    @State private var showAddForm = false
    @State private var newName = ""
    @State private var newCity = ""
    @State private var isCreating = false

    var body: some View {
        Section("Facility") {
            if isLoading && facilities.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if facilities.isEmpty && !showAddForm {
                Text("No saved facilities")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(facilities) { facility in
                    Button {
                        if selectedFacilityId == facility.id {
                            selectedFacilityId = nil
                        } else {
                            selectedFacilityId = facility.id
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(facility.name)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                if let city = facility.city, !city.isEmpty {
                                    Text(city)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if selectedFacilityId == facility.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }
            }

            if showAddForm {
                VStack(spacing: 8) {
                    TextField("Facility name", text: $newName)
                        .textInputAutocapitalization(.words)
                    TextField("City (optional)", text: $newCity)
                        .textInputAutocapitalization(.words)
                    HStack {
                        Button("Cancel") {
                            showAddForm = false
                            newName = ""
                            newCity = ""
                        }
                        Spacer()
                        Button {
                            guard !newName.isEmpty else { return }
                            isCreating = true
                            Task {
                                await onCreate(newName, newCity.isEmpty ? nil : newCity)
                                newName = ""
                                newCity = ""
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
                    Label("Add New Facility", systemImage: "plus.circle")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                }
            }
        }
    }
}
