# Feature Roadmap — ABC School

**Core purpose: hear it, say it, know it.** A child hears an English word pronounced correctly, says it back
and gets friendly feedback, all fully offline.

**Rule for every feature:** it ships only if it helps a child hear, say or remember a word, and only if we
can build it well.

## P0 — Essential (this release)

### 1. Word topics
- **Purpose:** 11 fruits is too little to learn from, and an app called "ABC School" needs the alphabet.
- **Content:** six topics with 78 words: Alphabet (26), Fruits (12, using the existing photos), Animals (12),
  Colors (10), Numbers 1–10, and Shapes (8).
- **User journey:** Home → pick a topic → see its words and how many have been practiced.
- **Screens:** Home and Topic.
- **Logic and data:** a bundled `catalog.json`. Each word has an id, text, syllables, an example sentence, a
  visual, an optional recording, and accepted alternative answers. Unit tests check that every referenced
  asset exists.
- **Works with:** Cards, Say It, the game and progress.

### 2. Listen: word cards
- **Purpose:** hear the correct pronunciation as often as wanted, at normal or slow speed.
- **User journey:** Topic → tap a word or "Learn" → swipe through cards. Each word plays automatically.
  Tap 🔊 to repeat it, 🐢 to hear it slowly, or the sentence to hear the word in context.
- **Logic:**
  - Uses the human recording when one exists and the on-device voice (American or British) otherwise.
  - Audio plays even when the silent switch is on.
  - A missing or broken recording falls back to the voice, and a new tap cancels the previous sound.

### 3. Say It: repeat and get feedback
- **Purpose:** the "repeating" half of the README promise, and the app's differentiator.
- **User journey:** Card → 🎤 → the child says the word (recording stops by itself when they go quiet) →
  0–3 stars and "I heard …" → hear yourself, then the word again → try again.
- **Logic:**
  - The recording stays on the device and is checked by speech recognition that runs on the device. It is
    never sent online.
  - Scoring uses fuzzy matching plus accepted alternatives, such as "bee" for B or "7" for Seven.
  - When on-device recognition isn't available or is declined, a **record-and-compare** mode lets a grown-up
    confirm the word instead.
- **States:** microphone permission intro, permission denied (with Open Settings), ready, recording (with a
  live level), checking, result, couldn't hear you, and recording failed.
- **Data:** the best star count per word. Recordings are deleted right away.

### 4. Listen & Find game
- **Purpose:** checks that the child recognizes words by sound. It is short (8 rounds) and easy to replay.
- **User journey:** Topic → Play → hear a word → tap the matching picture.
  - A wrong picture shakes and locks.
  - After two misses, the right answer is highlighted.
  - A correct pick moves on automatically.
  - At the end the child sees their stars and can play again.
- **Logic:** rounds are random, each with 4 different options. The score counts correct first tries, and the
  best score is saved per topic.

### 5. Lightweight progress
- **What it shows:** stars on every word tile, "x of y words" per topic, total stars on Home, and the best
  game score per topic.
- **Data:** stored in UserDefaults (it is tiny), survives relaunch, and can be reset from Settings.

### 6. Settings (one small sheet)
- Voice accent, auto-play, whether speech checking is available, reset progress, and a privacy note.

### Quality bar for every P0 feature
Light and Dark Mode, Dynamic Type, VoiceOver labels and Reduce Motion are supported throughout. Layouts work
on iPhone and iPad, and strings are ready for localization. The app also gets a branded launch screen, an
app icon and a privacy manifest.

## P1 — Next, once real users ask for it
- More topics (body, family, food, actions). This needs only content changes.
- Human recordings for every word.
- A "review" row that brings back words with low stars.

## P2 — Later
- Several children on one device.
- A "word of the day" widget.

## P3 — Optional
- iCloud sync.
- Other interface languages (Arabic first; the strings are already in a String Catalog).
- Downloadable word packs.

## Deliberately not building

| Idea | Why not |
|---|---|
| Accounts, login or a backend | Nothing needs to leave the device, and it protects children's privacy |
| Onboarding flow | Home explains itself. Permissions are asked in context, the first time Say It is used. |
| Dashboards, charts, achievements, streaks | Stars and topic progress are enough motivation at this age; more would be noise |
| Search, favorites | Young children don't type, and six topics are easy to browse |
| Parental gate | There are no links out, purchases or ads, and the one destructive action asks for confirmation |
| Online speech recognition | It would send a child's voice to a server |

## Known limitations (this release)

| Limitation | Impact | Plan |
|---|---|---|
| Only 4 of 78 words have human recordings | Most words use the on-device voice, which is clear but less natural | P1: record every word |
| Single letters are hard for speech recognizers | A correctly said letter can earn fewer stars | Accepted alternatives per letter; a near match still earns stars |
| Real on-device recognition is untested on hardware | The Simulator always uses grown-up confirm mode | Check on a physical iPhone before release |
| iPad layout not finished | On an iPad Simulator (iOS 26.3), the Animals and Colors emoji showed as "?" | Investigate when iPad work resumes |
| One child per device | Progress is shared | P2: several children on one device |
