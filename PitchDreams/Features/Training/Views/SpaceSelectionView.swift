import SwiftUI

struct SpaceSelectionView: View {
    let childId: String

    private let spaces: [(id: String, title: String, subtitle: String, icon: String)] = [
        ("small_indoor", "Small Indoor", "Bedroom, hallway, or small room", "house.fill"),
        ("large_indoor", "Large Indoor", "Gym, garage, or large room", "building.2.fill"),
        ("outdoor", "Outdoor", "Field, park, or driveway", "sun.max.fill"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Where are you training?")
                    .font(.title2.bold())
                    .padding(.top, 8)

                Text("We'll pick the best drills for your space.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(spaces, id: \.id) { space in
                    let drills = DrillRegistry.drills(for: space.id)
                    NavigationLink {
                        ActiveDrillView(
                            childId: childId,
                            drills: drills,
                            spaceType: space.id
                        )
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: space.icon)
                                .font(.title)
                                .foregroundStyle(.orange)
                                .frame(width: 48, height: 48)
                                .background(.orange.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(space.title)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(space.subtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text("\(drills.count) drills available")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .disabled(drills.isEmpty)
                    .opacity(drills.isEmpty ? 0.5 : 1)
                }
            }
            .padding()
        }
        .navigationTitle("Pick a Space")
        .navigationBarTitleDisplayMode(.inline)
    }
}
