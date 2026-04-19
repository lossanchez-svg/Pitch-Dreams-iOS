# Track F: Learn Module Clarity for Young Users — Implementation Spec

**Goal:** Make tactical animations genuinely understandable to 8-12 year olds while staying rich enough for 13-18 year olds.

**The problem:** Existing `AnimatedTacticalPitchView` + `LessonPlayerView` assume users can interpret bird's-eye diagrams, tactical vocabulary ("half-space," "press trigger"), and fast-paced abstract motion. An 8-year-old processes none of this.

**The critical test:** *An 8-year-old can complete 1 lesson without parent intervention.* If this test fails, Track F hasn't shipped.

---

## Foundational Context

### Existing System

```
LessonDetailView (entry)
    ↓
LessonPlayerView (full-screen step-by-step player)
    ↓
  - AnimatedTacticalPitchView (Canvas-based pitch with overlays)
  - CoachCharacterView (6-mood animated coach)
  - CoachVoice (AVSpeechSynthesizer)
  - LessonPlayerViewModel (step state machine)
  - InteractivePitchViewModel (tap handling — currently unused!)
```

### Data Models (Existing)

```swift
struct TacticalStep {
    let narration: String          // ← we'll add narrationYoung
    let diagram: TacticalDiagramState
    let duration: TimeInterval
    // NEW FIELDS (to be added):
    // var narrationYoung: String?
    // var spotlightElementId: String?
    // var shadowStep: TacticalStep?
    // var quiz: LessonQuiz?
}

struct TacticalPlayer {
    // ... existing
    // NEW FIELDS:
    // var tapDescription: String?
    // var tapDescriptionYoung: String?
}
```

### Age Determination

Child's age is stored on `ChildProfileDetail` (see `Models/User.swift`). The pattern:
```swift
let isYoungUser = (childAge ?? 12) <= 11
```

---

## F1. Spotlight Mode

**Concept:** Before each step animates, dim everything except one key element and display a caption for 1.5 seconds. Then the full step animates.

**Why:** Young kids get overwhelmed by 10 elements moving at once. A focal point primes them to watch the right thing.

### Model Changes

**File: `PitchDreams/Models/AnimatedTacticalTypes.swift`**

```swift
struct TacticalStep {
    let narration: String
    let narrationYoung: String?            // F2 — optional simplified variant
    let diagram: TacticalDiagramState
    let duration: TimeInterval

    // F1 additions:
    let spotlightElementId: String?         // player id, zone id, or arrow id to highlight
    let spotlightCaption: String?           // "Watch the midfielder first"
    let spotlightCaptionYoung: String?      // age-adapted caption

    // F6 additions (see F6 section):
    let shadowStep: ShadowStep?

    // F7 additions:
    let quiz: LessonQuiz?
}
```

### View Changes

**File: `PitchDreams/Features/Learn/Views/AnimatedTacticalPitchView.swift`**

Add spotlight phase logic:

```swift
struct AnimatedTacticalPitchView: View {
    let diagram: TacticalDiagramState
    let stepIndex: Int

    // F1 additions
    let spotlightElementId: String?
    let spotlightCaption: String?
    let onSpotlightPhaseEnd: (() -> Void)?

    @State private var isInSpotlightPhase = false
    @State private var appeared = false

    var body: some View {
        ZStack {
            // ... existing pitch background + overlays

            ForEach(diagram.players) { player in
                PlayerDot(player: player, size: size, appeared: appeared, reduceMotion: reduceMotion) { ... }
                    .opacity(isSpotlighted(id: player.id) ? 1.0 : (isInSpotlightPhase ? 0.15 : 1.0))
                    .overlay {
                        if isSpotlighted(id: player.id) && isInSpotlightPhase {
                            SpotlightPulseRing()
                        }
                    }
            }

            // Similar opacity logic for arrows and zones
            // ...

            // Spotlight caption overlay
            if isInSpotlightPhase, let caption = spotlightCaption {
                VStack {
                    Text(caption)
                        .font(DSFont.headline(18))
                        .foregroundStyle(Color.dsOnSurface)
                        .padding()
                        .background(Color.dsSurfaceContainer.opacity(0.95))
                        .clipShape(Capsule())
                        .transition(.opacity.combined(with: .scale))
                    Spacer()
                }
                .padding(.top, 24)
            }
        }
        .onChange(of: stepIndex) { _ in
            triggerStepAnimation()
        }
        .onAppear {
            triggerStepAnimation()
        }
    }

    private func isSpotlighted(id: String) -> Bool {
        id == spotlightElementId
    }

    private func triggerStepAnimation() {
        appeared = false
        if spotlightElementId != nil {
            isInSpotlightPhase = true
            withAnimation(.easeInOut(duration: 0.3)) { }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isInSpotlightPhase = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(reduceMotion ? .none : .easeOut(duration: 0.4)) {
                        appeared = true
                    }
                    onSpotlightPhaseEnd?()
                }
            }
        } else {
            // No spotlight — animate immediately
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(reduceMotion ? .none : .easeOut(duration: 0.4)) {
                    appeared = true
                }
            }
        }
    }
}

struct SpotlightPulseRing: View {
    @State private var scale: CGFloat = 1.0
    var body: some View {
        Circle()
            .stroke(Color.dsSecondary, lineWidth: 3)
            .scaleEffect(scale)
            .opacity(2.0 - scale)
            .onAppear {
                withAnimation(.easeOut(duration: 1.2).repeatForever(autoreverses: false)) {
                    scale = 2.0
                }
            }
    }
}
```

