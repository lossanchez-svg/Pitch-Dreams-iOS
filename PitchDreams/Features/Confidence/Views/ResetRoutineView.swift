import SwiftUI

/// The rehearsable 5-second mistake reset. Practiced here so it's automatic
/// on the pitch: breath in, slow breath out, cue word, back in the game.
struct ResetRoutineView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("resetCueWord") private var cueWord = ResetRoutine.defaultCueWords[0]

    @State private var startedAt: Date?
    @State private var finished = false

    private var routine: ResetRoutine { ResetRoutine(cueWord: cueWord) }

    var body: some View {
        ZStack {
            Color.dsBackground.ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                if startedAt == nil && !finished {
                    intro
                } else if finished {
                    done
                } else {
                    running
                }
            }
            .padding(Spacing.xl)
        }
    }

    // MARK: - Intro

    private var intro: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            Image(systemName: "arrow.counterclockwise.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color.dsSecondary)

            Text("The 5-second reset")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.dsOnSurface)

            Text("Everyone loses a ball. What great players never lose is the next one. Practice the reset now so it's there when you need it.")
                .font(.system(size: 15))
                .foregroundStyle(Color.dsOnSurfaceVariant)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 10) {
                Text("YOUR RESET WORD")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(Color.dsOnSurfaceVariant)

                HStack(spacing: 8) {
                    ForEach(ResetRoutine.defaultCueWords, id: \.self) { word in
                        Button {
                            cueWord = word
                        } label: {
                            Text(word)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(cueWord == word ? Color.dsSecondary : Color.dsOnSurfaceVariant)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(cueWord == word ? Color.dsSecondary.opacity(0.15) : Color.dsSurfaceContainerHighest)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().stroke(
                                        cueWord == word ? Color.dsSecondary.opacity(0.3) : .clear,
                                        lineWidth: 1
                                    )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.lg)
            .background(Color.dsSurfaceContainer)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))

            Spacer()

            Button {
                withAnimation(.dsSnappy) { startedAt = Date() }
            } label: {
                Text("START THE RESET")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color.dsCTALabel)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(DSGradient.primaryCTA)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                    .dsPrimaryShadow()
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Running

    private var running: some View {
        TimelineView(.animation) { context in
            let elapsed = context.date.timeIntervalSince(startedAt ?? context.date)

            if let active = routine.phase(at: elapsed) {
                VStack(spacing: Spacing.xl) {
                    Spacer()

                    breathCircle(for: active)

                    Text(active.phase.prompt)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.dsOnSurface)
                        .multilineTextAlignment(.center)
                        .id(active.index)

                    Spacer()

                    // Overall progress
                    ProgressView(value: min(elapsed / routine.totalDuration, 1))
                        .tint(Color.dsSecondary)
                }
            } else {
                Color.clear
                    .onAppear {
                        withAnimation(.dsSnappy) {
                            finished = true
                            startedAt = nil
                        }
                    }
            }
        }
    }

    private func breathCircle(for active: (index: Int, phase: ResetRoutine.Phase, progress: Double)) -> some View {
        let scale: Double
        switch active.phase.kind {
        case .breatheIn: scale = 0.55 + 0.45 * active.progress
        case .breatheOut: scale = 1.0 - 0.45 * active.progress
        case .cue: scale = 0.7
        }

        return ZStack {
            Circle()
                .fill(Color.dsSecondary.opacity(0.12))
                .frame(width: 220, height: 220)
            Circle()
                .fill(Color.dsSecondary.opacity(0.25))
                .frame(width: 220 * scale, height: 220 * scale)
            if active.phase.kind == .cue {
                Text("\u{201C}\(cueWord)\u{201D}")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.dsSecondary)
            }
        }
    }

    // MARK: - Done

    private var done: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 52))
                .foregroundStyle(.green)

            Text("You're reset.")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.dsOnSurface)

            Text("That's the whole thing — five seconds, any time, anywhere on the pitch. The mistake is over. The next ball is yours.")
                .font(.system(size: 15))
                .foregroundStyle(Color.dsOnSurfaceVariant)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Button {
                withAnimation(.dsSnappy) {
                    finished = false
                    startedAt = Date()
                }
            } label: {
                Text("RUN IT AGAIN")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(Color.dsOnSurface)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.dsSurfaceContainerHigh)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                    .ghostBorder()
            }
            .buttonStyle(.plain)

            Button {
                dismiss()
            } label: {
                Text("BACK TO IT")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color.dsCTALabel)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(DSGradient.primaryCTA)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                    .dsPrimaryShadow()
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    ResetRoutineView()
}
