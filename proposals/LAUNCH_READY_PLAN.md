# PitchDreams Launch-Ready Plan

**Goal:** Ship a polished, delightful, monetizable iOS app that stands out in the youth soccer market.

**Status:** Phase 1 feature spec exists (`PHASE1_IMPLEMENTATION_SPEC.md`). This document consolidates: Phase 1 features + launch polish features + bug fixes + freemium monetization strategy into a single end-to-end plan.

**Time to launch:** ~3 weeks of focused development, assuming Stitch mockups run in parallel.

---

## Table of Contents

1. [Timeline at a Glance](#timeline-at-a-glance)
2. [Track A — Phase 1 Features](#track-a--phase-1-features)
3. [Track B — Launch Polish Features](#track-b--launch-polish-features)
4. [Track C — Launch Blockers & Fixes](#track-c--launch-blockers--fixes)
5. [Track D — Freemium Monetization Strategy](#track-d--freemium-monetization-strategy)
6. [Track E — Kid Stickiness Features](#track-e--kid-stickiness-features)
7. [Track F — Learn Module Clarity for Young Users](#track-f--learn-module-clarity-for-young-users)
8. [Dependency Graph](#dependency-graph)
9. [Consolidated File Checklist](#consolidated-file-checklist)
10. [Post-Launch Content Roadmap (Months 1-12)](#post-launch-content-roadmap-months-1-12)
11. [Success Criteria](#success-criteria)

---

## Timeline at a Glance

| Week | Focus | Outcome |
|------|-------|---------|
| **Week 1** | Launch blockers + polish features + Stitch mockups | App is submittable + foundational features shipped |
| **Week 2** | Phase 1 features (XP, streaks, recap) | Retention loop is live |
| **Week 3** | Track E stickiness (Player Card, Signature Moves, Mystery Box) + Track F (Learn clarity) | App becomes "identity platform," lessons clear for 8-12 |
| **Week 4** | Monetization + final polish + beta | Ready for TestFlight → App Store |

---

## Track A — Phase 1 Features

**Detailed spec:** `PHASE1_IMPLEMENTATION_SPEC.md`

Summary of scope:
- **XP System unified with Avatar Evolution** — XP is the sole currency driving Rookie → Pro → Legend
- **Enhanced Streaks with Streak Shields** — escalating flame, shield bank, bonus XP at milestones
- **Weekly Recap Shareable Card** — Instagram-worthy screenshot that generates organic growth
- **Haptic & Animation Polish Pass** — haptics everywhere, spring animations, PB celebrations, dark mode audit

**Stitch mockups required** (create in Chrome/Stitch first):
`home_xp_bar`, `home_xp_earned_toast`, `evolution_celebration_enhanced`, `streak_ring_enhanced`, `shield_deployed_toast`, `weekly_recap_card`, `weekly_recap_sheet`

**Estimated effort:** ~5 days (plus parallel Stitch work)

---

## Track B — Launch Polish Features

Eight small but high-impact features that leverage existing infrastructure. All are days-work max.

### B1. Training Reminder Notifications *(2-3 hours)*

**Value:** The single biggest retention lever. Duolingo's daily reminders are their most effective mechanism.

- User picks preferred training time in Settings (e.g., "4:30 PM")
- `UserNotifications` framework sends a local notification
- Content varies by state: *"Your streak is waiting 🔥"* vs *"Start a new streak today"* vs *"15 days strong!"*
- Quiet hours respected (no notifications 9pm-7am)
- Parent can configure via ParentControls

**Files:**
- `PitchDreams/Core/Notifications/TrainingReminderManager.swift` (new)
- `PitchDreams/Features/ParentControls/Views/NotificationSettingsView.swift` (new)
- `PitchDreams/PitchDreamsApp.swift` — request notification permission on first launch

### B2. App Icon Variants *(2-3 hours)*

**Value:** Customization creates emotional ownership. Kids who personalize have ~2x retention.

Offer 4 alternate icons via `UIApplication.setAlternateIconName(_:)`:
- Default (orange logo)
- Wolf / Lion / Panther avatar icons
- Dark / minimalist

Settings screen with live preview picker.

**Files:**
- Add icon sets to `Assets.xcassets` under `AppIcon-Wolf`, `AppIcon-Lion`, etc.
- `Info.plist` — declare `CFBundleIcons` with `CFBundleAlternateIcons`
- `PitchDreams/Features/ParentControls/Views/AppIconPickerView.swift` (new)

### B3. Daily Focus Tip *(2-3 hours)*

**Value:** Daily hook even on rest days. Positions PitchDreams as more than a drill library — it's a daily companion.

- Static array of 100+ rotating tips (technical, mental, recovery, tactical)
- Show one on home dashboard each day (`Calendar.component(.dayOfYear)`-based rotation)
- Dismissible card, respects dismissal for the day
- Categories: "Today's Focus" shows tip with tag (💪 Technical / 🧠 Mental / 🛌 Recovery)

**Files:**
- `PitchDreams/Models/DailyTip.swift` (new)
- `PitchDreams/Core/Content/DailyTipRegistry.swift` (new — 100+ tips)
- `PitchDreams/Features/ChildHome/Views/DailyTipCard.swift` (new)
- `PitchDreams/Features/ChildHome/Views/ChildHomeView.swift` (modify — add card)

### B4. Keep Screen Awake During Training *(5 minutes)*

`UIApplication.shared.isIdleTimerDisabled = true` on `onAppear` in `ActiveDrillView`, reset on `onDisappear`. One-liner, obvious QoL.

**Files:**
- `PitchDreams/Features/Training/Views/ActiveDrillView.swift`

### B5. Review Prompt *(30 minutes)*

`SKStoreReviewController.requestReview()` triggered when:
- User completes their 5th total session, OR
- User hits a streak milestone (7, 14, 30 days), OR
- Avatar evolves

iOS limits prompts to 3/year automatically. Critical for App Store ratings.

**Files:**
- `PitchDreams/Core/Reviews/ReviewPromptManager.swift` (new)
- Call sites: `ActiveTrainingViewModel`, `StreakMilestoneModal`, `EvolutionModal`

### B6. Empty State Illustrations *(2-3 hours)*

Replace bare empty states with avatar art + encouraging copy. Current empty states are text-only placeholders. Use the existing avatar asset system — show the user's chosen avatar at Rookie stage with a message.

Screens to update:
- `ProgressDashboardView` — "No sessions yet. Let's change that."
- `ActivityLogView` — "Your first log is one tap away."
- `SkillTrackView` — "Unlock your first drill."
- `LearnView` — "Your soccer IQ starts here."

**Files:**
- Modify each empty-state view listed above

### B7. Rest Day Mode *(3-4 hours)*

**Value:** Shows parents the app cares about their kid's body, not just engagement numbers. Huge differentiation.

When check-in shows `soreness: HIGH` or `mood: TIRED`:
- Surface a "Rest Day Suggested" card instead of pushing training
- Offer 5-min light stretching routine (SF Symbol-driven figure animations)
- Award *reduced* XP (20 XP) for honoring rest — so streak stays alive
- Parent notification: *"Alex logged soreness. They're taking a rest day."*

**Files:**
- `PitchDreams/Features/Training/Views/RestDayCardView.swift` (new)
- `PitchDreams/Features/Training/Views/StretchingRoutineView.swift` (new)
- `PitchDreams/Features/Training/ViewModels/TrainingViewModel.swift` (modify — detect high soreness)

### B8. Coach Voice Milestone Lines *(1-2 hours)*

**Value:** Personality layer. Makes the app feel alive.

Add 15-20 new encouraging phrases to the existing coach voice (uses `AVSpeechSynthesizer`):
- Streak milestones
- Avatar evolution
- Personal bests
- First session of the day / week
- After tough check-in (mood: STRESSED)

Content-only, no infrastructure changes.

**Files:**
- `PitchDreams/Core/Voice/CoachVoice.swift` (modify — add `celebratePhrase(for:)` methods)

**Track B total effort:** ~15 hours across 8 features.

---

## Track C — Launch Blockers & Fixes

Codebase is clean (no TODOs, no force unwraps, only 1 print statement) but has real launch-blockers.

### C1. Photo Library Permission *(1 minute — BLOCKER)*

Weekly Recap save-to-Photos will crash without this.

```xml
<key>NSPhotoLibraryAddUsageDescription</key>
<string>PitchDreams saves your weekly recap cards to your photo library.</string>
```

### C2. Orientation Lock *(5 minutes — BLOCKER)*

`Info.plist` currently supports all 4 orientations on iPhone. Every screen is portrait-designed. Landscape will break layouts. Remove landscape from iPhone (keep for iPad).

**File:** `PitchDreams/Info.plist`

### C3. Privacy Manifest *(30 minutes — BLOCKER for App Store submission)*

iOS 17+ requires `PrivacyInfo.xcprivacy`. Without it, App Store submission is rejected.

Declare:
- `NSPrivacyAccessedAPITypes` — UserDefaults usage (reason: `CA92.1` for app functionality)
- `NSPrivacyCollectedDataTypes` — training stats, device identifiers
- `NSPrivacyTracking` — false (no cross-app tracking)

**File:** `PitchDreams/PrivacyInfo.xcprivacy` (new)

### C4. COPPA Compliance *(1-2 hours — BLOCKER legal)*

Targets kids 8-18. Must:
- Declare app as "Kids 6-8" or "Kids 9-11" or "Kids 12+" category in App Store Connect
- Link Privacy Policy + Terms of Service in Settings (`ParentControlsView`)
- Confirm no third-party analytics SDKs collect child PII
- Parental consent flow already exists via ParentControls — document it
- Age-gate at onboarding (already exists — verify it's enforced)

**Files:**
- `PitchDreams/Features/ParentControls/Views/ParentControlsView.swift` — add Legal section
- New markdown: `docs/privacy-compliance.md` for App Review Board

### C5. Offline Handling *(2-3 hours — HIGH)*

No `NWPathMonitor` anywhere. Weak-connection users see API spinners forever.

- Add `NetworkMonitor` actor
- Show persistent banner when offline: *"You're offline. Training will sync when you're back online."*
- Gracefully degrade home dashboard to cached data

**Files:**
- `PitchDreams/Core/Network/NetworkMonitor.swift` (new)
- `PitchDreams/Features/ChildHome/Views/OfflineBanner.swift` (new)

### C6. Branded Launch Screen *(1-2 hours — HIGH first impression)*

Currently `UILaunchScreen` = AccentColor only (blank screen with a color). First launch-day installers see nothing.

Replace with branded launch: logo + tagline fade-in, avatar silhouette.

**Files:**
- `PitchDreams/Resources/LaunchScreen.storyboard` OR use `UILaunchScreen` dict with logo image

### C7. Token Refresh Strategy *(2-3 hours — HIGH)*

`AuthManager.handleUnauthorized()` logs the user out on 401. If JWT expires mid-training, the user is kicked. Options:
- Extend JWT lifetime server-side (easiest — coordinate with web)
- Implement refresh token flow (if web supports it)
- Silent re-login using stored credentials (only if acceptable security-wise)

**Files:**
- `PitchDreams/Core/Auth/AuthManager.swift`
- `PitchDreams/Core/API/TokenInterceptor.swift`

### C8. Session Retry Queue *(3-4 hours — HIGH)*

If a session save fails (network blip at end of drill), it's lost. Kids will rage-quit.

- `SessionSyncQueue` actor persists failed saves to UserDefaults
- Retry on app foreground and when network returns
- Optimistic UI: show "Session saved" immediately, queue behind the scenes

**Files:**
- `PitchDreams/Core/Sync/SessionSyncQueue.swift` (new)
- `PitchDreams/Features/Training/ViewModels/ActiveTrainingViewModel.swift` (modify)
- `PitchDreams/Features/QuickLog/ViewModels/QuickLogViewModel.swift` (modify)

### C9. Accessibility Pass *(4-6 hours — MEDIUM but watchdog-level)*

Only 3 `.accessibility*` calls across 50+ views. App Store reviewers check.

- Add `.accessibilityLabel` to all icon-only buttons (tab bar, celebrations, avatars)
- Add `.accessibilityValue` to progress rings, XP bars, streak counters
- Add `.accessibilityHint` for celebratory modals
- Test with VoiceOver on
- Add `Dynamic Type` support via `@ScaledMetric` where hardcoded sizes exist

**Files:** Broad modification across `Features/` views

### C10. Input Validation *(2-3 hours — MEDIUM)*

Onboarding has minimal validation. Add inline errors:
- Email format check before API call
- Password strength hint in real time
- PIN must be 4 digits, reject `0000`/`1234`/all-same
- Nickname: 2-20 chars, no profanity (basic blocklist)

**Files:** Onboarding views + `AuthManager`

### C11. Loading Skeletons vs Spinners *(2-3 hours — MEDIUM)*

Codebase has `SkeletonView` but not used everywhere. Audit and replace `ProgressView` spinners with skeletons on all data-loading screens.

**Files:** Broad `Features/` audit

### C12. Force Portrait in Info.plist *(combined with C2)*

See C2.

**Track C total effort:** ~22 hours. Blockers (C1-C4) are < 4 hours combined.

---

## Track D — Freemium Monetization Strategy

### The Premise

Youth soccer costs families $5K-$20K/year. A $9.99/mo subscription is 1% of their annual spend. **The pricing question isn't "Will they pay?" — it's "Can they instantly see why it's worth 1% more for 10x more value?"**

Competitor pricing for reference:
- Techne Futbol: $9.99-$37.99/mo
- Mojo Sport: $59.99/yr (~$5/mo)
- Anytime Soccer Training: $12.99/mo
- DribbleUp: $96/yr + $100 smart ball
- TopYa: Freemium

Market sweet spot: **$7-12/mo or $60-90/yr for a solo plan.**

### Conventional Model (What Everyone Does)
Free tier + Pro tier + maybe Family tier. Gate enough features to force upgrade.

### Unconventional Models Worth Considering

#### Model 1: "Free for the Kid, Paid for the Parent"
The kid uses the app for free forever. Parents pay for parent-value features only.

- **FREE (kid-facing):** All drills, training modes, XP, streaks, 1 avatar, basic stats, voice commands, missions
- **PARENT PREMIUM ($6.99/mo or $59/yr):**
  - Parent Insights Dashboard with weekly notifications
  - Development Profile PDF (shareable with coaches)
  - College Recruiting Readiness score (13-18)
  - Side-by-side multi-kid view (up to 4 kids)
  - Priority support
  - Advanced training analytics

**Why it's smart:** The kid never hits a paywall → they keep training → their engagement is the pitch to the parent. "Look, Alex has a 30-day streak — want to see the full report?" Parent converts because the kid is already hooked.

**Risk:** Might leave money on the table if the kid would've wanted premium features.

---

#### Model 2: "The 1% Framing" Pricing Narrative
Frame the subscription explicitly as a percentage of soccer spend.

**Messaging:** *"You spend $8,000/year on club soccer. Get 10x more out of it for 1% more."*

This is a marketing positioning, not a pricing tier. Works with any conventional tier structure. Moves the mental anchor from "another app subscription" to "soccer investment optimization."

---

#### Model 3: "Founders Pricing" Launch Play
First 1,000 subscribers lock in **$4.99/mo forever** (vs $9.99 list). Creates:
- Launch urgency
- Word-of-mouth ("I got founders pricing")
- Early adopter evangelists
- Real revenue data at low CAC

After first 1,000, switch to standard pricing. The locked-in users become your loudest fans.

**Implementation:** Simple `foundersUser: Bool` flag on the subscription. StoreKit supports tiered pricing.

---

#### Model 4: "Skin-in-the-Game" Refund (Bold)
**$9.99/mo. If your kid trains 15+ days in any month, you get 50% back that month.**

This is radical alignment. You're saying: "We only make money if your kid actually uses the app."

**Why it's potentially brilliant:**
- The app is designed to drive 15+ training days/mo anyway (that's the whole point of streaks)
- Parents perceive almost-zero risk
- Creates a goal parents and kids share (both want the refund)
- Insanely differentiating messaging
- Math works: most successful users hit the refund threshold, but ARPU stays healthy because many users lapse

**Risk:** If WAY too many users hit the refund, ARPU tanks. Need to monitor closely. Could offer as a "launch promotion" with sunset clause.

---

#### Model 5: Grandparent Gift Subscriptions
**Underserved acquisition channel.** Grandparents LOVE buying things for their grandkid's sports. Offer:
- Gift a year of Premium ($79 as a gift card)
- Beautiful gift card delivery via email
- No App Store friction — web-based purchase (in-app code redemption)

**Why it works:**
- Parents won't always upgrade themselves but won't turn down a gift
- Grandparents feel involved in the kid's development
- Birthday / Christmas / season-kickoff purchase moments
- Retention after gift expires is 40-60% typical for gifted subs

---

#### Model 6: Club Partnership B2B (Highest LTV)
**$299/year per club for up to 25 players.**

Clubs already budget for player development platforms. Sell:
- Coach dashboard: see all players' training consistency
- Identify underperformers before they quit
- Centralized club branding in the app
- Attribution: "Powered by Club ABC"

**Why it's attractive:**
- Single sales motion = 25 subs
- Retention tied to club contract (annual)
- Creates app moats — hard to churn when your whole team is on it
- Clubs become channel partners (emails, flyers)

**Challenge:** Requires a sales motion. Could start with 2-3 pilot clubs for free in exchange for case studies.

---

### Recommended Launch Monetization Strategy

Combine these into a clear ladder:

#### Tier Structure

**FREE FOREVER (core)**
- All training drills, modes, and activities
- 1 avatar (chosen at onboarding)
- Basic streaks + Streak Shields
- XP system (but XP doesn't unlock all avatars)
- Voice commands
- Last 30 days of history
- Daily Focus Tip
- Missions

**PREMIUM ($8.99/mo or $69/yr) — Player + Parent**
- ALL 7 avatars unlocked
- Unlimited training history
- Weekly Recap shareable cards (viral feature)
- Parent Insights Dashboard with notifications
- Advanced analytics (trends, comparisons)
- Rest Day intelligence
- Priority support
- App Icon variants
- Coach Voice packs (all included, no per-pack purchases)

**PREMIUM FAMILY ($13.99/mo or $109/yr)**
- Everything in Premium
- Up to 4 kids on one account
- Cross-sibling "family league" (siblings compete gently)
- Single parent dashboard for all kids

**FOUNDERS PRICING (launch promo, first 1,000 subscribers)**
- $4.99/mo Premium locked forever
- $89/yr Family Plan locked forever

**CLUB PLAN ($299/yr per club, up to 25 players)**
- B2B sales motion, post-launch
- Everything in Premium Family + Coach Dashboard

#### One-Time IAPs (Impulse + Upsell)

| IAP | Price | Value |
|-----|-------|-------|
| Player Development PDF Report | $4.99 | Beautiful shareable report (quarter/season summary) — perfect for coaches, grandparents, college applications |
| Recruiting Readiness Assessment | $19.99 | Deep analysis for ages 13-18, benchmarked against D1/D2/D3 stats (once Phase 2 ships) |
| Avatar Cosmetic Packs | $1.99-$4.99 | Cosmetic skins: jerseys, boots, celebration animations. Kids-pressuring-parents model |
| Streak Insurance (extra shield) | $0.99 | Impulse save-my-streak |
| Gift a Year of Premium | $79 | Grandparent channel |

#### First-Run Monetization Flow

1. **Onboarding — no paywall.** Friction-free signup → avatar selection → first session.
2. **After first session** — show the Weekly Recap concept ("Come back Sunday to see your first recap!") with a subtle Premium teaser on one locked feature.
3. **Day 3-5** — Push notification: *"Alex has 3 days in. See what Premium unlocks →"* Soft nudge.
4. **After streak milestone (7 days)** — Full paywall moment: "You're committed. Unlock the whole experience."
5. **Parent Dashboard (first visit by parent)** — Parent-specific paywall with parent-value pitch. ("Get the full picture of Alex's development. $8.99/mo.")

**Key principle:** Never paywall the kid during training. Paywall parents in parent contexts. This is how Model 1 ("Free for Kid, Paid for Parent") can live inside a conventional tier structure.

#### Projected Economics (Directional)

Assumptions: 10,000 downloads in first 6 months.

| Conversion | Users | ARPU | Monthly Revenue |
|------------|-------|------|-----------------|
| Free (no conversion) | 7,500 (75%) | $0 | $0 |
| Founders Premium (first 1000, locked) | 500 | $4.99 | $2,495 |
| Standard Premium | 1,500 (15%) | $8.99 | $13,485 |
| Premium Family | 500 (5%) | $13.99 | $6,995 |
| One-time IAP (PDF reports) | 200 purchases/mo | $4.99 | $998 |
| **Estimated Month 6 MRR** | | | **~$24K/mo** |

Numbers are illustrative. Real conversion rates for freemium apps range 2-10% — family-cost alignment could push toward the higher end.

#### Technical Implementation Notes

- Use Apple StoreKit 2 (iOS 15+)
- Subscription management via `Product.SubscriptionInfo`
- Server-side receipt validation (coordinate with web backend)
- Entitlement caching for offline access to paid features
- No IAP UI required during onboarding (lower conversion vs delayed paywall)

**Files to create:**
- `PitchDreams/Core/Subscriptions/SubscriptionManager.swift`
- `PitchDreams/Core/Subscriptions/EntitlementStore.swift`
- `PitchDreams/Features/Paywall/Views/PaywallView.swift`
- `PitchDreams/Features/Paywall/ViewModels/PaywallViewModel.swift`

**Estimated effort:** 3-5 days for StoreKit 2 integration + paywall UI. Gate existing features behind entitlement checks.

---

## Track E — Kid Stickiness Features

The philosophical shift: stop being a training app. Become a **soccer identity platform** that happens to make kids better. Training apps optimize for adults imagining what kids should want. Identity apps optimize for what kids actually want: identity expression, collecting, status, surprise, ownership.

All Track E features reinforce each other — the Player Card displays the Signature Moves you've unlocked, the Mystery Box can drop moves, squads compete to own the best moves, etc.

### E1. Player Card (SHIP AT LAUNCH — highest leverage single feature)

A beautiful, shareable trading-card-style profile that evolves with the kid.

**What it is:**
- Avatar at current evolution stage (uses existing art)
- Position badge (GK, DEF, MID, FWD)
- Self-chosen archetype tag ("Speedster," "Playmaker," "Wall," "Magician")
- Top 4 stats (Speed, Touch, Vision, Shot Power, Work Rate, Composure) — earned through training
- 4 "Signature Moves" loadout slots (see E2)
- Achievements row (badges earned)
- Club crest (self-designed or club-licensed later)
- Custom flair border (unlockable frames)

**Why it's sticky:**
- AirDrop-able between friends ("here's my card")
- Postable to Instagram/TikTok (viral loop — permanently theirs, not a one-time recap)
- Investment — they spend hours perfecting it
- Evolves as they train → comes back to see updates
- Social currency **outside** the app

**Stitch mockups required:**
- `player_card_front` — The canonical card design
- `player_card_editor` — Flow for picking stats, moves, archetype
- `player_card_share` — Share sheet with export options

**Files to create:**
```
PitchDreams/Models/PlayerCard.swift
PitchDreams/Models/PlayerArchetype.swift
PitchDreams/Features/PlayerCard/Views/PlayerCardView.swift
PitchDreams/Features/PlayerCard/Views/PlayerCardEditorView.swift
PitchDreams/Features/PlayerCard/Views/PlayerCardShareSheet.swift
PitchDreams/Features/PlayerCard/ViewModels/PlayerCardViewModel.swift
```

**Files to modify:**
```
PitchDreams/Features/ChildHome/Views/ChildHomeView.swift  # Add "My Card" entry point
PitchDreams/Core/Navigation/ChildTabNavigation.swift       # Consider adding Card tab (replaces/complements Skills?)
```

**Effort:** 3-5 days. Reuses avatar system, stats data, `ImageRenderer` for sharing.

---

### E2. Signature Moves System (SHIP AT LAUNCH with 5 fully-authored moves)

Unlockable pro skill moves functioning as collectibles + mastery milestones. **Each is a full technique-teaching journey, not a drill-completion checkbox.**

> **Implementation spec:** `TRACK_E_SIGNATURE_MOVES_DETAIL.md`

**Launch set of 5 fully-authored moves:**
1. Scissor (common, beginner)
2. Step-Over (common, beginner)
3. Body Feint (common, beginner)
4. La Croqueta (rare, intermediate)
5. Elastico (rare, intermediate)

**Post-launch release cadence — 1 new move every 3-4 weeks:**
6. Rainbow Flick (+3 weeks)
7. Rabona (+6 weeks)
8. Maradona Turn (+10 weeks)
9. Zidane Roulette (+14 weeks)
10. Scorpion Kick (+18 weeks — seasonal event)

Each release includes in-app banner, push notification, social clip, and 2x XP on that move for 48 hours — turning content drops into re-engagement events.

**Each move has:**
- Pro-footage preview (short clip — can be stock animation initially, real footage later)
- Animated diagram walkthrough (uses existing `AnimatedTacticalPitchView` system)
- 3-stage progressive drill unlock sequence (Beginner Attempt → Intermediate → Mastery)
- Unique badge/stamp earned at mastery
- Slot eligibility on Player Card (pick your 4 "loadout" moves)

**Why it's sticky:**
- Collectibility (Pokémon pattern — gotta catch 'em all)
- Mastery (genuine skill progression)
- Status (teammates see your loadout on your Player Card)
- Aspiration ("I have Messi's La Croqueta unlocked")
- Content treadmill — 2-3 new moves released monthly post-launch

**Stitch mockups required:**
- `signature_moves_library` — Grid of all moves with locked/unlocked states
- `signature_move_detail` — Single move with preview video, unlock stages, drill progression
- `signature_move_unlocked_celebration` — New move unlock celebration

**Files to create:**
```
PitchDreams/Models/SignatureMove.swift
PitchDreams/Models/SignatureMoveRegistry.swift          # 10 launch moves
PitchDreams/Core/Persistence/SignatureMoveStore.swift   # Unlock progress tracking
PitchDreams/Features/SignatureMoves/Views/SignatureMovesLibraryView.swift
PitchDreams/Features/SignatureMoves/Views/SignatureMoveDetailView.swift
PitchDreams/Features/SignatureMoves/Views/SignatureMoveUnlockedView.swift
PitchDreams/Features/SignatureMoves/ViewModels/SignatureMovesViewModel.swift
```

**Integration:**
- Connects to Skills tab as new section
- Drill completions check move unlock progress
- Player Card loadout picker reads unlocked moves
- Mystery Box (E5) can drop free move attempts

**Effort:** 5-7 days (content creation heavy — the move animations and drill progressions are most of the work). Engine is simple.

---

### E3. Daily Mystery Box (SHIP AT LAUNCH — highest retention-per-hour-of-work)

Variable reward schedule — the single most addictive mechanic in app design. Ethically framed around earned rewards, not paid loot boxes.

**What it is:**
Every day on home dashboard, a closed box appears. Tap to open for a random reward:

| Reward | Drop Rate | Effect |
|--------|-----------|--------|
| Small XP bonus (+25) | 30% | Instant XP |
| Medium XP bonus (+50) | 20% | Instant XP |
| Signature Move attempt | 15% | Try a locked move's drill for free today |
| Fever Time activation | 10% | Next 15 min of training = 3x XP |
| Cosmetic drop | 10% | Jersey color, celebration animation, card frame |
| Streak Shield (extra) | 8% | Bonus shield |
| Mystery reward | 5% | Larger XP, bigger cosmetic |
| Legendary drop | 2% | Unique achievement, rare avatar unlock, exclusive card frame |

**Key mechanics:**
- One box per day, resets at midnight local time
- Must open to reveal — builds anticipation, requires daily return
- Drop rates transparent in Settings ("See odds") — ethical positioning
- Box opens with physics animation + haptic crescendo + confetti

**Why it's sticky:**
- Variable rewards hijack the same loops as TikTok and slot machines — ethically aimed at good behavior
- Forces daily open even on non-training days
- Small surprises drive retention better than predictable bigger rewards
- Streak adjacent: "Opened a box 30 days in a row" is a separate achievement

**Ethical guardrails:**
- No money involved in randomness (no paid loot boxes)
- Drop rates disclosed
- No gambling-adjacent escalation mechanics
- Parents can disable via ParentControls (`showMysteryBox: Bool`)

**Stitch mockups required:**
- `mystery_box_closed` — The enticing closed box on home dashboard
- `mystery_box_opening` — Box opening animation sequence
- `mystery_box_reveal` — Reward reveal screen

**Files to create:**
```
PitchDreams/Models/MysteryReward.swift
PitchDreams/Core/Content/MysteryBoxEngine.swift   # Drop rate logic, weighted random
PitchDreams/Core/Persistence/MysteryBoxStore.swift # Daily state tracking
PitchDreams/Features/ChildHome/Views/MysteryBoxView.swift
PitchDreams/Features/ChildHome/Views/MysteryBoxRevealView.swift
PitchDreams/Features/ChildHome/ViewModels/MysteryBoxViewModel.swift
```

**Effort:** 1-2 days. Simple weighted-random + UI + persistence.

---

### E4. Squad Identity (POST-LAUNCH PHASE 2 — expand existing Squad Challenges)

Already in Phase 2 spec as "Squad Challenges." Track E extends it with identity:
- Squad name, color, crest design
- Squad motto (pre-approved emoji-only for COPPA safety)
- Squad rank (Bronze → Silver → Gold → Platinum → Diamond)
- Emoji-only reactions to shared squad moments (COPPA-safe social)
- Squad-collective badges

**Effort:** Adds ~2 days to original Squad Challenges scope.

---

### E5. IRL Pitch Layer (SHIP AT LAUNCH if time allows, otherwise Month 1 post-launch)

GPS-based real-world integration. When the kid is at an actual pitch/field, the app transforms.

**Mechanics:**
- "⚽️ You're at the pitch" banner on home dashboard when GPS confirms a pitch location
- Bonus XP multiplier active (2x for the duration of the session)
- Pitch-specific achievements ("Trained at 5 different pitches" = badge)
- "Away game mode" — traveling to a new pitch unlocks a travel sticker
- Home pitch designation — regular pitch gets a custom name on Player Card

**Sneaky dual benefit:**
- Bridges digital → physical (Pokémon GO principle)
- Partial verification without feeling like surveillance — sessions at real pitches get extra credibility in parent dashboard

**Files to create:**
```
PitchDreams/Core/Location/PitchDetector.swift    # Core Location integration
PitchDreams/Models/TrainingPitch.swift            # User's logged pitches
PitchDreams/Features/ChildHome/Views/PitchLocationBanner.swift
```

**Permissions:**
Add to `Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>PitchDreams detects when you're at a soccer pitch to give you bonus XP for real training.</string>
```

**Effort:** 1-2 days.

---

### E6. Train Like Your Hero (POST-LAUNCH MONTH 2-3)

Choose a pro player, get a curated 4-6 week training program. Described in stickiness analysis — sticky and licensable. Defer to post-launch to secure any partnerships worth having.

---

### E7. Highlight Reel & Journey Timeline (POST-LAUNCH MONTH 3-4)

Auto-compiled monthly highlight from logged sessions + optional user-recorded 10-sec drill videos. Video verification problem becomes a beloved feature. Defer until base app is stable — content-generation UX is tricky to get right.

---

### Track E Summary

| # | Feature | Ship When | Effort |
|---|---------|-----------|--------|
| E1 | Player Card | LAUNCH | 3-5 days |
| E2 | Signature Moves (5 fully-authored moves) | LAUNCH | 12-15 days |
| E3 | Daily Mystery Box | LAUNCH | 1-2 days |
| E4 | Squad Identity (extend Squad Challenges) | Phase 2 | +2 days |
| E5 | IRL Pitch Layer | LAUNCH or Month 1 | 1-2 days |
| E6 | Train Like Your Hero | Month 2-3 | 5-7 days |
| E7 | Highlight Reel | Month 3-4 | 7-10 days |

**Launch scope for Track E:** E1 + E2 + E3 + E5 = **~17-24 days**. E2 alone consumed the original Week 3 budget. Two options:

**Option A — Extend timeline to 5 weeks total.** Dedicate Weeks 3-4 to Track E + Track F, push monetization to Week 5.

**Option B — Reduce Signature Moves launch scope further.** Ship 3 moves at launch (Scissor, Body Feint, La Croqueta) = ~8-10 days, fits the original Week 3. Release the other 2 launch moves (Step-Over, Elastico) in Month 1 post-launch as "Week 1 bonus drops."

Recommendation: **Option B.** Shipping 3 excellent moves is better than 5 rushed ones, and post-launch "bonus drops" create instant re-engagement.

---

## Track F — Learn Module Clarity for Young Users

**The problem:** Tactical animations in `AnimatedTacticalPitchView` assume users can interpret bird's-eye-view diagrams, tactical vocabulary ("half-space," "press trigger"), and fast-paced abstract motion. An 8-year-old processes none of this. A 12-year-old barely does. A 15-year-old mostly can.

The existing `LEARN_ANIMATIONS_PLAN.md` handles animation mechanics well but doesn't address comprehension gaps for the youngest half of the user base.

**The fix:** Seven concrete techniques to make lessons land for ages 8-12 while staying rich enough for ages 13-18.

### F1. Spotlight Mode (BEFORE each step)

Before the full diagram animates, dim everything except the key element for 1.5 seconds with a caption:
*"Watch the midfielder first."*

Then the full animation plays. Gives young kids a focal point before visual overload.

**Implementation:** Add `spotlightElementId: String?` to `TacticalStep`. When set, play a 1.5s spotlight phase before the regular animation — all other elements at 15% opacity with a pulse ring around the spotlight element.

**Files to modify:**
```
PitchDreams/Models/AnimatedTacticalTypes.swift       # Add spotlightElementId to TacticalStep
PitchDreams/Features/Learn/Views/AnimatedTacticalPitchView.swift  # Add spotlight phase before main animation
```

**Effort:** ~1 day.

---

### F2. Age-Adaptive Narration Scripts

The user's age (already collected in onboarding — stored as `age` on profile) determines narration vocabulary.

**Each step gets two narration scripts:**
- `narrationYoung: String` — age 8-11 (simplified language, concrete metaphors)
- `narration: String` — age 12+ (standard tactical vocabulary)

**Example:**
- Young (age 9): *"See the gap? That's an invisible road. Run down the road before a defender closes it."*
- Standard (age 14): *"Identify the half-space. Time your run to exploit the passing lane before the opposition's press reorganizes."*

**Implementation:**
- Add `narrationYoung: String?` to `TacticalStep` (optional — falls back to `narration` if absent)
- `LessonPlayerView` picks the right script based on `childProfile.age`
- Content team writes young variants for all priority lessons

**Files to modify:**
```
PitchDreams/Models/AnimatedTacticalTypes.swift
PitchDreams/Models/AnimatedTacticalLessonRegistry.swift   # Add young narration for all lessons
PitchDreams/Features/Learn/Views/LessonPlayerView.swift   # Read age, pick script
```

**Effort:** 1 day engine + ~3 days content writing for all existing lessons.

---

### F3. Tap-to-Explain (Interactive Pause)

Any element on the pitch is tappable at any time. Tapping pauses the animation and shows a speech bubble with what that character is thinking/doing in plain language.

Example: tap the defender. Bubble appears: *"I'm trying to block the pass. If I can force the ball to the sideline, the goalkeeper has an easier save."*

**Already partially implemented:** `AnimatedTacticalPitchView` supports `onPlayerTap`, `onArrowTap`, `onZoneTap` callbacks but they're unused. Wire them up.

**Implementation:**
- Add `tapDescriptionYoung: String?` and `tapDescription: String?` to each `TacticalPlayer`, `TacticalArrow`, `TacticalZone`
- `LessonPlayerView` handles taps → pauses animation → displays speech bubble overlay
- Bubble dismisses on tap-outside → animation resumes

**Files to create:**
```
PitchDreams/Features/Learn/Views/ElementSpeechBubble.swift
```

**Files to modify:**
```
PitchDreams/Models/AnimatedTacticalTypes.swift             # Add tap descriptions
PitchDreams/Features/Learn/Views/LessonPlayerView.swift    # Wire tap handlers, bubble state
```

**Effort:** 2 days engine + content writing for priority elements.

---

### F4. Slow-Mo Replay Button

Every step has a prominent "🐢 Slow-Mo" button. Plays the step at 0.5x speed with extended narration and per-element highlights. Kids can rewatch as many times as they want.

**Implementation:**
- Add playback rate control to `AnimatedTacticalPitchView`
- Button in `LessonPlayerView` adjacent to the pitch
- Narration uses SSML rate adjustment via `AVSpeechSynthesizer` (already available)

**Files to modify:**
```
PitchDreams/Features/Learn/Views/AnimatedTacticalPitchView.swift
PitchDreams/Features/Learn/Views/LessonPlayerView.swift
PitchDreams/Core/Voice/CoachVoice.swift    # Add slow narration variant
```

**Effort:** 0.5 days.

---

### F5. "Your Avatar Is the Player" Personalization

In tactical diagrams, the primary/highlighted player is rendered as the kid's avatar (Wolf, Lion, etc.), not an abstract dot. Creates immediate emotional investment.

"The Wolf (you!) scans the field. The Wolf sees the run. The Wolf passes."

**Implementation:**
- Extend `PlayerDot` view to render avatar image when `player.type == .self_` AND an avatar is available
- Use existing `Avatar.assetName(for:totalXP:)` to pick the right evolution stage
- Fall back to abstract dot if no avatar assigned

**Files to modify:**
```
PitchDreams/Features/Learn/Views/AnimatedTacticalPitchView.swift   # PlayerDot rendering
```

**Effort:** 0.5 days.

---

### F6. Cause-and-Effect Shadow Replay

For lessons teaching WHY a technique matters, show the bad outcome first, then the good one.

Example for "Scan Before Receiving":
- **Shadow replay (bad):** Player receives without scanning → defender steals → sad face emoji, gentle "oops" sound.
- **Real replay (good):** Player scans, receives, turns, passes successfully → happy pulse + positive sound.

Makes the concept visceral, not theoretical.

**Implementation:**
- Optional `shadowStep: TacticalStep?` field on lessons that benefit from contrast
- `LessonPlayerView` plays shadow step first with "What NOT to do" caption in red, then standard step with "Do this instead" in green
- Applies to ~30% of lessons (those teaching a technique vs. those teaching a concept)

**Files to modify:**
```
PitchDreams/Models/AnimatedTacticalTypes.swift              # Add shadowStep
PitchDreams/Models/AnimatedTacticalLessonRegistry.swift    # Add shadow steps for key lessons
PitchDreams/Features/Learn/Views/LessonPlayerView.swift
```

**Effort:** 1 day engine + content writing per lesson.

---

### F7. Mini-Quiz Comprehension Check (End of Each Lesson)

Not pass/fail — just reinforcement. 2-3 tap-based questions per lesson:

- **"Tap where the midfielder should go next."** (Tap on pitch)
- **"Which player has the most space?"** (Tap an avatar)
- **"What does the blue arrow mean?"** (Multiple choice with icons)

Correct = green pulse + XP bonus + "You got it!" Wrong = gentle "Hmm, watch again" → replays relevant step.

**Files to create:**
```
PitchDreams/Models/LessonQuiz.swift
PitchDreams/Features/Learn/Views/LessonQuizView.swift
```

**Files to modify:**
```
PitchDreams/Models/AnimatedTacticalLessonRegistry.swift    # Add quiz questions
PitchDreams/Features/Learn/Views/LessonPlayerView.swift   # Show quiz after last step
```

**Effort:** 2-3 days engine + quiz authoring per lesson.

---

### Track F Summary

| # | Feature | Effort | Impact on 8-12 Audience |
|---|---------|--------|------------------------|
| F1 | Spotlight Mode | 1 day | Huge — gives a focal point |
| F2 | Age-Adaptive Narration | 4 days | Massive — vocabulary match |
| F3 | Tap-to-Explain | 2 days | Deepens engagement |
| F4 | Slow-Mo Replay | 0.5 day | High — self-paced learning |
| F5 | Your Avatar Is the Player | 0.5 day | Emotional connection |
| F6 | Cause-and-Effect Shadow | 1 day + content | Makes concepts visceral |
| F7 | Mini-Quiz | 3 days + content | Converts passive → active |

**Total engine effort:** ~8 days. **Content effort:** ~3-5 days alongside. Fits into Week 3.

**Minimum viable set for launch:** F1 + F2 + F4 + F5 (~6 days). F3, F6, F7 can follow Month 1 post-launch.

---

## Dependency Graph

```
                    ┌──────────────────────────────────────────────┐
                    │ Week 1: Foundation                           │
                    └──────────────────────────────────────────────┘
                              │              │              │
            ┌─────────────────┼──────────────┼──────────────┼──────────────────┐
            ▼                 ▼              ▼              ▼                  ▼
    [Stitch mockups]   [C1-C4 blockers]  [B1 reminders]  [B2 app icons]   [B5 review prompt]
     (7 screens)        (4 hours total)   (2-3 hr)        (2-3 hr)          (30 min)
            │
            ▼
    ┌───────────────────────────────────────────────────────────┐
    │ Week 2: Phase 1 Features                                  │
    └───────────────────────────────────────────────────────────┘
            │
            ├── Workstream 1: XP + Avatar Evolution (CRITICAL PATH)
            │   depends on: home_xp_bar, home_xp_earned_toast, evolution_celebration mockups
            │
            ├── Workstream 2: Enhanced Streaks (depends on XP)
            │   depends on: streak_ring_enhanced, shield_deployed_toast mockups
            │
            └── Workstream 3: Weekly Recap (depends on XP)
                depends on: weekly_recap_card, weekly_recap_sheet mockups
                REQUIRES: C1 (Photo Library permission)

    ┌───────────────────────────────────────────────────────────┐
    │ Week 3: Kid Stickiness + Learn Clarity                    │
    └───────────────────────────────────────────────────────────┘
            │
            ├── Track E1: Player Card (3-5 days)
            ├── Track E2: Signature Moves w/ 10 launch moves (5-7 days)
            ├── Track E3: Daily Mystery Box (1-2 days)
            ├── Track E5: IRL Pitch Layer (1-2 days, optional at launch)
            ├── Track F1-F2, F4-F5: Learn clarity MVP (~6 days)
            └── Workstream 4c: PB Celebrations

    ┌───────────────────────────────────────────────────────────┐
    │ Week 4: Monetization + Final Polish + Beta                │
    └───────────────────────────────────────────────────────────┘
            │
            ├── StoreKit 2 integration + Paywall
            ├── C5-C8 offline/retry/launch screen/token refresh
            ├── C9-C11 accessibility/validation/skeletons
            ├── B3 Daily Tip + B6 Empty States + B7 Rest Day + B8 Coach Voice
            └── TestFlight beta → feedback loop → App Store submission
```

---

## Consolidated File Checklist

### New Files (29 total)

**Models:**
```
PitchDreams/Models/XPLevel.swift
PitchDreams/Models/WeeklyRecap.swift
PitchDreams/Models/DailyTip.swift
```

**Core Infrastructure:**
```
PitchDreams/Core/Persistence/XPStore.swift
PitchDreams/Core/Persistence/PersonalBestStore.swift
PitchDreams/Core/Network/NetworkMonitor.swift
PitchDreams/Core/Sync/SessionSyncQueue.swift
PitchDreams/Core/Notifications/TrainingReminderManager.swift
PitchDreams/Core/Reviews/ReviewPromptManager.swift
PitchDreams/Core/Content/DailyTipRegistry.swift
PitchDreams/Core/Subscriptions/SubscriptionManager.swift
PitchDreams/Core/Subscriptions/EntitlementStore.swift
```

**Feature Views:**
```
PitchDreams/Features/ChildHome/Views/XPBarView.swift
PitchDreams/Features/ChildHome/Views/XPEarnedToast.swift
PitchDreams/Features/ChildHome/Views/WeeklyRecapCardView.swift
PitchDreams/Features/ChildHome/Views/WeeklyRecapSheetView.swift
PitchDreams/Features/ChildHome/Views/ShieldDeployedToast.swift
PitchDreams/Features/ChildHome/Views/DailyTipCard.swift
PitchDreams/Features/ChildHome/Views/OfflineBanner.swift
PitchDreams/Features/ChildHome/ViewModels/WeeklyRecapViewModel.swift
PitchDreams/Features/Training/Views/RestDayCardView.swift
PitchDreams/Features/Training/Views/StretchingRoutineView.swift
PitchDreams/Features/ParentControls/Views/NotificationSettingsView.swift
PitchDreams/Features/ParentControls/Views/AppIconPickerView.swift
PitchDreams/Features/Paywall/Views/PaywallView.swift
PitchDreams/Features/Paywall/ViewModels/PaywallViewModel.swift
```

**Resources:**
```
PitchDreams/PrivacyInfo.xcprivacy
PitchDreams/Resources/LaunchScreen.storyboard (or equivalent)
Assets.xcassets/AppIcon-Wolf, -Lion, -Panther, -Dark (new icon sets)
```

**Tests:**
```
PitchDreamsTests/Core/XPCalculatorTests.swift
PitchDreamsTests/Core/XPStoreTests.swift
PitchDreamsTests/Core/PersonalBestStoreTests.swift
PitchDreamsTests/Core/NetworkMonitorTests.swift
PitchDreamsTests/Core/SessionSyncQueueTests.swift
PitchDreamsTests/Core/SubscriptionManagerTests.swift
PitchDreamsTests/Features/WeeklyRecapViewModelTests.swift
PitchDreamsTests/Features/PaywallViewModelTests.swift
```

### Files to Modify (20 total)

```
PitchDreams/Info.plist                                        # C1, C2, icon declarations
PitchDreams/PitchDreamsApp.swift                              # Notification permission, StoreKit init
PitchDreams/Models/Avatar.swift                               # XP-driven evolution (CRITICAL)
PitchDreams/Features/ChildHome/Views/ChildHomeView.swift      # XP bar, daily tip, recap banner, offline banner
PitchDreams/Features/ChildHome/Views/ConsistencyRingView.swift # Escalating flame, shield bank
PitchDreams/Features/ChildHome/Views/EvolutionModal.swift     # XP context enhancement
PitchDreams/Features/ChildHome/Views/StreakMilestoneModal.swift # XP bonus, potential evolution trigger
PitchDreams/Features/ChildHome/Views/AvatarChangeSheet.swift  # Migrate to totalXP
PitchDreams/Features/ChildHome/Views/FirstSessionGuideView.swift # Remove print
PitchDreams/Features/ChildHome/ViewModels/ChildHomeViewModel.swift # XP data, tip, recap availability
PitchDreams/Features/Training/ViewModels/ActiveTrainingViewModel.swift # Award XP, review prompt trigger
PitchDreams/Features/Training/ViewModels/TrainingViewModel.swift # Detect high soreness → rest day
PitchDreams/Features/Training/Views/ActiveDrillView.swift     # Idle timer disable, avatar migration
PitchDreams/Features/QuickLog/ViewModels/QuickLogViewModel.swift # XP awards
PitchDreams/Features/FirstTouch/ViewModels/FirstTouchViewModel.swift # XP + PB detection
PitchDreams/Features/Learn/Views/CoachCharacterView.swift     # Avatar migration
PitchDreams/Features/ParentDashboard/Views/ParentDashboardView.swift # Avatar migration, premium gate
PitchDreams/Features/ParentDashboard/Views/ChildDetailView.swift # Avatar migration
PitchDreams/Features/ParentControls/Views/ParentControlsView.swift # Legal section, notification settings, icon picker, subscription mgmt
PitchDreams/Core/Voice/CoachVoice.swift                       # Milestone celebration phrases
PitchDreams/Core/Extensions/DesignSystem.swift                # Haptic modifier, spring presets
PitchDreams/Core/Auth/AuthManager.swift                       # Token refresh
PitchDreams/Core/API/TokenInterceptor.swift                   # Token refresh
PitchDreams/Core/Navigation/ChildTabNavigation.swift          # Verify haptics
PitchDreams/Features/Onboarding/*.swift                       # Input validation
```

---

## Post-Launch Content Roadmap (Months 1-12)

The launch delivers the foundation. Stickiness depends on *continuously* delivering new content — especially Signature Moves, seasonal events, and Train-Like-Your-Hero programs. The app that looks alive 6 months after launch wins.

### Month 1: Stabilize + Momentum

**Priorities:**
- Triage and fix P0/P1 bugs from real user data
- Ship 2-3 new Signature Moves (content drop schedule starts here)
- First seasonal event: "Welcome to the Pitch" — 14-day onboarding challenge with exclusive card frame reward
- E5 IRL Pitch Layer if not shipped at launch
- F3 Tap-to-Explain + F6 Cause-and-Effect Shadow (remaining Learn clarity improvements)

**Metric to watch:** Day 7 retention. If below 30%, polish onboarding and the first-session experience before adding more.

### Month 2: Depth Expansion

**New features:**
- **E6 Train Like Your Hero** — Launch with 3-5 pro programs (Messi, Mbappé, Putellas, Modric, Pulisic). Each is a 4-6 week structured training arc with themed coach voice lines and culminates in unlocking the pro's signature move.
- **Position-Specific Skill Trees** (deferred Phase 2 feature) — RPG-style branching development paths for GK / DEF / MID / FWD.
- **F7 Lesson Mini-Quizzes** across all existing tactical lessons
- 3 more Signature Moves (content treadmill continues)

**Metric to watch:** Day 30 retention. Streak distribution — what % of users have a 14+ day streak?

### Month 3: Social + Creative

**New features:**
- **Squad Challenges full launch** (if not at launch) — with E4 Squad Identity
- **E7 Highlight Reel + Journey Timeline** — users can record optional 10-sec drill videos that auto-compile into monthly highlight reels
- **Trick Studio** — creative mode where kids combine unlocked moves into custom sequences and share with friends
- **Mental Game Toolkit** (deferred Phase 2 feature) — pre-game routines, bounce-back cards, confidence journal
- 3 more Signature Moves

**Metric to watch:** K-factor (referral rate). Player Card shares + squad invites should drive organic growth by now.

### Month 4: Verification Layer

**New features:**
- **Audio-based juggling counter** — on-device ML detects rhythmic ball touches via microphone during "challenge mode." First objectively-verified metric on the parent dashboard.
- **Parent Witness Mode** — parents can confirm sessions they observed. Verified sessions get a ✓ badge.
- **Verified Skill Benchmarks tier** — parent dashboard cleanly separates "Training Activity (self-logged)" from "Skill Benchmarks (verified)"
- Anti-gaming guardrails from the earlier discussion: minimum session time, non-pausable drill timers, anomaly flagging

**Metric to watch:** Premium conversion rate. Verified metrics make the Parent Insights tier concretely valuable.

### Month 5: Community

**New features:**
- **Leagues** (deferred Phase 2) — activate now that WAU supports 15-20 person leagues per tier. Announce as major "new feature" to re-engage lapsed users.
- **Club Plan B2B launch** — sales motion begins. First 10 clubs onboarded at promotional pricing. Target: clubs with 50+ players.
- **Referral rewards** — invite a friend → both get premium trial extension

**Metric to watch:** ARPU. B2B deals should lift it materially if secured.

### Month 6: College + Parent Value

**New features:**
- **College Recruiting Dashboard** (deferred Phase 2) — timeline tracker, development profile PDF, ID camp calendar
- **Recruiting Readiness Assessment** ($19.99 IAP or Premium-included) — analysis benchmarked against verified data
- **Parent-facing weekly development insights emails** (off-app channel) — keeps parents engaged even without opening the app

**Metric to watch:** Parent-tier conversion among users age 13+.

### Month 7-9: Differentiation Moves

**New features:**
- **Camera-based touch tracking** (ambitious) — ML detects ball touches from phone camera video. The DribbleUp moat without the $100 ball.
- **Pro partnerships** — licensed coach voices, exclusive content, or branded challenges (contingent on deals)
- **Seasonal competitions** tied to real-world soccer calendar (Euros, Copa America, MLS playoffs, World Cup run-up)
- **Global Leaderboards** — once user base reliably supports large-scale ranking

**Metric to watch:** 6-month retention. Product-market fit signals lock in here or don't.

### Month 10-12: Moats + Expansion

**Strategic priorities:**
- **Season Mode narrative** — a year-long story arc with chapter milestones, building to a season finale ceremony. Gives the app a *beginning-middle-end* feel.
- **Multi-sport exploration** — if soccer works, evaluate basketball/baseball/tennis adjacent entries
- **Family Plan expansion** — more multi-kid features, cross-sibling dynamics
- **International expansion** — localization (Spanish first, then Portuguese for LATAM market)
- **API for club platforms** — enable clubs to integrate PitchDreams into their existing tools

**Metric to watch:** Annual retention cohorts. Users who've been in the app 12 months = your most valuable asset.

### Content Cadence (Recurring)

| Cadence | Deliverable |
|---------|-------------|
| **Weekly** | New Daily Tip content, Weekly Recap delivery |
| **Bi-weekly** | 1 new Signature Move drop |
| **Monthly** | 1 seasonal event, 1 major feature update, 2-3 new lessons with tactical diagrams |
| **Quarterly** | Major feature launch (Mental Game, Squads, Leagues, etc.) |
| **Seasonally** | Themed events tied to real soccer calendar |
| **Annually** | Season Mode narrative refresh, pricing/tier review |

The content team (even if it's one person) needs this cadence locked in. The apps that die are the ones that ship big at launch and then go quiet.

---

## Success Criteria

### Launch-Ready Gate (MUST PASS before submission)
- [ ] All Stitch mockups created (7 screens)
- [ ] App builds with `xcodebuild build` cleanly
- [ ] All tests pass (existing + new)
- [ ] C1-C4 blockers resolved (photo perm, orientation, privacy manifest, COPPA)
- [ ] No force unwraps, no TODOs, no prints
- [ ] Offline banner appears when airplane mode enabled
- [ ] Session save works even if network flakes mid-save
- [ ] JWT expiration doesn't kick user mid-training
- [ ] Branded launch screen shows on cold start
- [ ] Accessibility pass completed (VoiceOver navigable)
- [ ] Multi-device test suite passes (`./scripts/test-all-devices.sh --quick`)

### Feature Completeness Gate (Phase 1)
- [ ] Avatar evolution driven solely by total XP
- [ ] XP bar on home dashboard shows progress to next evolution
- [ ] Level-up triggers enhanced `EvolutionModal` with celebration
- [ ] Streak flame escalates visually at milestones
- [ ] Shield deployment shows toast
- [ ] Streak milestones award bonus XP
- [ ] Weekly Recap Card generates + shares as image
- [ ] Personal bests trigger celebrations + bonus XP
- [ ] Haptic feedback on all interactive elements
- [ ] Spring animations replace defaults throughout

### Launch Polish Gate
- [ ] Training Reminders work (tested end-to-end)
- [ ] App Icon variants switchable from Settings
- [ ] Daily Focus Tip rotates by day-of-year
- [ ] Keep-screen-awake during training
- [ ] Review prompt fires on milestones
- [ ] Empty states use avatar illustrations
- [ ] Rest Day mode surfaces on high soreness
- [ ] Coach voice has milestone celebration phrases

### Kid Stickiness Gate (Track E)
- [ ] Player Card renders with avatar, stats, archetype, move loadout
- [ ] Player Card shareable via AirDrop/Messages/Instagram (image render works)
- [ ] 10 Signature Moves authored with drill progressions and preview
- [ ] Unlock flow progresses through 3 mastery stages per move
- [ ] Signature move loadout slots on Player Card are editable
- [ ] Daily Mystery Box appears on home dashboard, once-per-day
- [ ] Mystery Box drop rates match spec, transparent in Settings
- [ ] IRL Pitch Layer detects known pitches and applies 2x XP (or deferred Month 1)

### Learn Clarity Gate (Track F)
- [ ] Spotlight mode plays before each step animation
- [ ] Age-adaptive narration: young users (≤11) get simplified scripts
- [ ] Your-avatar-as-player renders for `self_` player type in diagrams
- [ ] Slow-mo replay button works at 0.5x on every step
- [ ] Comprehension check: 8-year-old test user can complete 1 lesson without parent help
- [ ] (Month 1) Tap-to-explain speech bubbles, cause-and-effect shadow, mini-quizzes ship

### Monetization Gate
- [ ] StoreKit 2 products configured in App Store Connect
- [ ] PaywallView renders with correct pricing
- [ ] Entitlement checks gate premium features correctly
- [ ] Subscription purchase flow works end-to-end
- [ ] Restore Purchases works
- [ ] Founders pricing tier functions (first 1,000 detection)
- [ ] Family plan supports up to 4 child profiles
- [ ] Receipt validation confirmed with web backend
- [ ] Paywall triggers at the right moments (day 7 milestone, parent dashboard)
- [ ] Free-forever experience is complete and satisfying

### Beta Gate
- [ ] TestFlight build distributed to 20+ test users
- [ ] Feedback collected via in-app "Report Feedback" button
- [ ] P0/P1 bugs from beta resolved
- [ ] App Store screenshots captured (6.7", 6.1", 5.5", iPad Pro)
- [ ] App Store preview video recorded
- [ ] App Store description finalized (with keywords: soccer training, youth, player development, soccer skills)
- [ ] Privacy Policy + Terms of Service live on pitchdreams.soccer

---

## Recommended Execution Order

### Week 1 — Foundation (Parallel Tracks)

**Track A (critical path):** Create Stitch mockups in Chrome. 7 original Phase 1 mockups + Track E mockups (player_card_front, player_card_editor, player_card_share, signature_moves_library, signature_move_detail, signature_move_unlocked_celebration, mystery_box_closed, mystery_box_opening, mystery_box_reveal). ~16 mockups total.

**Track B (parallel):** C1-C4 launch blockers + B1 reminders + B2 app icons + B5 review prompt + C6 branded launch screen.

**Track C (parallel):** C5 offline handling, C7 token refresh, C8 session retry queue.

### Week 2 — Phase 1 Features

**Day 1-2:** Workstream 1 — XP + Avatar Evolution (CRITICAL — `Avatar.swift` migration first).

**Day 3:** Workstream 2 — Streak enhancements.

**Day 4:** Workstream 3 — Weekly Recap card.

**Day 5:** Workstream 4a-4d — Haptic polish, springs, dark mode audit.

### Week 3 — Kid Stickiness + Learn Clarity

**Day 1-2:** Track E1 — Player Card (views, editor, share flow)

**Day 2-6:** Track E2 — Signature Moves deep implementation with **3 fully-authored moves** (Scissor, Body Feint, La Croqueta) — full multi-screen learning flow per `TRACK_E_SIGNATURE_MOVES_DETAIL.md`. Step-Over and Elastico ship as Month 1 bonus drops.

**Day 6:** Track E3 — Daily Mystery Box

**Day 7:** Track E5 — IRL Pitch Layer (if time), Workstream 4c PB Celebrations, Track F1-F2 + F4-F5 Learn clarity MVP

### Week 4 — Monetization + Polish + Beta

**Day 1-3:** StoreKit 2 integration + Paywall UI + feature gating + receipt validation with web.

**Day 4:** B3 Daily Tip + B6 Empty States + B7 Rest Day + B8 Coach Voice Lines.

**Day 5:** C9 Accessibility + C10 Input Validation + C11 Loading Skeletons.

**Day 6-7:** TestFlight beta, bug fixes, App Store assets.

**Submit to App Store** end of Week 4.

---

## Open Questions for You

Before a fresh Claude Code instance starts, you'll want to decide:

1. **Pricing finalize:** $8.99/mo or different? Yearly discount depth?
2. **Founders pricing:** Yes and how many? 500? 1000? 2500?
3. **Monetization model:** Conventional tiers? Model 1 (kid-free, parent-paid)? Skin-in-the-game refund?
4. **Family plan:** Included at launch or post-launch feature?
5. **Club Plan B2B:** Launch with it or defer to post-launch?
6. **Legal:** Are Privacy Policy and Terms of Service live on the web? Can you link directly from the app?
7. **Backend coordination:** Does the web team have refresh token support? Subscription receipt validation endpoint?
8. **Coach voice assets:** Will you record real audio files, or stick with AVSpeechSynthesizer? (AVSpeechSynthesizer is faster to ship.)
9. **Asset production:** App icon variants — who draws them? Empty state illustrations — use avatar art or new illustrations?
10. **Beta testers:** Do you have 20+ testers lined up? If not, start recruiting now (your soccer parent network, club contacts).
