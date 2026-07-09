# App Store Metadata — PitchDreams 1.0.0

Draft copy for App Store Connect. Character limits noted per field; everything
here fits them. Edit freely — the voice aims for parents first (they hold the
wallet and the account), kids second.

## App Name (30 chars max)
```
PitchDreams: Soccer Training
```
(28 chars)

## Subtitle (30 chars max)
```
Daily touches. Real progress.
```
(29 chars)

## Promotional Text (170 chars max — editable without review)
```
Turn backyard minutes into real skill. Guided sessions, streaks kids fight to keep, and a parent view that shows the work is paying off.
```
(136 chars)

## Description (4000 chars max)
```
PitchDreams turns solo practice into the part of the day your kid won't skip.

Built for players ages 8–18 — and the parents cheering them on — PitchDreams
guides real training sessions with a ball and a few feet of space, then turns
every rep into visible progress: streaks, XP, avatar evolutions, and skills
mastered.

FOR PLAYERS

• Guided training sessions — pick your space (backyard, park, small indoor),
  get a drill that fits, and train with a coach voice that counts you in.
• Signature Moves — learn real game moves like the Scissor and La Croqueta
  through staged animated lessons: watch it, mimic it, own it.
• First Touch lab — juggling and wall-ball counters with personal bests
  worth chasing.
• Streaks with heart — daily flames, streak freezes for rest days, and
  milestone celebrations with full-screen confetti.
• The Proof — before a big match, open your evidence: moves mastered,
  records set, days trained. Confidence built on facts, not hype.
• Learn the game — tactical lessons rendered on an animated pitch:
  scanning, positioning, decision-making.
• Voice coach — hands-free commands while you train ("next", "done",
  "pause"), so the phone stays in your pocket.

FOR PARENTS

• Your account, your control — parents create the account; kids log in
  with a simple PIN.
• A dashboard that answers "is this helping?" — sessions, minutes,
  streaks, intensity, and skill trends per child.
• Built for trust — no ads, no third-party trackers, no social feed, no
  chat with strangers. Data export and account deletion built in.
• Premium (optional) — deeper analytics, full training history, a
  development report coaches actually read, and multi-child support.

Training works offline — sessions logged at the park sync when you're
back online. Nothing your kid earns ever gets lost to a dead spot.

The free tier is a complete training experience. Premium unlocks the
parent insights layer.

PitchDreams. Train smarter. Play better.
```
(~1,900 chars)

## Keywords (100 chars max, comma-separated, no spaces after commas)
```
soccer,football,kids,youth,training,drills,juggling,skills,coach,practice,streak,futbol
```
(95 chars)

## Category
- Primary: **Sports**
- Secondary: **Health & Fitness** (alternative: Education)

## Age Rating
Answer the questionnaire honestly — expect **4+** (no objectionable content).
Note: NOT enrolling in the Kids Category (deliberate — see
APP_STORE_LAUNCH_PLAN.md P0.6); the app is parent-managed with an adult
gate at signup.

## URLs
- Support URL: `https://www.pitchdreams.soccer` (or a /support page if one exists)
- Marketing URL: `https://www.pitchdreams.soccer`
- Privacy Policy URL (App Store field): `https://www.pitchdreams.soccer/privacy`

## App Privacy questionnaire (must match PrivacyInfo.xcprivacy)
- Data collected: Name (child nickname), Email (parent), User ID, Product
  Interaction / Other Usage Data
- All: **linked to identity**, **not used for tracking**
- No third-party advertising, no data brokers

## Review Notes (paste into App Review Information)
```
PitchDreams is a parent-managed training app for youth soccer players.
Parents create the account; children sign in with the parent's email,
their nickname, and a PIN.

Demo account (pre-seeded with training data):
- Parent login: [CREATE A FRESH DEMO ACCOUNT — do not reuse internal test
  credentials]
- Child login: parent email + nickname [X] + PIN [XXXX]

Microphone/Speech: used only for optional hands-free voice commands
during training ("start", "next", "done"). Deny-able; all features work
without it.

Subscriptions unlock parent-facing analytics; the child training
experience is fully functional on the free tier.
```

## Screenshot plan (capture on 6.9" iPhone + 13" iPad, dark UI)
1. Child Home — avatar hero, streak flame, XP bar ("Their daily training buddy")
2. Active drill — timer ring + technique animation ("Guided sessions, anywhere")
3. Session complete — confetti celebration ("Effort gets celebrated")
4. Signature Move lesson — animated demo ("Learn real game moves")
5. The Proof / Evidence Bank ("Confidence built on facts")
6. Parent dashboard child detail ("See the work paying off")

## Pre-submission blockers still open
- [ ] `https://www.pitchdreams.soccer/kids-privacy` is 404 (app links to it
      from Parent Controls → Legal). Publish the page or repoint the link.
- [ ] IAP products created + attached to the 1.0.0 version in ASC
- [ ] Fresh demo account created and filled with a week of activity