### ViewModel Changes

**File: `PitchDreams/Features/Learn/ViewModels/LessonPlayerViewModel.swift`** (modify)

```swift
@MainActor
final class LessonPlayerViewModel: ObservableObject {
    // ... existing properties

    // F1: narrator should delay main narration until after spotlight phase
    // Wire up onSpotlightPhaseEnd to trigger narration
    func onSpotlightPhaseEnd() {
        guard let voice = voice else { return }
        let text = preferredNarration(for: currentStep)
        voice.speak(text, voice: .standard)
    }

    // F2: age-adaptive narration selection
    func preferredNarration(for step: TacticalStep) -> String {
        if isYoungUser, let young = step.narrationYoung {
            return young
        }
        return step.narration
    }

    private var isYoungUser: Bool {
        (childAge ?? 12) <= 11
    }
}
```

### Content Authoring

**File: `PitchDreams/Models/AnimatedTacticalLessonRegistry.swift`** (modify existing lessons)

For every lesson step, author:
- `spotlightElementId: String?` — picks the single most important element for that step
- `spotlightCaption: String?` — standard caption for 12+
- `spotlightCaptionYoung: String?` — simple caption for 8-11

Example update to "3-Point Scan" lesson (if it exists):
```swift
TacticalStep(
    narration: "Before receiving the ball, scan twice to locate teammates and opponents.",
    narrationYoung: "Look around two times before the ball gets to you. See who's where!",
    diagram: ...,
    duration: 6,
    spotlightElementId: "player-self",
    spotlightCaption: "Watch your body position as you scan",
    spotlightCaptionYoung: "Watch yourself — you're about to look around!",
    shadowStep: nil,
    quiz: nil
)
```

### Effort
- Engine: 1 day
- Content authoring (spotlight choices + captions for all existing lessons): 1-2 days

---

## F2. Age-Adaptive Narration Scripts

**Concept:** Every step has two narration scripts. The player picks based on child age.

### Model Changes

Already shown in F1 (`narrationYoung: String?` added to `TacticalStep`).

### Content Writing Guidelines

| Age | Vocabulary | Sentence Length | Examples |
|-----|-----------|-----------------|----------|
| **8-11 (young)** | Everyday words, concrete metaphors | 6-12 words per sentence | "The gap between them? That's the door. Run through it fast." |
| **12+ (standard)** | Tactical terms okay, multi-clause ok | 10-20 words per sentence | "Identify the half-space and time your run to exploit the passing lane before the defensive block reorganizes." |

**Common translations (author a glossary per lesson):**

| Tactical term | Young version |
|---------------|---------------|
| "half-space" | "the gap between the wing and center" |
| "press trigger" | "the signal that tells the team to go" |
| "passing lane" | "the invisible road for the ball" |
| "cover shadow" | "the area behind you where you can't see" |
| "third-man run" | "sneaking in after two teammates pass" |
| "switch the play" | "send the ball to the other side" |
| "overload" | "more of us than them in one spot" |

### Content Authoring Task

For each existing tactical lesson in `AnimatedTacticalLessonRegistry`:
1. Identify all `narration` strings
2. Author `narrationYoung` variant using the glossary
3. Keep both semantically equivalent — young version shouldn't omit content, just simplify

### ViewModel Integration

Already in F1 — `LessonPlayerViewModel.preferredNarration(for:)` selects by age.

### Voice Integration

**File: `PitchDreams/Core/Voice/CoachVoice.swift`** (modify)

Adjust speech rate for young users (slightly slower):

```swift
func speak(_ text: String, forYoungUser: Bool = false) {
    let utterance = AVSpeechUtterance(string: text)
    utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
    utterance.rate = forYoungUser ? 0.45 : 0.5   // default is 0.5
    utterance.pitchMultiplier = 1.0
    synthesizer.speak(utterance)
}
```

### Effort
- Engine: 1 hour (the model change is trivial)
- Content authoring: 3-4 days for all existing lessons (this is the bulk of the work)

---

## F3. Tap-to-Explain (Interactive Pause)

**Concept:** Any element on the pitch is tappable at any time. Tap pauses the animation and shows a speech bubble describing what that element is doing/thinking in plain language.

### Model Changes

