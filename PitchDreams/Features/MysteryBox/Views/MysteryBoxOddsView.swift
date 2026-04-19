import SwiftUI

/// Settings disclosure for the daily mystery box — lists each reward type
/// with its transparent drop rate so parents can see the odds are flat,
/// non-manipulative, and capped.
///
/// Stated directly per the ethical-positioning rule: rewards are earned
/// daily, no money is involved, no gambling-adjacent escalation.
struct MysteryBoxOddsView: View {
    @Environment(\.dismiss) private var dismiss

    private var odds: [(type: MysteryRewardType, rate: Double)] {
        let context = MysteryBoxContext(
            lockedMoveIds: SignatureMoveRegistry.launchMoves.map(\.id),
            availableCosmeticIds: ["placeholder"],
            streakShieldsMaxed: false
        )
        return MysteryBoxEngine.publicOdds(context: context)
            .sorted(by: { $0.rate > $1.rate })
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Mystery box rewards are daily, free, and never tied to money.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.dsOnSurface)
                        Text("Drop rates are fixed — they don't shift based on streaks, spend, or anything else. Parents can disable the mystery box entirely from \(Text("Permissions").italic()).")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.dsOnSurfaceVariant)
                    }
                    .padding(.vertical, 4)
                }

                Section("Drop rates") {
                    ForEach(odds, id: \.type) { entry in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.type.displayName)
                                    .font(.system(size: 14, weight: .semibold))
                                Text(entry.type.rarity.displayName)
                                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                                    .tracking(1)
                                    .foregroundStyle(Color(hex: entry.type.rarity.accentColorHex))
                            }
                            Spacer()
                            Text(percent(entry.rate))
                                .font(.system(size: 15, weight: .heavy, design: .rounded).monospacedDigit())
                                .foregroundStyle(Color.dsOnSurface)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section {
                    Text("These are the raw weights. The app filters out reward types that make no sense in the moment — for example, no \(Text("Free Move Attempt").italic()) drops when every move is already mastered. When a type is filtered, the remaining weights rebalance to 100%.")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.dsOnSurfaceVariant)
                }
            }
            .navigationTitle("Mystery Box Odds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func percent(_ value: Double) -> String {
        let pct = value * 100
        if pct >= 10 {
            return String(format: "%.0f%%", pct)
        }
        return String(format: "%.1f%%", pct)
    }
}
