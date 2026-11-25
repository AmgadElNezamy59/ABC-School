# Architecture — ABC School

**Principle:** use the simplest structure that keeps the logic testable. That means about 35 small files, no
third-party dependencies, and no dependency-injection framework.

## Decisions

| Concern | Choice | Why |
|---|---|---|
| UI | SwiftUI, iOS 17+ | Gives `@Observable`, `ContentUnavailableView`, `sensoryFeedback` and symbol effects. iOS 17+ covers nearly all active devices. |
| Shared state | A few `@Observable` objects passed through `.environment(_:)` | No Combine and no container type needed |
| View models | Only for Say It (`PracticeModel`) and the game (`ListenGame`) | These are the two real state machines. Every other screen is a plain view over shared state. |
| Content | Bundled `catalog.json` | Words can change without code changes, and tests validate them |
| Persistence | `UserDefaults` holding one Codable snapshot | Under 5 KB of data, so SwiftData would be overkill |
| Audio | `AVSpeechSynthesizer`, `AVAudioPlayer`, `AVAudioRecorder` | Built in and offline |
| Speech check | Speech framework with `requiresOnDeviceRecognition = true` | Private and offline |
| Concurrency | Swift 6 language mode, `@MainActor` services, async/await | The compiler checks for data races |
| Protocols | Two: `VoiceRecording` and `SpeechChecking` | Only where hardware must be faked in tests |
| Project format | Xcode folder-synchronized groups | Adding a file no longer means editing `project.pbxproj` |

## Layers

```
Views (Features/*)                     SwiftUI only: layout, animation, haptics
   │
   ├── PracticeModel, ListenGame        state machines (tested with fakes)
   │
Services (Services/*)                  Speaker · VoiceRecorder · SpeechChecker
   │                                   ProgressStore · AppSettings · AudioSession
   │
Pure logic (Logic/*)                   PronunciationScorer · GameBuilder · SilenceDetector
   │
Data                                   catalog.json · UserDefaults · bundled audio
```

Pure logic has no dependencies and is unit-tested directly. Services wrap Apple frameworks and contain as
little logic as possible.

## Folder structure

```
Fruits/                     app target (folder name kept so project history stays intact)
  App/                      entry point, root view, launch options
  Models/                   Category, Word, WordVisual, Catalog loader
  Logic/                    pure, testable rules
  Services/                 audio, speech, persistence, settings
  DesignSystem/             tokens (Theme) and reusable components
  Features/
    Home/  Topic/  Learn/  Practice/  Game/  Settings/
  Resources/                catalog.json, audio, Assets.xcassets, Localizable.xcstrings, PrivacyInfo
FruitsTests/                Swift Testing unit tests
FruitsUITests/              XCTest UI tests for the main journeys
Scripts/                    generators for the app icon and sound effects (reproducible assets)
```

## Data flow

1. `ABCSchoolApp` creates `AppSettings`, `ProgressStore` and `Speaker` once and injects them with `.environment`.
2. `RootView` loads the catalog. If loading fails it shows a retry state; otherwise it shows `HomeView`.
3. Navigation is one `NavigationStack` with a typed `Route` (`.topic`, `.learn`). Practice opens as a
   sheet and the game as a full-screen cover.
4. Views read progress from `ProgressStore` (observed). Only `PracticeModel` and `ListenGame` write to it.
5. `ProgressStore` saves a snapshot to `UserDefaults` after every change.

## Error handling

| Failure | Behavior |
|---|---|
| Catalog missing or corrupt | Full-screen message with Try Again (unit tests make sure this never ships) |
| Recording missing or undecodable | Falls back to the on-device voice and logs through `os.Logger` |
| Microphone denied | Explains why and offers Open Settings |
| On-device recognition unavailable or declined | Record-and-compare mode |
| Recognizer error or timeout | Record-and-compare mode for that attempt |
| Nothing heard | "I couldn't hear you" with a hint, and nothing is saved |
| Corrupt saved progress | Starts fresh and logs the error; the app never crashes on bad data |

## Privacy and security

- No network code and no analytics. Recordings live in `tmp/` and are deleted when practice ends.
- The privacy manifest declares no tracking and no collected data. Its only required-reason API is
  UserDefaults (`CA92.1`).
- There are no secrets; nothing in the app needs the Keychain.

## Testing strategy

- **Unit tests (Swift Testing):**
  - Scorer, game builder and game rules, silence detection.
  - Progress persistence and settings.
  - Practice state machine (with fakes).
  - Catalog integrity: assets, audio file names with exact case, unique ids, and color contrast.
- **UI tests (XCTest):**
  - Browse a topic and the cards.
  - Play a whole game.
  - Settings and resetting progress.
- UI tests launch with `-ui-testing`, which uses a throw-away UserDefaults suite and turns off animations.
