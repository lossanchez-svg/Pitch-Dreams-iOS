# Stitch Prompts — Launch Mockup Queue

Paste-ready prompts for Google Stitch (`stitch.withgoogle.com`). One prompt per
screen. Run in priority order A → E; stop at any time and come back later.

## Working rules

- **Save each output using the exact name given in the heading** (`player_card_front`, etc.). The iOS code references these names and we want parity.
- **Paste the "Global preamble" into every Stitch chat first** so the AI holds the design system in context. Then paste the screen-specific prompt below it.
- When a prompt lists variants/states (e.g., locked / unlocked / mastered), ask Stitch for each variant as a separate frame in the same output.
- Export each frame as PNG and drop into `proposals/stitch/<mockup_name>.png` or send the screenshots in chat — I'll implement from whichever you prefer.
- If Stitch drifts from the design system, the fix is usually: paste the global preamble again, then re-prompt the specific screen.

## Global preamble (paste first, every conversation)

> You are designing iOS 17 screens for **PitchDreams** — a dark-themed youth
> soccer training app for ages 8–18. Enforce this design system strictly on
> every output.
>
> **Canvas:** 393×852 pt iPhone portrait (iPhone 17 Pro). Safe-area aware.
>
> **Colors (hex):**
> - Background `#0C1322` (Starlight Pitch)
> - Surface `#191F2F`, Surface-Low `#121828`, Surface-High `#232A3C`
> - Accent orange `#FF6B2C` (primary), Cyan `#46E5F8` (secondary), Gold `#FFE9BD` (tertiary)
> - CTA gradient: peach `#FFE6DE` → `#FFD4C8`
> - Error red `#EF4444`, Success green `#10B981`, Purple `#8B5CF6`
>
> **Typography:**
> - SF Rounded throughout, mostly heavy/bold
> - Labels UPPERCASE with 2–3 pt letter-spacing, 9–11 pt
> - Body 14 pt medium; Headings 18–24 pt heavy
> - Display 48–64 pt heavy with monospaced digits for numbers
>
> **Components:**
> - 16 pt rounded corners on cards; 24 pt on hero surfaces
> - 1 px ghost border = `white 5% opacity`
> - Capsule CTAs 56 pt tall, full-width, with orange→peach gradient + subtle shadow
> - Icons: SF Symbols; treat premium icons as `.symbolRenderingMode(.hierarchical)` when multi-color
>
> **Forbidden:** `.regularMaterial` / translucent blurs, iOS default blues/grays
> anywhere, light-mode surfaces, Helvetica / SF Pro (this app is SF Rounded
> only), gradient backgrounds except where explicitly specified.
>
> **Audience:** avatars are anthropomorphic animals (Wolf / Lion / Eagle /
> Fox / Shark / Panther / Bear) at one of three evolution stages (Rookie /
> Pro / Legend). When a screen shows an avatar, show the Wolf at Rookie
> stage as the canonical placeholder.
>
> I will send you a series of screens to design. For each, produce ONE
> deliverable frame (or multiple frames if variants are requested) and
> nothing else — no extra art, no marketing copy.

---

## Priority A — Player Card (Week 3 blocker, 4 screens)

Drive spec: `proposals/TRACK_E_STICKINESS_SPEC.md` §E1.

### 1. `player_card_front`

