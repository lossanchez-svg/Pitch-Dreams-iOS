# Track E: Kid Stickiness Features — Implementation Spec

**Goal:** Transform PitchDreams from a training app into a soccer identity platform. Four launch features that create the collecting + identity + surprise + real-world loops that make kids return 5x/day.

**Scope at Launch:**
- E1: Player Card (the identity + viral centerpiece)
- E2: Signature Moves (collectibles + mastery)
- E3: Daily Mystery Box (variable reward loop)
- E5: IRL Pitch Layer (real-world bridge)

**Deferred to post-launch:** E4 Squad Identity (Month 3), E6 Train Like Your Hero (Month 2-3), E7 Highlight Reel (Month 3-4).

---

## CRITICAL: Design-First Workflow

All Track E screens MUST be designed in Google Stitch before implementation. Follow the pattern from `AvatarSelectionStepView` (`onboarding_choose_avatar_1` mockup).

### Stitch Mockups Required

| Mockup Name | Description | Blocks |
|-------------|-------------|--------|
| `player_card_front` | The canonical card layout — avatar, stats, archetype, move loadout, achievements | E1 |
| `player_card_editor` | Editing flow — pick archetype, stat display, move loadout, card frame | E1 |
| `player_card_share` | Share sheet with AirDrop / Messages / Save to Photos preview | E1 |
| `player_card_back` | Back side with achievements, pitch history, career totals | E1 |
| `signature_moves_library` | Grid of all moves with locked/unlocked states, rarity tiers | E2 |
| `signature_move_detail` | Single move: preview video area, 3-stage drill progression, unlock button | E2 |
| `signature_move_unlocked_celebration` | Full-screen unlock celebration with confetti | E2 |
| `mystery_box_closed` | Home dashboard component — closed box with pulse animation inviting tap | E3 |
| `mystery_box_opening` | Box opening animation sequence (lid lifts, glow spills out) | E3 |
| `mystery_box_reveal` | Reward reveal screen with rarity-based visual treatment | E3 |
| `pitch_location_banner` | Home dashboard banner when GPS detects a pitch | E5 |
| `pitch_home_designation` | Set-your-home-pitch flow | E5 |

**Design system reference:** `#0C1322` background, `#FF6B2C` orange, `#46E5F8` cyan, `#FFE9BD` gold. SF Rounded typography. `CornerRadius.xxl` for cards. See `DesignSystem.swift` for full tokens.

---

## Architecture Principles

All Track E features follow existing codebase conventions:

- ViewModels: `@MainActor final class FooViewModel: ObservableObject` with DI
- Persistence: `actor FooStore` backed by UserDefaults (keyed by childId)
- Models: `Codable` structs in `PitchDreams/Models/`
- Views: `@StateObject` pattern with init-based DI
- Tests: `MockAPIClient` + fixtures
- After new files: `xcodegen generate`

All Track E features reinforce each other:
- Player Card **displays** Signature Moves loadout and IRL Pitch badges
- Signature Moves **unlock attempts** can drop from Mystery Box
- Mystery Box **cosmetic drops** customize Player Card frames
- IRL Pitch **visits** unlock card achievements and boost XP flowing into moves/avatar

---

## E1. Player Card

### Overview

A trading-card-style profile that functions as the kid's digital soccer identity. Shareable outside the app (the viral loop). Evolves continuously with training.

### Data Models

**New file: `PitchDreams/Models/PlayerCard.swift`**

```swift
import Foundation

struct PlayerCard: Codable, Equatable {
    let childId: String

    // Identity
    var archetype: PlayerArchetype      // self-chosen flavor
    var displayedStats: [CardStat]       // pick 4 of 6 to show on card
    var moveLoadout: [String]            // up to 4 Signature Move IDs
    var clubCrestDesign: ClubCrestDesign // jersey color + crest pattern
    var cardFrame: CardFrame             // unlockable border style
    var archetypeTagline: String?        // optional self-written ("Speedster")

    // Computed from elsewhere in the app
    // - avatarId, avatarStage → from child profile + XP store
    // - position → from child profile
    // - totalXP, level → from XP store
    // - achievements → from AchievementStore
    // - streak → from streak API
}

enum PlayerArchetype: String, Codable, CaseIterable {
    case speedster   // high speed, low composure
    case playmaker   // high vision, high touch
    case wall        // defender — high work rate, composure
    case magician    // creative — high touch, vision
    case finisher    // striker — high shot power, composure
    case engine      // midfielder — high work rate, vision
    case sweeper     // high vision, work rate (defender)
    case allrounder  // balanced — default

    var displayName: String {
        switch self {
        case .speedster:  return "Speedster"
        case .playmaker:  return "Playmaker"
        case .wall:       return "The Wall"
        case .magician:   return "Magician"
        case .finisher:   return "Finisher"
        case .engine:     return "Engine"
        case .sweeper:    return "Sweeper"
        case .allrounder: return "All-Rounder"
        }
    }

    var accentColorHex: String {
        switch self {
        case .speedster:  return "#FF6B2C"  // orange — speed
        case .playmaker:  return "#46E5F8"  // cyan — vision
        case .wall:       return "#8B5CF6"  // purple — defensive
        case .magician:   return "#E879F9"  // pink — creative
        case .finisher:   return "#EF4444"  // red — clinical
        case .engine:     return "#10B981"  // green — tireless
        case .sweeper:    return "#3B82F6"  // blue — composed
        case .allrounder: return "#FFE9BD"  // gold — balanced
        }
    }

    /// Baseline stats for this archetype. Actual user stats add/subtract
    /// from these based on training activity.
    var baselineStats: CardStats {
        switch self {
        case .speedster:  return CardStats(speed: 90, touch: 65, vision: 60, shotPower: 70, workRate: 75, composure: 55)
        case .playmaker:  return CardStats(speed: 70, touch: 88, vision: 92, shotPower: 65, workRate: 75, composure: 78)
        case .wall:       return CardStats(speed: 65, touch: 68, vision: 75, shotPower: 60, workRate: 92, composure: 88)
        case .magician:   return CardStats(speed: 72, touch: 94, vision: 88, shotPower: 68, workRate: 70, composure: 82)
        case .finisher:   return CardStats(speed: 80, touch: 78, vision: 70, shotPower: 94, workRate: 65, composure: 82)
        case .engine:     return CardStats(speed: 78, touch: 75, vision: 80, shotPower: 70, workRate: 95, composure: 75)
        case .sweeper:    return CardStats(speed: 70, touch: 75, vision: 90, shotPower: 62, workRate: 85, composure: 92)
        case .allrounder: return CardStats(speed: 75, touch: 75, vision: 75, shotPower: 75, workRate: 75, composure: 75)
        }
    }
}

struct CardStats: Codable, Equatable {
    var speed: Int
    var touch: Int
    var vision: Int
    var shotPower: Int
    var workRate: Int
    var composure: Int

    func value(for stat: CardStat) -> Int {
        switch stat {
        case .speed:      return speed
        case .touch:      return touch
        case .vision:     return vision
        case .shotPower:  return shotPower
        case .workRate:   return workRate
        case .composure:  return composure
        }
    }
}

enum CardStat: String, Codable, CaseIterable {
    case speed, touch, vision, shotPower, workRate, composure

    var displayName: String {
        switch self {
        case .speed:     return "SPD"
        case .touch:     return "TCH"
        case .vision:    return "VIS"
        case .shotPower: return "SHT"
        case .workRate:  return "WRK"
        case .composure: return "COM"
        }
    }

    var longName: String {
        switch self {
        case .speed:     return "Speed"
        case .touch:     return "Touch"
        case .vision:    return "Vision"
        case .shotPower: return "Shot Power"
        case .workRate:  return "Work Rate"
        case .composure: return "Composure"
        }
    }

    var icon: String {
        switch self {
        case .speed:     return "bolt.fill"
        case .touch:     return "hand.tap.fill"
        case .vision:    return "eye.fill"
        case .shotPower: return "target"
        case .workRate:  return "flame.fill"
        case .composure: return "leaf.fill"
        }
    }
}

struct ClubCrestDesign: Codable, Equatable {
    var primaryColorHex: String
    var secondaryColorHex: String
    var crestPatternId: String   // "stripes", "chevron", "solid", "split"
    var crestSymbolId: String    // SF Symbol name or registry key
}

enum CardFrame: String, Codable, CaseIterable {
    case standard         // default, free
    case bronze           // unlocked at Pro avatar stage
    case silver           // Unlocked at Legend avatar stage
    case gold             // 30-day streak achievement
    case legendary        // 100-day streak achievement
    case mysteryBoxRare   // only via Mystery Box legendary drop
    case founders         // Founders tier subscription exclusive

    var displayName: String {
        switch self {
        case .standard:       return "Standard"
        case .bronze:         return "Bronze"
        case .silver:         return "Silver"
        case .gold:           return "Gold"
        case .legendary:      return "Legendary"
        case .mysteryBoxRare: return "Platinum Rare"
        case .founders:       return "Founders"
        }
    }

    var isUnlockedByDefault: Bool { self == .standard }
}
```

### Stat Computation

Stats are **computed**, not stored directly. They combine archetype baseline + training activity modifiers.

**New file: `PitchDreams/Core/PlayerCard/StatComputer.swift`**

