# App Store Launch Plan — Ready for Prime Time

**Goal:** Submit a reliable, delightful v1.0 to App Store review, with the build work done by **July 12, 2026**.

**Verdict from the full-codebase audit (July 7):** the app is closer than expected. The design system is real and consistently used, the in-app engagement loop (streaks, avatar evolution, confetti, coach voice) is polished, privacy fundamentals are in place (privacy manifest, in-app account deletion, no third-party trackers), and Track A of `PLAYER_DEVELOPMENT_PLAN.md` is ~80% already shipped. What stands between today and a strong launch is:

1. **Two high-severity reliability bugs** (silent session-expiry brick; offline queue drops sessions on server 5xx) — these are launch blockers because they hit the worst-case user moment: a kid loses a finished session.
2. **A handful of App Store review blockers** (dead paywall legal links, stubbed-but-tappable features, missing export-compliance key, icon alpha).
3. **Trust-eroding fakery and drift** (hardcoded "A+" grade, placeholder parent stats, dead hero-animation placeholders, light-mode rendering break).
4. **A stubbed parent-retention loop** (Weekly Insights Email UI with no backend) and the unbuilt "brain layer" differentiation — important, but mostly post-submission work.

This plan is organized as **P0 (submission blockers) → P1 (trust & polish) → P2 (delight & retention) → P3 (post-launch)**, with a day-by-day schedule at the end. P0+P1 fit before July 12. P2 starts in parallel where it doesn't touch the same files, and continues while the build is in review.

---

## P0 — Submission blockers (must land before archive)

### P0.1 Fix 401 handling — the silent-brick bug ⚠️ highest blast radius
31 files each instantiate their own `APIClient()`; only `AuthManager`'s private instance has `onUnauthorized` wired (`Core/Auth/AuthManager.swift:23-34`). When the JWT expires, `restoreSession()` restores `.authenticated` from Keychain with no validation (`AuthManager.swift:37-55`), every data call 401s (`Core/API/APIClient.swift:92-94`), ViewModels swallow the errors, and the kid stares at an empty app with no recovery path. There is no token refresh anywhere.

**Fix:**
- Introduce a shared `APIClient` (singleton or environment-injected factory) so `onUnauthorized` fires from any request; keep the `APIClientProtocol` DI seam for tests.
- On 401: `AuthManager.handleUnauthorized()` → clear session → route to login with a friendly "Session expired — log in again" message (kid-appropriate copy for the PIN screen).
- On launch, validate the restored token with one lightweight authenticated call before showing the authenticated UI (or tolerate first-401-redirects gracefully).
- **Add `APIClientTests`**: status-code mapping, 401 → `onUnauthorized` invocation, decode-error path. This bug shipped precisely because these are untested.

### P0.2 Stop losing kids' sessions — sync queue and save-path fixes ⚠️ data loss
- `SessionSyncQueue.send` treats any non-network/non-401 error as `permanentFailure` and **deletes the queued entry** (`Core/.../SessionSyncQueue.swift:163-168`) — a transient 500 permanently destroys an offline-queued session. **Fix:** 5xx → `retryLater`; reserve `permanentFailure` for 4xx/validation/decoding.
- `ActiveTrainingViewModel.saveSession` queues only on `APIError.network` (`:259-262`); a 5xx at save time loses the session. **Fix:** queue on 5xx too.
- Extend the queue beyond `session`/`quickSession` (`SessionSyncQueue.swift:17-20`) to **check-ins and activity logs** — logging a game offline currently throws and is lost (`ActivityLogViewModel.swift:154-156`, `TrainingViewModel.swift:61-64`).
- Add `guard !isSaving` re-entrancy guards to `QuickLogViewModel.save` (`:45`) and `ActivityLogViewModel.saveActivity` (`:127`) — `ActiveTrainingViewModel` already does this right (`:241`).
- Tests: queue-on-5xx, drop-only-on-4xx, activity/check-in queueing, double-submit.