**File: `PitchDreams/Models/AnimatedTacticalTypes.swift`**

```swift
struct TacticalPlayer: Identifiable {
    // ... existing fields
    let tapDescription: String?        // 12+ version
    let tapDescriptionYoung: String?   // 8-11 version
}

// Same additions to TacticalArrow and TacticalZone
struct TacticalArrow: Identifiable {
    // ... existing
    let tapDescription: String?
    let tapDescriptionYoung: String?
}

struct TacticalZone: Identifiable {
    // ... existing
    let tapDescription: String?
    let tapDescriptionYoung: String?
}
```

### New View

**New file: `PitchDreams/Features/Learn/Views/ElementSpeechBubble.swift`**

```swift
struct ElementSpeechBubble: View {
    let text: String
    let position: CGPoint
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0

    var body: some View {
        VStack(spacing: 6) {
            Text(text)
                .font(DSFont.headline(14, weight: .semibold))
                .foregroundStyle(Color.dsOnSurface)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.dsSurfaceContainer)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.dsSecondary, lineWidth: 2)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.3), radius: 8, y: 4)

            // Bubble tail pointing to element
            Triangle()
                .fill(Color.dsSurfaceContainer)
                .frame(width: 12, height: 8)
                .overlay(
                    Triangle().stroke(Color.dsSecondary, lineWidth: 2)
                )
        }
        .scaleEffect(scale)
        .position(position)
        .onAppear {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                scale = 1.0
            }
        }
        .onTapGesture {
            dismiss()
        }
        // Tap anywhere outside also dismisses — handled by parent
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            scale = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
```

### ViewModel Changes

**File: `PitchDreams/Features/Learn/ViewModels/LessonPlayerViewModel.swift`** (modify)

```swift
@Published var activeBubble: SpeechBubbleState?

struct SpeechBubbleState {
    let text: String
    let position: CGPoint
}

func showBubble(for player: TacticalPlayer, at position: CGPoint) {
    pauseAnimation()
    let text = preferredDescription(player: player)
    guard let text else { return }
    activeBubble = SpeechBubbleState(text: text, position: position)
}

func showBubble(for arrow: TacticalArrow, at position: CGPoint) {
    pauseAnimation()
    let text = preferredDescription(arrow: arrow)
    guard let text else { return }
    activeBubble = SpeechBubbleState(text: text, position: position)
}

func showBubble(for zone: TacticalZone, at position: CGPoint) {
    pauseAnimation()
    let text = preferredDescription(zone: zone)
    guard let text else { return }
    activeBubble = SpeechBubbleState(text: text, position: position)
}

func dismissBubble() {
    activeBubble = nil
    resumeAnimation()
}

private func preferredDescription(player: TacticalPlayer) -> String? {
    if isYoungUser, let young = player.tapDescriptionYoung { return young }
    return player.tapDescription
}
private func preferredDescription(arrow: TacticalArrow) -> String? {
    if isYoungUser, let young = arrow.tapDescriptionYoung { return young }
    return arrow.tapDescription
}
private func preferredDescription(zone: TacticalZone) -> String? {
    if isYoungUser, let young = zone.tapDescriptionYoung { return young }
    return zone.tapDescription
}
```

### View Integration

**File: `PitchDreams/Features/Learn/Views/LessonPlayerView.swift`** (modify)

Wire up tap handlers:

```swift
AnimatedTacticalPitchView(
    diagram: viewModel.currentStep.diagram,
    stepIndex: viewModel.currentStepIndex,
    spotlightElementId: viewModel.currentStep.spotlightElementId,
    spotlightCaption: viewModel.spotlightCaption,
    onSpotlightPhaseEnd: viewModel.onSpotlightPhaseEnd,
    onPlayerTap: viewModel.showBubble(for:at:),
    onArrowTap: viewModel.showBubble(for:at:),
    onZoneTap: viewModel.showBubble(for:at:)
)
.overlay {
    if let bubble = viewModel.activeBubble {
        ElementSpeechBubble(
            text: bubble.text,
            position: bubble.position,
            onDismiss: viewModel.dismissBubble
        )
    }
}
.onTapGesture {
    // Tap outside dismisses bubble
    if viewModel.activeBubble != nil {
        viewModel.dismissBubble()
    }
}
```

### Content Authoring

For each player/arrow/zone in each lesson, author tap descriptions.

**Example** — a striker in a "finding space" lesson:
- `tapDescription`: "I'm reading the defender's hips. When they open up, I'll attack the far post."
- `tapDescriptionYoung`: "I'm watching where the defender's body points. When they turn, I'll run past them!"

Prioritize authoring tap descriptions for:
1. The highlighted "self" player (most important)
2. The ball (always)
3. Key opposition players in the step
4. Important zones

### Effort
- Engine: 2 days
- Content authoring: ~1 day per complex lesson for comprehensive descriptions; start with priority lessons