```swift
actor StatComputer {
    private let xpStore: XPStore
    private let sessionsCache = NSCache<NSString, NSArray>()

    init(xpStore: XPStore = XPStore()) {
        self.xpStore = xpStore
    }

    /// Computes current stats from baseline + training activity.
    /// Training activity *nudges* stats but never drops them below baseline.
    func computeStats(
        for card: PlayerCard,
        sessions: [SessionLog]
    ) -> CardStats {
        var stats = card.archetype.baselineStats

        // Training volume boost: every 50 sessions adds 1 point to all stats
        let volumeBonus = min(10, sessions.count / 50)
        stats.speed += volumeBonus
        stats.touch += volumeBonus
        stats.vision += volumeBonus
        stats.shotPower += volumeBonus
        stats.workRate += volumeBonus
        stats.composure += volumeBonus

        // Specific skill boosts from drill categories
        let ballMasterySessions = sessions.filter { $0.activityType == "drill" && ($0.focus ?? "").contains("ball_mastery") }.count
        stats.touch += min(8, ballMasterySessions / 10)

        let firstTouchSessions = sessions.filter { $0.focus?.contains("first_touch") == true }.count
        stats.touch += min(6, firstTouchSessions / 8)

        let jugglingSessions = sessions.filter { $0.focus?.contains("juggling") == true }.count
        stats.touch += min(5, jugglingSessions / 10)
        stats.composure += min(5, jugglingSessions / 15)

        let shootingSessions = sessions.filter { $0.focus?.contains("shooting") == true }.count
        stats.shotPower += min(10, shootingSessions / 8)

        // Consistency (streak-based) boosts composure + work rate
        let totalXP = await xpStore.getTotalXP(childId: card.childId)
        let xpBonus = min(8, totalXP / 500)
        stats.workRate += xpBonus
        stats.composure += xpBonus

        // Clamp to 0-99
        stats.speed = min(99, max(30, stats.speed))
        stats.touch = min(99, max(30, stats.touch))
        stats.vision = min(99, max(30, stats.vision))
        stats.shotPower = min(99, max(30, stats.shotPower))
        stats.workRate = min(99, max(30, stats.workRate))
        stats.composure = min(99, max(30, stats.composure))

        return stats
    }

    /// Overall rating — shown prominently on the card (FIFA-style).
    /// Weighted average of the 4 displayed stats.
    func overallRating(stats: CardStats, displayed: [CardStat]) -> Int {
        let values = displayed.map { stats.value(for: $0) }
        guard !values.isEmpty else { return 0 }
        return Int(Double(values.reduce(0, +)) / Double(values.count))
    }
}
```

### Persistence

**New file: `PitchDreams/Core/Persistence/PlayerCardStore.swift`**

```swift
import Foundation

actor PlayerCardStore {
    private let defaults = UserDefaults.standard

    func get(childId: String) -> PlayerCard {
        guard let data = defaults.data(forKey: key(childId)),
              let card = try? JSONDecoder().decode(PlayerCard.self, from: data) else {
            return defaultCard(childId: childId)
        }
        return card
    }

    func save(_ card: PlayerCard) {
        guard let data = try? JSONEncoder().encode(card) else { return }
        defaults.set(data, forKey: key(card.childId))
    }

    func updateArchetype(_ archetype: PlayerArchetype, childId: String) {
        var card = get(childId: childId)
        card.archetype = archetype
        save(card)
    }

    func updateDisplayedStats(_ stats: [CardStat], childId: String) {
        var card = get(childId: childId)
        card.displayedStats = Array(stats.prefix(4))
        save(card)
    }

    func updateMoveLoadout(_ moveIds: [String], childId: String) {
        var card = get(childId: childId)
        card.moveLoadout = Array(moveIds.prefix(4))
        save(card)
    }

    func updateFrame(_ frame: CardFrame, childId: String) {
        var card = get(childId: childId)
        card.cardFrame = frame
        save(card)
    }

    // MARK: - Helpers

    private func key(_ childId: String) -> String { "player_card_\(childId)" }

    private func defaultCard(childId: String) -> PlayerCard {
        PlayerCard(
            childId: childId,
            archetype: .allrounder,
            displayedStats: [.speed, .touch, .vision, .workRate],
            moveLoadout: [],
            clubCrestDesign: ClubCrestDesign(
                primaryColorHex: "#FF6B2C",
                secondaryColorHex: "#0C1322",
                crestPatternId: "solid",
                crestSymbolId: "star.fill"
            ),
            cardFrame: .standard,
            archetypeTagline: nil
        )
    }
}
```

### ViewModel

**New file: `PitchDreams/Features/PlayerCard/ViewModels/PlayerCardViewModel.swift`**

```swift
import SwiftUI

@MainActor
final class PlayerCardViewModel: ObservableObject {
    @Published var card: PlayerCard
    @Published var stats: CardStats = CardStats(speed: 75, touch: 75, vision: 75, shotPower: 75, workRate: 75, composure: 75)
    @Published var overallRating: Int = 75
    @Published var avatarId: String = "default"
    @Published var avatarStage: AvatarStage = .rookie
    @Published var position: String = ""
    @Published var totalXP: Int = 0
    @Published var streak: Int = 0
    @Published var unlockedMoves: [SignatureMove] = []
    @Published var unlockedFrames: [CardFrame] = [.standard]
    @Published var isLoading = false

    let childId: String
    private let apiClient: APIClientProtocol
    private let store: PlayerCardStore
    private let xpStore: XPStore
    private let moveStore: SignatureMoveStore
    private let statComputer: StatComputer

    init(
        childId: String,
        apiClient: APIClientProtocol = APIClient(),
        store: PlayerCardStore = PlayerCardStore(),
        xpStore: XPStore = XPStore(),
        moveStore: SignatureMoveStore = SignatureMoveStore(),
        statComputer: StatComputer? = nil
    ) {
        self.childId = childId
        self.apiClient = apiClient
        self.store = store
        self.xpStore = xpStore
        self.moveStore = moveStore
        self.statComputer = statComputer ?? StatComputer(xpStore: xpStore)
        self.card = PlayerCard(
            childId: childId,
            archetype: .allrounder,
            displayedStats: [.speed, .touch, .vision, .workRate],
            moveLoadout: [],
            clubCrestDesign: ClubCrestDesign(
                primaryColorHex: "#FF6B2C",
                secondaryColorHex: "#0C1322",
                crestPatternId: "solid",
                crestSymbolId: "star.fill"
            ),
            cardFrame: .standard,
            archetypeTagline: nil
        )
    }

    func load() async {
        isLoading = true
        card = await store.get(childId: childId)

        // Load sessions for stat computation
        var sessions: [SessionLog] = []
        do {
            sessions = try await apiClient.request(APIRouter.listSessions(childId: childId, limit: 200))
        } catch {
            sessions = []
        }

        // Load profile for avatar + position
        if let profile: ChildProfileDetail = try? await apiClient.request(APIRouter.getChildProfile(childId: childId)) {
            avatarId = profile.avatarId ?? "default"
            position = profile.position ?? ""
        }

        // Compute stats
        let computedStats = await statComputer.computeStats(for: card, sessions: sessions)
        stats = computedStats
        overallRating = await statComputer.overallRating(stats: computedStats, displayed: card.displayedStats)

        // XP + avatar stage
        totalXP = await xpStore.getTotalXP(childId: childId)
        avatarStage = XPCalculator.avatarStageForXP(totalXP)

        // Unlocked moves
        unlockedMoves = await moveStore.unlockedMoves(childId: childId)

        // Unlocked frames — computed from achievements/avatar stage
        unlockedFrames = computeUnlockedFrames(avatarStage: avatarStage, totalXP: totalXP)

        isLoading = false
    }

    func setArchetype(_ archetype: PlayerArchetype) async {
        await store.updateArchetype(archetype, childId: childId)
        card.archetype = archetype
        await load()  // recompute stats
    }

    func setDisplayedStats(_ newStats: [CardStat]) async {
        let clamped = Array(newStats.prefix(4))
        await store.updateDisplayedStats(clamped, childId: childId)
        card.displayedStats = clamped
        overallRating = await statComputer.overallRating(stats: stats, displayed: clamped)
    }

    func setMoveLoadout(_ moveIds: [String]) async {
        await store.updateMoveLoadout(moveIds, childId: childId)
        card.moveLoadout = Array(moveIds.prefix(4))
    }

    func setFrame(_ frame: CardFrame) async {
        guard unlockedFrames.contains(frame) else { return }
        await store.updateFrame(frame, childId: childId)
        card.cardFrame = frame
    }

    private func computeUnlockedFrames(avatarStage: AvatarStage, totalXP: Int) -> [CardFrame] {
        var unlocked: [CardFrame] = [.standard]
        if avatarStage.rawValue >= AvatarStage.pro.rawValue { unlocked.append(.bronze) }
        if avatarStage.rawValue >= AvatarStage.legend.rawValue { unlocked.append(.silver) }
        // Gold/Legendary frames check streak milestones — wire up to StreakData when available
        return unlocked
    }
}
```

### Views

**New file: `PitchDreams/Features/PlayerCard/Views/PlayerCardView.swift`**

