# Player Development Plan — Train the Brain, Cut the Clunk

## Overview

Two moves, one thesis. PitchDreams already teaches **technique** well (rich Signature Moves, staged progression) and builds **habits** well (streaks, XP, freezes). What it does *not* do is train the part of the game that actually decides matches: **perception, decision-making, creativity, and confidence.** And it spends a lot of its complexity budget making the kid fill in adult-flavored data-entry (RPE 1–10, soreness scales, facility/coach pickers) whose payoff goes to the parent dashboard, not the kid.

This plan does both at once:

- **Track A — Subtract the clunk.** Remove or demote ~5 flows that an 8–13-year-old won't finish, so the app gets faster and lighter.
- **Track B — Add the brain layer.** Reinvest that freed complexity into a *lightweight* psychological/decision layer: a Confidence Evidence Bank, a mistake-reset routine, tap-to-decide "Game Moments," command-driven first touch, and a Creativity Lab.

**Guiding rule for everything new:** *If it's a field the kid fills in for someone else to read, it's suspect. If it shows the kid proof or trains a decision in taps, it earns its place.*

**Scope:** iOS (primary) + Web (parallel, kept in sync). ~7 PRs. Track A ships first (lower risk, frees screen real estate), then Track B.

---

## Current State

| Area | Today | Problem |
|---|---|---|
| Session logging | Two paths: `ActivityLog` (4 steps, 12+ inputs, **required** Facility/Coach/Program) and `QuickLog` (3 taps) | Solo kid can't finish ActivityLog; redundant maintenance |
| Pre-session check-in | 6 self-ratings (energy, soreness, focus, mood, time, pain) | Abstract for kids ("soreness: medium?"); only energy + time change the drill |
| Post-session reflection | 4 sequential screens (RPE → highlights → next-focus → mood) | Feels like homework at the moment the kid wants to leave |
| Progress page | Mood trends, effort trends, tag frequency, consistency ring, history | Data-dense; analytics belong to the parent, not the 10-year-old |
| Lessons | 10 passive read + occasional quiz | Reading + quizzes = "school"; no decision *training* |
| Mental skills | One "Breathing Under Pressure" lesson; mood emoji; `stageConfidenceRatings` stored but never reflected back | No confidence, pressure, creativity, or decision training as an active domain |
| Web dev pages | `/styleguide`, `/hud-demo`, `/components-demo`, `/dev/animations` publicly reachable | Bloat exposed in production |

---

# TRACK A — Simplification (ships first)

## Phase A1: One logging path (PR #1)

**Goal:** Kill the redundant heavy logger; make the fast one the only one.

### iOS
- **Demote `ActivityLog` as a kid-facing path.** Make `QuickLog` the single "Log Session" entry point.
- Make `selectedFacilityId` / `selectedCoachId` / `selectedProgramId` **optional** in `ActivityLogViewModel` (currently required, no nil default). Keep the rich form reachable only behind an explicit "Add details" affordance for older players/parents.
- Remove the ActivityLog entry from `ChildTabNavigation` / primary CTAs.

### Web
- Keep `/child/[childId]/log`; remove or hide `/child/[childId]/activity/new` from kid navigation.

### Files
- `PitchDreams/Features/ActivityLog/ViewModels/ActivityLogViewModel.swift` (optional fields)
- `PitchDreams/Features/ActivityLog/Views/NewActivityView.swift` (gate behind "Add details")
- `PitchDreams/Core/Navigation/ChildTabNavigation.swift` (remove primary entry)
- Web: `app/child/[childId]/activity/new/page.tsx`, nav component

### Tests (~6)
- QuickLog saves with no facility/coach/program
- ActivityLog ViewModel accepts nil facility/coach/program
- Regression: existing ActivityLog saves still decode

---

## Phase A2: Shrink the check-in (PR #2)

**Goal:** Two inputs, not six. Keep the one-tap mood quick-start as default.