---

## F4. Slow-Mo Replay

**Concept:** A prominent "🐢 Slow-Mo" button on the lesson player. Plays the current step at 0.5x speed with extended narration.

### View Changes

**File: `PitchDreams/Features/Learn/Views/LessonPlayerView.swift`** (modify)

Add slow-mo button to the control bar:

```swift
HStack(spacing: 16) {
    Button { viewModel.replaySlowMo() } label: {
        HStack(spacing: 6) {
            Image(systemName: "tortoise.fill")
            Text("Slow-Mo")
                .font(DSFont.headline(12, weight: .bold))
                .tracking(1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.dsSurfaceContainer)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.dsSecondary.opacity(0.5), lineWidth: 1))
    }
    .buttonStyle(.plain)

    Spacer()

    // existing next/previous buttons
}
```

### ViewModel Changes

```swift
@Published var playbackRate: PlaybackRate = .normal

enum PlaybackRate {
    case normal   // 1.0x
    case slowMo   // 0.5x
}

func replaySlowMo() {
    playbackRate = .slowMo
    restartCurrentStep()
    // Narration triggers with slow-mo rate
    if let voice = voice {
        let text = preferredNarration(for: currentStep)
        voice.speak(text, forYoungUser: isYoungUser, rate: 0.35)  // slower speech
    }
    // Schedule reset to normal after step completes
    DispatchQueue.main.asyncAfter(deadline: .now() + currentStep.duration * 2) {
        self.playbackRate = .normal
    }
}
```

### Animation Rate Propagation

**File: `PitchDreams/Features/Learn/Views/AnimatedTacticalPitchView.swift`** (modify)

Accept a `playbackRate: Double` parameter and apply to all animations:

```swift
let playbackRate: Double  // 1.0 = normal, 0.5 = slow-mo

// In transitions:
withAnimation(.easeOut(duration: 0.4 / playbackRate)) {
    appeared = true
}
```

### Voice Integration

**File: `PitchDreams/Core/Voice/CoachVoice.swift`**

```swift
func speak(_ text: String, forYoungUser: Bool = false, rate: Float? = nil) {
    let utterance = AVSpeechUtterance(string: text)
    utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
    if let r = rate {
        utterance.rate = r
    } else {
        utterance.rate = forYoungUser ? 0.45 : 0.5
    }
    synthesizer.speak(utterance)
}
```

### Effort
- Engine: 0.5 days

---

## F5. Your Avatar Is the Player

**Concept:** In tactical diagrams, the primary/highlighted player (`type == .self_`) renders as the kid's actual avatar (Wolf, Lion, etc.), not an abstract dot. Creates immediate emotional investment.

### View Changes

**File: `PitchDreams/Features/Learn/Views/AnimatedTacticalPitchView.swift`** (modify)

Update `PlayerDot` view:

```swift
struct PlayerDot: View {
    let player: TacticalPlayer
    let size: CGSize
    let appeared: Bool
    let reduceMotion: Bool
    let userAvatarId: String?       // NEW — injected from parent
    let userTotalXP: Int            // NEW — for evolution stage
    let onTap: () -> Void

    var body: some View {
        Group {
            if player.type == .self_, let avatarId = userAvatarId {
                // Render user's actual avatar art
                let assetName = Avatar.assetName(for: avatarId, totalXP: userTotalXP)
                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 34, height: 34)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(Color.dsSecondary, lineWidth: 2)
                    )
                    .shadow(color: Color.dsSecondary.opacity(0.5), radius: 6)
            } else {
                // Abstract dot for teammates / opponents
                Circle()
                    .fill(colorForType(player.type))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Text(player.label ?? "")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    )
            }
        }
        .position(
            x: size.width * player.x / 100,
            y: size.height * player.y / 100
        )
        .scaleEffect(appeared ? 1.0 : 0.3)
        .opacity(appeared ? 1.0 : 0)
        .animation(reduceMotion ? .none : .spring(response: 0.5, dampingFraction: 0.6), value: appeared)
        .onTapGesture {
            onTap()
        }
    }

    private func colorForType(_ type: PlayerType) -> Color {
        switch type {
        case .self_:     return Color.dsSecondary
        case .teammate:  return Color(hex: "#46E5F8")
        case .opponent:  return Color(hex: "#EF4444")
        }
    }
}
```

### Pass-Through from LessonPlayerView

**File: `PitchDreams/Features/Learn/Views/LessonPlayerView.swift`** (modify)

Expose avatar/XP to `AnimatedTacticalPitchView`:

```swift
AnimatedTacticalPitchView(
    diagram: viewModel.currentStep.diagram,
    stepIndex: viewModel.currentStepIndex,
    userAvatarId: viewModel.userAvatarId,
    userTotalXP: viewModel.userTotalXP,
    // ... other params
)
```

### ViewModel Changes