### P0.3 Network timeouts
`APIClient` uses `URLSession.shared` — a flaky-connection save can hang 60s with a disabled button, and kids will force-quit. **Fix:** custom `URLSessionConfiguration` with `timeoutIntervalForRequest ≈ 15s` and `waitsForConnectivity` for saves; the sync queue makes timeouts safe.

### P0.4 Force dark mode — one line, kills the worst visual break
The entire app is authored on a hardcoded dark palette (`dsBackground = #0C1322`), but nothing sets the color scheme. On a light-mode device, `.ultraThinMaterial`/`.regularMaterial` panels (home rank bar `ChildHomeView:563`, PRO badge `:418`, voice footer `ActiveDrillView:430`, skeletons), keyboard accessory, spinners, sliders, and sheet dimming all render **light-on-dark**. **Fix:** `.preferredColorScheme(.dark)` at the app root (or `UIUserInterfaceStyle = Dark` in Info.plist). Sanity-pass the main screens in light-mode-device + forced-dark afterward.

### P0.5 App Store review blockers (config + guideline issues)
| Item | Fix | Where |
|---|---|---|
| Paywall Terms/Privacy buttons are no-ops — **Guideline 3.1.2 subscription rejection** | Wire to live `pitchdreams.soccer/terms` and `/privacy` | `Features/Paywall/Views/PaywallView.swift:284-285` |
| Missing export-compliance key | Add `ITSAppUsesNonExemptEncryption = false` (standard HTTPS only) | `PitchDreams/Info.plist` |
| App icon is 8-bit **RGBA** — transparency is rejected | Flatten to opaque RGB | `Assets.xcassets/AppIcon.appiconset/app-icon.png` |
| Stubbed-but-tappable features read as broken — **Guideline 2.1 completeness risk** | Hide the SignatureMoves record-self camera stub (`SignatureMoveRecordSelfView.swift` — camera flip no-op, saves placeholder path) behind a flag; remove/complete MysteryBox `availableCosmeticIds: ["placeholder"]` (`MysteryBoxOddsView.swift:15`) | SignatureMoves, MysteryBox |
| Account deletion doesn't tear down the session | `deleteAccount()` success → explicit logout + confirmation | `ParentControlsView.swift:640-649` |
| Marketing version is `0.1.0` / build 1 | Bump to `1.0.0` | `project.yml:39-40` |
| Location + photo usage strings exist for features that may not ship | Confirm the features ship in v1 or remove the strings | `Info.plist:52-55` |

### P0.6 COPPA / age-rating decision (decide now; small build cost)
Recommendation: **do NOT enter Apple's Kids Category** for v1 — the paywall, external web links, and account model make Kids Category compliance (parental gates on every outbound link/purchase, no external links) a heavy lift. Instead:
- Position as a **parent-managed app** (parent creates the account; child uses a PIN — the architecture already says this). Set the age rating honestly (likely 4+ content, but the *account holder* is the parent).
- Add a lightweight **adult gate at signup** (e.g., birth-year picker or "parents only" interstitial before account creation) so the consent checkbox (`SignupStepView.swift:55-59`) is backed by an assertion the account creator is an adult.
- **Verify before submission that `pitchdreams.soccer/privacy`, `/terms`, and `/kids-privacy` are live** (web repo task) — they're linked from `ParentControlsView.swift:465-472` and signup.

