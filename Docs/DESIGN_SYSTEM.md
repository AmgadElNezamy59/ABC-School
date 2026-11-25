# Design System — ABC School

**Mood:** "a sunny classroom". Warm paper and plum ink by day, deep navy by night. Word pictures sit on
bright colored "stages" that look the same in both modes, like illustrations in a picture book.

All tokens live in [`Theme.swift`](../Fruits/DesignSystem/Theme.swift); components live in
[`DesignSystem/Components`](../Fruits/DesignSystem/Components). Views use tokens only — no raw hex values or
magic numbers in feature code.

## Color

| Token | Light | Dark | Use |
|---|---|---|---|
| `appBackground` | asset `AppBackground` | asset `AppBackground` | Screen and launch background |
| `surface` | `#FFFFFF` | `#1E1E36` | Cards, tiles, raised surfaces |
| `surfaceMuted` | `#F1EADF` | `#2C2C4A` | Progress tracks, wells, quiet fills |
| `ink` | `#2B2340` | `#F5F3FF` | Primary text |
| `inkSecondary` | `#6E6787` | `#A9A4C4` | Secondary text |
| `brand` | `#6C5CE7` | `#8E80FF` | Primary actions, selection (matches `AccentColor`) |
| `star` | `#FFB400` | `#FFC83D` | Stars and rewards |
| `success` | `#1E9E5A` | `#3DD68C` | Correct answers |
| `attention` | `#F2545B` | `#FF7A80` | Recording and "try again": warm coral, never an alarming red |

**Content colors** (topic and word gradients) are data in `catalog.json`, not tokens. A unit test
(`whiteTitlesAreReadableOnEveryTopicColor`) enforces WCAG contrast for white titles on every topic color.

## Typography

SF Pro Rounded everywhere (`.design(.rounded)`), including the navigation bar
(`Typography.configureNavigationBar()`). Every font uses a Dynamic Type text style except the word visual,
which scales with its container. At accessibility sizes Home switches to one column, and the Topic grid
uses larger cells.

## Spacing, radius and elevation

| Spacing | xxs | xs | s | m | l | xl |
|---|---|---|---|---|---|---|
| pt | 4 | 8 | 12 | 16 | 24 | 32 |

| Radius | small | medium | large |
|---|---|---|---|
| pt | 12 | 20 | 28 |

There is one shadow, `softShadow()` (8 % black, radius 12, y 6). `surfaceCard(radius:)` combines a surface
fill with continuous corners and that shadow.

## Components

| Component | File | Notes |
|---|---|---|
| `ChunkyButtonStyle` | Buttons.swift | Toy-like 3D button that presses down. The primary action style. Press animation is skipped under Reduce Motion. |
| `PressableButtonStyle` | Buttons.swift | Gentle shrink on press, for cards and tiles |
| `CaptionedIconButton` | Buttons.swift | Round icon button with a caption under it ("Slow", "Say it") |
| `StageBackground` | StageBackground.swift | The colored rounded stage under every picture, the same in both modes |
| `WordVisualView` | WordVisualView.swift | Draws any `WordVisual` at any size: photo, emoji, letters plus badge, number with ten-frame, color swatch, SF Symbol shape. Hidden from VoiceOver; the parent control carries the label. |
| `TenFrame` | WordVisualView.swift | Two rows of five dots for seeing quantities |
| `StarsView` | ProgressViews.swift | Filled and empty stars, read as "2 of 3 stars" |
| `ProgressBar` | ProgressViews.swift | Rounded track; decorative, the parent provides the spoken value |
| `StarCountBadge` | ProgressViews.swift | Total stars on Home |

## Interaction and feedback

- Haptics use `sensoryFeedback`: a medium impact when recording starts, success for 2–3 stars and a
  warning for fewer.
- Short generated sound effects (`correct`, `retry`, `finish`) from `Scripts/make_sounds.py`.
- Recording shows a pulsing mic tied to the input level. Under Reduce Motion it stays still.

## Accessibility checklist (every screen)

- Light and dark mode, checked in the Simulator.
- Dynamic Type up to accessibility sizes without clipping.
- VoiceOver: every control has a spoken label and value; pictures are decorative.
- Reduce Motion respected for press springs and the recording pulse.
- Touch targets of at least 44 pt (chunky buttons are at least 56 pt), sized for small hands.
- Accessibility identifiers on every control the UI tests use.