```swift
@Published var userAvatarId: String?
@Published var userTotalXP: Int = 0

func loadUserData() async {
    if let profile: ChildProfileDetail = try? await apiClient.request(
        APIRouter.getChildProfile(childId: childId)
    ) {
        userAvatarId = profile.avatarId
    }
    userTotalXP = await xpStore.getTotalXP(childId: childId)
}
```

### Narration Language

Narration scripts should optionally reference "you" when the `self_` player is on screen:
- Before: "The midfielder scans the field."
- After (young): "The Wolf — that's you! — scans the field."
- After (standard): "You scan the field — that's your player."

This is achieved by having the young narration variant reference "you."

### Effort
- Engine: 0.5 days

---

## F6. Cause-and-Effect Shadow Replay

**Concept:** For lessons teaching WHY a technique matters, show the bad outcome first ("what happens if we DON'T do this"), then the good one. Makes the concept visceral.

### Model Changes

**File: `PitchDreams/Models/AnimatedTacticalTypes.swift`**

```swift
struct ShadowStep: Codable {
    let narration: String
    let narrationYoung: String?
    let diagram: TacticalDiagramState
    let duration: TimeInterval
    let outcomeLabel: String       // "The ball gets stolen"
    let outcomeLabelYoung: String? // "Oops! They took the ball"
    let outcomeEmoji: String       // "😞" or similar
}

struct TacticalStep {
    // ... existing
    let shadowStep: ShadowStep?   // optional — only for lessons where it adds value
}
```

### ViewModel Flow

**File: `PitchDreams/Features/Learn/ViewModels/LessonPlayerViewModel.swift`** (modify)

```swift
@Published var shadowPhase: ShadowPhase = .notPlaying

enum ShadowPhase {
    case notPlaying
    case playingShadow       // "What NOT to do"
    case transitioning       // Between shadow and real
    case playingReal         // "Do this instead"
}

func onAppear() {
    if let shadow = currentStep.shadowStep {
        playShadowSequence(shadow: shadow)
    } else {
        playRegularStep()
    }
}

private func playShadowSequence(shadow: ShadowStep) {
    shadowPhase = .playingShadow
    let text = isYoungUser ? (shadow.narrationYoung ?? shadow.narration) : shadow.narration
    voice?.speak("Here's what NOT to do. \(text)", forYoungUser: isYoungUser)
    DispatchQueue.main.asyncAfter(deadline: .now() + shadow.duration) {
        self.shadowPhase = .transitioning
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.shadowPhase = .playingReal
            self.playRegularStep()
        }
    }
}
```

### View Treatment

During `.playingShadow`:
- Top banner: "What NOT to do" in red (`Color.dsError`) with `outcomeEmoji`
- Diagram tinted slightly red (negative visual cue)
- Gentle "oops" sound when step ends

During `.transitioning`:
- Brief swipe animation
- Banner swaps to "Do this instead" in green

During `.playingReal`:
- Banner: "Do this instead" with checkmark
- Full green/positive tint
- Success chime when step ends

### Which Lessons Get Shadow Steps?

Author shadow steps for lessons teaching a *technique or discipline* (contrast-worthy):
- ✅ "Scan Before Receiving" (shadow: receive without scanning → get tackled)
- ✅ "Open Body Position" (shadow: closed body → can only pass backward)
- ✅ "First Touch Away From Pressure" (shadow: first touch into pressure → lose ball)
- ❌ "Understanding 4-3-3 Formation" (conceptual, no clear bad outcome)

Aim for ~30-40% of lessons having shadow steps.

### Effort
- Engine: 1 day
- Content authoring: ~30 min per shadow step; plan for 1 week of content

---

## F7. Mini-Quiz Comprehension Check

**Concept:** At the end of each lesson, a 2-3 question tap-based quiz reinforces comprehension. Not pass/fail — wrong answers trigger a replay suggestion.

### Model Changes

**New file: `PitchDreams/Models/LessonQuiz.swift`**

```swift
import Foundation

struct LessonQuiz: Codable, Equatable {
    let questions: [QuizQuestion]
}

struct QuizQuestion: Codable, Equatable, Identifiable {
    let id: String
    let question: String
    let questionYoung: String?
    let type: QuizQuestionType
    let suggestedReplayStepIndex: Int?  // if wrong, replay this step
}

enum QuizQuestionType: Codable, Equatable {
    /// Tap on a specific location on the pitch diagram.
    /// Correct answer is within `radiusPercent` of (targetX, targetY).
    case tapOnPitch(
        targetX: Double,           // 0-100
        targetY: Double,
        radiusPercent: Double,     // tolerance
        referenceDiagram: TacticalDiagramState
    )
    /// Tap on one of the displayed players by id.
    case tapOnPlayer(
        correctPlayerId: String,
        referenceDiagram: TacticalDiagramState
    )
    /// Multiple choice with visual options.
    case multipleChoice(
        options: [QuizOption],
        correctOptionId: String
    )
}

struct QuizOption: Codable, Equatable, Identifiable {
    let id: String
    let label: String
    let labelYoung: String?
    let iconSymbolName: String?
    let imageAsset: String?
}
```

