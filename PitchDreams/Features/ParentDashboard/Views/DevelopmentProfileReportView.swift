import SwiftUI

/// Letter-size SwiftUI template (612×792pt) rendered to PDF via ImageRenderer.
/// Layout matches the in-app ChildDetail analytics but formatted for print:
/// white background (printable), dark navy ink, serif-free display fonts,
/// footer watermark.
///
/// All data flows in from `DevelopmentProfileViewModel` — the template only
/// composes. This makes PDF regeneration deterministic: same inputs → same PDF.
struct DevelopmentProfileReportView: View {
    let viewModel: DevelopmentProfileViewModel

    /// US Letter in points. Landscape is 792×612; we render portrait.
    static let pageSize = CGSize(width: 612, height: 792)

    private var ink: Color { Color(red: 0.07, green: 0.10, blue: 0.17) }
    private var accent: Color { Color(red: 1.0, green: 0.42, blue: 0.17) } // dsAccentOrange
    private var cyan: Color { Color(red: 0.27, green: 0.90, blue: 0.97) }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            summaryStrip
            activityBreakdown
            trendSparkline
            if !viewModel.parentNote.isEmpty {
                parentNoteSection
            }
            Spacer()
            footer
        }
        .padding(36)
        .frame(width: Self.pageSize.width, height: Self.pageSize.height, alignment: .topLeading)
        .background(Color.white)
        .foregroundStyle(ink)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            avatarCircle
                .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.childName)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                metaLine

                Text("DEVELOPMENT PROFILE · \(viewModel.period.rawValue.uppercased())")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(accent)
                    .padding(.top, 6)

                Text(viewModel.periodLabel)
                    .font(.system(size: 11))
                    .foregroundStyle(ink.opacity(0.65))
            }
            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("PitchDreams")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(accent)
                Text("pitchdreams.soccer")
                    .font(.system(size: 9))
                    .foregroundStyle(ink.opacity(0.55))
            }
        }
        .padding(.bottom, 14)
        .overlay(alignment: .bottom) {
            Rectangle().fill(accent).frame(height: 2)
        }
    }

    @ViewBuilder
    private var avatarCircle: some View {
        // Prefer the avatarId from the detail profile but fall back to the
        // summary avatar so the report renders before async profile load.
        let avatarId = viewModel.profile?.avatarId ?? viewModel.child.avatarId ?? "wolf"
        // Total XP isn't exposed on ChildProfileDetail; the report renders
        // with stage-1 art. A future pass can load XPStore to stage-match.
        let totalXP = 0
        let assetName = Avatar.assetName(for: avatarId, totalXP: totalXP)
        if UIImage(named: assetName) != nil {
            Image(assetName)
                .resizable()
                .scaledToFill()
                .clipShape(Circle())
                .overlay(Circle().stroke(accent, lineWidth: 2))
        } else {
            Circle()
                .fill(accent.opacity(0.15))
                .overlay(
                    Image(systemName: "figure.soccer")
                        .font(.system(size: 24))
                        .foregroundStyle(accent)
                )
                .clipShape(Circle())
        }
    }

    private var metaLine: some View {
        HStack(spacing: 8) {
            chip("Age \(viewModel.child.age)")
            if let position = viewModel.child.position, !position.isEmpty {
                chip(position)
            }
        }
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .heavy, design: .rounded))
            .tracking(1)
            .foregroundStyle(ink)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(ink.opacity(0.08))
            .clipShape(Capsule())
    }

    // MARK: - Summary strip

    private var summaryStrip: some View {
        HStack(spacing: 12) {
            statCell(label: "SESSIONS", value: "\(viewModel.totalSessions)")
            statCell(label: "TIME", value: viewModel.totalHoursFormatted)
            statCell(label: "STREAK", value: "\(viewModel.currentStreak) days")
            statCell(label: "AVG RPE", value: viewModel.avgEffortLabel)
        }
    }

    private func statCell(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(ink.opacity(0.55))
            Text(value)
                .font(.system(size: 20, weight: .black, design: .rounded).monospacedDigit())
                .foregroundStyle(ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(ink.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(ink.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Activity breakdown

    private var activityBreakdown: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Activity Breakdown")
            let items = viewModel.activityBreakdown
            if items.isEmpty {
                placeholder("No activities logged in this period.")
            } else {
                let maxCount = max(1, items.map(\.count).max() ?? 1)
                VStack(spacing: 8) {
                    ForEach(Array(items.prefix(5)), id: \.type) { item in
                        activityRow(
                            type: item.type,
                            count: item.count,
                            minutes: item.minutes,
                            fillFraction: Double(item.count) / Double(maxCount)
                        )
                    }
                }
            }
        }
    }

    private func activityRow(type: String, count: Int, minutes: Int, fillFraction: Double) -> some View {
        HStack(spacing: 12) {
            Text(ActivityType(rawValue: type)?.displayName ?? type)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .frame(width: 120, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(ink.opacity(0.06))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(cyan)
                        .frame(width: max(6, geo.size.width * fillFraction))
                }
            }
            .frame(height: 12)
            Text("\(count) · \(minutes)m")
                .font(.system(size: 11, weight: .medium, design: .rounded).monospacedDigit())
                .foregroundStyle(ink.opacity(0.65))
                .frame(width: 80, alignment: .trailing)
        }
    }

    // MARK: - Trend sparkline

    private var trendSparkline: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Sessions · last 4 weeks")
            let values = viewModel.sessionsLast4Weeks
            if values.allSatisfy({ $0 == 0 }) {
                placeholder("No sessions in the last 4 weeks.")
            } else {
                HStack(alignment: .bottom, spacing: 12) {
                    ForEach(Array(values.enumerated()), id: \.offset) { index, count in
                        VStack(spacing: 6) {
                            let maxVal = max(1, values.max() ?? 1)
                            let height = CGFloat(count) / CGFloat(maxVal) * 60
                            RoundedRectangle(cornerRadius: 4)
                                .fill(accent)
                                .frame(width: 36, height: max(4, height))
                            Text("W\(values.count - index)")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundStyle(ink.opacity(0.55))
                            Text("\(count)")
                                .font(.system(size: 11, weight: .black, design: .rounded).monospacedDigit())
                                .foregroundStyle(ink)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .frame(height: 90)
            }
        }
    }

    // MARK: - Parent note

    private var parentNoteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Parent's Note")
            Text(viewModel.parentNote)
                .font(.system(size: 11))
                .foregroundStyle(ink.opacity(0.85))
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(ink.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(ink.opacity(0.08), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Text("Generated by PitchDreams")
                .font(.system(size: 9))
                .foregroundStyle(ink.opacity(0.5))
            Spacer()
            Text(Self.dateFormatter.string(from: Date()))
                .font(.system(size: 9))
                .foregroundStyle(ink.opacity(0.5))
        }
        .padding(.top, 8)
        .overlay(alignment: .top) {
            Rectangle().fill(ink.opacity(0.1)).frame(height: 1)
        }
    }

    // MARK: - Shared bits

    private func sectionTitle(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .tracking(1.5)
            .foregroundStyle(ink.opacity(0.55))
    }

    private func placeholder(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11))
            .foregroundStyle(ink.opacity(0.5))
            .padding(.vertical, 8)
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f
    }()
}

#Preview {
    DevelopmentProfileReportView(viewModel: {
        let stub = ChildSummary(
            id: "preview", nickname: "Alex", age: 11,
            position: "Midfielder", avatarId: "wolf"
        )
        let vm = DevelopmentProfileViewModel(child: stub)
        vm.parentNote = "Big improvement on first-touch this month — keep it up!"
        return vm
    }())
    .previewLayout(.fixed(width: 612, height: 792))
}
