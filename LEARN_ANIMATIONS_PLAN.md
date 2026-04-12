# Learn Section Animations — Implementation Plan

## Overview

Port and enhance the web's character animations and lesson animations to iOS, making them more informative than the web versions by leveraging iOS-native capabilities (haptics, Siri voices, gesture interaction, Canvas rendering).

**5 features across 5 PRs, ~53 new tests, ~26 new/modified files.**

---

## Current State

| Component | iOS | Web |
|---|---|---|
| Pitch diagram | Static Canvas render, all elements at once, only pulsing ring on highlight | SVG with staggered element animation per step |
| Coach character | Static SF Symbol icon (44pt) | Framer-motion animated coach with 6 moods, speech bubbles, particles |
| Lesson player | Step list with checkboxes, no sequencing | Full-screen step-by-step player with intro video, narration, auto-advance |
| Skill animations | 8 static Canvas diagrams | 10 animated skill performances with ball physics, speed lines, particles |
| Interactive elements | None | None (iOS can go further than web here) |

---

## Phase 1: Data Model Foundation (PR #1)

**Goal**: Migrate from flat `[PitchElement]` to step-based `TacticalStep` with per-step diagram states.

### New Files

**`PitchDreams/Models/AnimatedTacticalTypes.swift`**
```swift
enum PlayerType: String { case self_, teammate, opponent }
enum ArrowType: String { case pass, run, scan, space }
enum ZoneType: String { case space, danger, opportunity }

struct TacticalPlayer: Identifiable {
    let id: String
    let x: CGFloat        // 0-100
    let y: CGFloat        // 0-100
    let type: PlayerType
    let label: String?
    let highlight: Bool
    let description: String?
}

struct TacticalArrow: Identifiable {
    let id: String
    let fromX, fromY, toX, toY: CGFloat
    let type: ArrowType
    let label: String?
    let delay: TimeInterval  // stagger within a step
}

struct TacticalZone: Identifiable {
    let id: String
    let x, y, w, h: CGFloat
    let type: ZoneType
    let label: String?
    let description: String?
}

struct BallPosition { let x, y: CGFloat }

struct TacticalDiagramState {
    let players: [TacticalPlayer]
    let arrows: [TacticalArrow]
    let zones: [TacticalZone]
    let ball: BallPosition?
}

struct TacticalStep {
    let narration: String
    let diagram: TacticalDiagramState
    let duration: TimeInterval  // seconds
}

struct AnimatedTacticalLesson: Identifiable {
    let id: String
    let title: String
    let track: String
    let description: String
    let difficulty: String
    let steps: [TacticalStep]
    let relatedDrillKey: String?
}
```

**`PitchDreams/Models/AnimatedTacticalLessonRegistry.swift`**
- Port web registry's step-based lesson data for all lessons with diagrams
- Each lesson gets 3-5 steps with narration and per-step diagram
- Start with 3-Point Scan as the template (port from web `registry.ts`)

**`PitchDreams/Models/SkillAnimationType.swift`**
```swift
enum SkillAnimationKey: String, CaseIterable {
    case juggling, dribbling, passing, shooting, first_touch
    case defending, scanning, decision, tempo, generic
}

struct SkillAnimationConfig {
    let displayName: String
    let description: String
    let durationSeconds: TimeInterval
    let showsBall: Bool
    let hasImpactFlash: Bool
    let speedLineDirection: SpeedLineDirection
}

enum SpeedLineDirection { case left, right, up, radial }
```

### Modified Files

**`PitchDreams/Models/TacticalLessonRegistry.swift`**
- Add `static func animatedLesson(for id: String) -> AnimatedTacticalLesson?`
- Existing `all` and `TacticalLesson` untouched for backwards compat

### Tests (12)

| Test File | Tests |
|---|---|
| `AnimatedTacticalTypesTests.swift` | Diagram element counts, coordinates in 0-100, step durations > 0, narrations non-empty |
| `AnimatedTacticalLessonRegistryTests.swift` | Lesson count, all have ≥2 steps, unique IDs, all tracks covered |
| `SkillAnimationTypeTests.swift` | All 10 keys have configs, resolve returns expected keys, falls back to generic, CaseIterable count |

---

## Phase 2: Animated Pitch View + Coach Character (PR #2)

**Goal**: Build the two visual components that form the lesson player's core.

### New Files

