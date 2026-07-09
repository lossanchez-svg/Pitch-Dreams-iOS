# Video Generation Prompts — Hero Clips

Ready-to-paste prompts for Sora 2 / Veo 3 / Kling 2.1. Each clip is 6 s,
portrait 9:16, same player + kit + field across all drills so the hero reel
feels like one cohesive ad campaign, not a mixed bag.

## Consistency rules (apply to every prompt)

- **Subject**: a 13-year-old male soccer player, short dark hair, athletic
  build, navy-and-gold kit (#0C1E3E jersey, #F4B740 shorts), white cleats,
  shin guards visible.
- **Setting**: manicured soccer pitch at golden hour (45 min before sunset),
  slight haze in the air, stadium seating soft-blurred in the background.
- **Camera package**: shot on ARRI Alexa Mini with anamorphic 35mm lens,
  shallow depth of field (f/2.0), subtle handheld micro-movement.
- **Grade**: teal-and-amber, deep shadows with slight film grain, no
  oversaturation. Think *Ted Lasso* meets Nike's *Winner Stays On* ads.
- **Pace**: 30 fps capture, internal 120 fps slow-mo on the moment of contact.
- **Character reference**: *upload the same still frame* (a generated or
  stock photo of the player in neutral stance) as reference to every prompt
  so the face/body/kit stay locked. Without this, consistency falls apart.

## 1. Scissor Hero — `scissor_hero.mp4`

Matches `scissorStillBall` keyframes (2 s motion + 0.5 s hold).

```
Cinematic portrait 9:16 slow-motion shot, 6 seconds. A 13-year-old male
soccer player in a navy-and-gold kit stands over a stationary white soccer
ball on fresh-cut grass, golden-hour backlight rimming his shoulders. He
executes a textbook scissor feint: right foot sweeps in a slow outward arc
OVER the ball without touching it, body leans sharply left, right foot plants
close to the ball, then an explosive push with the inside of the LEFT foot
rolls the ball diagonally away from camera. Camera is a low-profile 24mm
dolly staying level with the ball, shallow focus on the feet, ball stays
tack-sharp throughout. Grass particles kick up on the plant. Teal-and-amber
grade, subtle anamorphic lens flare on the explosion. No text, no audio.
```

**Alt for Kling (needs more concrete motion cues)**: add "freeze on final
frame for 0.5 seconds" at the end if the model doesn't hold cleanly.

## 2. Inside-Outside Cut — `inside_outside_hero.mp4`

Generic cut-up move; good second hero if you don't have a specific drill yet.

```
Cinematic portrait 9:16 slow-motion, 6 seconds. Same 13-year-old male soccer
player, navy-and-gold kit, dribbling a white ball straight at camera on fresh
grass at golden hour. He pushes the ball right with the OUTSIDE of his right
foot in one touch, plants, then immediately slices it left with the INSIDE
of the same right foot on the very next step — a sharp V-cut. Ball leaves a
thin streak of dew behind it on each touch. Low 24mm lens tracking him from
waist-down on a gimbal, shallow focus on the boot, legs cross-cut the frame.
Teal-and-amber grade, crisp contact sound design implied but no audio. Hold
final frame for 0.5 seconds.
```

## 3. First-Touch Volley — `first_touch_hero.mp4`

Feeds the existing FirstTouch feature (`Features/FirstTouch/`).

```
Cinematic portrait 9:16 slow-motion, 6 seconds. Same 13-year-old male player,
navy-and-gold kit, receives a waist-high driven pass on the open pitch at
golden hour. He cushions the ball with the inside of his right foot,
dropping it dead an inch from his planted foot — zero bounce. Camera is a
low 35mm at his ankle level, racks focus from the incoming ball onto the
moment of contact. Ball visibly compresses against the boot then drops flat.
Micro-dust particles lift on the touch. Teal-and-amber grade, hint of slow
shutter motion blur on the incoming ball, tack-sharp on the receiving foot.
Hold final frame for 0.5 seconds.
```

## 4. Croqueta — `croqueta_hero.mp4`

The Iniesta / classic roll-across move.

```
Cinematic portrait 9:16 slow-motion, 6 seconds. Same 13-year-old male player,
navy-and-gold kit, jogging with the ball at his right foot on fresh pitch
at golden hour. Mid-stride, he rolls the ball laterally with the INSIDE of
his right foot across his body and seamlessly meets it with the INSIDE of
his left foot, redirecting it 45 degrees left — one fluid motion, no pause.
Low 24mm gimbal tracking him waist-down, ball stays dead-center in frame as
it crosses between his feet. Grass kicks up on the left-foot redirect. Teal-
and-amber grade, shallow focus, subtle whip-pan on the direction change.
Hold final frame for 0.5 seconds.
```

## Editing pass (where "studio" actually happens)

AI output is ~70% of the way there. The last 30% — the thing that makes it
feel like a Nike ad instead of a demo reel — is post-processing in CapCut or
DaVinci Resolve (both free):

1. **Speed ramp**: full-speed approach (0–2 s) → 25% speed on contact
   (2–4 s) → 60% speed on explosion/follow-through (4–6 s). The drama
   is entirely in the ramp.
2. **Sound design**: drop in three cues from Artlist / Epidemic Sound:
   - A sub-bass whoomph on the plant/contact frame
   - A high-frequency tick on the push-away
   - Soft field ambience under the whole clip (wind, distant whistle)
   Even though the app mutes audio at runtime, the TTS layer will feel
   *right* over a clip that was edited *to* sound.
3. **Graphic overlays** (optional): one kinetic title card at t=0
   ("THE SCISSOR" stacked typography, out by t=0.5), one technique callout
   at the plant moment ("PLANT CLOSE", 3-frame fade). Generate in Figma,
   export as PNG sequence, overlay in the editor.
4. **Color grade**: apply the same LUT to every clip. Free LUTs from
   GroundControl (groundcontrolcolor.com) — "Premiere Gold" is a solid start
   for the teal-amber look.
5. **Final export** via the ffmpeg command in ARCHITECTURE.md §"Encoding".

## Negative prompts (what to tell the model to avoid)

Add to every prompt when the model supports negatives:

```
Negative: cartoon, animated, 3D rendered, video game, low resolution, blurry,
distorted limbs, extra fingers, wrong number of legs, ball clipping through
foot, floating ball, unnatural gait, two players, audience cheering, crowd
noise, on-screen text, UI overlays, logos, brand marks.
```

## Generation workflow

1. Lock the character reference image FIRST. Generate 20 stills of the
   player in neutral stance; pick the best one. Use it as image-reference
   for every clip.
2. Generate 5 variants of clip 1 (Scissor). Pick the best. Total cost so far:
   ~$3–6 depending on tool.
3. Iterate: if variant is 80% right but ball physics are off, re-prompt with
   more concrete motion language ("ball rolls 4 feet to the left in 0.4
   seconds, staying on the ground").
4. Once clip 1 looks right, the *same prompt skeleton* reuses for clips 2–4;
   only the action description changes.
5. Edit all four in one CapCut project — consistent grade, consistent sound
   palette, consistent title cards.

Expected yield: 4 final clips from ~30 generations, ~4 editing hours.
