# Scissor Hero — Rive Authoring Spec

Authoring source-of-truth for `scissor_hero.riv`, bundled at
`PitchDreams/Resources/scissor_hero.riv` and loaded by
[`RiveTechniqueView`](../../PitchDreams/Core/Animation/RiveTechniqueView.swift).

Fallback path (Canvas keyframes) lives in
[`TechniqueAnimationRegistry.swift`](../../PitchDreams/Core/Animation/TechniqueAnimationRegistry.swift)
under `scissorStillBall` — the `.riv` is the hero-quality version of that same
motion. When the `.riv` is absent from the bundle, the app renders the keyframe
fallback automatically.

## 1. Overview

Still-Ball Scissor, profile view. Four beats over 2.0 s, ball stationary until
beat 4, then left foot pushes it away. Loops with a 0.5 s hold on the final
pose (matches `scissorHero.loopPauseSeconds`).

This spec mirrors the canonical keyframes in `scissorStillBall` so the Rive
render and the Canvas fallback stay visually interchangeable.

## 2. Coordinate mapping

| System | X | Y | Notes |
|---|---|---|---|
| Keyframes (`NormPoint`) | 0.0 = left, 1.0 = right | 0.0 = top, 1.0 = bottom | Normalized; origin top-left; ground plane at y ≈ 0.92 |
| Rive artboard | 0 = left, 1000 = right | 0 = top, 1500 = bottom | Fixed 1000×1500 artboard (see §3). Multiply normalized values by (1000, 1500) |

Player faces **screen-right** (the escape direction is screen-left, so the
lean/explode are visibly "away from the lead foot"). Ball sits at center stance
before beat 4, pushed toward x = 0.22 at beat 4.

## 3. Artboard setup

- **Name**: `ScissorHero`
- **Size**: 1000 × 1500 (2:3 portrait — matches the iOS hero slot aspect)
- **Origin**: top-left
- **Background**: transparent (the iOS screen supplies the gradient)
- **Safe margins**: 80 px all sides — joints and ball never exit this region
- **Reference ground line**: y = 1380 (= 0.92 × 1500)

## 4. Bone hierarchy

Single skeleton, FK driven. Parent → child:

```
root                              (pelvis, world pos = centerOfMass)
├── torso                         (rotates by torsoTilt)
│   ├── neck
│   │   └── head
│   └── shoulders                 (rotates by shoulderTilt, inherits torso)
│       ├── left_arm
│       │   └── left_hand
│       └── right_arm
│           └── right_hand
├── left_hip                      (rotates by leftHipAngle)
│   └── left_knee                 (rotates by leftKneeBend)
│       └── left_ankle
│           └── left_foot         (world pos exposed for IK-verify)
└── right_hip                     (rotates by rightHipAngle)
    └── right_knee                (rotates by rightKneeBend)
        └── right_ankle
            └── right_foot

ball                              (sibling of root; world pos from ballX/ballY)
ball_shadow                       (sibling of ball; follows ballX with fixed y)
foot_glow_left                    (decoration; opacity = leftFootActive ? 1 : 0)
foot_glow_right                   (decoration; opacity = rightFootActive ? 1 : 0)
```

The driver script (§7) publishes both the **joint angles** *and* the **world
foot positions** from `FootState.position`. Designer chooses either:

- **FK path (preferred)**: bind hip/knee rotations to the published angles;
  world foot positions are ignored (the skeleton implies them).
- **IK path**: add a Rive IK constraint from ankle to a data-bound target
  whose position = world foot position. Use this if the FK result drifts from
  the authored foot positions.

## 5. State machine vs. timeline-driven

Two viable Rive-native approaches — pick one:

### Option A (recommended): script-driven, no state machine

The Node script in §7 is the single source of truth. No timeline keyframes; no
state machine transitions. Every animated property flows through the
`ScissorPose` ViewModel. This stays in lockstep with the Swift keyframe data —
if `scissorStillBall` ever gets re-timed, the script's keyframe table updates
and nothing in the editor has to be re-keyed.

### Option B: editor-keyed timeline + script for polish

Key all bone rotations and ball position on a 2.0 s timeline in the editor;
use the script only for decorative effects (ball trail, foot dust). Faster to
polish visually, but **drifts from the Swift keyframes unless kept in sync by
hand**. If we go this route, add a regression test that loads the `.riv`,
samples its ScissorPose VM at t = 0.0, 0.7, 1.3, 2.0, and asserts the values
match `scissorStillBall.keyframes` within a tolerance.

## 6. Data Binding — `ScissorPose` ViewModel

Define in Rive's Data panel. Script writes to this VM every frame; bones and
ball bind their properties to VM fields.

| Field | Type | Range / domain | Bound to |
|---|---|---|---|
| `time` | number | 0 … 2.5 (duration + loopPause) | — (script-internal) |
| `ballX` | number | 0 … 1000 | ball.x |
| `ballY` | number | 0 … 1500 | ball.y |
| `leftFootX` | number | 0 … 1000 | left_foot.x (IK target) |
| `leftFootY` | number | 0 … 1500 | left_foot.y (IK target) |
| `leftFootActive` | boolean | — | foot_glow_left.opacity (0/1) |
| `leftFootSurface` | number (enum) | 0…5 | surface-indicator art layer choice |
| `rightFootX` | number | 0 … 1000 | right_foot.x |
| `rightFootY` | number | 0 … 1500 | right_foot.y |
| `rightFootActive` | boolean | — | foot_glow_right.opacity |
| `rightFootSurface` | number (enum) | 0…5 | — |
| `torsoTilt` | number (radians) | −0.4 … +0.4 | torso.rotation |
| `shoulderTilt` | number (radians) | −0.5 … +0.5 | shoulders.rotation |
| `leftHipAngle` | number (radians) | −0.3 … +0.6 | left_hip.rotation |
| `rightHipAngle` | number (radians) | −0.3 … +0.6 | right_hip.rotation |
| `leftKneeBend` | number (radians) | 0 … 0.6 | left_knee.rotation |
| `rightKneeBend` | number (radians) | 0 … 0.6 | right_knee.rotation |
| `centerOfMassX` | number | 0 … 1000 | root.x |
| `centerOfMassY` | number | 0 … 1500 | root.y |
| `captionIndex` | number | 0 … 3 | caption event trigger (see §9) |