**`PitchDreams/Features/Learn/Views/AnimatedTacticalPitchView.swift`**
- Takes `diagram: TacticalDiagramState` and `stepIndex: Int`
- Canvas for pitch lines (reuse from existing `TacticalPitchView`)
- SwiftUI overlay views for animated elements (not Canvas — enables `.animation()`, `.transition()`)
- Players: `scaleEffect` spring (0 → 1), labels fade in after 0.3s delay
- Arrows: `trim(from:to:)` on `Path` shape with draw-on animation, respects `delay`
- Zones: fade in with opacity + scaleEffect
- Ball: bounce-in with spring
- Highlighted players: pulsing ring (existing pattern)
- Step change triggers animated transition of elements
- Respects `@Environment(\.accessibilityReduceMotion)`

**`PitchDreams/Features/Learn/Views/Components/AnimatedArrowShape.swift`**
- Custom `Shape` for arrow path with arrowhead
- Supports `trim(from:to:)` for progressive draw animation

**`PitchDreams/Features/Learn/Views/CoachCharacterView.swift`**
```swift
enum CoachMood: String { case idle, speaking, encouraging, celebrating, listening, skeptical }
enum CoachSize { case sm, md, lg } // 64, 96, 128 pt
```
- SF Symbol `figure.soccer` as avatar (zero dependencies), or coach PNG if bundled
- Mood-driven animations:
  - `idle`: gentle bobbing offset with repeating easeInOut (3s)
  - `speaking`: subtle scale pulse + faster bob (1.5s)
  - `encouraging`: lean + scale up with spring
  - `celebrating`: bounce sequence + scale + rotation wiggle
  - `listening`: subtle lean + pulsing ring overlay
  - `skeptical`: slight shrink + head shake
- Glow background circle with radial gradient, color from mood
- Speech bubble positioned above character

**`PitchDreams/Features/Learn/Views/Components/CoachBubbleView.swift`**
- Rounded rect with tail triangle
- Text with `.font(.subheadline)`, `.lineLimit(4)`
- Spring transition show/hide

**`PitchDreams/Features/Learn/ViewModels/CoachCharacterViewModel.swift`**
- `@Published var mood: CoachMood`, `speechText: String`, `isSpeaking: Bool`
- `speak()`, `stopSpeaking()`, `listen()`, `setMood()`
- Transient moods (encouraging, celebrating) auto-return to idle after 3s

### Tests (9)

| Test File | Tests |
|---|---|
| `CoachCharacterViewModelTests.swift` | Initial mood idle, speak sets mood+text, stopSpeaking clears, encouraging auto-returns, celebrating auto-returns, listen sets mood, rapid mood changes |
| `AnimatedArrowShapeTests.swift` | Path non-empty, trim produces partial path |

---

## Phase 3: Lesson Player (PR #3)

**Goal**: Full-screen step-by-step lesson experience with coach + animated pitch + narration.

### New Files

**`PitchDreams/Core/Voice/CoachVoiceProtocol.swift`**
```swift
protocol CoachVoiceProtocol: AnyObject {
    var isSpeaking: Bool { get }
    func speak(_ text: String, personality: String)
    func stop()
}
```

**`PitchDreams/Features/Learn/ViewModels/LessonPlayerViewModel.swift`**
- `let lesson: AnimatedTacticalLesson`
- `@Published var currentStepIndex: Int = 0`
- `@Published var isAutoAdvancing: Bool = true`
- `@Published var isCompleted: Bool = false`
- `@Published var voiceEnabled: Bool = true`
- Computed: `currentStep`, `totalSteps`, `progressFraction`
- `goToNext()`, `goToPrevious()`, `goToStep()`, `toggleAutoAdvance()`, `toggleVoice()`
- Auto-advance: schedules next step after `step.duration` or speech completion (whichever longer)
- CoachVoice injected via protocol for testability

**`PitchDreams/Features/Learn/Views/LessonPlayerView.swift`**
- Full-screen presentation
- Navigation bar: back button, step counter
- Segmented progress bar (tappable to jump)
- AnimatedTacticalPitchView + CoachCharacterView with speech bubble
- Bottom controls: previous, voice toggle, auto-play toggle, next/finish
- Swipe gesture for step navigation
- Completion state: confetti + mark-complete button

