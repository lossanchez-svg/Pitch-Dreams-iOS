# Signature Move Hero Clips — Self-Shoot List

Phone-friendly shoot list for the 10 launch signature moves. Each clip lands
in `PitchDreams/Resources/` as the filename in column 3, then auto-resolves
through the three-tier render in `SignatureMoveOverviewView` (video → Rive →
placeholder). See [ARCHITECTURE.md](./ARCHITECTURE.md) for the iOS plumbing.

## Setup that makes them feel like one reel

- **Same kit** every clip (navy + gold ideal; use whatever you actually own)
- **Same field** (one location = one lighting profile)
- **Golden hour** — 45 min before sunset. Biggest single "studio" tell.
- **Phone**: shoot landscape 1080p 30fps; crop to 9:16 portrait in CapCut after.
  Do NOT shoot 4K or HDR (file bloat, conversion headaches).
- **Low angle** — phone propped on the ground or against a shoe. Ankle-level
  framing makes amateur shots feel cinematic.
- **10 takes per move** — first 3 will be stiff. Keepers are usually takes 7–10.
- **Slate each take**: clap your hands once on camera before the move. Makes
  trimming in post 10× faster.

## Already-authored moves (drills shipped; hero clip is the missing piece)

| Move | Filename | Beats to film | Camera | Difficulty |
|---|---|---|---|---|
| **Scissor** | `scissor_hero.mp4` | Stand over still ball → right foot arcs OUTWARD around ball (no contact) → plants close → LEFT foot pushes ball away with inside | Profile, ankle-height | ⭐⭐ |
| **Body Feint** | `body_feint_hero.mp4` | Dribbling forward → sharp shoulder/hip dip to one side → explode opposite direction | 3/4 angle, waist-up to catch lean | ⭐⭐ |
| **La Croqueta** | `la_croqueta_hero.mp4` | Jog with ball on one foot → sharp lateral roll across body to opposite inside → redirect 45° | Low waist-down gimbal/handheld | ⭐⭐⭐ |

## Placeholder moves (locked tiles; hero clip unlocks them visually)

| Move | Filename | Beats to film | Camera | Difficulty |
|---|---|---|---|---|
| **Step-Over** | `step_over_hero.mp4` | Lift foot UP and OVER ball (vertical, like stepping over a puddle) → push with outside of other foot | Profile, ankle-height | ⭐⭐ |
| **Elastico** | `elastico_hero.mp4` | ONE foot only: push ball OUT with outside → snap back IN with inside, no foot replant | Low front, ankle-height | ⭐⭐⭐⭐ |
| **Rainbow Flick** | `rainbow_flick_hero.mp4` | Squeeze ball between dominant heel and weak-foot sole → flick UP and OVER your head | Side angle, captures the full arc | ⭐⭐⭐ |
| **Rabona** | `rabona_hero.mp4` | Plant strong foot outside ball → swing kicking leg BEHIND standing leg → strike with inside | Side or directly behind | ⭐⭐⭐⭐⭐ |
| **Maradona Turn** | `maradona_turn_hero.mp4` | Sole-drag ball → plant → 360° pivot on planting foot → continue with first foot's outside | Top-down or wide profile | ⭐⭐⭐⭐ |
| **Zidane Roulette** | `zidane_roulette_hero.mp4` | 360° spin while shielding ball: drag-drag both feet alternating, ball stays glued | Top-down ideal | ⭐⭐⭐⭐ |
| **Scorpion Kick** | `scorpion_kick_hero.mp4` | ⚠️ **Do NOT self-shoot.** Diving + heel-kick mid-air, injury-prone. Source from Storyblocks instead. | — | ⭐⭐⭐⭐⭐ |

## When you're back with footage

1. Dump all raw files into `~/Pitch-Dreams-iOS/raw-footage/` (any filenames —
   I'll figure out which is which).
2. Tell me which take number to use per move (e.g., "scissor: take 8, body
   feint: take 5"). Or let me pick.
3. I'll handle: 9:16 crop, color grade with the teal-amber LUT, sound design
   from Pixabay, trim to 6–8 s, ffmpeg encode at H.264 / 2.5 Mbps, drop into
   `Resources/`, wire each move's `heroDemoAsset` to the animation registry.

## Quick technique-accuracy checklist before each shoot

For every move, watch a 30-second YouTube reference clip first. The most
common self-shoot failure is muscle memory drifting your version away from
the canonical move (your scissor becomes a step-over, your croqueta becomes
a regular pass). Reference clips reset that.

| Move | Search term that pulls clean references |
|---|---|
| Scissor | `scissor feint tutorial slow motion` |
| Body Feint | `body feint dribbling neymar slow` |
| La Croqueta | `la croqueta iniesta tutorial` |
| Step-Over | `step over robinho slow motion` |
| Elastico | `elastico ronaldinho tutorial` |
| Rainbow Flick | `rainbow flick slow motion tutorial` |
| Rabona | `rabona pass tutorial` |
| Maradona Turn | `maradona turn tutorial slow` |
| Zidane Roulette | `roulette zidane tutorial slow` |

## Safety

- Pick a flat surface (turf or short-grass pitch). No concrete, no dewy
  morning grass (slip risk on lateral moves).
- Warm up. Croqueta and Elastico in particular load the standing-foot ankle.
- Skip moves your body says no to. The drills will work fine without their
  hero — placeholder tier (play-button graphic) handles it.