### P0.7 App Store Connect setup (parallel, non-code)
- Create/submit the IAP subscription products matching `Models/Entitlement.swift:153-157` and `PitchDreams.storekit`; they must be attached to the version for review.
- App privacy questionnaire — answer to match `PrivacyInfo.xcprivacy` (name, email, userID, usage data; linked, non-tracking).
- Screenshots (6.9" + 6.1" iPhone, 13" iPad), description, keywords, support URL, marketing URL. Screenshot the polished screens: ChildHome, ActiveDrill, SessionComplete confetti, ParentDashboard child detail.
- Demo account for review: provide a parent login **and** child PIN with pre-seeded data (do not reuse the real test account credentials from the repo docs).

---

## P1 — Trust & polish (should land before archive; each is small)

**Honesty fixes (these erode trust the moment a user notices):**
1. **Kill fake metrics.** `skillGrade` "A+" is streak-derived (`ChildHomeView:682-690`) and parent-card "Consistent"/"This Week" pills are static strings (`ParentDashboardView:293-294`). Wire to real data or remove — a static A+ is worse than no grade.
2. **Hero animation placeholders → working keyframe fallback.** Zero `.riv`/`.mp4` assets ship, so every SignatureMoves hero demo dead-ends at a play-button placeholder (`SignatureMoveOverviewView:103-153`). Change the fallback chain to end at the *working* `TechniqueAnimationView` keyframe renderer instead of the placeholder. (Authoring real MP4s via the in-flight `video-authoring/` work is P2.)
3. **Reduce locked-content clutter.** 7 of 10 signature moves are "COMING SOON" tiles — show 1-2 teasers, hide the rest, until content is authored.
4. **Fix contradictory empty-state copy.** Parent dashboard says "Add a child at pitchdreams.soccer" while an in-app Add Child sheet exists (`ParentDashboardView:65-78`).

**Consistency fixes:**
5. **Home loading skeleton mismatch.** `skeletonContent` renders components removed from the real layout (`ChildHomeView:1113-1114` vs `:765,838`) — loading previews a dead screen. Rebuild skeleton to match the current bento layout.
6. **Bring `StreakMilestoneModal` on-system.** The app's biggest celebration moment is the most off-system screen (raw `.title`/`.white`, emoji flame vs SF Symbol flame elsewhere). Apply the rounded/`dsCTALabel` treatment; reconcile the flame treatment with `ConsistencyRingView`.
7. **Tokenize the stray hex colors.** Promote the repeat offenders (`#34D9EC`, `#9D3500`, `#8B5CF6`, flame reds) into the DesignSystem palette; sweep the 81 out-of-system `Color(hex:)` calls.
8. **Add a used typography scale to `DSFont`** (`sectionLabel`, `statValue`, `ctaLabel`, `body`) and migrate the highest-traffic screens; full 808-site migration is P3.
9. **Standardize error/empty states.** Route `ParentDashboardView`'s hand-rolled states through the shared `EmptyStateView`/`ErrorBannerView`; stop interpolating raw `"\(error)"` to parents (`ParentDashboardView:61,392`). Add `errorMessage` + retry to the highest-traffic VMs that lack it (12 of 27 have none — start with `ChildHomeViewModel`, which currently swallows every failure silently).

**Recoverability fixes:**
10. **Voice permission dead end.** Denied mic/speech permission is invisible — `VoiceCommandBar` never reads `speechRecognizer.error` (`SpeechRecognizer.swift:29-47`). Add an alert distinguishing "denied → Open Settings deep link" from "unavailable."
11. **Contrast bump on micro-labels.** Size 9-10 `dsOnSurfaceVariant` labels are borderline AA (`ChildHomeView:541,552`) — bump a step in size/weight/color.

**CI hardening:**
12. Make contract tests actually gate something: `APIContractTests` currently run only on main with `continue-on-error: true` (`.github/workflows/ci.yml:315`). At minimum, drop `continue-on-error` on main; add the new `APIClientTests`/`SessionSyncQueueTests` cases to the PR gate.

---

## P2 — Delight & retention (start in parallel; finish while in review)

These make the app *worth keeping* — they matter more than anything above for long-term success, but none should delay submission.

1. **Weekly Insights Email backend** *(web repo — parallel track, doesn't touch iOS code)*. The single biggest parent-retention hole: `WeeklyInsightsEmailSettingsView` persists a toggle to UserDefaults and no email is ever sent. A paying parent enables a premium feature and gets nothing — ship the server-side send, or **hide the toggle for v1** (cheap P0-adjacent alternative if the backend can't land in time).
2. **Streak-at-risk local notification.** `TrainingReminderManager` already schedules daily reminders; add an evening "your 12-day streak needs 10 minutes" variant. Cheap, uses existing infrastructure, directly protects the core loop.
3. **Confidence Evidence Bank (Track B, Phase B1)** — the flagship differentiator from `PLAYER_DEVELOPMENT_PLAN.md`, and deliberately cheap: ~70% is re-presenting data already stored (mastered moves, PBs, streak, `stageConfidenceRatings`). New `Features/Confidence/` + a Home entry card. This is the first genuinely novel feature a reviewer or parent will describe to a friend.
4. **Author signature-move content.** Land the in-flight video-tier WIP (current branch: `VideoTechniqueView`, video→Rive→keyframe chain, `video-authoring/` scaffolding), then produce hero clips and author the 7 locked moves. Pure content work; the engine is done.
5. **Finish Track A cleanup:** remove `ActivityLog` as any kid-facing path (it survives in the "More" menu); resolve the "Skills" (drill stats) vs "SignatureMoves" (trick learning) naming collision.

## P3 — Post-launch roadmap (v1.1+)
- **Dynamic Type migration** (808 fixed font sizes, 0 `ScaledMetric`) — biggest accessibility gap; too large for this window, so do it as a screen-by-screen campaign starting with CTAs and body text.
- **APNs push** for parents (milestones, weekly recap) — the only real lapsed-user re-engagement channel.
- **Game Moments (B2)** decision trainer and **Match Mode (B3)** per the player-development plan.
- **Server-driven content** so drills/lessons/moves don't require app releases.
- Token refresh flow (v1 ships with clean 401→login instead).

---

## Schedule (July 7–12)

| Day | Focus |
|---|---|
| **Mon 7/7** | P0.1 shared APIClient + 401 flow + `APIClientTests`; P0.2 sync-queue fixes + tests |
| **Tue 7/8** | P0.2 finish (activity/check-in queueing, re-entrancy guards); P0.3 timeouts; P0.4 dark mode + visual sanity pass |
| **Wed 7/9** | P0.5 review blockers (paywall links, encryption key, icon, stubs hidden, delete-logout, version bump); P0.6 adult gate; start P0.7 App Store Connect setup |
| **Thu 7/10** | P1 sweep: fake metrics, skeleton, milestone modal, hex tokens, error/empty standardization, voice-permission alert, hero-animation fallback |
| **Fri 7/11** | Full regression: unit suite + `./scripts/test-all-devices.sh --quick`, end-to-end flows against production, light/dark + iPad pass, TestFlight build to yourself |
| **Sat 7/12** | Buffer + screenshots + metadata + **submit**. P2 items (weekly email backend on web, Evidence Bank) continue during review. |

**Cut line if time runs short:** everything in P0 is non-negotiable; from P1, keep items 1, 2, 5, 9, 10 (honesty + recoverability) and defer the cosmetic sweeps (6-8, 11). Hide the Weekly Insights toggle rather than shipping the promise unbacked.

## Verification checklist before archive
- [ ] Kill network mid-session save → session queued, XP awarded on reconnect, nothing lost
- [ ] Expire/corrupt the stored JWT → app routes to login with friendly message (both parent and child PIN paths)
- [ ] Force 500 from save endpoint (or mock) → entry stays queued, retries succeed
- [ ] Light-mode device → app renders fully dark, no white material panels
- [ ] Deny mic permission → tapping mic explains and deep-links to Settings
- [ ] Delete account → session torn down, back at login
- [ ] Paywall Terms/Privacy open live pages; all three policy URLs live on the web
- [ ] Every visible tappable element does something (no stub camera, no placeholder cosmetics)
- [ ] Fresh-install first-run: onboarding → first session → celebration, on iPhone SE and iPad