**`PitchDreams/Features/Learn/Views/Components/LessonProgressBar.swift`**
- Horizontal capsule segments
- Current = track color, completed = filled, future = dim
- Tappable segments

### Modified Files

- **`LessonDetailView.swift`** — Add "Start Lesson" button when animated version available
- **`CoachVoice.swift`** — Conform to `CoachVoiceProtocol`

### Tests (15)

| Test File | Tests |
|---|---|
| `LessonPlayerViewModelTests.swift` | Initial state, goToNext increments, goToNext on last sets completed, goToPrevious decrements, goToPrevious on 0 no-op, goToStep jumps + pauses auto-advance, goToStep clamps, toggleAutoAdvance, toggleVoice, progressFraction correct, auto-advance creates timer, auto-advance waits for speech, auto-advance cancelled on manual nav, goToPrevious clears completed, speak called with narration |
| `MockCoachVoice.swift` (test helper) | Records calls, controllable isSpeaking |

---

## Phase 4: Skill Animations (PR #4)

**Goal**: Port 10 web skill animations as SwiftUI Canvas animations. **Can be developed in parallel with PR #3.**

### New Files

**`PitchDreams/Features/Skills/Views/SkillPerformAnimationView.swift`**
- Takes `animationKey`, `isPlaying`, `onComplete`, `accentColor`
- `TimelineView(.animation)` driving Canvas with `progress: CGFloat`
- 7 layers: background glow, speed lines, player action, ball path, glow arc, impact flash, particles
- Each skill has unique configuration from `SkillAnimationConfig`

**`PitchDreams/Features/Skills/Views/Components/SkillAnimationRenderer.swift`**
- 10 Canvas draw functions, one per skill
- All use `progress: CGFloat` (0.0-1.0) for frame interpolation — no timing dependencies
- `drawJugglingAnimation` — ball bounces up/down in parabolic arcs
- `drawDribblingAnimation` — player moves L→R, ball alongside, weaving cones
- `drawPassingAnimation` — two players, ball arc between them
- `drawShootingAnimation` — wind up, ball rockets to goal
- `drawFirstTouchAnimation` — ball arrives, player cushions
- `drawDefendingAnimation` — lateral shuffle, interception
- `drawScanningAnimation` — rotating scan arrows from player
- `drawDecisionAnimation` — branching arrows, decision tree
- `drawTempoAnimation` — metronome pulse, rhythm
- `drawGenericAnimation` — simple pulse/glow fallback

**`PitchDreams/Features/Skills/Views/Components/BallPhysics.swift`**
```swift
static func parabolicArc(from:to:height:progress:) -> CGPoint
static func bounceSequence(start:bounceCount:progress:) -> CGPoint
static func linearTravel(from:to:progress:) -> CGPoint
```
- Pure math functions, easily unit-testable

**`PitchDreams/Features/Skills/Views/Components/SpeedLinesView.swift`**
- Canvas overlay with directional streaks
- `direction`, `color`, `progress` parameters

**`PitchDreams/Features/Skills/Views/Components/ParticleFieldView.swift`**
- Deterministic particle positions (seeded from index, not random)
- `count`, `color`, `progress` parameters

### Modified Files

- **`SkillDiagramView.swift`** — Add `animated: Bool` parameter (default `false`). When true, render `SkillPerformAnimationView` instead of static diagrams.

### Tests (11)

| Test File | Tests |
|---|---|
| `BallPhysicsTests.swift` | Arc at progress 0 returns from, at 1 returns to, at 0.5 offset by height, bounce ground contacts, linear interpolation |
| `SkillAnimationConfigTests.swift` | All 10 keys non-zero duration, showsBall false only for scanning+decision, hasImpactFlash for shooting+defending+passing, speed line directions |
| `SkillPerformAnimationViewTests.swift` | Phase transitions idle→active→complete, onComplete callback fires |

---

## Phase 5: Interactive Pitch Elements (PR #5)

**Goal**: Tap-to-inspect on pitch elements with popover, coach voice, and haptics.

### New Files

**`PitchDreams/Features/Learn/Views/Components/PitchElementPopover.swift`**
- Floating card near tapped element
- Shows element role description
- Dismiss on tap outside or after 4s
- Consistent with `CoachBubbleView` styling

