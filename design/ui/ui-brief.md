# UI Pattern Brief (Mobbin research)

Status: phase 1. Searched 2026-11-23 on Mobbin (iOS). Reference only: no screen is copied.

## The honest finding first

Mobbin catalogues apps, not games. It returned almost no native game menus and nothing in landscape. The strongest references came from game-like apps (Duolingo, Finch, Brilliant, AllTrails) and from settings screens in mainstream apps. Patterns below are adapted to a landscape pixel-art game; where a recommendation comes from game conventions rather than Mobbin, it is marked **[game convention]**.

## What works, and why

| Pattern | Seen in | Why it works | Our version |
|---|---|---|---|
| One dominant primary action on the entry screen | [Duolingo game intro](https://mobbin.com/screens/dd8b6b31-0668-4f27-9cb4-830914b79ea3), [Netflix game page](https://mobbin.com/screens/a74bced1-1d7e-4b78-8204-b61e760eedcd), [Wordle in Discord](https://mobbin.com/screens/5965f6f3-fda9-4d19-9f6a-90e42735a24e) | A child knows what to press in under a second. Secondary actions are visually quieter. | Title: one large "Begin the Journey" / "Continue" button; Settings, Codex and Credits as small icon buttons. |
| A path map with locked, current and completed nodes | [Duolingo path](https://mobbin.com/screens/3cc1779f-ef61-4e0a-8b00-adecbd24aa6d), [Duolingo ABC](https://mobbin.com/screens/d016b202-6612-4df4-918a-b3088415b177), [Life Reset](https://mobbin.com/screens/cb3e87ef-1183-486f-bd20-2f465417d486), [Liven](https://mobbin.com/screens/d98bf80c-9d46-45c6-833d-d0baef1b2e1d) | Progress is spatial and visible; the next step glows; locked nodes show what is coming without spoiling it. | World map is the road itself: a horizontal winding road across one illustrated map (landscape fits a left-to-right journey better than Duolingo's vertical scroll). Completed stages show a lit lantern and Scroll count (0/3 to 3/3). |
| Collections as a grid with silhouettes for missing items | [Finch collection](https://mobbin.com/screens/83509751-7c83-4eeb-ba04-f9e3c37689d3), [AllTrails stamps](https://mobbin.com/screens/735d6ccf-c400-4960-95d5-40ea81360797), [Duolingo badges](https://mobbin.com/screens/021cfe8b-04e2-456b-821e-fe8a8ffb72ea) | The count ("1/63") and visible gaps motivate completion; greyed shapes hint without revealing. | Codex: 9 stage tabs, 3 Scroll slots each; collected entries show the verse title; missing ones show a sealed scroll and the stage where it hides. Counter "12 / 27". |
| Avoid all-blank "?" grids | [Life Reset achievements](https://mobbin.com/screens/543e2188-14ef-4181-9ea3-1ed472b2e00e) | A wall of identical question marks gives no hint and feels like a chore. | Missing Scrolls name their stage and a vague hint once that stage is finished. |
| Grouped settings with plain-language descriptions under each toggle | [Canva accessibility](https://mobbin.com/screens/0e0b8aed-7212-44d1-a85c-be08f628e2b6), [Starling accessibility](https://mobbin.com/screens/e465aa3a-1860-41df-9cda-42c0ab9786d8), [Tide Guide](https://mobbin.com/screens/42ee74ba-d425-47c6-8006-7ea733ab68a2) | Users understand what a toggle does before flipping it; grouping keeps long lists scannable. | Settings in 4 tabs: Sound, Display, Controls, Accessibility. Each option has a one-line description. |
| Live preview for text size | [Telegram text size](https://mobbin.com/screens/c4324f74-c637-4e49-b9e8-c30e59b05bed) | The slider means nothing until you see its effect. | Text size control shows a live sample dialogue box with Evangelist's portrait. |
| Gesture coach marks shown once, over a dimmed scene | [Telegram stories](https://mobbin.com/screens/44cc1608-a319-4252-961b-26ee9db04dfa), [Polarsteps](https://mobbin.com/screens/705552aa-40c7-4c47-b67d-292ca45ad647), [Ladder](https://mobbin.com/screens/8a029664-8985-4ae1-be69-8a25f6727b4c) | Short verb + icon, dismissed with one tap. | We go further **[game convention]**: teach in the level, not in an overlay. The first time a control is needed, a small in-world prompt appears next to Christian showing the right glyph for the active input (touch, gamepad or keyboard). No upfront tutorial screens. |
| Story dialogue: portrait near the text, short lines, one advance button | [Kit](https://mobbin.com/screens/efb78fab-2427-4aef-be68-001c7cc840f9), [Duolingo stories](https://mobbin.com/screens/aaa44dcc-b20d-4c0e-aa8f-c7324b0a6725), [Speak](https://mobbin.com/screens/4d5267dc-14e2-41c0-8959-28393a5469f0) | The speaker is obvious; the text is short enough to read on a phone; one clear "next". | Bottom dialogue box (up to 3 lines), portrait on the speaker's side, name tab in gold, a blinking advance arrow. |
| Pause as a clear overlay with Resume dominant | [Ladder paused](https://mobbin.com/screens/4f7017d2-a805-4fcb-9024-23edfc6e4617), [AllTrails](https://mobbin.com/screens/09db6e11-c87e-492f-a3c1-b3b924762bd7), [Slopes](https://mobbin.com/screens/6354105c-39b0-46a8-878b-15ca9132f85a) | Resume is the big, first, safe action; "end" actions are smaller and separated. | Pause: dimmed game behind, parchment card: Resume (large), Settings, Codex, Return to map (asks for confirmation; progress since the last checkpoint is lost). |

## What does not transfer

- Bottom tab bars, streak counters, XP and energy meters (Duolingo, Finch). They belong to habit apps and would cheapen a story game. The prototype's XP is dropped in favour of Light and Scrolls.
- Portrait-orientation layouts. Everything here is redesigned for landscape at 480 x 270.
- Mobbin had no paid-game App Store screenshot layouts. Store screenshot guidance is in `docs/app-store.md` and comes from Apple's specifications, not Mobbin.

## Rules for every screen

1. Design at the minimum view, 480 x 270 game pixels; anchor to edges so wider screens gain margin, not stretched elements.
2. Interactive elements at least 24 game pixels tall (at the 2x scale of small phones that is 48 points, above Apple's 44 pt minimum).
3. All UI inside the safe area (`ScreenFit.safe_rect()`).
4. Every screen is fully usable with touch, gamepad (focus ring in gold) and keyboard.
5. Back is always top-left (touch), B / Circle (gamepad), Esc (keyboard).
6. Text in Pixelify Sans at 8, 16 or 24 px only (whole multiples of the font's pixel grid); Figtree for codex body text at the Large text setting.

## Screens

Wireframes for Title, Save slots, World map, Pause, Settings, Codex and Credits: `design/ui/wireframes.html` (open in a browser). Each is drawn at 480 x 270 in the master palette.