### ViewModel Changes

**File: `PitchDreams/Features/Learn/ViewModels/LessonPlayerViewModel.swift`**

```swift
@Published var showingQuiz = false
@Published var quizIndex = 0
@Published var quizFeedback: QuizFeedback?

struct QuizFeedback {
    let isCorrect: Bool
    let suggestedReplayStepIndex: Int?
}

func stepCompleted() {
    if currentStepIndex == totalSteps - 1 {
        // End of lesson — check for quiz
        if let quiz = lesson.finalQuiz {
            showingQuiz = true
            quizIndex = 0
        } else {
            markCompleted()
        }
    } else {
        goToNext()
    }
}

func handleQuizAnswer(questionId: String, userAnswer: QuizAnswer) {
    guard let quiz = lesson.finalQuiz else { return }
    let question = quiz.questions[quizIndex]
    let isCorrect = evaluateAnswer(question: question, userAnswer: userAnswer)
    quizFeedback = QuizFeedback(
        isCorrect: isCorrect,
        suggestedReplayStepIndex: isCorrect ? nil : question.suggestedReplayStepIndex
    )

    if isCorrect {
        // Award XP bonus
        Task { _ = await xpStore.addXP(15, childId: childId) }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    } else {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}

func nextQuizQuestion() {
    guard let quiz = lesson.finalQuiz else { return }
    quizFeedback = nil
    if quizIndex < quiz.questions.count - 1 {
        quizIndex += 1
    } else {
        showingQuiz = false
        markCompleted()
    }
}

enum QuizAnswer {
    case tap(CGPoint, pitchSize: CGSize)
    case player(String)  // player id
    case option(String)  // option id
}

private func evaluateAnswer(question: QuizQuestion, userAnswer: QuizAnswer) -> Bool {
    switch (question.type, userAnswer) {
    case let (.tapOnPitch(targetX, targetY, radiusPercent, _), .tap(point, size)):
        let userPctX = Double(point.x / size.width) * 100
        let userPctY = Double(point.y / size.height) * 100
        let dx = userPctX - targetX
        let dy = userPctY - targetY
        return sqrt(dx*dx + dy*dy) <= radiusPercent
    case let (.tapOnPlayer(correctId, _), .player(tappedId)):
        return correctId == tappedId
    case let (.multipleChoice(_, correctId), .option(chosenId)):
        return correctId == chosenId
    default:
        return false
    }
}
```

### New View

**New file: `PitchDreams/Features/Learn/Views/LessonQuizView.swift`**

Full-screen quiz display with:
- Progress indicator ("Question 2 of 3")
- Question text (age-adaptive)
- Interactive answer area (pitch diagram, player grid, or MCQ buttons)
- Feedback state:
  - ✅ Correct: green pulse + "+15 XP" + "Next" button
  - ❌ Wrong: gentle amber "Hmm, let's watch that step again" + "Replay Step" button that replays the suggested step, then retries the quiz question

```swift
struct LessonQuizView: View {
    @ObservedObject var viewModel: LessonPlayerViewModel
    let childAge: Int?

    var body: some View {
        VStack(spacing: 24) {
            // Header
            Text("Check What You Learned")
                .font(DSFont.headline(20, weight: .heavy))
                .foregroundStyle(Color.dsOnSurface)

            // Progress
            HStack(spacing: 4) {
                ForEach(0..<(viewModel.lesson.finalQuiz?.questions.count ?? 0), id: \.self) { idx in
                    Capsule()
                        .fill(idx <= viewModel.quizIndex ? Color.dsSecondary : Color.dsSurfaceContainerHigh)
                        .frame(height: 4)
                }
            }

            // Question
            if let question = viewModel.currentQuestion {
                Text(preferredQuestionText(question))
                    .font(DSFont.headline(18, weight: .semibold))
                    .foregroundStyle(Color.dsOnSurface)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Answer UI — switches on type
                answerView(for: question)

                // Feedback
                if let feedback = viewModel.quizFeedback {
                    feedbackCard(feedback)
                }
            }
        }
        .padding()
        .background(Color.dsBackground)
    }

    @ViewBuilder
    private func answerView(for question: QuizQuestion) -> some View {
        switch question.type {
        case let .tapOnPitch(_, _, _, diagram):
            TapOnPitchQuizAnswer(diagram: diagram) { point, size in
                viewModel.handleQuizAnswer(
                    questionId: question.id,
                    userAnswer: .tap(point, pitchSize: size)
                )
            }
        case let .tapOnPlayer(_, diagram):
            TapOnPlayerQuizAnswer(diagram: diagram) { playerId in
                viewModel.handleQuizAnswer(
                    questionId: question.id,
                    userAnswer: .player(playerId)
                )
            }
        case let .multipleChoice(options, _):
            MultipleChoiceQuizAnswer(options: options, isYoung: isYoung) { optionId in
                viewModel.handleQuizAnswer(
                    questionId: question.id,
                    userAnswer: .option(optionId)
                )
            }
        }
    }

    @ViewBuilder
    private func feedbackCard(_ feedback: QuizFeedback) -> some View {
        if feedback.isCorrect {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.green)
                Text("Got it! +15 XP")
                    .font(DSFont.headline(16, weight: .bold))
                Spacer()
                Button("Next") { viewModel.nextQuizQuestion() }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color.green.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            VStack {
                HStack {
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundStyle(Color.orange)
                    Text(isYoung ? "Almost! Let's watch that again." : "Not quite. Review the key step.")
                        .font(DSFont.headline(14, weight: .semibold))
                }
                HStack {
                    Button("Replay Step") {
                        if let idx = feedback.suggestedReplayStepIndex {
                            viewModel.goToStep(idx)
                            viewModel.showingQuiz = false
                            // After the step, quiz re-opens to this question
                        }
                    }
                    Button("Try Again") {
                        viewModel.quizFeedback = nil
                    }
                }
            }
            .padding()
            .background(Color.orange.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var isYoung: Bool { (childAge ?? 12) <= 11 }

    private func preferredQuestionText(_ q: QuizQuestion) -> String {
        if isYoung, let young = q.questionYoung { return young }
        return q.question
    }
}
```

