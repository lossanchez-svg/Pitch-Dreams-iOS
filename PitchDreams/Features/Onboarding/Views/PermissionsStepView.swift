import SwiftUI

struct PermissionsStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Free text toggle
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(isOn: $viewModel.freeTextEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Allow Free-Text Notes")
                                .font(.subheadline.weight(.medium))
                            Text("Let your player type notes during sessions. Recommended for ages 14+.")
                                .font(.caption)
                                .foregroundStyle(Color.dsOnSurfaceVariant)
                        }
                    }

                    if viewModel.age < 14 && viewModel.freeTextEnabled {
                        Label("Player is under 14. Consider keeping this off.", systemImage: "info.circle")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .background(Color.dsSurfaceContainerHighest)
                .cornerRadius(12)

                // Training window
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: $viewModel.trainingWindowEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Set Training Window")
                                .font(.subheadline.weight(.medium))
                            Text("Limit when training sessions can be started.")
                                .font(.caption)
                                .foregroundStyle(Color.dsOnSurfaceVariant)
                        }
                    }

                    if viewModel.trainingWindowEnabled {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Start")
                                    .font(.caption.weight(.medium))
                                TextField("08:00", text: $viewModel.windowStart)
                                    .keyboardType(.numbersAndPunctuation)
                                    .padding(10)
                                    .background(Color(.tertiarySystemBackground))
                                    .cornerRadius(8)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("End")
                                    .font(.caption.weight(.medium))
                                TextField("20:00", text: $viewModel.windowEnd)
                                    .keyboardType(.numbersAndPunctuation)
                                    .padding(10)
                                    .background(Color(.tertiarySystemBackground))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.dsSurfaceContainerHighest)
                .cornerRadius(12)

                // Next button
                Button {
                    viewModel.completePermissionsStep()
                } label: {
                    Text("Next")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.dsSecondary)
                        .foregroundColor(.white)
                        .font(.headline)
                        .cornerRadius(12)
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
    }
}