> **PREREQUISITE: Implement from `player_card_front` Stitch mockup.**

The canonical card. Rendered both in-app and into an image for sharing. Design specs:

- Aspect ratio: 3:4 portrait (typical trading card)
- Dimensions when rendered for sharing: 1080 x 1440 (3x for retina)
- Archetype accent color as card frame base color
- Card frame variant adds decorative border treatment
- Club crest in top-left corner (small)
- Large overall rating in top-right ("87" in huge display font)
- Avatar illustration fills center (at current evolution stage — `Avatar.assetName(for:totalXP:)`)
- Position badge beneath avatar (GK / DEF / MID / FWD)
- Archetype tag beneath position ("SPEEDSTER")
- 2x2 grid of 4 displayed stats with label + number + small icon
- Move loadout: 4 small rectangular slots at bottom with move icons/names
- Frame-specific decorations (gold foil, bronze texture, etc. — done in Stitch)

### Important: The View Must Be Renderable

The view must work both as a SwiftUI view *in the app* and as an `ImageRenderer` source for share output. Keep it stateless — take `PlayerCard + CardStats + avatarId + avatarStage + position + unlockedMoves` as inputs, no environment dependencies inside the card view itself.

**New file: `PitchDreams/Features/PlayerCard/Views/PlayerCardEditorView.swift`**

> **PREREQUISITE: Implement from `player_card_editor` Stitch mockup.**

Editor flow with these sub-screens (use step-based navigation like `OnboardingView`):

1. **Archetype picker** — horizontal scroll of 8 archetypes, each with a hero illustration and baseline stats preview
2. **Stat selection** — pick 4 of 6 stats to display on card. Live preview of the card updates.
3. **Move loadout** — pick up to 4 unlocked Signature Moves. Greyed-out slots if fewer unlocked.
4. **Club design** — primary color, secondary color, crest pattern, crest symbol
5. **Card frame** — pick from unlocked frames with locked ones shown greyed with unlock hint
6. **Final preview + Save** — full card preview, "Save Card" CTA

**New file: `PitchDreams/Features/PlayerCard/Views/PlayerCardShareSheet.swift`**

> **PREREQUISITE: Implement from `player_card_share` Stitch mockup.**

Share presentation:
- Full card preview
- Action buttons row: "AirDrop", "Messages", "Instagram", "Save to Photos", "Copy Link" (if web has card URLs)
- Under the hood: `ImageRenderer` generates a 1080x1440 UIImage, passes to `UIActivityViewController`

```swift
@MainActor
func renderCardImage() -> UIImage? {
    let renderer = ImageRenderer(content:
        PlayerCardView(
            card: viewModel.card,
            stats: viewModel.stats,
            overallRating: viewModel.overallRating,
            avatarId: viewModel.avatarId,
            avatarStage: viewModel.avatarStage,
            position: viewModel.position,
            unlockedMoves: viewModel.unlockedMoves,
            renderMode: .share
        )
        .frame(width: 1080, height: 1440)
    )
    renderer.scale = 1.0  // we control dimensions absolutely
    return renderer.uiImage
}
```

### Integration Points

**`ChildHomeView`** — Add "My Card" entry as a featured button/banner:
```swift
NavigationLink(destination: PlayerCardView(childId: childId)) {
    PlayerCardPreviewCard(compact: true)
}
```

**`ChildTabNavigation`** — Consider adding a dedicated "Card" tab (5 tabs → 6 tabs) OR adding card entry to the Skills tab. Decide based on Stitch mockup flow.

**`ActiveTrainingViewModel`** — After XP is awarded, trigger stat recomputation. (Actually — stats are lazily computed on card load, so no action needed, but consider caching invalidation.)

### Tests

**New file: `PitchDreamsTests/Features/PlayerCardViewModelTests.swift`**

```swift
@MainActor
final class PlayerCardViewModelTests: XCTestCase {
    var vm: PlayerCardViewModel!
    var mockAPI: MockAPIClient!

    override func setUp() {
        mockAPI = MockAPIClient()
        vm = PlayerCardViewModel(childId: "test-child", apiClient: mockAPI)
    }

    func testDefaultCard_isAllrounder() async {
        mockAPI.enqueue(TestFixtures.emptySessions)
        mockAPI.enqueue(TestFixtures.makeChildProfileDetail())
        await vm.load()
        XCTAssertEqual(vm.card.archetype, .allrounder)
        XCTAssertEqual(vm.card.displayedStats.count, 4)
    }

    func testSetArchetype_updatesBaselineStats() async {
        await vm.setArchetype(.speedster)
        XCTAssertEqual(vm.card.archetype, .speedster)
        XCTAssertGreaterThan(vm.stats.speed, 80)  // speedster baseline speed = 90
    }

    func testSetMoveLoadout_capsAtFour() async {
        await vm.setMoveLoadout(["a", "b", "c", "d", "e", "f"])
        XCTAssertEqual(vm.card.moveLoadout.count, 4)
    }

    func testSetFrame_rejectsLockedFrame() async {
        // Initial state: only standard frame unlocked
        await vm.setFrame(.gold)
        XCTAssertEqual(vm.card.cardFrame, .standard) // remains default
    }

    func testSessionVolume_bumpsStats() async {
        let manySessions = (0..<100).map { _ in TestFixtures.makeSession() }
        mockAPI.enqueue(manySessions)
        mockAPI.enqueue(TestFixtures.makeChildProfileDetail())
        await vm.load()
        // 100 sessions = volumeBonus 2, so speed should be baseline + 2
        XCTAssertEqual(vm.stats.speed, 75 + 2)  // allrounder baseline 75
    }
}
```

**New file: `PitchDreamsTests/Core/PlayerCardStoreTests.swift`**

- `testDefaultCard_hasAllrounderArchetype`
- `testSave_persistsAcrossReads`
- `testUpdateArchetype_preservesOtherFields`
- `testMoveLoadout_capsAtFour`

**New file: `PitchDreamsTests/Core/StatComputerTests.swift`**

- `testBaselineStatsReturned_forEachArchetype`
- `testVolumeBonus_capsAt10`
- `testBallMasterySessionsBumpTouch`
- `testStatsClampAt99`
- `testStatsClampAt30Minimum`
- `testOverallRating_averagesDisplayedStats`

---

## E2. Signature Moves System

> **⚠️ MAJOR UPDATE — See `TRACK_E_SIGNATURE_MOVES_DETAIL.md` for the full authoritative spec.**
>
> The content below is the original lightweight version. It has been **superseded** by a complete technique-teaching system because the original didn't actually teach anything — mapping moves to generic ball-mastery drills (toe taps, sole rolls) doesn't teach a kid how to do a Rabona.
>
> **Key changes in the detail doc:**
> - **Launch scope reduced from 10 to 5 fully-authored moves** (Scissor, Step-Over, Body Feint, La Croqueta, Elastico)
> - **Expanded data model**: `LearningPhase` (groundwork/technique/mastery), `MoveDrillType` (watch/mimic/withBall/challenge), move-specific `MoveDrill` (not generic drill references)
> - **Full multi-screen learning flow**: Overview → Stage Intro → Drill Player → Drill Complete → Stage Complete → Record Yourself → Mastered
> - **11 Stitch mockups** (up from 6) — one per screen + 4 drill-type variants
> - **~12-15 days effort** (up from 5-7) reflecting real technique-teaching scope
> - **Post-launch cadence**: 1 new move every 3-4 weeks, each release a re-engagement event
>
> **Implement from `TRACK_E_SIGNATURE_MOVES_DETAIL.md`, not from the content below.** The content below is retained only for reference on the broader integration pattern (how moves connect to Player Card, Mystery Box, etc.).

### Overview (DEPRECATED — see detail doc)

Unlockable pro skill moves. Ships with 5 fully-authored moves at launch (not 10 as originally planned). Each is a 3-stage progressive learning journey: Groundwork (watch + mimic) → Technique (ball drills) → Mastery (pressure + recording). Moves appear on the Player Card as loadout slots.

### Data Models

**New file: `PitchDreams/Models/SignatureMove.swift`**