- Default path stays: **one mood tap → train.**
- Reduce the optional "Full Check-In" to **energy (1–5) + time available (10/20/30)** — the only two inputs that change which drill is served. Re-label it "Set up my session," not a clinical intake.
- **Drop** soreness and focus self-ratings from the kid flow. Fold the only safety-relevant bit into a single **"Anything hurt? (yes/no)"**.
- Server `CheckIn` keeps its columns for backward compat; just stop *collecting* soreness/focus from the kid (send sensible defaults).

### Data note
`CheckIn` currently requires `energy, soreness, focus, mood, timeAvail, painFlag`. Keep the struct; populate `soreness = "NONE"` / `focus = energy` as defaults when not asked, so `SessionMode` (PEAK/NORMAL/LOW_BATTERY/RECOVERY) still computes.

### Files
- `PitchDreams/Features/Training/Views/FullCheckInSheet.swift`
- `PitchDreams/Features/Training/ViewModels/` (check-in VM)
- Web: training launcher check-in component

### Tests (~5)
- Quick mood start still produces a valid session
- Reduced check-in computes a valid `SessionMode`
- Defaults fill soreness/focus without breaking decode

---

## Phase A3: Reflection 4 → 1, analytics to the parent (PR #3)

**Goal:** End the session in two taps; move dense trends off the kid's screen.

### Reflection
- Collapse to **one screen: effort (emoji/RPE) + mood**, two taps, done.
- Highlights / next-focus become an **optional** "Add a note?" — never a gate. (This is the seam where the Track B *bravery* prompt later lands as one optional tap.)
- Add a "Skip" affordance so a kid leaving the park can log now, reflect never.

### Progress page
- Kid view shows **streak + last 3–5 sessions + "you beat your record."** Nothing else.
- Move mood/effort **trends and tag-frequency** to the **parent** dashboard (web `/parent/dashboard`, iOS `ParentDashboard`), where numerical literacy is assumed and the data is actually useful.

### Files
- `PitchDreams/Features/Training/Views/ReflectionView.swift`
- `PitchDreams/Features/Progress/` (slim kid view)
- `PitchDreams/Features/ParentDashboard/` (receive trends)
- Web: `app/child/[childId]/progress/page.tsx`, `app/parent/dashboard/page.tsx`

### Tests (~6)
- One-screen reflection saves effort + mood
- Skip path saves a session with no reflection tags
- Parent dashboard renders trends that used to live on kid progress

---

## Phase A4: De-emphasize + gate (PR #4, small)

- **Voice commands:** keep as opt-in, add a one-time hint sheet ("try saying 'next' or 'done'"), but no flow may *depend* on it. No further investment. (Unreliable outdoors; two permission prompts.)
- **Training-arc narrative (web):** reduce to a badge — "Focus: Scanning · 2/5" — and move the explainer to the existing `/parent/education/training-arcs`.
- **Training window:** rename to "Recommended training time," single optional field; drop the surveillance tone.
- **Web dev pages:** put `/styleguide`, `/hud-demo`, `/components-demo`, `/dev/animations` behind an env flag or remove from production routing. Retire the `/skills → /learn` redirect stub once nothing links to it.

---

# TRACK B — The Brain Layer (ships after Track A)

## Phase B1: Confidence Evidence Bank + mistake reset (PR #5) — **flagship**

**Goal:** Turn data you already store into proof the kid can *feel*, and give them an in-the-moment reset so one bad touch doesn't snowball. Directly answers "I don't want them to play scared." ~70% of this is presentation of existing data.

### B1a — Evidence Bank
Self-efficacy (Bandura) is belief backed by evidence; the #1 source is mastery experience. Synthesize a confidence view — surfaced especially **before a match** — from data already in the app:

