import SwiftUI

struct DrillDetailView: View {
    let drill: DrillDefinition
    let childId: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Skill Diagram
                SkillDiagramView(drillId: drill.id, category: drill.category)

                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(drill.category)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(categoryColor.opacity(0.15))
                            .foregroundStyle(categoryColor)
                            .clipShape(Capsule())

                        Text(drill.difficulty.capitalized)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(difficultyColor.opacity(0.15))
                            .foregroundStyle(difficultyColor)
                            .clipShape(Capsule())
                    }

                    Text(drill.name)
                        .font(.title.bold())

                    Text(drill.description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                // Coach Tip
                VStack(alignment: .leading, spacing: 8) {
                    Label("Coach Tip", systemImage: "lightbulb.fill")
                        .font(.headline)
                        .foregroundStyle(.orange)

                    Text(drill.coachTip)
                        .font(.subheadline)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.orange.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Why It Matters
                VStack(alignment: .leading, spacing: 8) {
                    Label("Why It Matters", systemImage: "brain.fill")
                        .font(.headline)
                        .foregroundStyle(.purple)

                    Text(whyItMatters)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Details
                VStack(alignment: .leading, spacing: 12) {
                    Label("Details", systemImage: "info.circle.fill")
                        .font(.headline)

                    HStack(spacing: 16) {
                        detailItem(icon: "clock.fill", label: "Duration", value: formatDuration(drill.duration))
                        detailItem(icon: "repeat", label: "Reps", value: "\(drill.reps)")
                        detailItem(icon: "location.fill", label: "Space", value: spaceLabel)
                    }
                }

                // Recommended Frequency
                VStack(alignment: .leading, spacing: 8) {
                    Label("Recommended Frequency", systemImage: "calendar")
                        .font(.headline)

                    Text(recommendedFrequency)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Start Drill
                NavigationLink {
                    TrainingSessionView(childId: childId)
                } label: {
                    Label("Start Drill", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.orange.gradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding()
        }
        .navigationTitle(drill.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Helpers

    private var categoryColor: Color {
        switch drill.category {
        case "Ball Mastery": return .cyan
        case "Passing": return .green
        case "Shooting": return .red
        case "Dribbling": return .purple
        case "First Touch": return .orange
        default: return .blue
        }
    }

    private var difficultyColor: Color {
        switch drill.difficulty {
        case "beginner": return .green
        case "intermediate": return .orange
        case "advanced": return .red
        default: return .secondary
        }
    }

    private var spaceLabel: String {
        switch drill.spaceType {
        case "small_indoor": return "Small Indoor"
        case "large_indoor": return "Large Indoor"
        case "outdoor": return "Outdoor"
        default: return drill.spaceType
        }
    }

    private var whyItMatters: String {
        switch drill.category {
        case "Ball Mastery":
            return "Ball mastery is the foundation of every great player. These drills build the close control and confidence you need to keep the ball under pressure and create space in tight situations."
        case "Passing":
            return "Accurate passing is what separates good teams from great ones. Developing a crisp, weighted pass lets you control the tempo of the game and find teammates in dangerous areas."
        case "Shooting":
            return "Finishing chances wins games. Practicing shooting technique builds the muscle memory to stay composed in front of goal and convert when it matters most."
        case "Dribbling":
            return "Dribbling lets you beat defenders, create numerical advantages, and carry the ball into dangerous areas. Every skill move you master adds a new weapon to your game."
        case "First Touch":
            return "Your first touch determines everything that follows. A clean first touch gives you time, space, and options. A poor one puts you under pressure immediately."
        default:
            return "Consistent practice of fundamental skills is the key to long-term development as a player."
        }
    }

    private var recommendedFrequency: String {
        switch drill.difficulty {
        case "beginner": return "3-5 times per week. Master this drill before moving to intermediate."
        case "intermediate": return "2-3 times per week. Focus on quality and consistency."
        case "advanced": return "1-2 times per week. Combine with game-speed scenarios."
        default: return "2-3 times per week."
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)s" }
        let mins = seconds / 60
        let secs = seconds % 60
        return secs > 0 ? "\(mins)m \(secs)s" : "\(mins)m"
    }

    private func detailItem(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.orange)
            Text(value)
                .font(.subheadline.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    NavigationStack {
        DrillDetailView(
            drill: DrillRegistry.all.first!,
            childId: "preview-child"
        )
    }
}