```swift
import Foundation

struct SignatureMove: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let rarity: MoveRarity
    let difficulty: MoveDifficulty
    let famousFor: String             // "Ronaldinho's signature" or "Messi's classic"
    let description: String
    let iconSymbolName: String        // SF Symbol fallback; can use custom image later
    let previewAnimationAsset: String?  // optional video/lottie asset name
    let stages: [MoveStage]            // 3 progressive stages to unlock
    let coachTipYoung: String          // age-adaptive (≤11)
    let coachTip: String               // standard (12+)
}

enum MoveRarity: String, Codable, CaseIterable {
    case common      // 4 of 10 launch moves
    case rare        // 3 of 10
    case epic        // 2 of 10
    case legendary   // 1 of 10 (scorpion kick)

    var displayName: String {
        switch self {
        case .common:    return "Common"
        case .rare:      return "Rare"
        case .epic:      return "Epic"
        case .legendary: return "Legendary"
        }
    }

    var accentColorHex: String {
        switch self {
        case .common:    return "#94A3B8"  // slate
        case .rare:      return "#46E5F8"  // cyan
        case .epic:      return "#A855F7"  // purple
        case .legendary: return "#FFE9BD"  // gold
        }
    }

    /// XP bonus awarded on final mastery
    var masteryXP: Int {
        switch self {
        case .common:    return 100
        case .rare:      return 250
        case .epic:      return 500
        case .legendary: return 1000
        }
    }
}

enum MoveDifficulty: String, Codable, CaseIterable {
    case beginner, intermediate, advanced
    var displayName: String { rawValue.capitalized }
}

/// One of three progressive stages within a move.
/// Kid must complete stage 1 before stage 2 is available.
struct MoveStage: Codable, Equatable {
    let order: Int                // 1, 2, 3
    let name: String              // "Slow-motion walkthrough", "At full speed", "Under pressure"
    let drillKeys: [String]        // references DrillRegistry.DrillDefinition.id
    let requiredReps: Int          // target reps for mastery at this stage
    let requiredConfidence: Int    // required self-reported confidence 1-5
}

/// A user's progress on a single move.
struct MoveProgress: Codable, Equatable {
    let moveId: String
    var currentStage: Int         // 1 = first stage attempted; 0 = locked; 4 = fully mastered
    var stageCompletions: [Int: Int]  // stage order → rep count
    var masteredAt: Date?
    var lastAttemptAt: Date?

    var isMastered: Bool { masteredAt != nil }
    var isLocked: Bool { currentStage == 0 }
}
```

### Launch Move Registry

**New file: `PitchDreams/Models/SignatureMoveRegistry.swift`**

```swift
import Foundation

enum SignatureMoveRegistry {
    static let launchMoves: [SignatureMove] = [
        // COMMON (4)
        SignatureMove(
            id: "move-rainbow-flick",
            name: "Rainbow Flick",
            rarity: .common,
            difficulty: .beginner,
            famousFor: "Ronaldinho's crowd-pleaser",
            description: "Flick the ball up and over your head using both feet. A crowd classic.",
            iconSymbolName: "rainbow",
            previewAnimationAsset: "preview_rainbow_flick",
            stages: [
                MoveStage(order: 1, name: "The Setup",
                          drillKeys: ["bm-sole-rolls", "bm-toe-taps"], requiredReps: 30, requiredConfidence: 3),
                MoveStage(order: 2, name: "The Flick",
                          drillKeys: ["bm-foundation"], requiredReps: 20, requiredConfidence: 4),
                MoveStage(order: 3, name: "Full Speed",
                          drillKeys: ["bm-foundation"], requiredReps: 15, requiredConfidence: 4)
            ],
            coachTipYoung: "Squeeze the ball between your heels like a sandwich!",
            coachTip: "Clamp the ball between your dominant heel and the sole of your weak foot, then flick upward."
        ),
        SignatureMove(
            id: "move-scissor",
            name: "Scissor",
            rarity: .common,
            difficulty: .beginner,
            famousFor: "Cristiano Ronaldo's go-to",
            description: "Sweep one foot around the ball to sell the defender, then push off the other.",
            iconSymbolName: "scissors",
            previewAnimationAsset: nil,
            stages: [
                MoveStage(order: 1, name: "The Sweep", drillKeys: ["bm-sole-rolls"], requiredReps: 40, requiredConfidence: 3),
                MoveStage(order: 2, name: "Shift the Weight", drillKeys: ["bm-foundation"], requiredReps: 25, requiredConfidence: 4),
                MoveStage(order: 3, name: "Full Combo", drillKeys: ["bm-foundation"], requiredReps: 20, requiredConfidence: 4)
            ],
            coachTipYoung: "Pretend your foot is drawing a circle around the ball.",
            coachTip: "Circular motion over the ball, then explode laterally off the planted foot."
        ),
        SignatureMove(
            id: "move-body-feint",
            name: "Body Feint",
            rarity: .common,
            difficulty: .beginner,
            famousFor: "Messi's invisible weapon",
            description: "Shift your weight one way and go the other — no touch needed.",
            iconSymbolName: "arrow.triangle.swap",
            previewAnimationAsset: nil,
            stages: [
                MoveStage(order: 1, name: "The Shoulder Drop", drillKeys: ["bm-toe-taps"], requiredReps: 30, requiredConfidence: 3),
                MoveStage(order: 2, name: "The Explosion", drillKeys: ["bm-foundation"], requiredReps: 20, requiredConfidence: 4),
                MoveStage(order: 3, name: "Game Speed", drillKeys: ["bm-foundation"], requiredReps: 15, requiredConfidence: 4)
            ],
            coachTipYoung: "Your shoulders lie, your feet tell the truth!",
            coachTip: "Drop the shoulder opposite your intended direction. Defenders read shoulders first."
        ),
        SignatureMove(
            id: "move-step-over",
            name: "Step-Over",
            rarity: .common,
            difficulty: .intermediate,
            famousFor: "Robinho's signature rhythm",
            description: "Step over the ball without touching it, then take it the other way.",
            iconSymbolName: "figure.walk.motion",
            previewAnimationAsset: nil,
            stages: [
                MoveStage(order: 1, name: "The Cross Step", drillKeys: ["bm-foundation"], requiredReps: 30, requiredConfidence: 3),
                MoveStage(order: 2, name: "Double Step-Over", drillKeys: ["bm-foundation"], requiredReps: 25, requiredConfidence: 4),
                MoveStage(order: 3, name: "At Speed", drillKeys: ["bm-foundation"], requiredReps: 20, requiredConfidence: 4)
            ],
            coachTipYoung: "Your foot dances over the ball like it's hot lava.",
            coachTip: "Circular motion outside-in over the ball, plant opposite foot, push off explosively."
        ),

        // RARE (3)
        SignatureMove(
            id: "move-la-croqueta",
            name: "La Croqueta",
            rarity: .rare,
            difficulty: .intermediate,
            famousFor: "Iniesta's disappearing act",
            description: "Push the ball from one foot to the other in a single smooth motion to slip past defenders.",
            iconSymbolName: "arrow.left.and.right",
            previewAnimationAsset: nil,
            stages: [
                MoveStage(order: 1, name: "Inside-Inside Touch", drillKeys: ["bm-foundation"], requiredReps: 40, requiredConfidence: 3),
                MoveStage(order: 2, name: "Linear Croqueta", drillKeys: ["bm-foundation"], requiredReps: 30, requiredConfidence: 4),
                MoveStage(order: 3, name: "In Traffic", drillKeys: ["bm-foundation"], requiredReps: 25, requiredConfidence: 4)
            ],
            coachTipYoung: "Two touches, one smooth slide — like you're dealing cards!",
            coachTip: "Inside of one foot to inside of the other, low and quick. Defender's stride is your window."
        ),
        SignatureMove(
            id: "move-elastico",
            name: "Elastico",
            rarity: .rare,
            difficulty: .intermediate,
            famousFor: "Ronaldinho's outside-inside whip",
            description: "Push the ball outside with your outside foot, then snap it back inside in a blink.",
            iconSymbolName: "arrow.uturn.left.circle",
            previewAnimationAsset: nil,
            stages: [
                MoveStage(order: 1, name: "Outside Touch", drillKeys: ["bm-foundation"], requiredReps: 30, requiredConfidence: 3),
                MoveStage(order: 2, name: "Outside-Inside Combo", drillKeys: ["bm-foundation"], requiredReps: 25, requiredConfidence: 4),
                MoveStage(order: 3, name: "Snap Speed", drillKeys: ["bm-foundation"], requiredReps: 20, requiredConfidence: 4)
            ],
            coachTipYoung: "Pretend the ball is a rubber band — stretch it out, then snap it back!",
            coachTip: "Quick outside push then immediate inside snap. The whole move happens in one foot-plant."
        ),
        SignatureMove(
            id: "move-rabona",
            name: "Rabona",
            rarity: .rare,
            difficulty: .advanced,
            famousFor: "Ronaldinho & Neymar's showstopper",
            description: "Cross your kicking leg behind your standing leg to strike the ball.",
            iconSymbolName: "figure.cross.training",
            previewAnimationAsset: nil,
            stages: [
                MoveStage(order: 1, name: "Cross-Leg Touch", drillKeys: ["bm-sole-rolls"], requiredReps: 30, requiredConfidence: 3),
                MoveStage(order: 2, name: "Short Rabona Pass", drillKeys: ["bm-foundation"], requiredReps: 20, requiredConfidence: 4),
                MoveStage(order: 3, name: "Rabona Shot", drillKeys: ["bm-foundation"], requiredReps: 15, requiredConfidence: 4)
            ],
            coachTipYoung: "Your kicking foot hides behind your other leg like playing peekaboo.",
            coachTip: "Plant strong-foot outside the ball. Swing kicking leg behind and connect with the inside."
        ),

        // EPIC (2)
        SignatureMove(
            id: "move-maradona-turn",
            name: "Maradona Turn",
            rarity: .epic,
            difficulty: .advanced,
            famousFor: "Diego's 360 masterclass",
            description: "Drag the ball with one foot, spin 360°, continue with the other foot.",
            iconSymbolName: "arrow.clockwise.circle",
            previewAnimationAsset: nil,
            stages: [
                MoveStage(order: 1, name: "The Drag", drillKeys: ["bm-sole-rolls"], requiredReps: 40, requiredConfidence: 3),
                MoveStage(order: 2, name: "The 180", drillKeys: ["bm-foundation"], requiredReps: 30, requiredConfidence: 4),
                MoveStage(order: 3, name: "Full 360 at Speed", drillKeys: ["bm-foundation"], requiredReps: 25, requiredConfidence: 5)
            ],
            coachTipYoung: "Keep your foot on the ball and spin like a figure skater!",
            coachTip: "Sole-drag, plant, 360° pivot on planting foot, continue with original foot's outside."
        ),
        SignatureMove(
            id: "move-zidane-roulette",
            name: "Zidane Roulette",
            rarity: .epic,
            difficulty: .advanced,
            famousFor: "Zizou's elegant 360",
            description: "Spin 360° while protecting the ball with both feet — an artistic escape from pressure.",
            iconSymbolName: "arrow.triangle.2.circlepath.circle",
            previewAnimationAsset: nil,
            stages: [
                MoveStage(order: 1, name: "Foot 1 Drag", drillKeys: ["bm-sole-rolls"], requiredReps: 40, requiredConfidence: 3),
                MoveStage(order: 2, name: "Full Roulette Slow", drillKeys: ["bm-foundation"], requiredReps: 30, requiredConfidence: 4),
                MoveStage(order: 3, name: "Game-Speed Escape", drillKeys: ["bm-foundation"], requiredReps: 20, requiredConfidence: 5)
            ],
            coachTipYoung: "Two feet dance around the ball in a circle. You're the ball's bodyguard!",
            coachTip: "Pivot on supporting foot. Drag-drag pattern with both feet. Keep ball close — never let it leave your feet."
        ),

        // LEGENDARY (1)
        SignatureMove(
            id: "move-scorpion-kick",
            name: "Scorpion Kick",
            rarity: .legendary,
            difficulty: .advanced,
            famousFor: "René Higuita's impossible save, Olivier Giroud's Puskás winner",
            description: "Dive forward, kick the ball with your heels as your body flies parallel to the ground.",
            iconSymbolName: "figure.cross.training",
            previewAnimationAsset: nil,
            stages: [
                MoveStage(order: 1, name: "Heel Touch (on ground)", drillKeys: ["bm-sole-rolls"], requiredReps: 50, requiredConfidence: 3),
                MoveStage(order: 2, name: "Short Jump Heel Kick", drillKeys: ["bm-foundation"], requiredReps: 30, requiredConfidence: 4),
                MoveStage(order: 3, name: "Full Scorpion (with safety mat)", drillKeys: ["bm-foundation"], requiredReps: 10, requiredConfidence: 5)
            ],
            coachTipYoung: "Only try this on grass or a mat. Your heels kick the ball UP while you're flying!",
            coachTip: "Requires strong core, hip flexibility, and a soft landing surface. Start low and slow — safety first."
        )
    ]

    static func move(id: String) -> SignatureMove? {
        launchMoves.first { $0.id == id }
    }
}
```