```swift
// PitchDreams/Models/ConfidenceEvidence.swift
struct ConfidenceSnapshot {
    let masteredMoves: [String]        // from SignatureMove progress
    let personalBests: [PersonalBest]  // from FirstTouch / drills
    let currentStreak: Int             // from existing streak data
    let totalSessions: Int             // from SessionLog count
    let recentConfidence: [Int]        // from SignatureMove.stageConfidenceRatings
    let bravePlaysLogged: Int          // from new bravery reflection tap (Phase A3 seam)
}

struct PersonalBest { let drillKey: String; let value: Int; let achievedAt: Date }

enum EvidenceLine {  // rendered as a narrative, not a chart
    case mastery(String)       // "You've mastered the Scissor and La Croqueta."
    case record(String)        // "You've beaten your juggling record 12 times."
    case consistency(String)   // "18 days straight. That's not luck."
    case courage(String)       // "You tried something hard in 9 of your last 10 sessions."
}
```
- New `ConfidenceViewModel` assembles `[EvidenceLine]` from existing stores — **no new data collection.**
- New `EvidenceBankView` — a "you're ready" screen. Entry points: a card on Home, and the first step of Match Prep (Phase B3).

### B1b — Mistake reset
- Convert the **"Breathing Under Pressure"** lesson content from a 3-minute read into a **trainable 5-second tool**: breath + cue word + reset posture, rehearsable in-app.
- `ResetRoutineView` — a short guided loop the kid can run anytime; offered after a session and linkable from Match Prep.

### Files
- `PitchDreams/Models/ConfidenceEvidence.swift` (new)
- `PitchDreams/Features/Confidence/` (new: `ConfidenceViewModel`, `EvidenceBankView`, `ResetRoutineView`)
- `PitchDreams/Features/ChildHome/` (Evidence card entry point)
- Web mirror: `app/child/[childId]/confidence/page.tsx`

### Tests (~8)
- Evidence assembles from mastered moves / PBs / streak / confidence ratings
- Empty state (new player) produces an encouraging, non-empty snapshot
- Reset routine completes and is logged
- Confidence view reads `stageConfidenceRatings` without mutation

---

## Phase B2: Game Moments — decision training (PR #6)

**Goal:** Stop *reading* tactics, start *training* decisions. Reuse the `TacticalPitchView` Canvas renderer and the existing quiz infra.

- A freeze-frame scenario on the pitch, a **3-second shot clock**, the kid taps the best option, gets feedback on **correctness + speed**. Decision speed is the measurable, trainable variable.
- Build on the `AnimatedTacticalLesson` / `TacticalDiagramState` model already specced in `LEARN_ANIMATIONS_PLAN.md` — add an interactive scenario layer.

