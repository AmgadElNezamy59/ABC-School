# Testing Report — ABC School

**Date:** 2026-11-25 · **Result: all green** — 74 tests (86 runs counting parameterized cases), 0 failures.

Run on the iPhone 17 Pro Simulator (iOS 26.3), Xcode on macOS 26.4:

```bash
xcodebuild test -project Fruits.xcodeproj -scheme Fruits -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## Unit tests (Swift Testing) — 68 tests

| Suite | Tests | Covers |
|---|---|---|
| CatalogTests | 13 | Six topics in order, unique namespaced ids, enough words per game, every photo, SF Symbol and recording exists (exact file-name case), valid colors and numbers, white-title contrast, decoding of every visual kind and rejecting bad data |
| GameTests | 12 | Rounds and options are unique and contain the answer, small topics, seeded determinism, scoring, locked wrong picks, hint after two misses, finish and best score, restart |
| PracticeModelTests | 14 | Mic and speech permission flow, denial with a fix, stars and saving rules, silence and too-short recordings, grown-up confirm fallback, recognizer errors, mic failure recovery, try again, discarding recordings, no double start |
| ProgressAndSettingsTests | 14 | Best stars per word, clamping, totals, relaunch persistence, best game score, reset, corrupt data, settings defaults and persistence, hex parsing and WCAG contrast |
| PronunciationScorerTests | 15 | Exact and partial matches, case, punctuation and accents, phrases, multi-word answers, alternatives, top-guess rule, empty input, silence detector timing (waiting, stop after speech, pauses, time limit) |

## UI tests (XCTest) — 6 tests

| Test | Journey |
|---|---|
| `testHomeShowsEveryTopic` | Home lists all six topics |
| `testBrowseATopicAndItsWordCards` | Open Fruits, open a word from the grid, next and previous |
| `testFirstCardCannotGoBackAndLastCannotGoForward` | Card navigation limits |
| `testPlayAWholeListenAndFindGame` | Play all rounds of Listen & Find to the results screen |
| `testLeavingAGameMidwayAsksFirst` | Closing a game in progress asks for confirmation |
| `testSettingsChangeAndResetProgress` | Change a setting, reset progress with confirmation |

UI tests launch with `-ui-testing`: a throw-away UserDefaults suite and no animations.

## Manual checks

- Home, Topic, Learn, Say It, the game and Settings in light and dark mode on iPhone 17 Pro
  (screenshots in `Docs/images/after-*.jpg`).
- iPhone SE (3rd gen, iOS 18): Home, Learn, Say It and the game all fit without clipping.

## Not covered

- **Real speech recognition and microphone.** The Simulator has no on-device recognizer, so the app uses the
  grown-up confirm mode there. The real recognizer path is tested only through fakes and needs a check on a
  physical device.
- **Audio output quality** (voices, recordings, effects) is checked by ear, not by tests.
- **iPad layout was not finished.** The one iPad run (iOS 26.3) showed a "?" placeholder instead of the
  emoji on the Animals and Colors cards, while iPhone draws them fine. The cause isn't known yet (it may only
  happen in the Simulator), and iPad testing was set aside for now.