**`PitchDreams/Features/Learn/ViewModels/InteractivePitchViewModel.swift`**
- `@Published var selectedElement`, `popoverPosition`
- `tapElement()` — sets selection, triggers haptic, calls CoachVoice
- `dismiss()` — clears selection
- Element descriptions derived from type + label + context

### Modified Files

- **`AnimatedTacticalPitchView.swift`** — Add `onElementTap` closure, transparent tap targets on elements, `.sensoryFeedback` haptic
- **`LessonPlayerView.swift`** — Wire up `InteractivePitchViewModel`
- **`AnimatedTacticalTypes.swift`** — Add `description: String?` to `TacticalPlayer`, `TacticalArrow`, `TacticalZone`

### Tests (6)

| Test File | Tests |
|---|---|
| `InteractivePitchViewModelTests.swift` | Tap sets element+position, dismiss clears, description for each player type, for arrow types, for zone types, tap calls speak |

---

## Testing Strategy

### Total: ~53 new tests

**Animation testing approach (no flaky timing):**
- Animation logic lives in ViewModels with injectable dependencies
- Ball physics and paths are pure functions — test input/output
- `CoachVoice` is protocol-abstracted → `MockCoachVoice` records calls synchronously
- Auto-advance uses `Task.sleep` with cancellation — test by inspecting state, not waiting
- Canvas rendering verified through `#Preview` blocks, not snapshot tests
- Deterministic particle positions (index-seeded, not random)

### Test file locations
```
PitchDreamsTests/
├── Models/
│   ├── AnimatedTacticalTypesTests.swift
│   ├── AnimatedTacticalLessonRegistryTests.swift
│   └── SkillAnimationTypeTests.swift
├── Features/
│   ├── CoachCharacterViewModelTests.swift
│   ├── LessonPlayerViewModelTests.swift
│   ├── InteractivePitchViewModelTests.swift
│   └── SkillPerformAnimationViewTests.swift
├── Core/
│   └── AnimatedArrowShapeTests.swift
│   └── BallPhysicsTests.swift
└── Helpers/
    └── MockCoachVoice.swift
```

---

## PR Strategy & Dependencies

```
PR #1 (Data Models) ─────┬──→ PR #2 (Pitch + Coach) ──→ PR #3 (Lesson Player) ──→ PR #5 (Interactive)
                          │
                          └──→ PR #4 (Skill Animations)  ← parallel with #2/#3
```

| PR | Title | Dependencies | Est. Tests |
|----|-------|-------------|------------|
| #1 | Add step-based tactical lesson data model | None | 12 |
| #2 | Add AnimatedTacticalPitchView and CoachCharacterView | #1 | 9 |
| #3 | Add full-screen LessonPlayerView with narration | #1, #2 | 15 |
| #4 | Add Canvas-based skill perform animations | #1 | 11 |
| #5 | Add interactive pitch element tap-to-inspect | #2, #3 | 6 |

---

## Key Architecture Decisions

1. **Overlay views vs Canvas for animated elements** — Pitch *lines* stay in Canvas (static). *Elements* (players, arrows, zones) move to SwiftUI overlay views so they can use `.animation()` and `.transition()`.

2. **TimelineView for skill animations** — `TimelineView(.animation)` drives Canvas with `progress: CGFloat` for 60fps frame rendering without rapid `@State` churn.

3. **Protocol extraction for CoachVoice** — `CoachVoiceProtocol` enables mock injection in tests; avoids `AVSpeechSynthesizer` in CI.

4. **New type, not migration** — `AnimatedTacticalLesson` exists alongside `TacticalLesson`. `LessonDetailView` detects animated version and shows "Start Lesson" button. No breaking changes.

5. **Deterministic particles** — Index-seeded positions, not random, for reproducible rendering.

---

## Web Reference Files

For porting lesson data and animation configs:
- `/Users/lossa/Documents/Side Projects/Pitch Dreams/components/pitchdreams/CoachCharacter.tsx`
- `/Users/lossa/Documents/Side Projects/Pitch Dreams/components/pitchdreams/TacticalPitchView.tsx`
- `/Users/lossa/Documents/Side Projects/Pitch Dreams/components/pitchdreams/TacticalLessonPlayer.tsx`
- `/Users/lossa/Documents/Side Projects/Pitch Dreams/components/pitchdreams/SkillPerformAnimation.tsx`
- `/Users/lossa/Documents/Side Projects/Pitch Dreams/lib/animations/animationMap.ts`