> **Screen: `player_card_front`** — canonical trading-card-style identity card.
> This is the single most-shared screen; it will also render at 1080×1440 for
> social export, so design it to look great at both sizes.
>
> **Aspect:** 3:4 portrait card, 340 wide × 453 tall inside the screen (rest
> is background + share hint).
>
> **Card composition (top → bottom):**
> 1. **Header row (24 pt padding):** left = small club-crest badge (48×48,
>    rounded-12, gold stripe pattern, star SF Symbol centered). Right = huge
>    overall rating "87" in Display 56 heavy, above the word "OVR" in label
>    style.
> 2. **Avatar region (centered, 180 tall):** Wolf Rookie anthropomorphic
>    illustration on a subtle radial-orange glow. Avatar shadow below.
> 3. **Identity block:** position badge `MID` (small chip, cyan background,
>    uppercase). Below it: archetype tag "SPEEDSTER" in orange, 16 pt heavy,
>    tracking 3. Below that: a thin optional tagline "Fast feet, faster brain."
>    in 12 pt italic, gold, opacity 0.8.
> 4. **Stat grid (2×2, 32 pt padding, 16 pt gutter):** four stat tiles with
>    icon on top (SF Symbol colored by archetype accent), value in 32 pt
>    heavy, 3-letter label below. Stats shown: SPD 92, TCH 78, VIS 85, WRK 80.
> 5. **Move loadout row:** 4 small square slots (56×56, rounded 12), spacing
>    12. Each slot has a move icon + tiny label. Fill all 4 with placeholder
>    icons ("scissors", "figure.walk.motion", "arrow.triangle.swap",
>    "arrow.left.and.right"). If Stitch needs filler names: Scissor, Step-Over,
>    Body Feint, La Croqueta.
> 6. **Footer:** small "PITCHDREAMS" wordmark in 9 pt heavy tracking 4, gold,
>    opacity 0.4.
>
> **Frame:** outer 1 px gradient border (archetype orange → warm yellow),
> 24 pt rounded corners, elevated drop shadow. Card background is a deep
> Starlight Pitch with a subtle vignette.
>
> **Outside the card on the screen:** back-chevron + "MY CARD" title in
> nav bar, share icon top-right. At the bottom, a small helper "Long-press
> to AirDrop. Tap to edit." in 11 pt medium, secondary text.

### 2. `player_card_editor`

> **Screen: `player_card_editor`** — step-based editor for customizing the
> player card. Produce 6 frames (one per step) in a single output.
>
> **Frame A — Archetype picker:** horizontal snap scroll of 8 archetype
> cards (Speedster, Playmaker, The Wall, Magician, Finisher, Engine, Sweeper,
> All-Rounder). Each card 240×320, shows a hero avatar pose + archetype name
> + 6-stat spider radar. Archetype accent color is the card's glow.
>
> **Frame B — Stat selection:** "Pick 4 of 6 to display" header. A 2×3 grid
> of stat chips (SPD/TCH/VIS/SHT/WRK/COM) each 120×110 with icon + current
> numeric value (auto-computed from training). Selected chips get an orange
> checkmark and cyan outline. Below the grid: live card preview (shrunk to
> 60% scale) so the user sees their choices reflected.
>
> **Frame C — Move loadout:** "Pick up to 4 Signature Moves" header.
> Horizontal scroll of unlocked moves (show 3 unlocked + 2 greyed locked).
> Selected moves animate into 4 bottom slots. Below: live card preview.
>
> **Frame D — Club design:** primary color swatch row (8 colors), secondary
> color swatch row (8 colors), crest pattern grid (Solid, Stripes, Chevron,
> Split — 4 tiles), crest symbol grid (star, shield, lightning, paw, flame,
> crown — 6 tiles). Live mini card on right side.
>
> **Frame E — Frame picker:** vertical list of card frames: Standard, Bronze
> (Pro stage req), Silver (Legend req), Gold (30-day streak req), Legendary
> (100-day streak), Platinum Rare (mystery box drop), Founders (subscription).
> Locked frames show a lock icon and the unlock condition in small text.
>
> **Frame F — Preview + Save:** full-size card preview at the top. "Save Card"
> primary CTA at bottom. "Share after saving" checkbox.

### 3. `player_card_share`

> **Screen: `player_card_share`** — share sheet presentation for the card.
>
> **Layout:**
> - Full card preview centered, 80% scale, orange glow
> - Below the card: 5 share-action tiles in a horizontal row — each 72×72,
>   icon + label: AirDrop (SF `airplay`), Messages (`message.fill`),
>   Instagram (camera icon), Save to Photos (`square.and.arrow.down`),
>   Copy Link (`link`).
> - Below the row: a small "The card is saved locally. Sharing sends the
>   image only — no account info." helper text in 11 pt secondary.
> - Bottom: "Done" text button.

### 4. `player_card_back`