### Persistence & Unlock Logic

**New file: `PitchDreams/Core/Persistence/SignatureMoveStore.swift`**

```swift
import Foundation

actor SignatureMoveStore {
    private let defaults = UserDefaults.standard

    func getProgress(moveId: String, childId: String) -> MoveProgress {
        guard let data = defaults.data(forKey: key(moveId: moveId, childId: childId)),
              let progress = try? JSONDecoder().decode(MoveProgress.self, from: data) else {
            // Default: stage 1 is unlocked, stages 2+ need completion
            return MoveProgress(moveId: moveId, currentStage: 1, stageCompletions: [:],
                              masteredAt: nil, lastAttemptAt: nil)
        }
        return progress
    }

    func save(_ progress: MoveProgress, childId: String) {
        guard let data = try? JSONEncoder().encode(progress) else { return }
        defaults.set(data, forKey: key(moveId: progress.moveId, childId: childId))
    }

    /// Record reps toward a specific stage. Returns whether the stage was completed and whether the move was mastered.
    func recordStageAttempt(
        moveId: String,
        stage: Int,
        reps: Int,
        confidence: Int,
        childId: String
    ) -> (stageCompleted: Bool, moveMastered: Bool) {
        guard let move = SignatureMoveRegistry.move(id: moveId) else {
            return (false, false)
        }
        guard let stageDef = move.stages.first(where: { $0.order == stage }) else {
            return (false, false)
        }

        var progress = getProgress(moveId: moveId, childId: childId)
        guard stage <= progress.currentStage else { return (false, false) }  // stage not unlocked yet

        let prevReps = progress.stageCompletions[stage] ?? 0
        progress.stageCompletions[stage] = prevReps + reps
        progress.lastAttemptAt = Date()

        let stageCompleted = (progress.stageCompletions[stage] ?? 0) >= stageDef.requiredReps
                            && confidence >= stageDef.requiredConfidence

        if stageCompleted {
            progress.currentStage = min(4, stage + 1)
            if progress.currentStage == 4 && progress.masteredAt == nil {
                progress.masteredAt = Date()
                save(progress, childId: childId)
                return (true, true)
            }
        }

        save(progress, childId: childId)
        return (stageCompleted, false)
    }

    func unlockedMoves(childId: String) async -> [SignatureMove] {
        SignatureMoveRegistry.launchMoves.filter { move in
            getProgress(moveId: move.id, childId: childId).isMastered
        }
    }

    func allProgress(childId: String) async -> [(move: SignatureMove, progress: MoveProgress)] {
        SignatureMoveRegistry.launchMoves.map { move in
            (move: move, progress: getProgress(moveId: move.id, childId: childId))
        }
    }

    // MARK: - Helpers

    private func key(moveId: String, childId: String) -> String {
        "move_progress_\(childId)_\(moveId)"
    }
}
```

### Views

**New file: `PitchDreams/Features/SignatureMoves/Views/SignatureMovesLibraryView.swift`**

> **PREREQUISITE: Implement from `signature_moves_library` Stitch mockup.**

Grid of all 10 moves with:
- 2 columns on iPhone, 3 on iPad
- Each card: move icon, name, rarity badge (colored), difficulty
- Locked moves shown greyed out with a lock indicator
- Progress indicator (3-stage progress bar or checkmarks) for in-progress moves
- Mastered moves get a gold glow + checkmark

Filter toggles: `All / Common / Rare / Epic / Legendary / Unlocked / In Progress`.

**New file: `PitchDreams/Features/SignatureMoves/Views/SignatureMoveDetailView.swift`**

> **PREREQUISITE: Implement from `signature_move_detail` Stitch mockup.**

Single-move deep dive:
- Hero video/animation at top (use preview asset; fall back to SF Symbol + particles)
- Move name + rarity + "Famous for" quote
- Description in plain language
- 3 stages shown as vertical stepper:
  - Stage 1: "The Setup" — drill links, X/30 reps complete, confidence stars
  - Stage 2: locked until Stage 1 complete
  - Stage 3: locked until Stage 2 complete
- Coach tip (age-adaptive — uses `coachTipYoung` or `coachTip` based on child age)
- "Try Drill" CTA linked to the associated drill

**New file: `PitchDreams/Features/SignatureMoves/Views/SignatureMoveUnlockedView.swift`**

> **PREREQUISITE: Implement from `signature_move_unlocked_celebration` Stitch mockup.**

Full-screen celebration on mastery:
- Massive "MASTERED!" + move name
- Rarity-tier visual treatment (gold for legendary, purple for epic, etc.)
- Move icon with glow
- XP awarded prominently displayed
- "Add to My Card" CTA if loadout has space
- `.celebration(isPresented:)` modifier + ConfettiView + heavy haptic

### ViewModel

**New file: `PitchDreams/Features/SignatureMoves/ViewModels/SignatureMovesViewModel.swift`**

```swift
@MainActor
final class SignatureMovesViewModel: ObservableObject {
    @Published var moves: [(move: SignatureMove, progress: MoveProgress)] = []
    @Published var selectedFilter: MoveFilter = .all
    @Published var isLoading = false

    let childId: String
    let childAge: Int?
    private let store: SignatureMoveStore

    init(childId: String, childAge: Int? = nil, store: SignatureMoveStore = SignatureMoveStore()) {
        self.childId = childId
        self.childAge = childAge
        self.store = store
    }

    func load() async {
        isLoading = true
        moves = await store.allProgress(childId: childId)
        isLoading = false
    }

    var filteredMoves: [(move: SignatureMove, progress: MoveProgress)] {
        switch selectedFilter {
        case .all:         return moves
        case .unlocked:    return moves.filter { $0.progress.isMastered }
        case .inProgress:  return moves.filter { !$0.progress.isMastered && $0.progress.currentStage > 1 }
        case .rarity(let r): return moves.filter { $0.move.rarity == r }
        }
    }

    func coachTip(for move: SignatureMove) -> String {
        if let age = childAge, age <= 11 { return move.coachTipYoung }
        return move.coachTip
    }
}

enum MoveFilter: Equatable {
    case all, unlocked, inProgress
    case rarity(MoveRarity)
}
```

### Integration Points

**`ActiveTrainingViewModel`** — After drill completion, check if the drill is part of any in-progress move's current stage:

```swift
// In saveSession(), after successful save:
for (move, progress) in await moveStore.allProgress(childId: childId) {
    guard !progress.isMastered else { continue }
    guard let stage = move.stages.first(where: { $0.order == progress.currentStage }) else { continue }
    guard stage.drillKeys.contains(drillId) else { continue }

    let result = await moveStore.recordStageAttempt(
        moveId: move.id,
        stage: progress.currentStage,
        reps: repsCompleted,
        confidence: userConfidence,
        childId: childId
    )
    if result.moveMastered {
        // Award mastery XP, show celebration
        await xpStore.addXP(move.rarity.masteryXP, childId: childId)
        self.moveMasteredJustNow = move
    } else if result.stageCompleted {
        self.moveStageAdvanced = (move: move, newStage: progress.currentStage + 1)
    }
}
```

**`PlayerCardEditorView`** — Move loadout picker reads `moveStore.unlockedMoves()`.

**Navigation:** Add a "Signature Moves" entry under the Skills tab, or as a feature card on home dashboard.

### Tests

**New file: `PitchDreamsTests/Core/SignatureMoveStoreTests.swift`**

- `testInitialProgress_stageOneUnlocked`
- `testRecordStageAttempt_belowReps_doesNotAdvance`
- `testRecordStageAttempt_meetsReps_advancesStage`
- `testRecordStageAttempt_masterOnStage3_setsMasteredAt`
- `testRecordStageAttempt_confidenceBelowThreshold_doesNotComplete`
- `testUnlockedMoves_returnsOnlyMastered`

**New file: `PitchDreamsTests/Features/SignatureMovesViewModelTests.swift`**

- `testCoachTip_youngerThan12_returnsYoungVariant`
- `testCoachTip_ageNil_returnsStandard`
- `testFilteredMoves_unlockedOnly`
- `testFilteredMoves_inProgress`
- `testFilteredMoves_byRarity`

---

## E3. Daily Mystery Box

### Overview

Variable reward schedule mechanic. One box per day on home dashboard. Tap to open, reveals a random reward. Builds daily-open habit independent of training intent.

### Data Models

**New file: `PitchDreams/Models/MysteryReward.swift`**

```swift
import Foundation

enum MysteryRewardType: String, Codable, CaseIterable {
    case smallXP        // +25 XP
    case mediumXP       // +50 XP
    case moveAttempt    // free drill for locked move
    case feverTime      // 15 min 3x XP
    case cosmeticDrop   // card frame/color/celebration
    case bonusShield    // extra streak shield
    case mysteryReward  // bigger XP or cosmetic (middle-rarity)
    case legendaryDrop  // very rare

    var displayName: String {
        switch self {
        case .smallXP:        return "+25 XP"
        case .mediumXP:       return "+50 XP"
        case .moveAttempt:    return "Free Move Attempt"
        case .feverTime:      return "Fever Time"
        case .cosmeticDrop:   return "Cosmetic Unlock"
        case .bonusShield:    return "Bonus Shield"
        case .mysteryReward:  return "Mystery Reward"
        case .legendaryDrop:  return "Legendary Drop"
        }
    }

    /// Drop rate percentages — transparent in Settings.
    var dropRate: Double {
        switch self {
        case .smallXP:        return 0.30
        case .mediumXP:       return 0.20
        case .moveAttempt:    return 0.15
        case .feverTime:      return 0.10
        case .cosmeticDrop:   return 0.10
        case .bonusShield:    return 0.08
        case .mysteryReward:  return 0.05
        case .legendaryDrop:  return 0.02
        }
    }

    var rarity: MoveRarity {
        switch self {
        case .smallXP, .mediumXP, .bonusShield: return .common
        case .moveAttempt, .feverTime, .cosmeticDrop: return .rare
        case .mysteryReward: return .epic
        case .legendaryDrop: return .legendary
        }
    }
}

struct MysteryReward: Codable, Equatable, Identifiable {
    let id: UUID
    let type: MysteryRewardType
    let xpAmount: Int?             // for XP rewards
    let cosmeticId: String?         // for cosmetic drops
    let moveAttemptMoveId: String?  // for move attempts
    let openedAt: Date
}
```

### Drop Engine

**New file: `PitchDreams/Core/Content/MysteryBoxEngine.swift`**

```swift
import Foundation

enum MysteryBoxEngine {
    /// Produces a random reward weighted by drop rates.
    /// Contextual eligibility applied — e.g., don't drop moveAttempt if user has no locked moves.
    static func generateReward(context: MysteryBoxContext) -> MysteryReward {
        let eligibleTypes = MysteryRewardType.allCases.filter { type in
            context.isEligible(for: type)
        }

        // Weighted random
        let totalWeight = eligibleTypes.reduce(0.0) { $0 + $1.dropRate }
        let roll = Double.random(in: 0..<totalWeight)
        var cumulative = 0.0
        var selectedType: MysteryRewardType = .smallXP

        for type in eligibleTypes {
            cumulative += type.dropRate
            if roll < cumulative {
                selectedType = type
                break
            }
        }

        return buildReward(type: selectedType, context: context)
    }

    private static func buildReward(type: MysteryRewardType, context: MysteryBoxContext) -> MysteryReward {
        switch type {
        case .smallXP:
            return MysteryReward(id: UUID(), type: .smallXP, xpAmount: 25,
                                cosmeticId: nil, moveAttemptMoveId: nil, openedAt: Date())
        case .mediumXP:
            return MysteryReward(id: UUID(), type: .mediumXP, xpAmount: 50,
                                cosmeticId: nil, moveAttemptMoveId: nil, openedAt: Date())
        case .moveAttempt:
            let moveId = context.lockedMoveIds.randomElement() ?? "move-rainbow-flick"
            return MysteryReward(id: UUID(), type: .moveAttempt, xpAmount: nil,
                                cosmeticId: nil, moveAttemptMoveId: moveId, openedAt: Date())
        case .feverTime:
            return MysteryReward(id: UUID(), type: .feverTime, xpAmount: nil,
                                cosmeticId: nil, moveAttemptMoveId: nil, openedAt: Date())
        case .cosmeticDrop:
            let cosmeticId = context.availableCosmeticIds.randomElement() ?? "color_red"
            return MysteryReward(id: UUID(), type: .cosmeticDrop, xpAmount: nil,
                                cosmeticId: cosmeticId, moveAttemptMoveId: nil, openedAt: Date())
        case .bonusShield:
            return MysteryReward(id: UUID(), type: .bonusShield, xpAmount: nil,
                                cosmeticId: nil, moveAttemptMoveId: nil, openedAt: Date())
        case .mysteryReward:
            return MysteryReward(id: UUID(), type: .mysteryReward, xpAmount: 150,
                                cosmeticId: nil, moveAttemptMoveId: nil, openedAt: Date())
        case .legendaryDrop:
            return MysteryReward(id: UUID(), type: .legendaryDrop, xpAmount: 500,
                                cosmeticId: "frame_mysteryBoxRare", moveAttemptMoveId: nil, openedAt: Date())
        }
    }
}

struct MysteryBoxContext {
    let lockedMoveIds: [String]
    let availableCosmeticIds: [String]
    let streakShieldsMaxed: Bool

    func isEligible(for type: MysteryRewardType) -> Bool {
        switch type {
        case .moveAttempt:
            return !lockedMoveIds.isEmpty
        case .bonusShield:
            return !streakShieldsMaxed
        case .cosmeticDrop:
            return !availableCosmeticIds.isEmpty
        default:
            return true
        }
    }
}
```

### Persistence

**New file: `PitchDreams/Core/Persistence/MysteryBoxStore.swift`**

```swift
import Foundation

actor MysteryBoxStore {
    private let defaults = UserDefaults.standard
    private let calendar = Calendar.current

    /// Check if today's box has been opened.
    func isBoxAvailable(childId: String) -> Bool {
        guard let lastOpenedDate = getLastOpenedDate(childId: childId) else {
            return true
        }
        return !calendar.isDateInToday(lastOpenedDate)
    }

    /// Record that today's box was opened, save reward to history.
    func recordOpen(reward: MysteryReward, childId: String) {
        defaults.set(Date(), forKey: "mbox_last_opened_\(childId)")
        var history = getHistory(childId: childId)
        history.append(reward)
        if history.count > 60 { history = Array(history.suffix(60)) }
        if let data = try? JSONEncoder().encode(history) {
            defaults.set(data, forKey: "mbox_history_\(childId)")
        }
    }

    func getHistory(childId: String) -> [MysteryReward] {
        guard let data = defaults.data(forKey: "mbox_history_\(childId)"),
              let entries = try? JSONDecoder().decode([MysteryReward].self, from: data) else {
            return []
        }
        return entries
    }

    /// Number of consecutive days the box has been opened (the "box streak").
    func boxStreak(childId: String) -> Int {
        let history = getHistory(childId: childId)
        guard !history.isEmpty else { return 0 }

        let dates = history.map { calendar.startOfDay(for: $0.openedAt) }
        let uniqueDates = Set(dates).sorted(by: >)

        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
        for day in 0..<365 {
            if uniqueDates.contains(checkDate) {
                streak += 1
            } else if streak > 0 {
                break
            }
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
            _ = day
        }
        return streak
    }

    private func getLastOpenedDate(childId: String) -> Date? {
        defaults.object(forKey: "mbox_last_opened_\(childId)") as? Date
    }
}
```