### Content Authoring

Each lesson gets 2-3 quiz questions. Example for "Scan Before Receiving":

```swift
LessonQuiz(questions: [
    QuizQuestion(
        id: "q1",
        question: "How many times should you scan before receiving?",
        questionYoung: "How many times should you look around before the ball gets to you?",
        type: .multipleChoice(
            options: [
                QuizOption(id: "a", label: "Once", labelYoung: "1 time", iconSymbolName: "1.circle", imageAsset: nil),
                QuizOption(id: "b", label: "Twice", labelYoung: "2 times", iconSymbolName: "2.circle", imageAsset: nil),
                QuizOption(id: "c", label: "Three times", labelYoung: "3 times", iconSymbolName: "3.circle", imageAsset: nil),
                QuizOption(id: "d", label: "Never", labelYoung: "0 times", iconSymbolName: "xmark.circle", imageAsset: nil)
            ],
            correctOptionId: "b"
        ),
        suggestedReplayStepIndex: 0
    ),
    QuizQuestion(
        id: "q2",
        question: "Tap the open teammate.",
        questionYoung: "Tap the friend who has space!",
        type: .tapOnPlayer(
            correctPlayerId: "player-wing-teammate",
            referenceDiagram: /* specific diagram with open player */
        ),
        suggestedReplayStepIndex: 2
    )
])
```

### Effort
- Engine: 2-3 days
- Content authoring: ~20 min per question; plan for 1-2 days per full lesson set

---

## Rollout Plan

### Launch MVP (Week 3 of Launch Plan)
Ship F1 + F2 + F4 + F5 (the highest-impact, lowest-content-effort subset):
- **F1 Spotlight Mode** (1 day engine + 1-2 days content)
- **F2 Age-Adaptive Narration** (1 hour engine + 3-4 days content — can ship partial, expand over time)
- **F4 Slow-Mo Replay** (0.5 days)
- **F5 Avatar-as-Player** (0.5 days)

**Total launch effort:** ~6 days engine + content can grow after launch

### Post-Launch Month 1
Ship F3 + F6:
- **F3 Tap-to-Explain** (2 days engine + ongoing content)
- **F6 Cause-and-Effect Shadow** (1 day engine + ongoing content)

### Post-Launch Month 2
Ship F7:
- **F7 Mini-Quiz** (2-3 days engine + ongoing content)
- Quiz content becomes a recurring content deliverable (2-3 questions per lesson, priority on most-used lessons)

---

## File Checklist

### New Files

```
PitchDreams/
  Features/
    Learn/
      Views/
        ElementSpeechBubble.swift       # F3
        LessonQuizView.swift             # F7
        TapOnPitchQuizAnswer.swift       # F7
        TapOnPlayerQuizAnswer.swift      # F7
        MultipleChoiceQuizAnswer.swift   # F7
  Models/
    LessonQuiz.swift                     # F7

PitchDreamsTests/
  Features/
    LessonPlayerViewModelTests.swift     # expand existing
    LessonQuizTests.swift                # F7 evaluation logic
```

### Files to Modify