> **Screen: `player_card_back`** — flip-side of the trading card showing
> career totals and achievements. Same 3:4 card canvas, same frame treatment
> as `player_card_front`.
>
> **Composition (top → bottom):**
> 1. Header: "CAREER" label on left, "Season 1" on right.
> 2. **Career totals grid (3×2):** Sessions, Minutes trained, XP earned,
>    Days streak (all-time best), Personal bests, Pitches visited. Each
>    tile: value (24 pt heavy, monospace digits) on top, label below.
> 3. **Signature moves mastered:** "3 of 10" small header, then a horizontal
>    row of 10 move icons — 3 in color, 7 greyed. Scroll if needed.
> 4. **Pitch history:** 4 small chip cards listing named pitches ("Home
>    Pitch", "Summer Camp Field", "Club A Field", "Park"). Each shows visits
>    count.
> 5. **Achievements row:** 5 badge icons (gold glow), rest greyed.
> 6. **Flip-back hint:** "Tap to flip" at bottom, 10 pt label, opacity 0.4.

---

## Priority B — Signature Moves Learning Flow (11 screens)

Drive spec: `proposals/TRACK_E_SIGNATURE_MOVES_DETAIL.md` §Learning-Flow UI.

### 5. `signature_moves_library`

> **Screen: `signature_moves_library`** — grid of all signature moves with
> rarity indicators and progress states.
>
> **Top:** title "SIGNATURE MOVES" in 12 pt heavy tracking 3. Subtitle
> "3 of 10 mastered" in 14 pt bold on right. Below: horizontal filter pills
> — All, Common, Rare, Epic, Legendary, Unlocked, In Progress — pill-selected
> state cyan.
>
> **Grid:** 2 columns, 12 pt gutter. Each tile 170×200:
> - Rarity ribbon at top (Common=slate, Rare=cyan, Epic=purple, Legendary=gold)
> - Icon hero (56 pt SF symbol) centered, 96 pt vertical space
> - Move name 14 pt bold below
> - 3-dot progress indicator (stage dots): filled orange if started, cyan ring
>   if current, empty if locked
> - "Mastered" checkmark overlay + gold glow if mastered
> - Fully locked tiles are desaturated + padlock top-right
>
> **Produce 10 tiles** with these names and states:
> - Scissor (common, mastered, gold checkmark)
> - Step-Over (common, in progress, 2/3 dots filled)
> - Body Feint (common, in progress, 1/3 dots filled)
> - La Croqueta (rare, locked, padlock)
> - Elastico (rare, locked)
> - Rainbow Flick (common, locked)
> - Rabona (rare, locked)
> - Maradona Turn (epic, locked)
> - Zidane Roulette (epic, locked)
> - Scorpion Kick (legendary, locked, extra shimmer)

### 6. `signature_move_overview`

> **Screen: `signature_move_overview`** — hero entry page for a single move
> (use "Scissor" as the reference).
>
> **Composition (scrollable, top → bottom):**
> 1. **Hero demo player (top 280 pt):** play/pause button, speed toggle
>    (1× / 0.5×), loop toggle. Background is a stylized pitch with a frozen
>    Wolf avatar mid-scissor. Progress scrubber at bottom.
> 2. **Title block:** "Scissor" in 28 pt heavy. Rarity badge "Common" slate
>    pill. Difficulty pill "Beginner". Famous-for quote in italic small text:
>    *"Cristiano Ronaldo's go-to."*
> 3. **Description card:** 3 lines of plain language. Below: "Young mode"
>    toggle for kids ≤11 (shows `descriptionYoung` variant when on).
> 4. **3-stage vertical stepper:**
>    - **Stage 1 — Groundwork (phase icon: eye)** "The Fake" · 2 drills · 41 reps · ✓ complete
>    - **Stage 2 — Technique (phase icon: soccer ball)** "With the Ball" · 3 drills · 0/75 reps · IN PROGRESS
>    - **Stage 3 — Mastery (phase icon: flame)** "Sell It at Speed" · LOCKED
>    Each step has its phase icon, name, drill count, rep progress bar, state.
> 5. **Coach tip card:** dark surface, "COACH TIP" label, body text:
>    *"The fake is sold by the lean, not the foot. Your shoulders and hips
>    go with the swing, then explode opposite."*
> 6. **Sticky bottom CTA:** "CONTINUE STAGE 2" primary orange capsule.

### 7. `signature_move_stage_intro`

> **Screen: `signature_move_stage_intro`** — shown before the first drill
> in a stage (use Scissor → Stage 2 "With the Ball" as the reference).
>
> **Top:**
> - Phase icon (soccer ball) 48 pt, cyan
> - "STAGE 2 · TECHNIQUE" label
> - "With the Ball" 26 pt heavy
> - "Now add the ball. Start with a still ball, then walking, then past a cone." 14 pt secondary, 3-line body
>
> **Drill list (3 numbered cards):**
> Each card: circular number badge (01, 02, 03), drill title ("Still Ball
> Scissor" / "Walking Scissor" / "Cone Escape"), drill-type chip (with-ball
> icon + label), target reps + duration, "0/30" progress pill. Drill 1 has
> checkmark-complete state; Drill 2 is "NEXT"; Drill 3 is "LATER".
>
> **Secondary link** below list: "Review Stage 1" 12 pt underlined cyan.
>
> **Bottom sticky CTA:** "START DRILL 1 · STILL BALL SCISSOR" orange capsule.

### 8. `signature_move_drill_player_watch`

> **Screen: `signature_move_drill_player_watch`** — WATCH-type drill
> (video-based, user just watches and taps "I've watched this").
>
> **Top video player (60% of screen):**
> - Full-width video area showing pro-footage frame (stylized — a blurred
>   player mid-scissor). Big centered play button. Below the video area:
>   scrubber, current-time / duration, speed toggle (1× / 0.5×), replay icon.
>
> **Middle coach caption strip:** dark surface, "COACH CUE" label in cyan,
> body *"Watch the plant foot. See the hip swivel. Notice the explosion
> the other way."* Typewriter cursor at end to suggest live captioning.
>
> **Below caption — rotating "common mistake" card:** smaller, 2-line text,
> subtle red-tint accent bar on left.
>
> **Bottom sticky:** "I'VE WATCHED THIS" button — cyan outline, becomes
> filled orange after the video completes. Above CTA: small "0:45 remaining"
> helper in 11 pt.

### 9. `signature_move_drill_player_mimic`

> **Screen: `signature_move_drill_player_mimic`** — MIMIC-type drill (no
> ball, practice the motion; user taps rep counter).
>
> **Top:** looping figure animation — large SF Symbol `figure.walk.motion`
> or custom stick-figure at 180 pt, in purple accent. Subtle motion lines.
>
> **Middle:** huge tap-to-count rep counter button — 220×220 orange capsule,
> displays current count in 72 pt heavy monospaced digits. Below it: thin
> progress ring around the counter, progress = reps/target.
>
> **Target label:** "TARGET: 40 REPS" small, below counter.
>
> **Coach cue toast (top-right floating pill):** "Lean into it!" — slides
> in every ~12 seconds.
>
> **Common-mistake card (bottom, above CTA):** one mistake rotating every
> 20s, with emoji bullet.
>
> **Haptic metronome toggle (top-right of screen):** small pill "♩ METRONOME"
> that enables rhythmic haptic pulses.
>
> **Bottom CTA:** "I'M DONE" — greyed out until reps ≥ target, becomes
> orange when met. Secondary link: "Skip drill".

### 10. `signature_move_drill_player_withBall`

> **Screen: `signature_move_drill_player_withBall`** — ball-based drill
> (setup required: cones, space).
>
> **Top setup card:** dark surface, orange info icon, "SETUP" label, body:
> *"Place 1 cone in a 10m straight line path. You and a ball."* Below: "READY"
> primary cyan button that dismisses the setup and starts the demo loop.
>
> **After "Ready" is tapped:**
> - Middle: short demo animation (avatar with ball performing the scissor
>   past a cone — looping)
> - Below demo: timer counting UP in monospace digits (3 pt tracking) + tap
>   rep counter button, same as mimic drill
> - Coach cue toast + rotating mistake card as in mimic
>
> **Bottom CTA:** "I'M DONE" same behavior.
>
> Produce both frames (setup state and drill-running state) in one output.

### 11. `signature_move_drill_player_challenge`

> **Screen: `signature_move_drill_player_challenge`** — CHALLENGE-type drill
> with countdown and live cue toasts. Use "Speed Cone Corridor" (3 cones,
> 90 seconds, 10 clean runs) as the reference.
>
> **Frame A — Countdown:** full-screen dark, massive "3… 2… 1… GO!" in
> display font, pulse animation, cyan glow. At top: challenge type chip
> "⏱️ TIMED" and drill name.
>
> **Frame B — Running:**
> - Top-left: "⏱️ TIMED" chip + drill name
> - Top-right: circular countdown timer 72 pt, orange ring drawing down,
>   shows "00:42" in the center
> - Middle: big rep counter (tap-button or auto, doesn't matter) centered
>   showing "7 / 10 REPS"
> - Floating cue toast (slides in from top): "Clean at speed!" in cyan
>   rounded-pill
> - Rotating mistake card below the counter
> - Bottom: "END EARLY" text button (no-op until complete)
>
> **Frame C — Final screen:** total reps ("8 CLEAN REPS"), time taken
> ("1:30"), primary CTA "I'M DONE", secondary "TRY AGAIN". If target was
> missed, add an encouraging line.
>
> Produce all three frames in one output.

### 12. `signature_move_drill_complete`

> **Screen: `signature_move_drill_complete`** — post-drill confidence rating.
>
> **Composition:**
> - Top: massive checkmark-seal SF Symbol in cyan, 88 pt, scale-in haptic suggestion
> - "Drill Complete!" 28 pt heavy
> - Drill name 18 pt medium secondary
> - Stats row (2 tiles): "REPS" = 42 (or 30/30), "TIME" = 3:15. Values in
>   monospace digits, 28 pt heavy.
> - Confidence prompt: "How did that feel?" 16 pt, below: 5 empty stars
>   (SF Symbol `star.fill`) spaced 20 pt. Stars fill gold on tap/hover. 3 stars
>   = "ok", 4 = "good", 5 = "locked in".
> - Primary CTA: "NEXT DRILL · WALKING SCISSOR" orange capsule (or
>   "COMPLETE STAGE" if last drill).
> - Secondary link: "TRY AGAIN" underlined.

### 13. `signature_move_stage_complete`

> **Screen: `signature_move_stage_complete`** — celebrates finishing a stage
> (mid-journey, not full mastery). Moderate confetti; save the big celebration
> for `signature_move_unlocked_celebration`.
>
> **Composition:**
> - Confetti burst background at top (moderate density, rarity-tier colors
>   for common=slate/white, but this is an intermediate stage so use cyan)
> - Phase icon in rarity color, 64 pt
> - "STAGE 2 · TECHNIQUE" small label
> - "Stage Complete!" 28 pt heavy
> - XP row: "+25 XP" with lightning-bolt icon, count-up style
> - Summary tiles (3): Drills completed (3 of 3), Total reps (78), Time
>   invested (14 min).
> - **Next stage preview card:** phase icon flame, "Next: Stage 3 — Mastery",
>   brief description "Full-speed execution and double-scissor combos."
> - Primary CTA: "BEGIN STAGE 3" or "FINISH AND RETURN LATER" (show both;
>   first is primary, second is text-link)

### 14. `signature_move_record_self`

> **Screen: `signature_move_record_self`** — optional capstone at the end
> of the final stage; user films 10-sec video.
>
> **Frame A — Intro:**
> - Camera icon 72 pt, orange
> - Title "Film Yourself"
> - Body: "10 seconds of your best scissor sequence. We'll save it to your
>   Journey. Only you and your parents can see it."
> - CTA: "OPEN CAMERA" primary, "SKIP THIS" text link.
>
> **Frame B — Recording:**
> - Full-screen camera preview (dark placeholder with "CAMERA VIEW"
>   centered for the mockup), rear-camera default
> - Top-right: camera flip icon
> - Centered red record button (80×80 circle with white inner ring)
> - Progress ring around the record button, filling as seconds elapse
> - Bottom center: "00:04" timer in monospace digits
> - Top banner countdown 3-2-1 on start
>
> **Frame C — Review:**
> - Video playback with controls
> - 3 action buttons: "SAVE" (primary), "RETAKE", "SKIP THIS"
> - Privacy line at bottom: "Saved on this device only."

### 15. `signature_move_unlocked_celebration`

> **Screen: `signature_move_unlocked_celebration`** — full-screen mastery
> celebration; the single most emotional screen in the move journey.
>
> **Composition:**
> - Radial burst background: rarity color (use cyan for Scissor=common
>   → actually gold for variety; produce the frame for RARE La Croqueta in
>   gold/cyan palette instead so it reads premium)
> - Massive "MASTERED!" in 48 pt heavy, slight stroke
> - Move name below: "La Croqueta" in 32 pt bold
> - Move icon 120 pt with heavy glow, rarity-matched
> - Pro attribution under icon: "Iniesta's disappearing act" italic
> - XP banner: "+250 XP" in gold, 24 pt heavy, pulsing
> - 4-slot move-loadout preview at bottom: "ADD TO MY CARD" primary CTA if
>   a slot is free, or "SWAP IN A SLOT" if all 4 filled
> - Secondary: "SHARE THIS" icon button in bottom corner

---

## Priority C — Mystery Box (3 screens)

Drive spec: `proposals/TRACK_E_STICKINESS_SPEC.md` §E3.

### 16. `mystery_box_closed`

> **Screen component: `mystery_box_closed`** — home-dashboard component that
> invites the daily tap. This is a CARD within ChildHomeView, not a full
> screen. Render it as a single card on the standard dark canvas.
>
> **Composition (card 361 wide × 160 tall):**
> - Left 40%: 3D isometric closed box with gold lid hinge, orange bow on
>   top, soft pulse glow. Small sparkles around the box (3-5 stars).
> - Right 60%: "TODAY'S MYSTERY" in 10 pt heavy tracking 3, gold. Below:
>   "TAP TO OPEN" in 18 pt heavy, orange. Below that: small row "🎁 12
>   day box streak" in 11 pt bold secondary.
> - Ghost border + subtle radial orange glow behind the whole card.
>
> **Provide a second "already opened today" state:** grayscale box, small
> "COME BACK TOMORROW" badge, countdown to midnight.

### 17. `mystery_box_opening`

> **Screen: `mystery_box_opening`** — 2-second animation sequence shown when
> the user taps the closed box. Produce 3 frames in sequence for the opening
> phases.
>
> **Frame A (t=0s, shake):** box shaken off-axis 5°, glow pulse cyan.
>
> **Frame B (t=1s, lid lifting):** lid rotating up 30°, vertical light
> beam escaping upward, dust particles around the rim, rarity-tier color
> intensifying (for a legendary drop: gold → white with radial burst).
>
> **Frame C (t=1.5s, reveal ready):** lid fully off-screen-top, box
> dissolved to light, reward icon just beginning to emerge from the light
> column. Camera implicitly pulling back to full-screen reveal.

### 18. `mystery_box_reveal`

> **Screen: `mystery_box_reveal`** — reward reveal screen.
>
> **Produce 3 variants** in one output, for common / rare / legendary drops:
>
> **Variant A — Common (+25 XP):** slate-colored particle halo, small bolt
> icon spinning on top, "+25 XP" in 48 pt heavy orange with count-up style.
> Subtitle "Small bonus. Keep the streak alive." Button "GOT IT" cyan outline.
>
> **Variant B — Rare (Free Move Attempt):** cyan halo, small move icon, title
> "FREE MOVE ATTEMPT" in 20 pt heavy, move name "Rainbow Flick" 16 pt bold,
> flavor text "Try this locked move's drill free today." CTA "TRY IT NOW"
> orange primary, "SAVE FOR LATER" secondary.
>
> **Variant C — Legendary (Platinum Rare frame drop):** gold radial burst,
> crown icon, "LEGENDARY DROP" in 22 pt heavy gold with slight vibrato,
> frame preview below showing the gold card frame, flavor text "Ultra-rare
> Platinum frame for your Player Card." CTA "EQUIP NOW" orange, "VIEW
> COLLECTION" secondary. Subtle confetti + sparkles.

---

## Priority D — IRL Pitch (2 screens, stretch)

Drive spec: `proposals/TRACK_E_STICKINESS_SPEC.md` §E5.

### 19. `pitch_location_banner`

> **Component: `pitch_location_banner`** — home-dashboard banner when GPS
> confirms the child is at a known soccer pitch. Render as a card component
> on the standard ChildHomeView dark canvas.
>
> **Composition:**
> - Left: animated soccer-ball emoji inside a 48×48 rounded-12 cyan tile
> - Middle: "YOU'RE AT THE PITCH" in 10 pt heavy tracking 3, cyan. Below:
>   "HOME PITCH" (or the pitch nickname) 16 pt heavy. Below: "Bonus XP
>   active — 2× multiplier for this session" 11 pt bold gold.
> - Right: small "2×" badge in 18 pt heavy, gold on dark, pulsing.
> - Outer border: 1 px cyan glow + standard ghost border.

### 20. `pitch_home_designation`

> **Screen: `pitch_home_designation`** — flow for naming the user's home
> pitch on first detection, and reviewing saved pitches.
>
> **Frame A — First detection:** large map placeholder 200 tall, pin in
> center (orange). Below: "We spotted you at a new pitch." 16 pt bold.
> Text input "Name this pitch" (placeholder: "Home Pitch"). Toggle "Mark
> as my home pitch" switch. Primary CTA "SAVE", secondary "NOT A PITCH"
> text link.
>
> **Frame B — Saved pitches list:** section header "MY PITCHES · 4".
> List cards for each pitch (nickname, visits count, first visited date).
> First card has a gold "🏠 HOME" badge. Swipe-left reveals "Delete" red
> action. Bottom: "ADD PITCH MANUALLY" text link.

---

## Priority E — Phase 1 retroactive (7 screens, optional)

These are already implemented — only do them if you want visual iteration.
If the implementation looks good enough, skip. Otherwise regenerate via
these prompts and I'll re-implement.

### 21. `home_xp_bar`

> **Component: `home_xp_bar`** — XP progress bar on home dashboard, sits
> just below the rank badge row. Render as a component card on the dark
> canvas.
>
> **Composition (card 361 wide × 80 tall):**
> - Left: circular Wolf avatar at current stage, 40×40, 2-pt cyan ring
> - Center: pill-shaped track (full width ≈ 200 pt, 10 pt tall, surface-
>   highest fill) + orange gradient fill at 68% progress. Below track
>   (small, monospace digits): "340 / 500 XP"
> - Right: "→ Pro" label — small chevron icon + stage name, orange, 12 pt
>   heavy. When current stage is Legend, show "LEGEND" in gold, all-caps,
>   tracking 2, with full-bar gold gradient fill.
> - Ghost border + 16 pt corners.

### 22. `home_xp_earned_toast`

> **Component: `home_xp_earned_toast`** — floating toast shown briefly after
> earning XP.
>
> **Composition (pill 180 wide × 48 tall, auto-sizes to content):**
> - Background: orange 15% opacity, 1 px orange border 30% opacity, capsule
> - "+45 XP" in 16 pt heavy orange (numeric-transition style for count-up)
> - Lightning-bolt SF Symbol after the text, same orange
> - Soft drop shadow; the toast slides in from the top with spring physics.

### 23. `evolution_celebration_enhanced`

> **Screen: `evolution_celebration_enhanced`** — shown when the avatar
> evolves into a new stage. Full-screen.
>
> **Composition:**
> - "EVOLUTION PROTOCOL" label in cyan tracking 3
> - "Your Evolution Path" 32 pt heavy, centered, 2 lines
> - XP context subtitle: "You've earned 500 XP!" 14 pt heavy orange
> - Timeline spine with 3 stage cards (Rookie → Pro → Legend). Each card:
>   stage name, avatar at that stage. The newly-reached stage card is
>   larger, glows cyan, shows "CURRENT STAGE" label, and the avatar scales
>   in with spring physics. Locked future stages are blurred + desaturated
>   with a "EARN X MORE XP" requirement pill.
> - Bottom CTA: "BEGIN DAILY GRIND" orange capsule.

### 24. `streak_ring_enhanced`

> **Component: `streak_ring_enhanced`** — the ConsistencyRing card on the
> home dashboard, now with escalating flame + shield bank.
>
> **Composition (card ~361 wide × 120 tall):**
> - Left: circular progress ring (90×90) showing streak/target. Inside
>   ring: streak number (28 pt heavy) + pulsing flame icon. Flame sizes:
>   14 pt (<7 days), 18 pt (7-13), 22 pt (14-29), 26 pt (30-99), 30 pt
>   (100+). Flame color shifts from orange to red at 14+ days.
> - Right: "Great consistency!" message, a row of 3 stat items (Target,
>   Progress %, Shields count — shield icon is pulsing when shields > 0).
> - Ghost border + 16 pt corners.
> - Produce three variants: streak=3 (orange flame), streak=14 (red flame
>   + gold shield), streak=100 (largest flame + glow halo + 3 shields).

### 25. `shield_deployed_toast`

> **Component: `shield_deployed_toast`** — toast shown when a streak freeze
> is auto-applied. Slides in from the top.
>
> **Composition (card ~320 wide × 72 tall):**
> - Left: shield SF Symbol 18 pt, cyan
> - Right: Title "Streak Shield Deployed!" 14 pt bold, subtitle "Your
>   12-day streak is safe." 12 pt medium secondary, two lines.
> - Background cyan 15% opacity, 1 px cyan border 30%, 16 pt corners.

### 26. `weekly_recap_card`

> **Component: `weekly_recap_card`** — the shareable card rendered at 390×520
> pt (Instagram-Stories-like aspect ratio). This card is also used for
> social export, so make it visually bold.
>
> **Composition (top → bottom):**
> 1. Header: soccer-ball icon + "WEEKLY RECAP" label in cyan tracking 2.
>    Below: week range "Apr 7 – Apr 13" in 13 pt medium secondary.
> 2. Avatar centered, 100 tall, Wolf at current stage with subtle orange
>    glow.
> 3. Big session number centered: "5" in Display 56 heavy (count-up
>    transition). Below: "SESSIONS" label tracking 2.
> 4. Three stat pills in a row (each 90×70, subtle white 6% fill): clock
>    + "2h30" + "TIME"; flame + "12" + "STREAK"; lightning + "+340" + "XP".
> 5. 7-day activity dots row: M T W T F S S with filled-circles for
>    trained days.
> 6. Watermark bottom: "PitchDreams" small, 25% opacity.
>
> **Background:** rotating gradient preset (pick one moody dark palette
> from Starlight Pitch + deep blue/purple). 24 pt rounded corners.

### 27. `weekly_recap_sheet`

> **Screen: `weekly_recap_sheet`** — full-screen presentation wrapper for
> the recap card.
>
> **Composition:**
> - Top-right X button (32 circle, icon) to dismiss.
> - Centered: `weekly_recap_card` at 100% scale with subtle spring-scale
>   entrance animation suggestion.
> - Below card: "SHARE" CTA in orange-peach gradient capsule with
>   `square.and.arrow.up` icon on the left. 24 pt horizontal margin.
> - Optional confetti burst behind the card at first appearance.

---

## What to do with outputs

1. Save each Stitch output in this repo at `proposals/stitch/<mockup_name>.png`
   (multi-frame outputs: `<mockup_name>-1.png`, `<mockup_name>-2.png`, etc.).
2. Commit + push; I'll pick up the screenshots and implement.
3. Alternatively, drop screenshots straight into the chat — whichever is
   faster for you.

## Priority to finish first if time is tight

- **Minimum launch-critical set:** #1 `player_card_front`, #5
  `signature_moves_library`, #6 `signature_move_overview`, #9
  `signature_move_drill_player_mimic`, #15 `signature_move_unlocked_celebration`,
  #16 `mystery_box_closed`, #18 `mystery_box_reveal`.
- Everything else can be iterated in Month 1 if we're time-boxed.
