import SwiftUI

/// Shown on the Training screen when the child's check-in indicates they're
/// too sore or tired to push hard. Offers a structured light-movement routine
/// that still awards (reduced) XP so the streak survives an honest rest day.
struct RestDayCardView: View {
    let childId: String
    let reason: RestReason

    @State private var navigateToStretching = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack(spacing: 10) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "#8B5CF6"))
                Text("REST DAY SUGGESTED")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(3)
                    .foregroundStyle(Color(hex: "#8B5CF6"))
                Spacer()
            }

            Text(reason.title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color.dsOnSurface)

            Text(reason.message)
                .font(.system(size: 14))
                .foregroundStyle(Color.dsOnSurfaceVariant)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                navigateToStretching = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "figure.cooldown")
                        .font(.system(size: 16))
                    Text("5-MIN STRETCH ROUTINE")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .tracking(2)
                }
                .foregroundStyle(Color.dsOnSurface)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: "#8B5CF6").opacity(0.22))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(Color(hex: "#8B5CF6").opacity(0.5), lineWidth: 1)
                )
            }

            Text("You'll earn 20 XP and your streak stays alive.")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.dsOnSurfaceVariant)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(Spacing.xl)
        .background(Color.dsSurfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .ghostBorder()
        .navigationDestination(isPresented: $navigateToStretching) {
            StretchingRoutineView(childId: childId)
        }
    }

    enum RestReason {
        case highSoreness
        case tired
        case both

        var title: String {
            switch self {
            case .highSoreness: return "Your body's telling you something."
            case .tired:        return "You're running on empty today."
            case .both:         return "Sore AND tired? Today's for recovery."
            }
        }

        var message: String {
            switch self {
            case .highSoreness:
                return "You logged high soreness. Pushing through doesn't make you tougher — it makes you slower tomorrow. A structured stretch still counts."
            case .tired:
                return "You said you're tired. A 5-minute stretch is plenty to keep the habit alive without grinding a tired body into the ground."
            case .both:
                return "Sore and tired is a two-signal rest day. A light stretch still counts toward your streak and lets you come back strong."
            }
        }
    }

    /// Decides whether rest-day is suggested for a given check-in.
    static func reason(for checkIn: CheckIn) -> RestReason? {
        let sore = checkIn.soreness.uppercased() == "HIGH"
        let tired = checkIn.mood.uppercased() == "TIRED"
        switch (sore, tired) {
        case (true, true):   return .both
        case (true, false):  return .highSoreness
        case (false, true):  return .tired
        case (false, false): return nil
        }
    }
}

#Preview {
    NavigationStack {
        VStack(spacing: 16) {
            RestDayCardView(childId: "preview", reason: .highSoreness)
            RestDayCardView(childId: "preview", reason: .tired)
            RestDayCardView(childId: "preview", reason: .both)
        }
        .padding()
        .background(Color.dsBackground)
    }
}
