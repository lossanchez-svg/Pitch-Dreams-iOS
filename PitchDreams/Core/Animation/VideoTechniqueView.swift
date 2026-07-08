import SwiftUI
import AVKit

/// SwiftUI wrapper for a bundled MP4 hero clip.
///
/// Design:
/// - Fails the initializer (`init?`) when the named MP4 isn't in the bundle —
///   callers use the nil path to fall through to Rive or the placeholder.
/// - Auto-loops on item end, muted (the caption strip + coach voice own audio).
/// - Disables user controls; the view is a passive decoration.
/// - Pauses when the view disappears so a scroll past doesn't burn CPU/battery.
///
/// Fallback chain lives in `SignatureMoveOverviewView.heroPlayer`:
/// ```
/// if let videoName = animation.videoAssetName,
///    let video = VideoTechniqueView(assetName: videoName) {
///     video
/// } else if let riveName = animation.riveAssetName,
///           let rive = RiveTechniqueView(assetName: riveName) {
///     rive
/// } else {
///     placeholder
/// }
/// ```
struct VideoTechniqueView: View {
    let assetName: String
    @StateObject private var looper: LoopingPlayer

    /// - Parameter assetName: Basename of an `.mp4` in `Bundle.main` (no
    ///   extension). Returns nil when the file isn't present so the caller
    ///   can fall through cleanly.
    init?(assetName: String) {
        guard let url = Bundle.main.url(forResource: assetName, withExtension: "mp4") else {
            return nil
        }
        self.assetName = assetName
        _looper = StateObject(wrappedValue: LoopingPlayer(url: url))
    }

    var body: some View {
        VideoPlayer(player: looper.player)
            .disabled(true)
            .onAppear { looper.play() }
            .onDisappear { looper.pause() }
            .accessibilityLabel("Animated demo of \(assetName.replacingOccurrences(of: "_", with: " "))")
    }
}

/// Holds the AVPlayer + loop observer so the lifetime is bound to the View's
/// state rather than recreated on every body evaluation.
final class LoopingPlayer: ObservableObject {
    let player: AVPlayer
    private var loopObserver: NSObjectProtocol?

    init(url: URL) {
        let item = AVPlayerItem(url: url)
        self.player = AVPlayer(playerItem: item)
        self.player.isMuted = true
        self.player.actionAtItemEnd = .none
        self.loopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.player.seek(to: .zero)
            self?.player.play()
        }
    }

    deinit {
        if let loopObserver {
            NotificationCenter.default.removeObserver(loopObserver)
        }
    }

    func play()  { player.play() }
    func pause() { player.pause() }
}