### ViewModel

**New file: `PitchDreams/Features/ChildHome/ViewModels/MysteryBoxViewModel.swift`**

```swift
@MainActor
final class MysteryBoxViewModel: ObservableObject {
    @Published var isAvailable: Bool = false
    @Published var isOpening: Bool = false
    @Published var revealedReward: MysteryReward?
    @Published var boxStreak: Int = 0

    let childId: String
    private let store: MysteryBoxStore
    private let moveStore: SignatureMoveStore
    private let xpStore: XPStore

    init(
        childId: String,
        store: MysteryBoxStore = MysteryBoxStore(),
        moveStore: SignatureMoveStore = SignatureMoveStore(),
        xpStore: XPStore = XPStore()
    ) {
        self.childId = childId
        self.store = store
        self.moveStore = moveStore
        self.xpStore = xpStore
    }

    func load() async {
        isAvailable = await store.isBoxAvailable(childId: childId)
        boxStreak = await store.boxStreak(childId: childId)
    }

    func openBox() async {
        guard isAvailable && !isOpening else { return }
        isOpening = true

        // Build context for drop eligibility
        let allMoves = await moveStore.allProgress(childId: childId)
        let lockedMoveIds = allMoves.filter { !$0.progress.isMastered }.map(\.move.id)
        let context = MysteryBoxContext(
            lockedMoveIds: lockedMoveIds,
            availableCosmeticIds: ["color_red", "color_blue", "crest_shield", "celebration_wave"], // stub
            streakShieldsMaxed: false // wire to streak data
        )

        let reward = MysteryBoxEngine.generateReward(context: context)

        // Apply the reward
        switch reward.type {
        case .smallXP, .mediumXP, .mysteryReward, .legendaryDrop:
            if let xp = reward.xpAmount {
                _ = await xpStore.addXP(xp, childId: childId)
                await xpStore.recordXPEntry(
                    XPEntry(amount: xp, source: "mystery_box", date: Date()),
                    childId: childId
                )
            }
        case .feverTime:
            FeverTimeManager.shared.activate(duration: 15 * 60, multiplier: 3)
        case .cosmeticDrop:
            if let id = reward.cosmeticId {
                CosmeticStore.shared.unlock(id: id, childId: childId)
            }
        case .bonusShield, .moveAttempt:
            // Handled externally
            break
        }

        await store.recordOpen(reward: reward, childId: childId)
        revealedReward = reward
        isAvailable = false
        boxStreak = await store.boxStreak(childId: childId)
        isOpening = false
    }

    func dismissReveal() {
        revealedReward = nil
    }
}
```

### Views

**New file: `PitchDreams/Features/ChildHome/Views/MysteryBoxView.swift`**

> **PREREQUISITE: Implement from `mystery_box_closed` Stitch mockup.**

Home dashboard component:
- Closed box illustration (lottie animation or SF Symbols) with gentle pulse + particle sparkles
- "Today's Mystery" label above
- "Box streak: 12 🎁" indicator beneath (if streak > 1)
- Tapping triggers opening animation → reveal view
- When already opened today, shows "Come back tomorrow ⏰" dim state
- Haptic `.impact(style: .medium)` on tap

**New file: `PitchDreams/Features/ChildHome/Views/MysteryBoxRevealView.swift`**

> **PREREQUISITE: Implement from `mystery_box_opening` and `mystery_box_reveal` Stitch mockups.**

Sheet presentation with two animation phases:

Phase 1 (opening, 2 seconds):
- Box shakes, lid lifts
- Light beam escapes upward
- Rarity color glow intensifies (common = white, legendary = gold with radial burst)
- Crescendo haptics: `.light` → `.medium` → `.heavy`

Phase 2 (reveal):
- Reward icon scales in with spring (0 → 1.3 → 1.0)
- Reward name + XP amount shown in rarity color
- Flavor text ("Fever Time! Train now for 3x XP") with countdown timer if applicable
- "Got It!" dismiss button

### Integration

**`ChildHomeView`** — Add `MysteryBoxView` prominently on the dashboard:

```swift
if mysteryBoxVM.isAvailable {
    MysteryBoxView(viewModel: mysteryBoxVM)
        .padding(.horizontal)
}
```

**`ParentControlsView`** — Add toggle: "Show Mystery Box" (`showMysteryBox: Bool`). Respects parental disable.

**`SettingsView`** — Include "See Mystery Box odds" link → static view listing drop rates transparently.

### Tests

**New file: `PitchDreamsTests/Core/MysteryBoxEngineTests.swift`**

- `testGenerateReward_returnsValidType`
- `testGenerateReward_noLockedMoves_doesNotReturnMoveAttempt`
- `testGenerateReward_shieldsMaxed_doesNotReturnBonusShield`
- `testDropRates_sumToOne`

**New file: `PitchDreamsTests/Core/MysteryBoxStoreTests.swift`**

- `testIsBoxAvailable_trueByDefault`
- `testRecordOpen_setsLastOpenedToday`
- `testIsBoxAvailable_falseAfterOpen`
- `testIsBoxAvailable_trueNextDay`
- `testBoxStreak_consecutiveDays`
- `testBoxStreak_gapResets`
- `testHistory_capsAt60Entries`

---

## E5. IRL Pitch Layer

### Overview

GPS-based real-world integration. When the kid is at an actual pitch, app transforms with 2x XP and special content. Also provides soft verification — sessions at real pitches have higher credibility.

### Data Models

**New file: `PitchDreams/Models/TrainingPitch.swift`**

```swift
import Foundation
import CoreLocation

struct TrainingPitch: Codable, Identifiable, Equatable {
    let id: String             // UUID or geohash
    let nickname: String?       // user-named ("Home Pitch", "Summer Camp Field")
    let centerLatitude: Double
    let centerLongitude: Double
    let radiusMeters: Double    // typically 50-100m
    let firstVisitedAt: Date
    var lastVisitedAt: Date
    var visitCount: Int
    let isHomePitch: Bool       // user-designated

    var location: CLLocation {
        CLLocation(latitude: centerLatitude, longitude: centerLongitude)
    }
}

struct PitchDetectionResult {
    let pitch: TrainingPitch?
    let isKnownPitch: Bool
    let isNewPitch: Bool
}
```

### Pitch Detector

**New file: `PitchDreams/Core/Location/PitchDetector.swift`**

```swift
import Foundation
import CoreLocation

@MainActor
final class PitchDetector: NSObject, ObservableObject {
    @Published var currentPitch: TrainingPitch?
    @Published var isAtPitch: Bool = false
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let locationManager = CLLocationManager()
    private let store = PitchStore()
    private var currentChildId: String?

    // Minimum time at location to count as "at pitch" (avoid transients)
    private let minDwellTime: TimeInterval = 60
    private var dwellStartTime: Date?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 20  // meters
    }

    func start(childId: String) {
        currentChildId = childId
        requestPermissionIfNeeded()
        locationManager.startUpdatingLocation()
    }

    func stop() {
        locationManager.stopUpdatingLocation()
        isAtPitch = false
        currentPitch = nil
        dwellStartTime = nil
    }

    private func requestPermissionIfNeeded() {
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    /// Called when user explicitly starts training at their current location.
    /// Registers a new pitch if not near an existing one.
    func designateCurrentAsPitch(nickname: String?, isHome: Bool, childId: String) async {
        guard let currentLocation = locationManager.location else { return }
        await store.designatePitch(
            latitude: currentLocation.coordinate.latitude,
            longitude: currentLocation.coordinate.longitude,
            nickname: nickname,
            isHome: isHome,
            childId: childId
        )
    }
}

extension PitchDetector: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            authorizationStatus = status
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let childId = currentChildId, let userLocation = locations.last else { return }

        Task { @MainActor in
            // Check if at a known pitch
            let pitches = await store.getAllPitches(childId: childId)
            let nearestPitch = pitches.min(by: {
                $0.location.distance(from: userLocation) < $1.location.distance(from: userLocation)
            })

            if let pitch = nearestPitch, pitch.location.distance(from: userLocation) <= pitch.radiusMeters {
                if currentPitch?.id != pitch.id {
                    // Just arrived — start dwell timer
                    dwellStartTime = Date()
                    currentPitch = pitch
                } else if let dwellStart = dwellStartTime,
                          Date().timeIntervalSince(dwellStart) >= minDwellTime,
                          !isAtPitch {
                    // Passed dwell threshold
                    isAtPitch = true
                    await store.recordVisit(pitchId: pitch.id, childId: childId)
                }
            } else {
                // Left the pitch
                isAtPitch = false
                currentPitch = nil
                dwellStartTime = nil
            }
        }
    }
}
```

### Pitch Store

**New file: `PitchDreams/Core/Persistence/PitchStore.swift`**

