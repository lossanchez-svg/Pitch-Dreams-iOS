import SwiftUI

/// Drill-down for a single `SessionLog` from `FullSessionHistoryView`.
/// Surfaces all the fields that the summary row doesn't show — mood,
/// win, focus, full ISO timestamp — for parents who want the full context
/// of a particular training day.
struct SessionDetailView: View {
    let session: SessionLog

    var body: some View {
        List {
            Section {
                LabeledContent("Date") {
                    Text(Self.dateFormatter.string(from: parsedDate))
                        .font(.body.weight(.semibold))
                }
                LabeledContent("Time") {
                    Text(Self.timeFormatter.string(from: parsedDate))
                        .font(.body.monospacedDigit())
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                }
            } header: {
                Text("When")
            }

            Section("Activity") {
                LabeledContent("Type") {
                    HStack(spacing: 6) {
                        Image(systemName: activityIcon)
                            .foregroundStyle(Color.dsAccentOrange)
                        Text(activityLabel)
                            .font(.body.weight(.semibold))
                    }
                }
                if let duration = session.duration {
                    LabeledContent("Duration") {
                        Text("\(duration) min")
                            .font(.body.monospacedDigit().weight(.semibold))
                    }
                }
                if let effort = session.effortLevel {
                    LabeledContent("Effort (RPE)") {
                        HStack(spacing: 6) {
                            Text("\(effort) / 10")
                                .font(.body.monospacedDigit().weight(.semibold))
                            effortDot(for: effort)
                        }
                    }
                }
            }

            if session.mood != nil || session.win != nil || session.focus != nil {
                Section("Reflection") {
                    if let mood = session.mood, !mood.isEmpty {
                        LabeledContent("Mood") {
                            Text(mood.capitalized)
                                .font(.body.weight(.semibold))
                        }
                    }
                    if let focus = session.focus, !focus.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Focus")
                                .font(.caption)
                                .foregroundStyle(Color.dsOnSurfaceVariant)
                            Text(focus)
                                .font(.system(size: 14))
                        }
                        .padding(.vertical, 2)
                    }
                    if let win = session.win, !win.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("What went well")
                                .font(.caption)
                                .foregroundStyle(Color.dsOnSurfaceVariant)
                            Text(win)
                                .font(.system(size: 14))
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            Section("Session ID") {
                Text(session.id)
                    .font(.system(size: 11).monospaced())
                    .foregroundStyle(Color.dsOnSurfaceVariant)
                    .textSelection(.enabled)
            }
        }
        .navigationTitle("Session")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Derived

    private var parsedDate: Date {
        FullSessionHistoryViewModel.parseDate(session.createdAt) ?? Date()
    }

    private var activityLabel: String {
        guard let raw = session.activityType else { return "Training" }
        return ActivityType(rawValue: raw)?.displayName ?? raw
    }

    private var activityIcon: String {
        guard let raw = session.activityType else { return "figure.run" }
        switch raw {
        case "SELF_TRAINING":   return "figure.run"
        case "COACH_1ON1":      return "person.2.fill"
        case "TEAM_PRACTICE":   return "person.3.fill"
        case "GAME":            return "sportscourt.fill"
        case "CLASS":           return "book.closed.fill"
        default:                return "figure.run"
        }
    }

    @ViewBuilder
    private func effortDot(for effort: Int) -> some View {
        let color: Color = {
            switch effort {
            case ...3:  return .green
            case 4...6: return .orange
            default:    return .red
            }
        }()
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()
}

#Preview {
    NavigationStack {
        SessionDetailView(session: SessionLog(
            id: "sess-123",
            childId: "child-1",
            activityType: "SELF_TRAINING",
            effortLevel: 7,
            mood: "focused",
            duration: 45,
            win: "Made 12 in a row on juggling challenge!",
            focus: "First touch",
            createdAt: "2026-04-19T15:30:00Z"
        ))
    }
}
