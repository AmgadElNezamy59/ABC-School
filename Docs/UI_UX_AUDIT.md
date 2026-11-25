# UI/UX Audit — ABC School

## Current experience

| Issue | Impact |
|---|---|
| One endless scroll of identical cards | No sense of place, progress or choice, and the child scrolls past content |
| Dark Mode shows white blank cards | Unusable for anyone with Dark Mode on |
| White text on pale yellow and orange gradients | Banana, Orange, Pineapple and Peach titles are hard to read |
| Fixed 350 × 545 pt card | Clipped on iPhone SE, tiny on iPad, broken in landscape |
| Speaker icon with no label | VoiceOver reads a symbol name; a child doesn't know what to tap |
| No feedback while audio plays | A child taps repeatedly and nothing shows the sound is playing |
| Harsh black shadow, inconsistent capitalization | Looks unfinished |
| No way to say the word back | The core learning loop is missing |

## Design direction: a sunny classroom

The app should feel bright, warm and calm, like crayons on cream paper. Words are the heroes; the chrome
stays quiet.

- **Typography:** SF Pro Rounded everywhere. Words are set in heavy weights at large, Dynamic Type-scaled
  sizes.
- **Stages:** every word sits on a colorful rounded "stage" (a gradient tile) that looks the same in light
  and dark mode, like an illustration. Text never sits on a stage, except topic titles, which are checked for
  contrast.
- **Chunky buttons:** primary actions are toy-like 3D buttons that press down. They are large (at least
  56 pt) and use clear SF Symbols with text.
- **Feedback:** every tap answers with sound, a haptic or motion. Reduce Motion is respected.
- **Calm chrome:** a warm cream background in light mode, deep navy in dark mode, and white or navy surface
  cards with soft shadows.

## Screen map (6 screens)

```
Home ──► Topic ──► Cards ──► Say It (sheet)
  │        └─────► Listen & Find (full screen)
  └──► Settings (sheet)
```

- **Home:** greeting, total stars, and a grid of topic cards with progress.
- **Topic:** hero banner with progress, **Learn** and **Play** buttons, and a grid of word tiles with stars.
- **Cards:** swipeable word cards with a fixed control bar (🐢 Slow · 🔊 Listen · 🎤 Say it) and previous/next
  buttons.
- **Say It:** one focused task: a big mic button with a live level ring, then stars, "I heard …" and replay
  buttons.
- **Listen & Find:** big replay button, a 2 × 2 picture grid, round progress, and a results view.
- **Settings:** voice, auto-play, speech-check status, reset, and About.

## Design tokens (summary)

Full details will be in `DESIGN_SYSTEM.md` after implementation.

- **Colors:** background, surface, surfaceMuted, ink, inkSecondary, brand (violet), star (sun yellow),
  success (green), retry (soft coral). Each has a light and a dark value.
- **Spacing:** 4 · 8 · 12 · 16 · 24 · 32.
- **Radii:** 12 · 20 · 28 (continuous corners).
- **Shadows:** one soft card shadow.
- **Topic palette:**

  | Topic | Color |
  |---|---|
  | Alphabet | violet |
  | Fruits | coral |
  | Animals | green |
  | Colors | teal |
  | Numbers | blue |
  | Shapes | orange |

  White titles on every topic color must reach a contrast of at least 3:1, and a unit test checks this.

## Accessibility plan

- Every control has a spoken label. Stars read as "2 of 3 stars", and game options read their word.
- Dynamic Type works on every screen, and large words scale with `@ScaledMetric`.
- Tap targets are at least 56 pt for primary actions and 44 pt everywhere else.
- Reduce Motion turns off the pulsing, shaking and bouncing animations.
- Color is never the only signal: a wrong pick also shakes and shows a ✕, and stars are shapes, not just
  color.
