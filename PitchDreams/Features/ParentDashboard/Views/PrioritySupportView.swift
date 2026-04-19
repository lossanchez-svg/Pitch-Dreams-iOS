import SwiftUI
import UIKit

/// Premium parent surface: pre-filled support email with device + account
/// diagnostics so the support team can triage Premium requests quickly.
///
/// We use a plain `mailto:` URL instead of MFMailComposeViewController so
/// the link works whether or not Mail.app is configured — the system falls
/// through to the user's default mail client (or Safari, which then offers
/// the default mail client).
struct PrioritySupportView: View {
    let child: ChildSummary
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var entitlementStore: EntitlementStore
    @State private var mailtoFailed = false

    /// Support address. Update when the support inbox domain is finalized.
    private let supportEmail = "support@pitchdreams.soccer"

    var body: some View {
        List {
            Section {
                Label("Priority Support", systemImage: "star.fill")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.dsAccentOrange)
                Text("Premium subscribers get prioritized responses on account, billing, and feature questions.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.dsOnSurfaceVariant)
            }

            Section("What's covered") {
                bullet("Faster response on account or billing issues")
                bullet("Escalation for training data concerns")
                bullet("Feature requests surfaced to the product team")
            }

            Section {
                Button {
                    openSupportMail()
                } label: {
                    HStack {
                        Image(systemName: "envelope.fill")
                        Text("Contact Support")
                            .font(.body.weight(.semibold))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .foregroundStyle(Color.dsOnSurfaceVariant)
                    }
                }

                if mailtoFailed {
                    Text("Couldn't open mail. Email us directly at \(supportEmail).")
                        .font(.caption)
                        .foregroundStyle(Color.dsError)
                }
            } header: {
                Text("Send us a note")
            } footer: {
                Text("Opens your mail app with a pre-filled subject + diagnostic details.")
            }

            Section("Diagnostic details") {
                ForEach(diagnostics.previewLines, id: \.self) { line in
                    if line.isEmpty {
                        Spacer().frame(height: 2)
                    } else if line.hasPrefix("——") {
                        Text(line)
                            .font(.system(size: 11, weight: .heavy).monospaced())
                            .foregroundStyle(Color.dsOnSurfaceVariant)
                    } else {
                        Text(line)
                            .font(.system(size: 12).monospaced())
                            .foregroundStyle(Color.dsOnSurface)
                    }
                }
            }
        }
        .navigationTitle("Priority Support")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Helpers

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(Color.dsSecondary)
                .padding(.top, 2)
            Text(text)
                .font(.system(size: 13))
        }
    }

    private var diagnostics: SupportDiagnostics {
        SupportDiagnostics.snapshot(
            tier: entitlementStore.activeTier,
            childId: child.id,
            childName: child.nickname,
            parentEmail: authManager.currentUser?.email
        )
    }

    @MainActor
    private func openSupportMail() {
        mailtoFailed = false
        let subject = "PitchDreams Premium Support — \(child.nickname)"
        let body = """
        Hi PitchDreams Team,



        \(diagnostics.asEmailBlock)
        """

        var components = URLComponents()
        components.scheme = "mailto"
        components.path = supportEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]

        guard let url = components.url else {
            mailtoFailed = true
            return
        }
        UIApplication.shared.open(url) { success in
            if !success { mailtoFailed = true }
        }
    }
}

#Preview {
    NavigationStack {
        PrioritySupportView(
            child: ChildSummary(
                id: "preview", nickname: "Alex", age: 11,
                position: "Midfielder", avatarId: "wolf"
            )
        )
        .environmentObject(AuthManager())
        .environmentObject(EntitlementStore())
    }
}
