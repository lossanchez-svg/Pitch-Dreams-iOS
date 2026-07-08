import SwiftUI
import RiveRuntime

/// SwiftUI wrapper for a bundled Rive animation file (.riv).
///
/// Design:
/// - Fails the initializer (`init?`) when the named .riv file isn't in the
///   bundle — callers use the nil path to fall back to the next tier
///   (placeholder on hero surfaces; never used on drill surfaces).
/// - The actual Rive runtime only loads when a .riv exists, so shipping
///   the SDK dependency without any .riv files costs nothing visually.
/// - Caption and TTS are NOT piped through here. The keyframe engine's
///   captions don't translate 1:1 to Rive (Rive uses state-machine events
///   for captions). When a .riv ships with embedded caption events, a
///   follow-up PR will bridge those into the existing caption strip.
///
/// Status: no .riv files currently ship. MP4 clips via `VideoTechniqueView`
/// are the preferred hero format — Rive remains a second-tier fallback for
/// the unlikely case an animator authors one. See `SignatureMoveOverviewView`
/// for the full video → Rive → placeholder resolution chain.
struct RiveTechniqueView: View {
    let assetName: String
    private let viewModel: RiveViewModel

    /// - Parameter assetName: Basename of a `.riv` file in `Bundle.main`
    ///   (no extension). Returns nil when the file isn't present, so the
    ///   caller can fall back cleanly.
    init?(assetName: String) {
        guard Bundle.main.url(forResource: assetName, withExtension: "riv") != nil else {
            return nil
        }
        self.assetName = assetName
        self.viewModel = RiveViewModel(fileName: assetName)
    }

    var body: some View {
        viewModel.view()
            .accessibilityLabel("Animated demo of \(assetName.replacingOccurrences(of: "_", with: " "))")
    }
}