Enum mapping for `*FootSurface` (matches `FootSurface` in `TechniqueAnimation.swift`):
`0 = none, 1 = inside, 2 = outside, 3 = laces, 4 = sole, 5 = heel`.

## 7. Driver script

See [`scissor_hero_driver.luau`](./scissor_hero_driver.luau). It's a **Node
script** (attached to an empty `driver_node` inside the artboard) that:

1. Declares one `Input<Data.ScissorPose>` so the designer wires it to the VM.
2. Advances internal `time` each frame (`advance(seconds)`).
3. Interpolates between the 4 keyframes using the same `Easing` curves as the
   Swift code.
4. Writes every interpolated quantity to the VM.
5. Draws nothing — rendering is pure data-binding.

Keyframe values in the script **must match** `scissorStillBall.keyframes`
byte-for-byte. There's a verification checklist in §10.

## 8. Keyframe table (authoritative)

From `TechniqueAnimationRegistry.swift:336–384`. All `NormPoint` values scale
by (1000, 1500); angles stay in radians.

| t (s) | ball (norm) | leftFoot pos / surface / active | rightFoot pos / surface / active | pose | ease-in |
|---|---|---|---|---|---|
| 0.0 | (0.50, 0.78) | (0.42, 0.92) · none · off | (0.58, 0.92) · none · off | neutral | linear |
| 0.7 | (0.50, 0.78) | (0.40, 0.92) · none · off | (0.78, 0.60) · outside · ON | leanLeft | easeOut |
| 1.3 | (0.50, 0.78) | (0.40, 0.92) · none · off | (0.62, 0.90) · inside · ON | plantLeft | easeOut |
| 2.0 | (0.22, 0.80) | (0.30, 0.84) · inside · ON | (0.58, 0.88) · none · off | explodeLeft | spring |

Pose → joint angle presets are defined in `AvatarPose.kinematics`
(`TechniqueAnimation.swift:117–174`). The driver script duplicates them; if the
Swift side changes a pose, the Luau side must track it.

## 9. Captions & voiceover

Rive's `.riv` does **not** carry captions or TTS — those stay owned by Swift
(`InterpolatedFrame.caption`, `currentKeyframeIndex` → voiceover). The driver
writes `captionIndex` (0…3) to the VM; the iOS side doesn't currently read it.

If we later want the Rive render to drive captions, add an event listener on
`captionIndex` in `RiveTechniqueView` and publish into the existing caption
strip — that's a follow-up PR, explicitly called out in
[`RiveTechniqueView.swift:13-15`](../../PitchDreams/Core/Animation/RiveTechniqueView.swift).

## 10. Loop behavior

- **Total duration**: 2.0 s motion + 0.5 s hold on beat 4 = 2.5 s cycle.
- Script's `time` wraps on `time >= cycle`. During the hold window
  (t ∈ [2.0, 2.5]), the script clamps the playhead to beat 4 values — no
  interpolation past the final keyframe.
- Matches Swift's `frame(at:)` logic at `TechniqueAnimation.swift:258–269`.

## 11. Validation checklist

Before committing `scissor_hero.riv`:

- [ ] Artboard is `ScissorHero`, 1000×1500, transparent bg.
- [ ] `ScissorPose` ViewModel exists with every field in §6.
- [ ] Driver script is attached to `driver_node` and the VM input is bound.
- [ ] Sample VM at t = 0.0, 0.7, 1.3, 2.0:
  - Ball position matches keyframe × (1000, 1500) within 0.5 px.
  - Foot positions match within 0.5 px.
  - Joint angles match `AvatarPose.kinematics` preset within 1e-4 rad.
- [ ] `leftFootActive` / `rightFootActive` flip exactly on the keyframe where
      `FootState.isActive` flips.
- [ ] Loop holds on beat 4 for 0.5 s, then snaps back to beat 0.
- [ ] File is ≤ 150 KB (hero assets budget).
- [ ] Opens in the Rive iOS runtime (`RiveRuntime` SPM package, pinned `from: "6.0.0"`).
- [ ] Run `xcodebuild test -only-testing:PitchDreamsTests` — no regressions in
      `TechniqueAnimationTests` (Canvas fallback still works with the file
      absent, in case someone deletes it).

## 12. Open questions

1. **IK vs FK for feet** — unresolved until the first rig test. Default to FK;
   switch per foot if authored positions visibly drift.
2. **Ball squash on beat 4 push** — not in the keyframe data; add as Rive-only
   polish (scale down Y 5 % during the spring ease) or skip for MVP.
3. **Camera move on beat 4 explode** — small dolly-back (scale artboard 0.98)
   would sell the escape but isn't in the Canvas fallback. Skip for parity,
   revisit once both renderers are visible side-by-side.