```swift
// PitchDreams/Models/DecisionScenario.swift
struct DecisionOption: Identifiable {
    let id: String
    let label: String          // "Switch play", "Drive inside", "Recycle back"
    let target: BallPosition   // reuse from AnimatedTacticalTypes
    let isBest: Bool
    let rationale: String      // shown after the tap
}

struct DecisionScenario: Identifiable {
    let id: String
    let lessonId: String       // ties back to the tactical lesson it trains
    let diagram: TacticalDiagramState
    let options: [DecisionOption]
    let clockSeconds: TimeInterval   // default 3.0
}

struct DecisionResult { let chosen: String; let correct: Bool; let reactionMs: Int }
```
- `GameMomentsView` over `TacticalPitchView`; `GameMomentsViewModel` runs the clock, scores reaction time, tracks a per-lesson decision-speed trend (this trend belongs to the kid — it's a game skill, not admin data).
- Spaced-repetition resurfacing: "You learned Press Triggers 8 days ago — here's a live one."

### Files
- `PitchDreams/Models/DecisionScenario.swift` (new)
- `PitchDreams/Models/DecisionScenarioRegistry.swift` (new — seed 2–3 per tactical lesson)
- `PitchDreams/Features/Learn/` (`GameMomentsView`, `GameMomentsViewModel`)
- Reuse `Features/Learn/TacticalPitchView`
- Web mirror under `app/child/[childId]/learn/`

### Tests (~10)
- Correct option scored correct; clock expiry scored as miss
- Reaction time captured in ms
- Registry: every scenario has exactly one `isBest`
- Each authored tactical lesson maps to ≥1 scenario

---

## Phase B3: Match Mode — close the loop with real games (PR #7)

**Goal:** Every psychological moment that matters happens in a match the app never touches. Add a lightweight match companion. This is the structural change that turns a solo-drill app into a development companion.

- **Pre-match (≤90s):** Evidence Bank (B1a) → one breath cycle (B1b) → **one process goal** ("my job today: be brave receiving on the half-turn") → power cue. Process goals, not outcome goals, reduce performance anxiety.
- **Post-match reflection:** focuses on **bravery, effort, and decisions** — *not* goals scored or mistakes. "What did you try that was hard?" feeds `bravePlaysLogged` back into the Evidence Bank (the courage flywheel).

```swift
// PitchDreams/Models/MatchSession.swift
struct MatchPrep { let processGoal: String; let powerCue: String; let preppedAt: Date }
struct MatchReflection {
    let braveThingTried: String?   // free or chip; feeds ConfidenceSnapshot.bravePlaysLogged
    let effortLevel: Int
    let oneDecisionImProudOf: String?
}
```

### Files
- `PitchDreams/Models/MatchSession.swift` (new)
- `PitchDreams/Features/MatchMode/` (new: prep + reflection views/VM)
- Hook into existing `QuickLog` activity types (`OFFICIAL_GAME`, `FUTSAL_GAME`, `INDOOR_LEAGUE_GAME`)
- Web mirror under `app/child/[childId]/`

### Tests (~7)
- Match prep saves a process goal + cue
- Post-match "brave thing" increments `bravePlaysLogged`
- Match reflection never requires goals/mistakes input

---

## Phase B4 (optional / later): Scan & Solve + Creativity Lab

Lower priority; specced for completeness.

- **Scan & Solve (first touch):** reuse the **existing voice engine** to call a random direction ("turn!", "back!", "split!") before each touch; the kid takes their first touch into that space. Score "clean directional touches under command," not raw reps. Couples touch to a decision the way a match does. Files: `Features/FirstTouch/` + `Core/Voice/`.
- **Creativity Lab:** a differential-learning mode — *"never do the same rep twice."* Challenges like "beat the cone 5 different ways," "juggle 5 different body parts in a row," "invent a move and name it." Rewards **variety**, explicitly not repetition. Reuse the Signature Moves **video capture** for a "trick reel." Files: new `Features/Creativity/`, `Models/CreativityChallenge.swift`.

---

## Sequencing & Dependencies

```
A1 logging ─┐
A2 checkin  ├─ Track A: subtract clunk, free the complexity budget (lower risk, ship first)
A3 reflect ─┤     A3 plants the "bravery tap" seam used by B1/B3
A4 gate    ─┘
                      │
B1 Confidence ────────┤  flagship; mostly presents existing data
B2 Game Moments ──────┤  reuses TacticalPitchView + LEARN_ANIMATIONS_PLAN models
B3 Match Mode ────────┘  consumes B1 (Evidence) + A3 (bravery tap)
B4 Scan/Creativity ──── optional, after the core lands
```

**Cross-platform rule:** each phase ships iOS + web together (shared API/data shapes) so the two clients don't drift — logging, confidence, and decision data all round-trip through the same endpoints.

## What gets removed vs added (net)

- **Removed / demoted (~5):** ActivityLog as kid path, full 6-input check-in default, 3 of 4 reflection screens, kid-facing trend analytics, public web dev pages.
- **Added (thin, ~3 core):** Confidence Evidence Bank + reset, Game Moments decision trainer, Match Mode. None are forms.

Result: the app gets **simpler and more novel at the same time.**

---

## Open questions for the build

1. Confidence view — standalone tab, or a card on Home + step inside Match Prep only? (Recommend: card on Home + Match Prep; no new tab.)
2. Game Moments — its own section under Learn, or replace passive lessons outright? (Recommend: add alongside first, retire passive quizzes once coverage is good.)
3. Match Mode — manual "I have a game" trigger, or surface it off the existing game-type QuickLog? (Recommend: both — a Home button + auto-offer when a game is logged.)
