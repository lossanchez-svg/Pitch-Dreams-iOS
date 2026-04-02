# PitchDreams iOS App

Companion iOS app for [pitchdreams.soccer](https://pitchdreams.soccer) — a youth soccer training platform for ages 8-18.

**Web repo:** [github.com/lossanchez-svg/Pitch-Dreams-2](https://github.com/lossanchez-svg/Pitch-Dreams-2)
**iOS repo:** [github.com/lossanchez-svg/Pitch-Dreams-iOS](https://github.com/lossanchez-svg/Pitch-Dreams-iOS)

## Tech Stack

- **Framework:** SwiftUI (iOS 16+)
- **Architecture:** MVVM with protocol-based dependency injection
- **Auth:** Bearer token JWT stored in Keychain
- **API:** 38+ REST endpoints at `www.pitchdreams.soccer/api/v1/`
- **Voice:** Speech framework (SFSpeechRecognizer) + AVSpeechSynthesizer
- **Testing:** XCTest with 158+ unit tests + end-to-end flow tests
- **CI:** GitHub Actions (build + test)
- **Dependencies:** Zero third-party — all Apple frameworks

## Architecture

```
PitchDreams/
├── Core/
│   ├── API/          # APIClient (protocol), APIRouter (38 endpoints), APIError
│   ├── Auth/         # AuthManager, KeychainService, AuthenticatedUser
│   ├── Navigation/   # AppRouter, ChildTabNavigation (6 tabs), ParentNavigation
│   ├── Voice/        # SpeechRecognizer, CoachVoice, VoiceCommandMatcher, VoiceCommandBar
│   └── Extensions/   # DesignSystem, ConfettiView, SkeletonView, CelebrationModifier
├── Features/
│   ├── Auth/         # Login (parent + child), ForgotPassword, Onboarding (4-step signup)
│   ├── ChildHome/    # Home dashboard, ConsistencyRing, FirstSessionGuide, MilestoneModal
│   ├── Training/     # Check-in, SpaceSelection, ActiveDrill (timer+reps), Reflection
│   ├── ActivityLog/  # Multi-step form, FacilityPicker, CoachPicker, ProgramPicker, ChipPicker
│   ├── Skills/       # DrillStats, DrillDetail, SkillDiagramView
│   ├── Learn/        # Lessons by track, LessonDetail, TacticalPitchView (Canvas renderer)
│   ├── Progress/     # Stats grid, recent sessions, streak data
│   ├── QuickLog/     # Quick session logging (solo/team/game/class)
│   ├── FirstTouch/   # Juggling + wall ball drills with tap counter + 30s timer
│   ├── ParentDashboard/ # Child list, ChildDetail with analytics
│   └── ParentControls/  # 3-tab: Permissions, Data & Privacy, Child Login (PIN)
├── Models/           # Codable types matching all API responses
└── Resources/

PitchDreamsTests/
├── Core/             # AuthManager, VoiceCommandMatcher, ModelDecoding tests
├── Features/         # All 14 ViewModel unit tests
├── Registries/       # DrillRegistry, LessonRegistry, TacticalLessonRegistry
├── Regression/       # Known bug regression tests
├── Integration/      # End-to-end API flow tests (real server)
└── Helpers/          # MockAPIClient, MockKeychainService, TestFixtures
```

## Key Files

- `Core/API/APIClient.swift` — Protocol-based async/await HTTP client
- `Core/API/APIRouter.swift` — All 38+ endpoint definitions with path/method/body
- `Core/Auth/AuthManager.swift` — Login/logout/restore with Keychain JWT storage
- `Core/Voice/SpeechRecognizer.swift` — Continuous speech recognition with .playAndRecord audio
- `Features/Training/ViewModels/ActiveTrainingViewModel.swift` — Drill timer, rep counting, session save
- `Models/TacticalLessonRegistry.swift` — 10 lessons with pitch diagram data
- `Features/Training/Models/DrillRegistry.swift` — 10 drills filtered by space type

## Auth Flow

1. Parent/child calls `POST /api/v1/auth/token` → gets JWT
2. JWT stored in Keychain (`com.pitchdreams.training`)
3. `TokenInterceptor` adds `Authorization: Bearer` to all authenticated requests
4. 401 response triggers `AuthManager.handleUnauthorized()` → logout

## API Base URL

`https://www.pitchdreams.soccer` (NOT `pitchdreams.soccer` — that 307 redirects to `www`)

Non-v1 endpoints (signup, forgot-password, children, PIN): use `/api` base path
All v1 endpoints: use `/api/v1` base path

## Voice Commands

Voice works on: Home, Training (check-in + drill + reflection), FirstTouch, SpaceSelection
Commands: "start", "pause", "resume", "done", "next", "cancel", "mic off", numbers for reps/RPE

## Testing

```bash
# Unit tests (no network)
xcodebuild test -project PitchDreams.xcodeproj -scheme PitchDreams \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -skip-testing:PitchDreamsTests/APIContractTests \
  -skip-testing:PitchDreamsTests/EndToEndFlowTests

# End-to-end flow tests (needs network + test account)
xcodebuild test -project PitchDreams.xcodeproj -scheme PitchDreams \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:PitchDreamsTests/EndToEndFlowTests
```

Test account: `pitchdreams.soccer@gmail.com` / `loanDepot2010#` / Child: `Tester1` PIN `1111`

## Project Generation

Uses XcodeGen (`project.yml`). After adding/removing Swift files:
```bash
xcodegen generate
```
Then re-select Team in Signing & Capabilities.

## Known Issues (resolved)

- ~~Session save needs `SessionSaveResult` decode~~ → Shared `SessionSaveResult` model in `Drill.swift`, error logging added
- ~~Voice command matching uses substring contains~~ → Word-boundary regex matching (`\b...\b`)
- ~~End-to-end tests need token persistence~~ → JWT stored in Keychain via `getChildId()`/`loginAsParent()`
- ~~`requiresOnDeviceRecognition` may fail silently~~ → Falls back to server-based on error 201/203
- ~~Audio format mismatch on some devices~~ → Uses `nil` format for tap (already fixed)
- ~~`async let x: T? = try?` type inference bug~~ → Fixed in `ProgressViewModel.loadData()`
