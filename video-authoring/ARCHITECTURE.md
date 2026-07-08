# Video Hero Pipeline — iOS Architecture

Replace the Rive hero path with MP4 video. Canvas keyframe renderer stays as
the fallback and as the primary for technique-breakdown diagrams (where a
clean arrow/foot-path is pedagogically better than video).

## File changes (minimal)

### 1. Extend `TechniqueAnimation` with an optional video name

`PitchDreams/Core/Animation/TechniqueAnimation.swift` — add one field:

```swift
struct TechniqueAnimation: Codable, Equatable {
    let assetId: String
    let viewAngle: ViewAngle
    let keyframes: [TechniqueKeyframe]
    let loops: Bool
    let loopPauseSeconds: TimeInterval
    let videoAssetName: String?   // NEW: "scissor_hero" → scissor_hero.mp4
    let riveAssetName: String?    // kept for now; may remove later
    // ...
}
```

### 2. New `VideoTechniqueView`

`PitchDreams/Core/Animation/VideoTechniqueView.swift` — mirrors
`RiveTechniqueView`'s fail-init pattern so the caller can fall through to the
Canvas renderer when the MP4 isn't bundled:

```swift
import SwiftUI
import AVKit

struct VideoTechniqueView: View {
    let assetName: String
    private let player: AVPlayer

    init?(assetName: String) {
        guard let url = Bundle.main.url(forResource: assetName, withExtension: "mp4") else {
            return nil
        }
        self.assetName = assetName
        let item = AVPlayerItem(url: url)
        self.player = AVPlayer(playerItem: item)
        self.player.isMuted = true               // respect silent switch; captions supply the audio
        self.player.actionAtItemEnd = .none
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item, queue: .main
        ) { [weak player] _ in
            player?.seek(to: .zero)
            player?.play()
        }
    }

    var body: some View {
        VideoPlayer(player: player)
            .disabled(true)                       // no scrub/controls
            .onAppear { player.play() }
            .onDisappear { player.pause() }
            .accessibilityLabel("Demo video of \(assetName.replacingOccurrences(of: "_", with: " "))")
    }
}
```

### 3. Update the decision point in `TechniqueAnimationView`

Wherever the current Rive-vs-Canvas switch lives, prepend video:

```swift
if let videoName = animation.videoAssetName,
   let video = VideoTechniqueView(assetName: videoName) {
    video
} else if let riveName = animation.riveAssetName,
          let rive = RiveTechniqueView(assetName: riveName) {
    rive
} else {
    canvasBody
}
```

### 4. Bundle the MP4s

Drop `scissor_hero.mp4` etc. into `PitchDreams/Resources/`. Xcodegen picks up
all non-Swift files as bundle resources via the `sources: - PitchDreams` line
in `project.yml`. No project.yml edit needed.

### 5. (Optional) rip out Rive

Since no `.riv` will ship, `RiveRuntime` becomes dead weight. Removing it
saves ~2 MB off the app size and simplifies the dep story. Do this in a
separate PR *after* the first video hero ships and we're confident in the
video path. Keep the Rive code alive in the meantime — zero runtime cost when
no `.riv` files are bundled.

## Encoding target

- **Codec**: H.264 High profile, Level 4.0 (broadest iOS 16+ compatibility)
- **Container**: MP4 (fragmented not required for local playback)
- **Resolution**: 1080 × 1920 portrait (9:16) or 1440 × 1800 (4:5) for tighter
  hero slot. Pick one and keep consistent across all clips.
- **Frame rate**: 30 fps (60 fps has no visible benefit at this size and
  doubles the file)
- **Bitrate**: target 2.5 Mbps VBR — 6 s clip ≈ 1.9 MB
- **Audio**: strip it (`-an` in ffmpeg). The app's TTS owns narration.
- **Color**: BT.709, SDR. No HDR — too many simulators/devices to QA.

FFmpeg one-liner for the final pass after editing:

```bash
ffmpeg -i raw.mov -c:v libx264 -profile:v high -level 4.0 \
  -crf 22 -preset slow -pix_fmt yuv420p \
  -vf "scale=1080:1920:flags=lanczos" \
  -an -movflags +faststart scissor_hero.mp4
```

## Caption/VO bridge

Videos don't carry captions — the existing caption strip keeps working.
`TechniqueKeyframe.caption` and `.voiceover` remain source-of-truth and are
rendered over the video. The keyframe timing (0.0 / 0.7 / 1.3 / 2.0 s) should
align with the video's visible beats, so the video's editor trims to those
marks. This is a content constraint, not a code change.

## Validation

- [ ] MP4 loads from bundle, plays, loops without a hitch on iPhone SE (oldest target)
- [ ] First-frame render happens within 1 frame of view appear (no black flash)
- [ ] Canvas fallback still renders when MP4 is absent
- [ ] Memory doesn't balloon when scrolling past 10 video heroes (test with `xcrun simctl` memory profile)
- [ ] Video respects Low Power Mode (pause when backgrounded)
