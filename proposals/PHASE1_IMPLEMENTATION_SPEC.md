# Phase 1 Implementation Spec: XP + Avatar Evolution + Weekly Recap + Quick Wins

**Goal:** Ship the highest-impact individual features that work with a single user and make the app feel premium, sticky, and delightful.

**Scope:** 4 workstreams, ordered by dependency:
1. XP System Unified with Avatar Evolution (foundation for everything else)
2. Enhanced Streaks with Streak Shields
3. Weekly Recap Shareable Card
4. Haptic & Animation Polish Pass (quick wins)

**Not in scope (Phase 2+):** Leagues, Squad Challenges, Mental Game Toolkit, Global Leaderboards.

---

## CRITICAL: Design-First Workflow — Create Stitch Mockups via Chrome

**Every new screen or significant UI component MUST be designed in Google Stitch before implementation.** This is the established workflow — `AvatarSelectionStepView` was implemented from a Stitch mockup (`onboarding_choose_avatar_1`), and all previous design work has been done by navigating to Google Stitch in Chrome and creating mockups interactively.

### How to Create Stitch Mockups

1. **Open Google Stitch** in Chrome using browser automation (`mcp__Claude_in_Chrome__navigate` to `stitch.google.com` or the project's Stitch workspace)
2. **Create each mockup** using the design guidelines below, naming it exactly as specified in the table
3. **Take a screenshot** of each completed mockup for reference during implementation
4. **Only then** proceed to implement the corresponding SwiftUI view

### Stitch Mockups Required (create these BEFORE writing any view code)

| Mockup Name | Description | Priority |
|-------------|-------------|----------|
| `home_xp_bar` | XP progress bar on home dashboard, showing XP within current avatar stage, next evolution threshold | P0 — blocks Workstream 1 |
| `home_xp_earned_toast` | Floating toast that appears after a session showing "+45 XP" with avatar thumbnail | P0 — blocks Workstream 1 |
| `evolution_celebration_enhanced` | Enhanced evolution modal when avatar evolves (Rookie->Pro, Pro->Legend), showing before/after avatar art with XP milestone | P0 — blocks Workstream 1 |
| `weekly_recap_card` | The shareable card (390x520pt Instagram Stories format) with week stats, avatar, streak, XP | P0 — blocks Workstream 3 |
| `weekly_recap_sheet` | Full-screen sheet containing the recap card + share button + dismiss | P1 — blocks Workstream 3 |
| `shield_deployed_toast` | Toast overlay when streak freeze is auto-applied | P1 — blocks Workstream 2 |
| `streak_ring_enhanced` | Updated ConsistencyRing with escalating flame sizes and shield bank | P1 — blocks Workstream 2 |

### Stitch Design Guidelines

Match existing app visual language (the "Starlight Pitch" dark design system):
- Dark background: `#0C1322` (dsBackground)
- Surface cards: `#191F2F` (dsSurfaceContainer)
- Primary accent: `#FF6B2C` (dsAccentOrange)
- Secondary accent: `#46E5F8` (dsSecondary/cyan)
- Tertiary: `#FFE9BD` (dsTertiary/gold)
- CTA gradient: peach `#FFE6DE` → `#FFD4C8`
- Typography: SF Rounded, heavy/bold weights, uppercase labels with 2-3pt tracking
- Card corners: 16pt radius with 1px ghost border (`white 5% opacity`)
- Avatar art appears at current evolution stage
- No `.regularMaterial` — use explicit dark surface colors
- Section headers: uppercase, 12pt heavy rounded, 3pt tracking, cyan or orange accent

Reference existing Stitch mockups for tone: `onboarding_choose_avatar_1`, and the evolution modal visual language. The overall aesthetic is dark editorial/dossier with a premium sports-tech feel.

---

## Architecture: Unified XP + Avatar Evolution

### The Problem with the Original Spec

The original spec introduced 6 named tiers (Rookie, Amateur, Semi-Pro, Professional, World Class, Legend) that **conflict** with the existing avatar evolution system which already has 3 stages (Rookie, Pro, Legend) tied to streak milestones and mission XP.

### The Solution: XP Is the Fuel, Avatar Evolution Is the Reward

XP becomes the **single currency** driving avatar evolution. No separate tier names. The visible progression a player cares about is their avatar evolving from Rookie Wolf → Pro Wolf → Legend Wolf.

**Current system** (`Avatar.swift`):
```swift
// AvatarStage.current() currently uses:
// - Streak milestones (7 days → Pro, 30 days → Legend)
// - OR local mission XP (50 XP → Pro, 200 XP → Legend)
```

**New system**: Replace both inputs with total XP as the sole driver:
```swift
// AvatarStage.current() will use:
// - Total XP (threshold TBD via Stitch mockup iteration, but roughly: 500 XP → Pro, 2000 XP → Legend)
// - Streak milestones STILL MATTER — they award bonus XP, which flows into evolution
// - Mission XP STILL MATTERS — same flow
```

This means:
- **One progression system**, not three competing ones
- XP bar shows progress toward the **next avatar evolution** (not an abstract "level")
- The celebration moment is your avatar evolving — the most emotionally resonant thing in the app
- Streaks and missions are XP sources, not separate progression tracks

---

## Architecture Patterns (Follow These Exactly)

The codebase uses strict conventions. Every new feature must follow them:

- **ViewModels:** `@MainActor final class FooViewModel: ObservableObject` with `@Published` state, DI via `apiClient: APIClientProtocol = APIClient()` in init
- **Views:** `@StateObject private var viewModel` initialized in `init()`, use `ChildHomeView` pattern
- **Models:** `struct Foo: Codable` in `PitchDreams/Models/`
- **API Routes:** Add cases to `APIRouter` enum in `Core/API/APIRouter.swift`
- **Design tokens:** Use `Color.ds*`, `DSGradient.*`, `DSFont.*`, `Spacing.*`, `CornerRadius.*` from `DesignSystem.swift` — never hardcode colors/fonts
- **Celebrations:** Use `.celebration(isPresented:)` modifier and `ConfettiView`
- **Haptics:** Use `UIImpactFeedbackGenerator` (existing pattern in tab bar)
- **Tests:** `MockAPIClient` with `.enqueue()` / `.enqueueError()`, `TestFixtures` for model builders
- **File organization:** `Features/{FeatureName}/Views/`, `Features/{FeatureName}/ViewModels/`
- **After adding files:** Run `xcodegen generate` (project uses XcodeGen via `project.yml`)

---

## Workstream 1: XP System Unified with Avatar Evolution

### Overview
Every training activity earns XP. XP is the single currency driving avatar evolution (Rookie → Pro → Legend). An XP bar on the home dashboard shows progress toward the next evolution. When the threshold is crossed, the avatar evolves with a full celebration.

### Stitch Mockups Required BEFORE Implementation
- `home_xp_bar` — XP bar integrated into home dashboard below avatar
- `home_xp_earned_toast` — "+45 XP" toast after session completion
- `evolution_celebration_enhanced` — Enhanced `EvolutionModal` with XP milestone context

### Data Model

**New file: `PitchDreams/Models/XPLevel.swift`**

```swift
import Foundation

/// XP calculation engine. XP is the single currency driving avatar evolution.
/// There are NO separate tier names — the visible progression is avatar stages
/// (Rookie → Pro → Legend) defined in Avatar.swift.
enum XPCalculator {

    // MARK: - XP Awards

    /// XP earned for completing a training session.
    static func xpForSession(duration: Int?, effortLevel: Int?, activityType: String?) -> Int {
        var xp = 0

        // Base XP: 10 XP per 5 minutes of training
        let minutes = duration ?? 10
        xp += (minutes / 5) * 10

        // Effort bonus: high effort earns more
        if let effort = effortLevel {
            xp += effort * 5  // effort is 1-10, so 5-50 bonus
        }

        // Activity type bonus
        switch activityType?.lowercased() {
        case "drill": xp += 15
        case "game", "match": xp += 25
        case "class", "team": xp += 20
        default: xp += 10
        }

        return max(10, xp) // minimum 10 XP per session
    }

    /// Bonus XP for reaching a streak milestone.
    static func xpForStreakMilestone(_ milestone: Int) -> Int {
        switch milestone {
        case 7:   return 50
        case 14:  return 100
        case 30:  return 250
        case 100: return 1000
        default:  return 25
        }
    }

    /// Bonus XP for a new personal best.
    static let xpForPersonalBest = 25

    // MARK: - Avatar Evolution Thresholds

    /// XP required to reach each avatar stage.
    /// These thresholds replace the old milestone-based and mission-XP-based
    /// triggers in AvatarStage.current().
    static func avatarStageForXP(_ totalXP: Int) -> AvatarStage {
        if totalXP >= xpForStage(.legend) { return .legend }
        if totalXP >= xpForStage(.pro) { return .pro }
        return .rookie
    }

    /// XP threshold for a given stage.
    static func xpForStage(_ stage: AvatarStage) -> Int {
        switch stage {
        case .rookie: return 0
        case .pro:    return 500   // ~2-3 weeks of regular training
        case .legend: return 2000  // ~2-3 months of regular training
        }
    }

    /// XP progress within the current stage, as fraction 0.0–1.0.
    static func progressToNextStage(_ totalXP: Int) -> (progress: Double, xpInStage: Int, xpNeeded: Int) {
        let currentStage = avatarStageForXP(totalXP)

        guard currentStage != .legend else {
            return (progress: 1.0, xpInStage: 0, xpNeeded: 0) // maxed out
        }

        let nextStage: AvatarStage = currentStage == .rookie ? .pro : .legend
        let currentThreshold = xpForStage(currentStage)
        let nextThreshold = xpForStage(nextStage)
        let xpInStage = totalXP - currentThreshold
        let xpNeeded = nextThreshold - currentThreshold
        let progress = Double(xpInStage) / Double(xpNeeded)

        return (progress: min(1.0, progress), xpInStage: xpInStage, xpNeeded: xpNeeded)
    }
}
```

### Changes to Existing: `PitchDreams/Models/Avatar.swift`

Replace the dual-input `AvatarStage.current(forMilestones:localMissionXP:)` with XP-driven logic:

```swift
// REPLACE this method in AvatarStage:
static func current(forMilestones milestones: [Int], localMissionXP: Int = 0) -> AvatarStage

// WITH:
/// Derive avatar stage from total XP. This is now the SINGLE source of truth
/// for avatar evolution. Streak milestones and missions contribute XP, which
/// flows through here.
static func current(forTotalXP totalXP: Int) -> AvatarStage {
    XPCalculator.avatarStageForXP(totalXP)
}

/// Legacy convenience — reads XP from store for the given child.
/// Call sites that previously passed milestones should migrate to pass totalXP.
@available(*, deprecated, message: "Use current(forTotalXP:) instead")
static func current(forMilestones milestones: [Int], localMissionXP: Int = 0) -> AvatarStage {
    // Keep backward compat during migration: use mission XP as proxy
    current(forTotalXP: localMissionXP)
}
```

Also update `Avatar.assetName(for:milestones:localMissionXP:)` → `Avatar.assetName(for:totalXP:)`:

```swift
/// Resolve the right asset name from a stored avatarId + the child's total XP.
static func assetName(for avatarId: String?, totalXP: Int) -> String {
    let avatar = resolve(avatarId)
    let stage = AvatarStage.current(forTotalXP: totalXP)
    return avatar.assetName(stage: stage)
}
```

**Important:** Grep the codebase for all call sites of `AvatarStage.current(forMilestones:` and `Avatar.assetName(for:milestones:` and migrate them to use totalXP. Key files:
- `ChildHomeView.swift`
- `ChildHomeViewModel.swift`
- `EvolutionModal.swift`
- `AvatarChangeSheet.swift`
- `ActiveDrillView.swift`
- `CoachCharacterView.swift`
- `ParentDashboardView.swift` / `ChildDetailView.swift`

### Local Persistence

**New file: `PitchDreams/Core/Persistence/XPStore.swift`**

```swift
import Foundation

actor XPStore {
    private let defaults = UserDefaults.standard

    func getTotalXP(childId: String) -> Int {
        defaults.integer(forKey: "xp_total_\(childId)")
    }

    /// Add XP and return whether the avatar evolved.
    func addXP(_ amount: Int, childId: String) -> (
        newTotal: Int,
        evolved: Bool,
        oldStage: AvatarStage,
        newStage: AvatarStage
    ) {
        let oldTotal = getTotalXP(childId: childId)
        let oldStage = XPCalculator.avatarStageForXP(oldTotal)
        let newTotal = oldTotal + amount
        let newStage = XPCalculator.avatarStageForXP(newTotal)
        defaults.set(newTotal, forKey: "xp_total_\(childId)")
        return (newTotal, newStage != oldStage, oldStage, newStage)
    }

    func getXPHistory(childId: String) -> [XPEntry] {
        guard let data = defaults.data(forKey: "xp_history_\(childId)"),
              let entries = try? JSONDecoder().decode([XPEntry].self, from: data) else { return [] }
        return entries
    }

    func recordXPEntry(_ entry: XPEntry, childId: String) {
        var history = getXPHistory(childId: childId)
        history.append(entry)
        // Keep last 100 entries
        if history.count > 100 { history = Array(history.suffix(100)) }
        if let data = try? JSONEncoder().encode(history) {
            defaults.set(data, forKey: "xp_history_\(childId)")
        }
    }
}

struct XPEntry: Codable {
    let amount: Int
    let source: String  // "session", "drill", "first_touch", "streak_bonus", "personal_best"
    let date: Date
}
```

### Views

**New file: `PitchDreams/Features/ChildHome/Views/XPBarView.swift`**

> **PREREQUISITE: Implement from `home_xp_bar` Stitch mockup.**

An XP progress bar showing progress toward the next avatar evolution. Conceptual design (finalize in Stitch):

```
┌──────────────────────────────────────────┐
│  🐺 [avatar]   ████████░░░░░░  → Pro    │
│                 340 / 500 XP             │
└──────────────────────────────────────────┘
```

Key elements for the Stitch mockup:
- Left: small avatar image at current stage (use existing `avatar.assetName(stage:)`)
- Center: pill-shaped progress bar with gradient fill (`DSGradient.orangeAccent`)
- Right: next stage name as target ("→ Pro" or "→ Legend" or "LEGEND" if maxed)
- Below bar: "X / Y XP" text in `dsOnSurfaceVariant`
- Fill animates with `.spring(response: 0.6, dampingFraction: 0.7)` when XP changes
- Haptic `.impact(style: .light)` when the bar fills
- When at Legend (maxed): bar is full, gradient shifts to gold, shows total XP

**New file: `PitchDreams/Features/ChildHome/Views/XPEarnedToast.swift`**

> **PREREQUISITE: Implement from `home_xp_earned_toast` Stitch mockup.**

Floating toast shown briefly after earning XP:

```
    ┌──────────────────┐
    │  +45 XP  ⚡      │
    └──────────────────┘
```

- Slides in from top, auto-dismisses after 2 seconds
- Shows XP amount with a quick count-up animation
- Background: `Color.dsAccentOrange.opacity(0.15)` with orange border
- Spring slide-in animation

**Enhancement to: `PitchDreams/Features/ChildHome/Views/EvolutionModal.swift`**

> **PREREQUISITE: Update from `evolution_celebration_enhanced` Stitch mockup.**

The existing `EvolutionModal` already handles avatar evolution beautifully. Enhance it with:
- XP context: "You've earned 500 XP!" shown above the evolution
- Before/after: show the previous stage avatar shrinking as the new one scales in
- The existing spring animation and celebration modifier stay as-is
- Add haptic `.impact(style: .heavy)` on the evolution reveal moment

### Integration Points

**`ChildHomeViewModel`** — Load XP data and compute avatar stage:
```swift
// Add properties:
@Published var totalXP: Int = 0
@Published var xpProgress: (progress: Double, xpInStage: Int, xpNeeded: Int) = (0, 0, 0)
@Published var avatarStage: AvatarStage = .rookie

private let xpStore = XPStore()

// In loadData():
totalXP = await xpStore.getTotalXP(childId: childId)
xpProgress = XPCalculator.progressToNextStage(totalXP)
avatarStage = XPCalculator.avatarStageForXP(totalXP)
```

**`ChildHomeView`** — Add `XPBarView` below `ConsistencyRingView` on the home dashboard. Pass avatar, totalXP, and progress data.

**`ActiveTrainingViewModel`** — After session save succeeds, calculate and award XP:
```swift
// After successful session save in saveSession():
let xpEarned = XPCalculator.xpForSession(
    duration: elapsedSeconds / 60,
    effortLevel: nil,
    activityType: "drill"
)
let result = await xpStore.addXP(xpEarned, childId: childId)
await xpStore.recordXPEntry(
    XPEntry(amount: xpEarned, source: "drill", date: Date()),
    childId: childId
)
await MainActor.run {
    self.xpEarned = xpEarned
    self.didEvolve = result.evolved
    self.newStage = result.newStage
}
```

**`QuickLogViewModel`** — Same pattern after quick session save.

**`FirstTouchViewModel`** — Award XP after completing a first-touch drill.

### Tests

**New file: `PitchDreamsTests/Core/XPCalculatorTests.swift`**

Test cases:
- `testXPForSession_minimumIs10` — zero-duration session still earns 10 XP
- `testXPForSession_scalesWithDuration` — 30 min session earns more than 10 min
- `testXPForSession_effortBonus` — effort level 8 earns more than effort 3
- `testAvatarStageForXP_startsAtRookie` — 0 XP = Rookie
- `testAvatarStageForXP_proAt500` — 500 XP = Pro
- `testAvatarStageForXP_legendAt2000` — 2000 XP = Legend
- `testProgressToNextStage_halfwayToPro` — 250 XP → progress 0.5
- `testProgressToNextStage_legendIsMaxed` — 3000 XP → progress 1.0
- `testXPForStreakMilestone_7days` — returns 50
- `testXPForStreakMilestone_30days` — returns 250

**New file: `PitchDreamsTests/Core/XPStoreTests.swift`**

Test cases:
- `testAddXP_accumulatesCorrectly`
- `testAddXP_detectsEvolution` — crossing 500 XP triggers Pro evolution
- `testAddXP_noEvolutionWithinStage` — 400→450 XP does not evolve
- `testGetXPHistory_returnsEntriesInOrder`
- `testXPHistory_capsAt100Entries`

**Update: `PitchDreamsTests/Core/AvatarTests.swift`** (or wherever Avatar model is tested)
- `testAvatarStage_currentForTotalXP_matchesCalculator`
- `testAvatarAssetName_usesTotalXP` — verify new `assetName(for:totalXP:)` method
- `testLegacyMethod_stillWorks` — deprecated method doesn't crash

---

## Workstream 2: Enhanced Streaks with Streak Shields

### Overview
The streak system already exists (API: `getStreaks`, `checkFreeze`, `recordMilestone`; UI: `ConsistencyRingView`, `StreakMilestoneModal`). This workstream enhances it with:

1. **Streak flame that visually escalates** at milestone thresholds (7, 14, 30, 100 days)
2. **Shield bank display** — show how many shields are available, with a visual "shield deployed" animation when a freeze is used
3. **Streak bonus XP** — streak milestones award bonus XP that flows into avatar evolution

### Stitch Mockups Required BEFORE Implementation
- `streak_ring_enhanced` — Updated ConsistencyRing with escalating flame sizes and shield bank
- `shield_deployed_toast` — Toast overlay for when freeze is auto-applied

### Changes to Existing Files

**`PitchDreams/Features/ChildHome/Views/ConsistencyRingView.swift`**

> **PREREQUISITE: Implement from `streak_ring_enhanced` Stitch mockup.**

Enhance the flame icon:

```swift
// Replace static flame with escalating flame
private var flameView: some View {
    ZStack {
        Image(systemName: flameIcon)
            .font(.system(size: flameSize))
            .foregroundStyle(flameGradient)
            .symbolEffect(.pulse, options: .repeating, value: streak >= 7)
    }
}

private var flameIcon: String {
    streak >= 30 ? "flame.circle.fill" : "flame.fill"
}

private var flameSize: CGFloat {
    switch streak {
    case 0...6:   return 14
    case 7...13:  return 18
    case 14...29: return 22
    case 30...99: return 26
    default:      return 30  // 100+ days
    }
}

private var flameGradient: some ShapeStyle {
    switch streak {
    case 0...6:   return Color.dsAccentOrange  // single orange
    case 7...13:  return Color.dsAccentOrange  // brighter
    case 14...29: return Color(hex: "#FF4500") // red-orange
    default:      return Color(hex: "#FF0000") // red (legendary)
    }
}
```

Shield bank enhancements:
- Shield icon pulses gently when available (`symbolEffect(.pulse)`)
- When `FreezeCheckResult.freezeApplied == true`, show `ShieldDeployedToast`
- Haptic `.impact(style: .medium)` on shield deploy

**`PitchDreams/Features/ChildHome/Views/StreakMilestoneModal.swift`** — After awarding freeze, also award streak bonus XP:

```swift
// Add to milestone celebration — XP flows into avatar evolution:
let xpBonus = XPCalculator.xpForStreakMilestone(milestone)
let result = await xpStore.addXP(xpBonus, childId: childId)
await xpStore.recordXPEntry(
    XPEntry(amount: xpBonus, source: "streak_bonus", date: Date()),
    childId: childId
)
// If this milestone pushed the avatar to evolve, show EvolutionModal after milestone modal
if result.evolved {
    showEvolution = true
}
```

### New File: `PitchDreams/Features/ChildHome/Views/ShieldDeployedToast.swift`

> **PREREQUISITE: Implement from `shield_deployed_toast` Stitch mockup.**

A toast overlay that slides in from top when a freeze is auto-applied:
```
🛡️ Streak Shield Deployed!
Your 12-day streak is safe.
```
- Appears for 3 seconds, auto-dismisses
- Background: `Color.dsSecondary.opacity(0.15)` with cyan border
- Spring slide-in animation from top

### Tests

**Enhance `PitchDreamsTests/Features/ChildHomeViewModelTests.swift`:**
- `testFreezeCheck_whenApplied_setsShieldDeployedFlag`
- `testStreakMilestone_awardsCorrectBonusXP`
- `testStreakMilestone_canTriggerEvolution` — 30-day milestone with enough XP triggers avatar evolution

---

## Workstream 3: Weekly Recap Shareable Card

### Overview
Every Sunday (or on-demand), generate a visual card showing the week's training highlights. Designed to be screenshot-worthy and shareable. Features the player's avatar at its current evolution stage.

### Stitch Mockups Required BEFORE Implementation
- `weekly_recap_card` — The shareable card with avatar, stats, streak, XP
- `weekly_recap_sheet` — Full-screen sheet wrapper with share/dismiss

### Data Model

**New file: `PitchDreams/Models/WeeklyRecap.swift`**

```swift
import Foundation

struct WeeklyRecap {
    let weekStarting: Date
    let sessionsCompleted: Int
    let totalMinutes: Int
    let currentStreak: Int
    let xpEarned: Int          // XP earned THIS WEEK
    let totalXP: Int           // lifetime total (for avatar stage)
    let avatarId: String?      // for rendering avatar on card
    let bestDrill: String?     // name of drill with highest score
    let personalBests: Int     // number of new PBs this week
    let improvementStat: String? // e.g., "Juggling +15% this month"

    var avatarStage: AvatarStage {
        XPCalculator.avatarStageForXP(totalXP)
    }

    var formattedMinutes: String {
        if totalMinutes < 60 { return "\(totalMinutes) min" }
        let hours = totalMinutes / 60
        let mins = totalMinutes % 60
        return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
    }

    var weekLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let end = Calendar.current.date(byAdding: .day, value: 6, to: weekStarting) ?? weekStarting
        return "\(formatter.string(from: weekStarting)) - \(formatter.string(from: end))"
    }
}
```

### ViewModel

**New file: `PitchDreams/Features/ChildHome/ViewModels/WeeklyRecapViewModel.swift`**

```swift
@MainActor
final class WeeklyRecapViewModel: ObservableObject {
    @Published var recap: WeeklyRecap?
    @Published var isLoading = false

    let childId: String
    private let apiClient: APIClientProtocol
    private let xpStore: XPStore

    init(childId: String, apiClient: APIClientProtocol = APIClient(), xpStore: XPStore = XPStore()) {
        self.childId = childId
        self.apiClient = apiClient
        self.xpStore = xpStore
    }

    func loadRecap() async {
        isLoading = true
        do {
            let sessions: [SessionLog] = try await apiClient.request(
                APIRouter.listSessions(childId: childId, limit: 50)
            )
            let calendar = Calendar.current
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            let thisWeek = sessions.filter { session in
                guard let date = ISO8601DateFormatter().date(from: session.createdAt) else { return false }
                return date >= weekAgo
            }

            let totalXP = await xpStore.getTotalXP(childId: childId)

            // Calculate weekly XP from history
            let history = await xpStore.getXPHistory(childId: childId)
            let weeklyXP = history.filter { $0.date >= weekAgo }.reduce(0) { $0 + $1.amount }

            // Load profile for avatar
            let profile: ChildProfileDetail? = try? await apiClient.request(
                APIRouter.getChildProfile(childId: childId)
            )

            recap = WeeklyRecap(
                weekStarting: weekAgo,
                sessionsCompleted: thisWeek.count,
                totalMinutes: thisWeek.compactMap(\.duration).reduce(0, +),
                currentStreak: 0, // populated from streak data
                xpEarned: weeklyXP,
                totalXP: totalXP,
                avatarId: profile?.avatarId,
                bestDrill: nil,
                personalBests: 0,
                improvementStat: nil
            )
        } catch {
            recap = nil
        }
        isLoading = false
    }
}
```

### Views

**New file: `PitchDreams/Features/ChildHome/Views/WeeklyRecapCardView.swift`**

> **PREREQUISITE: Implement from `weekly_recap_card` Stitch mockup.**

The shareable card. Conceptual design (finalize in Stitch):

```
┌────────────────────────────────────┐
│     ⚽ WEEKLY RECAP               │  <- dsLabel style, tracking: 2
│     Apr 7 - Apr 13                │  <- dsOnSurfaceVariant
│                                    │
│        [🐺 Avatar]                 │  <- Avatar at current evolution stage
│                                    │
│         5                          │  <- DSFont.display(56), count-up animation
│      sessions                      │  <- dsLabel
│                                    │
│   ┌──────┐  ┌──────┐  ┌──────┐   │
│   │ 2h30 │  │  🔥12 │  │ +340 │   │  <- Three stat pills
│   │ time  │  │streak│  │  XP  │   │
│   └──────┘  └──────┘  └──────┘   │
│                                    │
│   ▪️▪️▪️▪️▪️▫️▫️                      │  <- 7-day activity dots
│   M  T  W  T  F  S  S             │
│                                    │
│         PitchDreams                │  <- Subtle watermark
└────────────────────────────────────┘
```

Design requirements:
- Background: bold gradient that changes weekly (cycle through 4-5 gradient presets)
- Avatar image rendered at current evolution stage (use `Avatar.assetName(for:totalXP:)`)
- Stat numbers use `.contentTransition(.numericText())` for count-up effect
- 7-day activity dots: filled circle for trained days, empty for missed
- Card dimensions: 390 x 520 points (optimized for Instagram Stories aspect ratio)
- All text uses `DSFont` system
- Rounded corners: `CornerRadius.xxl`

**Share functionality:**

```swift
@MainActor
func renderCard() -> UIImage? {
    let renderer = ImageRenderer(content:
        WeeklyRecapCardContent(recap: recap)
            .frame(width: 390, height: 520)
    )
    renderer.scale = UIScreen.main.scale
    return renderer.uiImage
}

func shareCard() {
    guard let image = renderCard() else { return }
    let activityVC = UIActivityViewController(
        activityItems: [image],
        applicationActivities: nil
    )
    // Present from the root view controller
}
```

**New file: `PitchDreams/Features/ChildHome/Views/WeeklyRecapSheetView.swift`**

> **PREREQUISITE: Implement from `weekly_recap_sheet` Stitch mockup.**

The presentation wrapper — shown as a `.sheet` from `ChildHomeView`:

- Full-screen card with the recap content
- "Share" button at bottom (SF Symbol: `square.and.arrow.up`)
- "Dismiss" X button top-right
- Card appears with a scale spring animation (0.8 -> 1.0)
- Confetti plays on first appear

### Integration

**`ChildHomeView`** — Add a button/banner that appears on Sundays (or when recap data is available):

```swift
if showWeeklyRecap {
    Button {
        showRecapSheet = true
    } label: {
        HStack {
            Image(systemName: "star.fill")
            Text("Your Weekly Recap is Ready!")
        }
        .font(DSFont.headline(14))
        .padding()
        .background(DSGradient.secondaryCTA)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
    }
    .sheet(isPresented: $showRecapSheet) {
        WeeklyRecapSheetView(childId: childId)
    }
}
```

Logic for when to show: Check if it's Sunday or if the user hasn't viewed this week's recap yet (store last-viewed date in UserDefaults).

### Tests

**New file: `PitchDreamsTests/Features/WeeklyRecapViewModelTests.swift`**

- `testLoadRecap_populatesSessionCount`
- `testLoadRecap_calculatesWeeklyXP`
- `testLoadRecap_filtersToLastSevenDays`
- `testLoadRecap_handlesEmptyWeek`
- `testLoadRecap_includesAvatarId`
- `testWeeklyRecap_avatarStage_derivedFromTotalXP`
- `testWeeklyRecap_formattedMinutes_showsHoursAndMinutes`
- `testWeeklyRecap_weekLabel_formatsCorrectly`

---

## Workstream 4: Haptic & Animation Polish Pass

These are quick wins that should be applied across the entire app. Each is independent and can be done in 30-60 minutes. **No Stitch mockups needed** — these are code-level enhancements to existing screens.

### 4a. Haptic Feedback on All Interactive Elements

Add `SensoryFeedback` (iOS 17+) or `UIImpactFeedbackGenerator` to:

| Element | Haptic | Location |
|---------|--------|----------|
| Tab bar buttons | `.impact(style: .light)` | `ChildTabNavigation.swift` (already exists — verify) |
| All primary CTA buttons | `.impact(style: .medium)` | Create a `DSButton` component or add modifier |
| Drill completion | `.notification(type: .success)` | `ActiveTrainingViewModel` on save |
| Rep counter increment | `.impact(style: .soft)` | `ActiveTrainingView` on each rep tap |
| Streak milestone reached | `.notification(type: .success)` | `StreakMilestoneModal` on appear |
| XP earned | `.impact(style: .light)` | `XPEarnedToast` on appear |
| Avatar evolution | `.impact(style: .heavy)` | `EvolutionModal` on reveal |
| Navigation transitions | `.impact(style: .soft)` | Tab switches, sheet presentations |
| Toggle switches | `.selection` | Any settings toggles |
| Error states | `.notification(type: .error)` | API error alerts |

Implementation: Create a reusable modifier:

```swift
// Add to DesignSystem.swift
extension View {
    func dsHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        self.simultaneousGesture(TapGesture().onEnded {
            UIImpactFeedbackGenerator(style: style).impactOccurred()
        })
    }
}
```

### 4b. Spring Animations on All Transitions

Replace default animations with spring throughout the app:

```swift
// Standard spring for most transitions:
.animation(.spring(response: 0.5, dampingFraction: 0.7), value: someState)

// Snappy spring for button presses:
.animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)

// Gentle spring for modals/sheets:
.animation(.spring(response: 0.6, dampingFraction: 0.8), value: isPresented)
```

Key locations to update:
- `ChildHomeView` — loading state transitions
- `ConsistencyRingView` — already has `.easeInOut`, replace with spring
- `TrainingSessionView` — step transitions (check-in -> drill -> reflection)
- All modals — add `presentationBackground` with blur
- Card appearances — scale from 0.95 -> 1.0 on appear

### 4c. Personal Best Celebrations

Wire up the existing `ConfettiView` and `.celebration()` modifier to trigger when any tracked metric exceeds its previous best:

**Metrics to track for PB:** Juggling count, wall-ball count, training streak length, weekly session count, single-session duration.

**New file: `PitchDreams/Core/Persistence/PersonalBestStore.swift`**

```swift
actor PersonalBestStore {
    private let defaults = UserDefaults.standard

    func checkAndUpdate(metric: String, value: Int, childId: String) -> Bool {
        let key = "pb_\(metric)_\(childId)"
        let previous = defaults.integer(forKey: key)
        if value > previous {
            defaults.set(value, forKey: key)
            return true  // New PB!
        }
        return false
    }
}
```

When a new PB is detected:
1. Trigger `.celebration()` modifier
2. Show a brief toast: "New Personal Best! Juggling: 47"
3. Haptic `.notification(type: .success)`
4. Award bonus XP: `XPCalculator.xpForPersonalBest` (25 XP) — flows into avatar evolution

### 4d. Dark Mode Audit

The app uses custom colors from `DesignSystem.swift` (dark backgrounds: `#0C1322`, `#070E1D`). Verify:
- All views use `Color.ds*` tokens, never `.white` or `.black` directly
- Text uses `Color.dsOnSurface` and variants
- System sheets and alerts respect the dark palette
- Status bar style is `.lightContent`

This should be a grep-and-fix pass:
```bash
# Find hardcoded colors
grep -rn "\.white\b\|\.black\b\|Color(\"" PitchDreams/Features/
```

---

## File Checklist

### New Files to Create
```
PitchDreams/
  Models/
    XPLevel.swift              # XPCalculator (XP awards + avatar stage thresholds)
    WeeklyRecap.swift          # Weekly recap data model
  Core/
    Persistence/
      XPStore.swift            # Local XP persistence (UserDefaults-backed actor)
      PersonalBestStore.swift  # PB tracking (UserDefaults-backed actor)
  Features/
    ChildHome/
      Views/
        XPBarView.swift              # XP progress bar → avatar evolution (from Stitch)
        XPEarnedToast.swift          # "+45 XP" floating toast (from Stitch)
        WeeklyRecapCardView.swift    # The shareable card content (from Stitch)
        WeeklyRecapSheetView.swift   # Sheet wrapper with share button (from Stitch)
        ShieldDeployedToast.swift    # Toast for streak freeze deployed (from Stitch)
      ViewModels/
        WeeklyRecapViewModel.swift   # Loads and computes recap data

PitchDreamsTests/
  Core/
    XPCalculatorTests.swift       # XP calculation + avatar stage threshold tests
    XPStoreTests.swift            # XP persistence + evolution detection tests
    PersonalBestStoreTests.swift  # PB detection tests
  Features/
    WeeklyRecapViewModelTests.swift  # Recap loading/computation tests
```

### Existing Files to Modify
```
PitchDreams/
  Models/Avatar.swift                                        # XP-driven evolution (CRITICAL)
  Features/ChildHome/Views/ChildHomeView.swift               # Add XPBarView, weekly recap banner
  Features/ChildHome/Views/ConsistencyRingView.swift         # Escalating flame, spring animations
  Features/ChildHome/Views/EvolutionModal.swift              # Enhanced with XP context
  Features/ChildHome/Views/StreakMilestoneModal.swift        # Streak bonus XP
  Features/ChildHome/Views/AvatarChangeSheet.swift           # Migrate to totalXP
  Features/ChildHome/ViewModels/ChildHomeViewModel.swift     # Load XP data, avatar stage
  Features/Training/ViewModels/ActiveTrainingViewModel.swift # Award XP after session
  Features/Training/Views/ActiveDrillView.swift              # Migrate avatar asset call
  Features/QuickLog/ViewModels/QuickLogViewModel.swift       # Award XP after quick log
  Features/FirstTouch/ViewModels/FirstTouchViewModel.swift   # Award XP + check PBs
  Features/Learn/Views/CoachCharacterView.swift              # Migrate avatar asset call
  Features/ParentDashboard/Views/ParentDashboardView.swift   # Migrate avatar asset call
  Features/ParentDashboard/Views/ChildDetailView.swift       # Migrate avatar asset call
  Core/Extensions/DesignSystem.swift                         # Add dsHaptic modifier
  Core/Navigation/ChildTabNavigation.swift                   # Verify/add haptics
```

### After All Changes
```bash
xcodegen generate
# Then re-select Team in Signing & Capabilities

# Run tests:
xcodebuild test -project PitchDreams.xcodeproj -scheme PitchDreams \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -skip-testing:PitchDreamsTests/APIContractTests \
  -skip-testing:PitchDreamsTests/EndToEndFlowTests
```

---

## Dependency Order

```
Workstream 4a (haptics)  ─── can start immediately, no dependencies, no Stitch needed
Workstream 4b (springs)  ─── can start immediately, no dependencies, no Stitch needed
Workstream 4d (dark mode) ── can start immediately, no dependencies, no Stitch needed

Stitch mockups ─────────── start immediately, in parallel with polish pass
    │
    ├── home_xp_bar ──────────┐
    ├── home_xp_earned_toast ─┤
    ├── evolution_enhanced ───┤
    │                         ▼
    │              Workstream 1 (XP + avatar evolution)
    │                         │
    │                         ├── Workstream 2 (streak shields)
    ├── streak_ring_enhanced ─┘        │ (needs streak_ring_enhanced +
    ├── shield_deployed_toast ─────────┘  shield_deployed_toast mockups)
    │
    ├── weekly_recap_card ────┐
    ├── weekly_recap_sheet ───┤
    │                         ▼
    │              Workstream 3 (weekly recap)
    │                         │
    │                         ▼
    │              Workstream 4c (PB celebrations — no Stitch needed)
```

### Recommended Execution Plan

**Day 1:** Start two tracks in parallel:
- **Track A:** Workstream 4a + 4b + 4d (code polish — no mockups needed)
- **Track B:** Open Google Stitch in Chrome and create all 7 mockups:
  1. `home_xp_bar` — XP bar with avatar, progress toward next evolution
  2. `home_xp_earned_toast` — "+45 XP" floating toast
  3. `evolution_celebration_enhanced` — avatar evolution with XP context
  4. `streak_ring_enhanced` — escalating flame + shield bank
  5. `shield_deployed_toast` — streak freeze toast
  6. `weekly_recap_card` — shareable card (390x520pt) with avatar + stats
  7. `weekly_recap_sheet` — sheet wrapper with share button
  Screenshot each mockup after completion for implementation reference.

**Day 2-3:** Workstream 1 (XP + avatar evolution — implement from Stitch mockups 1-3. `Avatar.swift` migration is the critical path.)

**Day 3-4:** Workstream 2 (streak enhancements — implement from Stitch mockups 4-5)

**Day 4-5:** Workstream 3 (weekly recap card — implement from Stitch mockups 6-7)

**Day 5:** Workstream 4c (PB celebrations — ties everything together, no mockup needed)

---

## Success Criteria

- [ ] All 7 Stitch mockups created and approved before implementation
- [ ] `AvatarStage.current()` driven solely by total XP (old milestone-based method deprecated)
- [ ] All call sites migrated from `forMilestones:` to `forTotalXP:`
- [ ] XP is awarded for every training activity (sessions, drills, first-touch, quick-log)
- [ ] XP bar on home dashboard shows progress toward next avatar evolution
- [ ] Avatar evolution triggers enhanced `EvolutionModal` with XP context
- [ ] Streak milestones award bonus XP that flows into avatar evolution
- [ ] Streak flame visually escalates at 7, 14, 30, 100 days
- [ ] Shield deployment shows toast when freeze is auto-applied
- [ ] Weekly recap card generates with avatar, correct stats, and XP
- [ ] Recap card is shareable via share sheet (renders as image)
- [ ] Haptic feedback fires on all interactive elements
- [ ] Spring animations replace default transitions throughout
- [ ] Personal bests trigger celebrations + bonus XP
- [ ] All new code has unit tests
- [ ] All tests pass (existing + new)
- [ ] `xcodegen generate` succeeds
- [ ] No hardcoded colors — all use DesignSystem tokens
