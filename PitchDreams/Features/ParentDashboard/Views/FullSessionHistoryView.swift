import SwiftUI

/// Premium parent surface: full training history beyond the free-tier
/// 30-day cap. Parents pick a range preset, see a summary strip, and
/// browse sessions grouped by month.
struct FullSessionHistoryView: View {
    let childName: String
    @StateObject private var viewModel: FullSessionHistoryViewModel

    init(childId: String, childName: String) {
        self.childName = childName
        _viewModel = StateObject(wrappedValue: FullSessionHistoryViewModel(childId: childId))
    }

    var body: some View {
        List {
            Section {
                Picker("Range", selection: $viewModel.range) {
                    ForEach(FullSessionHistoryViewModel.Range.allCases) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))

                summaryRow
            }

            if viewModel.isLoading && viewModel.allSessions.isEmpty {
                Section { loadingPlaceholder }
            } else if let error = viewModel.errorMessage {
                Section { errorRow(error) }
            } else if viewModel.filteredSessions.isEmpty {
                Section { emptyState }
            } else {
                ForEach(viewModel.groupedByMonth, id: \.monthStart) { group in
                    Section(Self.monthFormatter.string(from: group.monthStart)) {
                        ForEach(group.sessions) { session in
                            NavigationLink {
                                SessionDetailView(session: session)
                            } label: {
                                sessionRow(session)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Training History")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }

    // MARK: - Summary

    private var summaryRow: some View {
        HStack(spacing: 24) {
            statPair(label: "SESSIONS", value: "\(viewModel.totalSessions)")
            statPair(label: "TIME", value: viewModel.totalHoursFormatted)
            statPair(label: "AVG RPE", value: viewModel.avgEffortLabel)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }

    private func statPair(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .tracking(1)
                .foregroundStyle(Color.dsOnSurfaceVariant)
            Text(value)
                .font(.system(size: 16, weight: .heavy, design: .rounded).monospacedDigit())
                .foregroundStyle(Color.dsOnSurface)
        }
    }

    // MARK: - Session row

    private func sessionRow(_ session: SessionLog) -> some View {
        let date = FullSessionHistoryViewModel.parseDate(session.createdAt) ?? Date()
        return HStack(spacing: 12) {
            Image(systemName: activityIcon(session.activityType))
                .font(.system(size: 14))
                .foregroundStyle(Color.dsAccentOrange)
                .frame(width: 28, height: 28)
                .background(Color.dsAccentOrange.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(Self.rowFormatter.string(from: date))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.dsOnSurface)
                Text(activityLabel(session.activityType))
                    .font(.system(size: 11))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if let duration = session.duration {
                    Text("\(duration)m")
                        .font(.system(size: 13, weight: .heavy, design: .rounded).monospacedDigit())
                        .foregroundStyle(Color.dsOnSurface)
                }
                if let effort = session.effortLevel {
                    Text("RPE \(effort)")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                }
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - States

    private var loadingPlaceholder: some View {
        HStack {
            ProgressView()
            Text("Loading \(childName)'s full history…")
                .font(.system(size: 13))
                .foregroundStyle(Color.dsOnSurfaceVariant)
                .padding(.leading, 8)
        }
        .padding(.vertical, 8)
    }

    private func errorRow(_ text: String) -> some View {
        Label(text, systemImage: "exclamationmark.triangle")
            .foregroundStyle(Color.dsError)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock.badge.xmark")
                .font(.system(size: 28))
                .foregroundStyle(Color.dsOnSurfaceVariant)
            Text("No sessions in this range")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.dsOnSurface)
            Text("Try a wider time range.")
                .font(.system(size: 12))
                .foregroundStyle(Color.dsOnSurfaceVariant)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Helpers

    private func activityIcon(_ raw: String?) -> String {
        guard let raw else { return "figure.run" }
        switch raw {
        case "SELF_TRAINING":   return "figure.run"
        case "COACH_1ON1":      return "person.2.fill"
        case "TEAM_PRACTICE":   return "person.3.fill"
        case "GAME":            return "sportscourt.fill"
        case "CLASS":           return "book.closed.fill"
        default:                return "figure.run"
        }
    }

    private func activityLabel(_ raw: String?) -> String {
        guard let raw else { return "Training" }
        return ActivityType(rawValue: raw)?.displayName ?? raw
    }

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    private static let rowFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f
    }()
}

#Preview {
    NavigationStack {
        FullSessionHistoryView(childId: "preview", childName: "Alex")
    }
}
