# PitchDreams iOS

Companion iOS app for [PitchDreams](https://pitchdreams.soccer) -- a safe, web-first platform for youth soccer players (ages 8-18) to train, learn, and track progress with parent controls and privacy-by-design.

## Tech Stack

- **Language:** Swift 5.9
- **UI:** SwiftUI (iOS 16+)
- **Architecture:** MVVM with protocol-based dependency injection
- **Networking:** async/await with URLSession
- **Auth:** JWT token management with Keychain storage
- **Project Generation:** XcodeGen
- **CI:** GitHub Actions (Xcode 16, iPhone 16 Simulator)

## Architecture

```
PitchDreams/
  Core/
    API/              # API client, endpoint definitions, protocols
    Auth/             # AuthManager, token handling
    Extensions/       # Swift/SwiftUI extensions
    Navigation/       # AppRouter, navigation logic
    Utilities/        # Keychain service, helpers
  Features/
    Auth/Views/       # Parent + child login screens
    Auth/ViewModels/  # Login view models
    ParentDashboard/  # Parent dashboard (child list, controls)
    ChildHome/        # Child home screen
    Training/         # Training sessions
    ActivityLog/      # Activity log
    Progress/         # Progress dashboard
    Learn/            # Lessons and learning content
    Skills/           # Skill tracking
  Models/             # Shared data models
  Assets.xcassets/    # App icons, colors, images

PitchDreamsTests/
  Core/               # AuthManager tests
  Features/           # ViewModel tests
  Helpers/            # Mocks, fixtures
```

## Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/lossanchez-svg/Pitch-Dreams-iOS.git
   cd Pitch-Dreams-iOS
   ```

2. Install XcodeGen (if not already installed):
   ```bash
   brew install xcodegen
   ```

3. Generate the Xcode project:
   ```bash
   xcodegen generate
   ```

4. Open the project:
   ```bash
   open PitchDreams.xcodeproj
   ```

5. Select the **PitchDreams** scheme and an iOS Simulator, then build and run.

## Web App

The web version of PitchDreams is available at [pitchdreams.soccer](https://pitchdreams.soccer). Source code: [Pitch-Dreams-2](https://github.com/lossanchez-svg/Pitch-Dreams-2).