```
PitchDreams/Models/AnimatedTacticalTypes.swift                # F1, F2, F3, F6, F7 — add fields
PitchDreams/Models/AnimatedTacticalLessonRegistry.swift       # Content authoring for ALL existing lessons
PitchDreams/Features/Learn/Views/AnimatedTacticalPitchView.swift  # F1 spotlight, F4 rate, F5 avatar
PitchDreams/Features/Learn/Views/LessonPlayerView.swift       # F1, F3, F4, F5, F6, F7 — UI integration
PitchDreams/Features/Learn/ViewModels/LessonPlayerViewModel.swift  # All F features
PitchDreams/Core/Voice/CoachVoice.swift                       # F2, F4 — rate control
```

---

## Testing Strategy

### The Critical Test: 8-Year-Old Completion

Recruit 3-5 kids ages 8-10 (your network's soccer parents' kids). Observe them:
1. Complete onboarding
2. Open a tactical lesson they've never seen
3. Attempt to complete it without adult help

**Pass criteria:**
- Kid finishes the lesson without asking "what does that mean?"
- Kid correctly answers at least 2 of 3 mini-quiz questions
- Kid can explain (in their own words) the main idea of the lesson afterward
- Kid engaged and enjoyed it (not bored, not frustrated)

**Fail signals to act on:**
- Asks what a word means → F2 narration authoring needs deeper simplification
- Misses quiz question → F6 shadow or F3 tap-to-explain is missing for that concept
- Loses attention → step duration too long, or too many elements in diagram
- Frustration with quiz → add hint escalation

Iterate content until 80%+ pass rate.

### Unit Tests

```swift
// LessonPlayerViewModelTests (expand existing)
- testPreferredNarration_youngUser_returnsYoungVariant
- testPreferredNarration_standardUser_returnsStandard
- testPreferredNarration_youngUserNoVariant_fallsBack
- testSpotlightPhase_plays_beforeMainAnimation
- testSpotlightPhase_skippedWhenIdNil
- testShadowStep_playsBeforeRealStep
- testShadowPhase_transitions
- testTapShowsBubble_pausesAnimation
- testDismissBubble_resumesAnimation
- testQuizCorrectAnswer_awardsXP
- testQuizWrongAnswer_showsReplaySuggestion
- testEvaluateAnswer_tapWithinRadius_correct
- testEvaluateAnswer_tapOutsideRadius_wrong
- testEvaluateAnswer_playerCorrect
- testEvaluateAnswer_optionCorrect
- testSlowMoMode_halvesRate
```

### Accessibility

- All new views support VoiceOver with descriptive labels
- Reduce Motion disables spotlight pulse, shadow transitions, and quiz feedback animations (still shows results, just static)
- Dynamic Type supported on all text
- Quiz answers should be reachable via keyboard (iPad keyboard navigation)

---

## Success Criteria (Track F)

### Launch MVP (F1, F2, F4, F5)
- [ ] Spotlight phase plays before each step animation
- [ ] Spotlight caption displayed in correct language for child's age
- [ ] `narrationYoung` variants authored for all existing tactical lessons
- [ ] Coach voice reads correct variant based on age
- [ ] Slow-mo button present on lesson player, works at 0.5x
- [ ] Slow-mo narration uses slower speech rate
- [ ] `self_` player type renders as user's avatar image at correct evolution stage
- [ ] Legacy lessons without avatar assignments gracefully fall back to abstract dots

### Post-Launch (F3, F6, F7)
- [ ] Tap-to-explain speech bubbles work on all pitch elements
- [ ] Bubble dismisses on tap-outside
- [ ] Animation pauses while bubble shown, resumes on dismiss
- [ ] Shadow steps authored for at least 30% of lessons (priority: technique-focused)
- [ ] "What NOT to do" vs "Do this" visual treatment works end-to-end
- [ ] Quiz questions appear at end of every lesson
- [ ] Correct answers award 15 XP + success feedback
- [ ] Wrong answers suggest replay step with one-tap navigation
- [ ] Tap-on-pitch quiz type evaluates within defined radius
- [ ] Multiple choice quiz type works with icon options

### The Ultimate Gate
- [ ] **3 out of 5 tested 8-year-olds can complete a tactical lesson and answer the comprehension quiz correctly without parent help**

If this gate isn't passing, ship is not ready regardless of other checkboxes.

---

## Dependencies & Coordination

### Content Team (Content Writer / Designer)
Track F is content-heavy. Engine work is ~5 days total; content authoring is ~10-15 days spread across launch and post-launch:
- Glossary of tactical → young translations
- `narrationYoung` for all existing steps
- `spotlightElementId` + captions for all steps
- Tap descriptions for all elements (F3)
- Shadow step authoring for eligible lessons (F6)
- Quiz question writing for all lessons (F7)

### Voice Team
If switching from AVSpeechSynthesizer to real recorded coach audio, both `narration` and `narrationYoung` need recordings. Currently using synthesis — acceptable for launch, recording is a post-launch enhancement.

### Testing Team
Kid-testing sessions with real 8-10 year olds are the only real signal. Recruit through soccer parent network. Budget 2-3 test sessions before launch.
