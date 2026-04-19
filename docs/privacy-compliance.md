# PitchDreams — Privacy & Compliance Notes (App Review)

This document summarizes how PitchDreams handles data from minors and what
the App Review Board can expect to see on submission.

## Target audience

- Ages 8–18. The App Store category is **Kids 9–11** / **Kids 12+** (reviewed
  case-by-case; the default at submission will be Kids 12+).
- Sign-up requires a **parent/guardian** to create the account. Children log in
  via a parent-set PIN bound to the parent's email and the child's nickname.

## COPPA posture (US)

- **Verifiable parental consent** is captured at signup: the parent creates the
  account, sets up the child's profile (nickname, age, position, avatar), and
  configures a login PIN. Child accounts cannot exist without a parent account.
- **No direct contact with children.** All cross-user communication features
  are emoji-only reactions (planned) or parent-gated.
- **No behavioral advertising.** `NSPrivacyTracking: false`. No third-party ad
  or analytics SDKs that profile children.
- **Age-gate** enforced in `PermissionsStepView.swift`: free-text notes are
  disabled by default for children under 14.
- **Parental dashboard** (`Features/ParentDashboard/`) gives the parent a full
  view of the child's activity and controls (`Features/ParentControls/`).

## Privacy manifest

`PitchDreams/PrivacyInfo.xcprivacy` declares:
- `NSPrivacyTracking: false`
- Collected data types: name, email, userID, non-PII usage data — each with
  purpose `NSPrivacyCollectedDataTypePurposeAppFunctionality`, never marked
  for tracking.
- API reasons: `NSPrivacyAccessedAPICategoryUserDefaults` → `CA92.1` (app
  functionality).

## Data collection summary

| Category | Collected | Purpose | Retained |
|----------|-----------|---------|----------|
| Parent email + password hash | Yes | Authentication | Until account deletion |
| Child nickname + age + avatar | Yes | Profile, personalization | Until parent deletes child |
| Training activity (self-reported sessions, reps, confidence, check-ins, streaks, XP) | Yes | Progression, parent insights | Until reset / account deletion |
| Device identifier | No | — | — |
| Ad identifier | No | — | — |
| Location | Only with explicit parent opt-in for the IRL Pitch feature (post-launch); disclosed at permission prompt | Real-pitch XP bonus | Visit counts only; no coordinates shared off-device |
| Photos | Only when parent uses "Save Weekly Recap to Photos" (explicit tap) | Sharing | User's photo library |
| Microphone | Opt-in per session for voice commands; parent can disable globally | Voice commands during drills | Not recorded server-side |

## Third-party SDKs

**None.** The app is built on Apple frameworks only (SwiftUI, Foundation,
URLSession, Keychain, AVSpeechSynthesizer, Speech, UserNotifications, Network,
StoreKit). No ad networks, no analytics, no crash-reporter SDKs that transmit
child data.

## Parent controls (in-app)

Located under Settings → [Child Name] Controls:
- Permissions: coach personality, voice commands, free text, training window
- Notifications: daily training reminder (with 9 pm–7 am quiet hours)
- Data & Privacy: export child data, reset progress, delete child profile
- Legal: Privacy Policy, Terms of Service, Kids Privacy (COPPA) links
- Child Login: PIN reset

## Account deletion

- In-app: "Delete Child Profile" (single child) and "Delete My Account" (parent
  + all children). Both confirm with destructive alerts.
- Delete My Account hits `DELETE /api/v1/parent/account` which deletes the
  parent record and cascades to all child profiles and their training data.
- The app uses no analytics copies or third-party stores; server-side deletion
  is sufficient to remove all data.

## Data export

Parent can trigger `POST /api/v1/parent/children/{id}/export`. Server emails
the parent a download link for a portable archive of the child's data.

## Submission checklist (non-exhaustive)

- [ ] App Store category set to **Kids 12+** (or Kids 9-11 if age range
  narrows at review).
- [ ] Age rating questionnaire completed with honest answers re: social
  features (none at launch) and user-generated content (none at launch).
- [ ] `NSPhotoLibraryAddUsageDescription`, `NSMicrophoneUsageDescription`,
  `NSSpeechRecognitionUsageDescription` present in `Info.plist`.
- [ ] Privacy Policy at `https://pitchdreams.soccer/privacy` reachable.
- [ ] Terms of Service at `https://pitchdreams.soccer/terms` reachable.
- [ ] Kids Privacy notice at `https://pitchdreams.soccer/kids-privacy`
  reachable.
