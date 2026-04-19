import SwiftUI
import Charts

/// First Track D premium parent surface: deeper training analytics for a
/// single child. Three charts:
/// 1. Sessions per week (last 12 weeks) — bar
/// 2. Training minutes per month (last 6 months) — line
/// 3. Effort-level trend per week — line with smoothing
///
/// Entry is from `ChildDetailView → Advanced Analytics`. Free-tier parents
/// see a dimmed preview with a "tap to unlock" overlay via `.gated(by:)`;
/// premium parents see the real charts with live data.
struct AdvancedAnalyticsView: View {
    let childName: String
    @StateObject private var viewModel: AdvancedAnalyticsViewModel

    init(childId: String, childName: String) {
        self.childName = childName
        _viewModel = StateObject(wrappedValue: AdvancedAnalyticsViewModel(childId: childId))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                summaryStats
                sessionsPerWeekChart
                minutesPerMonthChart
                effortTrendChart

                if viewModel.weeklyBuckets.isEmpty && !viewModel.isLoading {
                    emptyState
                }
            }
            .padding(20)
        }
        .background(Color.dsBackground)
        .navigationTitle("Advanced Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }

    // MARK: - Summary stats

    private var summaryStats: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                summaryPill(
                    label: "WEEKLY AVG",
                    value: String(format: "%.1f", viewModel.avgSessionsPerWeek),
                    unit: "sessions"
                )
                summaryPill(
                    label: "AVG LENGTH",
                    value: String(format: "%.0f", viewModel.avgMinutesPerSession),
                    unit: "min"
                )
            }
            if let delta = viewModel.monthOverMonthPercent {
                momCard(delta: delta)
            }
        }
    }

    private func summaryPill(label: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(Color.dsOnSurfaceVariant)
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .black, design: .rounded).monospacedDigit())
                    .foregroundStyle(Color.dsOnSurface)
                Text(unit)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.dsSurfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
    }

    private func momCard(delta: Int) -> some View {
        let trending = delta >= 0
        return HStack(spacing: 10) {
            Image(systemName: trending ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(trending ? Color.dsSecondary : Color.dsError)
            VStack(alignment: .leading, spacing: 2) {
                Text("MONTH OVER MONTH")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(Color.dsOnSurfaceVariant)
                Text("\(trending ? "+" : "")\(delta)% vs last month")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.dsOnSurface)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.dsSurfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
    }

    // MARK: - Charts

    private var sessionsPerWeekChart: some View {
        chartCard(title: "Sessions per week", subtitle: "Last 12 weeks") {
            Chart(viewModel.weeklyBuckets) { bucket in
                BarMark(
                    x: .value("Week", bucket.weekStart, unit: .weekOfYear),
                    y: .value("Sessions", bucket.sessionCount)
                )
                .foregroundStyle(Color.dsAccentOrange.gradient)
                .cornerRadius(4)
            }
            .frame(height: 180)
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear, count: 2)) { value in
                    AxisValueLabel(format: .dateTime.month().day(), centered: true)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
        }
    }

    private var minutesPerMonthChart: some View {
        chartCard(title: "Training minutes per month", subtitle: "Last 6 months") {
            Chart(viewModel.monthlyBuckets) { bucket in
                LineMark(
                    x: .value("Month", bucket.monthStart, unit: .month),
                    y: .value("Minutes", bucket.minutes)
                )
                .foregroundStyle(Color.dsSecondary)
                .interpolationMethod(.catmullRom)
                .symbol {
                    Circle()
                        .fill(Color.dsSecondary)
                        .frame(width: 8, height: 8)
                }
                AreaMark(
                    x: .value("Month", bucket.monthStart, unit: .month),
                    y: .value("Minutes", bucket.minutes)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.dsSecondary.opacity(0.3), Color.dsSecondary.opacity(0.05)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
            .frame(height: 180)
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated), centered: true)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
        }
    }

    private var effortTrendChart: some View {
        let withEffort = viewModel.weeklyBuckets.filter { $0.avgEffort != nil }
        return chartCard(
            title: "Effort level trend",
            subtitle: "Weekly average (RPE 1-10)"
        ) {
            if withEffort.isEmpty {
                Text("No effort data yet")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
            } else {
                Chart(withEffort) { bucket in
                    LineMark(
                        x: .value("Week", bucket.weekStart, unit: .weekOfYear),
                        y: .value("Effort", bucket.avgEffort ?? 0)
                    )
                    .foregroundStyle(Color.dsTertiary)
                    .interpolationMethod(.catmullRom)
                    .symbol {
                        Circle().fill(Color.dsTertiary).frame(width: 7, height: 7)
                    }
                }
                .frame(height: 180)
                .chartYScale(domain: 0...10)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .weekOfYear, count: 2)) { _ in
                        AxisValueLabel(format: .dateTime.month().day(), centered: true)
                    }
                }
                .chartYAxis {
                    AxisMarks(values: [0, 2, 4, 6, 8, 10]) { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func chartCard<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.dsOnSurface)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.dsSurfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 40))
                .foregroundStyle(Color.dsOnSurfaceVariant)
            Text("No training data yet")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.dsOnSurface)
            Text("Once \(childName) starts training, trends will appear here.")
                .font(.system(size: 13))
                .foregroundStyle(Color.dsOnSurfaceVariant)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

#Preview {
    NavigationStack {
        AdvancedAnalyticsView(childId: "preview", childName: "Alex")
            .environmentObject(EntitlementStore())
            .environmentObject(SubscriptionManager(entitlementStore: EntitlementStore()))
    }
}
