import SwiftUI

/// Home-dashboard card showing today's rotating tip. Dismissible for the day;
/// dismissal state is stored per-child per-date in UserDefaults so each kid
/// can clear their own without affecting a sibling on the same device.
struct DailyTipCard: View {
    let childId: String
    let tip: DailyTip
    @Binding var isDismissed: Bool

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.lg) {
            // Category emoji badge
            Text(tip.category.emoji)
                .font(.system(size: 28))
                .frame(width: 52, height: 52)
                .background(Color(hex: tip.category.accentColorHex).opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("TODAY'S FOCUS · \(tip.category.displayName.uppercased())")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(Color(hex: tip.category.accentColorHex))

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.dsOnSurfaceVariant)
                            .frame(width: 20, height: 20)
                            .background(Color.dsSurfaceContainerHighest)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Dismiss today's tip")
                }

                Text(tip.text)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.dsOnSurface)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(Spacing.lg)
        .background(Color.dsSurfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .ghostBorder()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Today's focus: \(tip.category.displayName). \(tip.text)")
    }

    private func dismiss() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isDismissed = true
        }
        DailyTipDismissal.dismiss(tip: tip, childId: childId)
    }
}

// MARK: - Per-child, per-day dismissal

/// Thin UserDefaults wrapper so the home view doesn't have to know the key shape.
enum DailyTipDismissal {
    private static let key = "dailyTipDismissed"

    static func isDismissed(tip: DailyTip, childId: String, date: Date = Date()) -> Bool {
        let dayKey = Self.dayKey(for: date)
        return UserDefaults.standard.string(forKey: "\(key)_\(childId)") == "\(dayKey)_\(tip.id)"
    }

    static func dismiss(tip: DailyTip, childId: String, date: Date = Date()) {
        let dayKey = Self.dayKey(for: date)
        UserDefaults.standard.set("\(dayKey)_\(tip.id)", forKey: "\(key)_\(childId)")
    }

    private static func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

#Preview {
    VStack(spacing: 16) {
        DailyTipCard(childId: "preview", tip: DailyTipRegistry.all[0], isDismissed: .constant(false))
        DailyTipCard(childId: "preview", tip: DailyTipRegistry.all[12], isDismissed: .constant(false))
        DailyTipCard(childId: "preview", tip: DailyTipRegistry.all[24], isDismissed: .constant(false))
        DailyTipCard(childId: "preview", tip: DailyTipRegistry.all[36], isDismissed: .constant(false))
    }
    .padding()
    .background(Color.dsBackground)
}
