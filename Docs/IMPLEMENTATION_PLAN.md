# Implementation Plan — ABC School

The app is built in small steps, and each step ends with a passing build (the gate). Nothing is called done
until it has run in the Simulator.

| # | Step | Gate |
|---|---|---|
| 1 | **Project foundation.** Convert to folder-synchronized groups, add unit and UI test targets and a shared scheme. Set iOS 17, Swift 6, the display name "ABC School", usage descriptions, `.gitignore`, privacy manifest and launch screen. | Empty app builds; `xcodebuild -list` shows 3 targets |
| 2 | **Content and models.** Write `catalog.json` (6 topics, 78 words) and the `Category`/`Word`/`WordVisual` models and loader. Give resources consistent lowercase names and fix the fruit typos. | Catalog integrity tests pass |
| 3 | **Design system.** Tokens (`Theme`) and components: chunky buttons, stage, word visual, stars, progress bar. Generate the app icon. | Previews render in light and dark |
| 4 | **Services.** `AudioSession`, `Speaker` (recording, then voice, plus slow mode and effects), `ProgressStore`, `AppSettings`. | Unit tests for progress and settings |
| 5 | **Home, Topic, Cards.** Navigation, auto-play, previous/next, stars. | Manual run in the Simulator, light and dark |
| 6 | **Say It.** `VoiceRecorder`, `SpeechChecker`, `SilenceDetector`, `PronunciationScorer`, `PracticeModel`, and every state's UI. | Scorer and practice-model tests; permission flow checked in the Simulator |
| 7 | **Listen & Find.** `GameBuilder`, `ListenGame`, game and results UI, best score. | Game tests; a full game played in the Simulator |
| 8 | **Settings.** Accent with a sample, auto-play, speech-check status, reset with confirmation, About. | UI test for reset |
| 9 | **Polish pass.** Accessibility labels, Reduce Motion, iPad layout, iPhone SE layout, empty and error states. | Screenshots on iPhone SE, iPhone 17 Pro and iPad |
| 10 | **Tests and docs.** UI tests for the 3 journeys, a full test run, `DESIGN_SYSTEM.md`, `TESTING_REPORT.md`, final roadmap and limitations. | All tests green |

## What changes in existing code

| File | Fate | Reason |
|---|---|---|
| `View/FruitsApp.swift` | Becomes `App/ABCSchoolApp.swift` | Sets up shared services and the audio session |
| `View/ContentView.swift` | Replaced by `RootView` and `HomeView` | The single scroll list goes away |
| `Components/FruitsView.swift` | Replaced by `WordCardView` and `WordVisualView` | Fixed size, dark-mode bug, no accessibility |
| `Model/Fruits.swift` | Replaced by `Word`, `Category` and `catalog.json` | Hard-coded data, typos, UI types inside the model |
| `Utilities/PlaySound.swift` | Replaced by `Speaker` | Global state; wrong word played for 7 fruits |
| Fruit images | **Kept**, renamed to lowercase correct spellings | Good assets |
| Fruit gradient colors | **Kept** as values in `catalog.json`; color sets removed | One source of truth, and fixes the dark-mode bug |
| 4 MP3 recordings | **Kept**, renamed to lowercase | Human recordings are the best pronunciation source |

## Risks

| Risk | Mitigation |
|---|---|
| On-device speech recognition is missing on some devices or in the Simulator | Record-and-compare fallback, with both paths tested |
| Recognizers are bad at single letters | Accepted alternatives per letter (e.g. "bee", "see"); a near match still earns stars |
| A child goes silent mid-word | Silence detection waits 0.9 s after speech, and recording stops after at most 5 s |