```swift
import Foundation

actor PitchStore {
    private let defaults = UserDefaults.standard
    private let defaultRadius: Double = 75  // meters

    func getAllPitches(childId: String) -> [TrainingPitch] {
        guard let data = defaults.data(forKey: key(childId: childId)),
              let pitches = try? JSONDecoder().decode([TrainingPitch].self, from: data) else {
            return []
        }
        return pitches
    }

    func savePitches(_ pitches: [TrainingPitch], childId: String) {
        if let data = try? JSONEncoder().encode(pitches) {
            defaults.set(data, forKey: key(childId: childId))
        }
    }

    func designatePitch(latitude: Double, longitude: Double, nickname: String?, isHome: Bool, childId: String) {
        var pitches = getAllPitches(childId: childId)

        // Check if nearby existing pitch
        let newLocation = CLLocation(latitude: latitude, longitude: longitude)
        if let existing = pitches.first(where: {
            CLLocation(latitude: $0.centerLatitude, longitude: $0.centerLongitude).distance(from: newLocation) < 100
        }) {
            // Already exists — just update home designation if needed
            if isHome {
                pitches = pitches.map { p in
                    var updated = p
                    if p.id == existing.id {
                        return TrainingPitch(
                            id: p.id, nickname: nickname ?? p.nickname,
                            centerLatitude: p.centerLatitude, centerLongitude: p.centerLongitude,
                            radiusMeters: p.radiusMeters,
                            firstVisitedAt: p.firstVisitedAt, lastVisitedAt: p.lastVisitedAt,
                            visitCount: p.visitCount, isHomePitch: true
                        )
                    } else {
                        return TrainingPitch(
                            id: p.id, nickname: p.nickname,
                            centerLatitude: p.centerLatitude, centerLongitude: p.centerLongitude,
                            radiusMeters: p.radiusMeters,
                            firstVisitedAt: p.firstVisitedAt, lastVisitedAt: p.lastVisitedAt,
                            visitCount: p.visitCount, isHomePitch: false  // only one home
                        )
                    }
                }
            }
        } else {
            // New pitch
            if isHome {
                pitches = pitches.map { p in
                    TrainingPitch(
                        id: p.id, nickname: p.nickname,
                        centerLatitude: p.centerLatitude, centerLongitude: p.centerLongitude,
                        radiusMeters: p.radiusMeters,
                        firstVisitedAt: p.firstVisitedAt, lastVisitedAt: p.lastVisitedAt,
                        visitCount: p.visitCount, isHomePitch: false
                    )
                }
            }
            let now = Date()
            pitches.append(TrainingPitch(
                id: UUID().uuidString,
                nickname: nickname,
                centerLatitude: latitude,
                centerLongitude: longitude,
                radiusMeters: defaultRadius,
                firstVisitedAt: now,
                lastVisitedAt: now,
                visitCount: 1,
                isHomePitch: isHome
            ))
        }

        savePitches(pitches, childId: childId)
    }

    func recordVisit(pitchId: String, childId: String) {
        var pitches = getAllPitches(childId: childId)
        pitches = pitches.map { p in
            guard p.id == pitchId else { return p }
            return TrainingPitch(
                id: p.id, nickname: p.nickname,
                centerLatitude: p.centerLatitude, centerLongitude: p.centerLongitude,
                radiusMeters: p.radiusMeters,
                firstVisitedAt: p.firstVisitedAt,
                lastVisitedAt: Date(),
                visitCount: p.visitCount + 1,
                isHomePitch: p.isHomePitch
            )
        }
        savePitches(pitches, childId: childId)
    }

    private func key(childId: String) -> String { "training_pitches_\(childId)" }
}
```

### Views

**New file: `PitchDreams/Features/ChildHome/Views/PitchLocationBanner.swift`**

> **PREREQUISITE: Implement from `pitch_location_banner` Stitch mockup.**

Banner shown on home dashboard when `PitchDetector.isAtPitch == true`:

- Horizontal layout with pitch icon, "You're at [Home Pitch]!" text, "2x XP active" badge
- Green/cyan pulsing border
- Tapping it begins a training session
- Dismiss button to hide for today

**New file: `PitchDreams/Features/ChildHome/Views/DesignatePitchView.swift`**

> **PREREQUISITE: Implement from `pitch_home_designation` Stitch mockup.**

Shown when user is at an unrecognized location but starts a session:

- "You're somewhere new. Set as a pitch?"
- Input for nickname
- Toggle for "Home Pitch" designation
- Save / Skip buttons

### Info.plist Changes

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>PitchDreams detects when you're at a soccer pitch to give you bonus XP for real training.</string>
```

### Integration

**`ActiveTrainingViewModel`** — When starting a session, check `pitchDetector.isAtPitch`:
- If true, apply 2x XP multiplier to all XP earned in the session
- Tag the session with `pitchId` for parent dashboard verification signal

**`ChildHomeView`** — Inject `PitchDetector` as `@StateObject`, call `start(childId:)` on appear.

### Tests

**New file: `PitchDreamsTests/Core/PitchStoreTests.swift`**

- `testDesignatePitch_addsNewPitch`
- `testDesignatePitch_nearExisting_updatesExisting`
- `testDesignatePitch_asHome_unsetsOtherHome`
- `testRecordVisit_incrementsCount`
- `testRecordVisit_updatesLastVisited`

**Note:** `PitchDetector` is hard to unit test due to `CLLocationManager`. Use protocol-based DI for testability or test manually on a real device.

---

## File Checklist

### New Files (31 total)

```
PitchDreams/
  Models/
    PlayerCard.swift
    SignatureMove.swift
    SignatureMoveRegistry.swift
    MysteryReward.swift
    TrainingPitch.swift
  Core/
    PlayerCard/
      StatComputer.swift
    Persistence/
      PlayerCardStore.swift
      SignatureMoveStore.swift
      MysteryBoxStore.swift
      PitchStore.swift
    Content/
      MysteryBoxEngine.swift
    Location/
      PitchDetector.swift
    Fever/
      FeverTimeManager.swift       # stub — apply XP multiplier during fever
    Cosmetics/
      CosmeticStore.swift           # stub — unlock tracking
  Features/
    PlayerCard/
      Views/
        PlayerCardView.swift
        PlayerCardEditorView.swift
        PlayerCardShareSheet.swift
        PlayerCardBackView.swift
      ViewModels/
        PlayerCardViewModel.swift
    SignatureMoves/
      Views/
        SignatureMovesLibraryView.swift
        SignatureMoveDetailView.swift
        SignatureMoveUnlockedView.swift
      ViewModels/
        SignatureMovesViewModel.swift
    ChildHome/
      Views/
        MysteryBoxView.swift
        MysteryBoxRevealView.swift
        PitchLocationBanner.swift
        DesignatePitchView.swift
      ViewModels/
        MysteryBoxViewModel.swift

PitchDreamsTests/
  Core/
    StatComputerTests.swift
    PlayerCardStoreTests.swift
    SignatureMoveStoreTests.swift
    MysteryBoxEngineTests.swift
    MysteryBoxStoreTests.swift
    PitchStoreTests.swift
  Features/
    PlayerCardViewModelTests.swift
    SignatureMovesViewModelTests.swift
    MysteryBoxViewModelTests.swift
```

### Files to Modify

```
PitchDreams/Info.plist                                              # Location permission
PitchDreams/Features/ChildHome/Views/ChildHomeView.swift            # Player card link, mystery box, pitch banner
PitchDreams/Features/ChildHome/ViewModels/ChildHomeViewModel.swift  # Mystery box state, pitch detector
PitchDreams/Features/Training/ViewModels/ActiveTrainingViewModel.swift  # Pitch XP multiplier, move unlock check
PitchDreams/Features/ParentControls/Views/ParentControlsView.swift  # Mystery box toggle
PitchDreams/Core/Navigation/ChildTabNavigation.swift                # Consider Card tab
```

---

## Execution Order

**Day 1 (pre-code):** Create all 12 Track E Stitch mockups in Chrome.

**Day 2-3:** E1 Player Card — data models, store, stat computer, view model, view, editor, share flow. Render-test `ImageRenderer` output on physical device.

**Day 4-5:** E2 Signature Moves — models, registry with all 10 moves authored, store, library view, detail view, unlock celebration. Integration with `ActiveTrainingViewModel`.

**Day 6:** E3 Mystery Box — engine, store, box view + reveal animations, integration.

**Day 7:** E5 IRL Pitch Layer (if time) — detector, store, banner, designate view, Info.plist update.

Total: 7 days for full Track E launch scope.

---

## Success Criteria (Track E)

- [ ] All 12 Stitch mockups created and referenced in code
- [ ] Player Card renders with all 8 archetypes showing distinct baseline stats
- [ ] Player Card shareable as image via `ImageRenderer` → `UIActivityViewController`
- [ ] 10 Signature Moves fully authored with 3-stage drills, coach tips (young + standard), and rarity tiers
- [ ] Drill completion auto-advances move progress when thresholds met
- [ ] Move mastery triggers celebration with rarity-based visual treatment and XP bonus
- [ ] Player Card loadout editor shows only unlocked moves
- [ ] Mystery Box available once per day per child
- [ ] Drop rates match spec (transparent display in Settings)
- [ ] Mystery Box eligibility context respects locked moves and maxed shields
- [ ] Box Streak tracks consecutive opens
- [ ] Pitch Detector requests location permission with clear purpose string
- [ ] Known pitches detected within 75m radius; new pitches promptable to save
- [ ] 2x XP multiplier applies when training at pitch
- [ ] Parents can disable Mystery Box via ParentControls
- [ ] All unit tests pass
- [ ] `xcodegen generate` succeeds
