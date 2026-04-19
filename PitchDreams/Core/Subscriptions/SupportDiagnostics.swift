import Foundation
import UIKit

/// Collects the diagnostic payload appended to every Premium support email.
/// Kept small and human-readable so parents can review it before hitting
/// Send — the block is rendered in the view as a preview, not hidden.
///
/// Support routing on the inbound side uses the `Child ID` line to pull the
/// account + training data quickly, and the `Tier` line to triage Premium
/// requests ahead of free-tier volume.
struct SupportDiagnostics {
    let appVersion: String
    let appBuild: String
    let iosVersion: String
    let deviceModel: String
    let tier: SubscriptionTier
    let childId: String?
    let childName: String?
    let parentEmail: String?

    /// Rendered version of the diagnostics block. Ends with a blank line
    /// so body text above it doesn't collide with the "-- Diagnostics --"
    /// divider when the parent types their issue description.
    var asEmailBlock: String {
        var lines: [String] = [
            "",
            "—— Diagnostics ——",
            "App: \(appVersion) (\(appBuild))",
            "iOS: \(iosVersion) · \(deviceModel)",
            "Tier: \(tier.displayName)",
        ]
        if let childId { lines.append("Child ID: \(childId)") }
        if let childName { lines.append("Child: \(childName)") }
        if let parentEmail { lines.append("Account: \(parentEmail)") }
        lines.append("")
        return lines.joined(separator: "\n")
    }

    /// Multi-line preview shown in the UI. Same content as the email block
    /// so there's no surprise when the draft opens.
    var previewLines: [String] {
        asEmailBlock
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)
    }

    // MARK: - Factory

    @MainActor
    static func snapshot(
        tier: SubscriptionTier,
        childId: String?,
        childName: String?,
        parentEmail: String?
    ) -> SupportDiagnostics {
        SupportDiagnostics(
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—",
            appBuild: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—",
            iosVersion: UIDevice.current.systemVersion,
            deviceModel: Self.hardwareModel(),
            tier: tier,
            childId: childId,
            childName: childName,
            parentEmail: parentEmail
        )
    }

    /// Raw machine identifier (e.g. "iPhone15,3") — more useful for support
    /// triage than the generic "iPhone"/"iPad" from `UIDevice.model`.
    private static func hardwareModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        let bytes = mirror.children.compactMap { $0.value as? Int8 }.filter { $0 != 0 }
        return String(bytes: bytes.map { UInt8(bitPattern: $0) }, encoding: .ascii) ?? UIDevice.current.model
    }
}
