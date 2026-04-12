import SwiftUI

struct ChipItem: Identifiable {
    let id: String
    let label: String
}

struct ChipPickerView: View {
    let items: [ChipItem]
    @Binding var selectedIds: Set<String>
    var maxSelection: Int = 3
    var accentColor: Color = .orange

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if maxSelection < items.count {
                Text("\(selectedIds.count) of \(maxSelection) selected")
                    .font(.caption)
                    .foregroundStyle(Color.dsOnSurfaceVariant)
            }

            FlowLayout(spacing: 8) {
                ForEach(items) { item in
                    let isSelected = selectedIds.contains(item.id)
                    Button {
                        toggleSelection(item.id)
                    } label: {
                        Text(item.label)
                            .font(.subheadline)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(isSelected ? accentColor.opacity(0.15) : Color.dsSurfaceContainerHighest)
                            .foregroundColor(isSelected ? accentColor : .primary)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(isSelected ? accentColor : Color.clear, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(!isSelected && selectedIds.count >= maxSelection)
                    .opacity(!isSelected && selectedIds.count >= maxSelection ? 0.5 : 1)
                }
            }
        }
    }

    private func toggleSelection(_ id: String) {
        if selectedIds.contains(id) {
            selectedIds.remove(id)
        } else if selectedIds.count < maxSelection {
            selectedIds.insert(id)
        }
    }
}
