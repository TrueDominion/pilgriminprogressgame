# Pilgrim in Progress

A 2D pixel-art side-scrolling adventure after John Bunyan's *The Pilgrim's Progress* (1678).
Paid, native iOS game. Web builds for playtesting.

**Status:** Phase 1 (plan) awaiting approval. See `design/gdd.md`.

## Stack

| | |
|---|---|
| Engine | Godot 4.7.2-stable, GDScript, Compatibility renderer (all targets) |
| Targets | iOS (primary), Web (playtests), macOS (optional) |
| View | 480x270 minimum, whole-number scaling, nearest-neighbour, expands to fill the screen (cap 720x416) |
| Grid | 16x16 tiles, ~32x48 player cell |

## Layout

```
/game        Godot project (processed, in-game assets live here in plain git)
/design      GDD, art bible, assets.csv, credits.csv, levels/*.md, UI brief, schedule, risks
/content     dialogue/*.csv, codex.csv
/art-src     raw Higgsfield outputs + prompt metadata (Git LFS)
/audio-src   raw audio (Git LFS)
/tools       sprite pipeline and palette scripts
/docs        App Store listing, privacy policy, submission checklist, rights
```

## Build locally

1. Install Godot 4.7.2-stable and its export templates.
2. Open `game/project.godot`, or export from the command line:

```bash
godot --headless --path game --import
godot --headless --path game --export-release "Web" ../build/web/index.html
```

3. Serve `build/web` with any static server (`python3 -m http.server -d build/web`).
   The web build is single-threaded, so it needs no special COOP/COEP headers.

## CI

`.github/workflows/web.yml` builds the web export on every push and pull request,
and deploys to GitHub Pages from `main` only.

## Rules

- Every task is a GitHub issue. One branch and pull request per phase or stage.
- All player-visible text lives in `/content` or `game/data`, never in scripts.
- All balance numbers live in `game/data/*.json`.
- No generation without an approved budget line in `design/credits.csv`.
- Never commit signing certificates, provisioning profiles or API keys.

## Credits

Story by John Bunyan (1678, public domain). Scripture quotations from the King James
Version. Fonts: Pixelify Sans and Figtree (SIL Open Font License 1.1). Full list in
`design/credits-attribution.md`.
