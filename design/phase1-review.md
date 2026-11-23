# Phase 1 Gate: Review Summary

Date: 2026-11-23. Decision needed: approve the plan (with any changes) so phase 2 can start.

## What is in this phase

| Deliverable | File |
|---|---|
| Game design document, movement numbers frozen | `design/gdd.md`, `game/data/movement.json` |
| 9 level outlines | `design/levels/stage1.md` to `stage9.md` |
| Art bible, style formula, 48-colour palette | `design/art-bible.md`, `design/palette.gpl` |
| Asset manifest (301 rows) | `design/assets.csv` |
| Credit budget and ledger | `design/budget.md`, `design/credits.csv` |
| UI pattern brief and wireframes | `design/ui/ui-brief.md`, `design/ui/wireframes.html` |
| Schedule, risk register | `design/schedule.md`, `design/risks.md` |
| App Store plan, rights, privacy draft | `docs/app-store.md`, `docs/rights.md`, `docs/privacy-policy.md` |

## Headline numbers

- Full game: about 2,980 credits including 20% contingency (125 more with voice). Balance 908.5. Phase 2 needs about 568, already covered.
- Ship target: submission by 2027-05-23. Your time: about 25 hours over six months.

## Decisions I need from you

| # | Decision | My recommendation |
|---|---|---|
| D1 | Approve the frozen movement numbers | Approve; they get tuned in phase 2 with one change at a time |
| D2 | Create `main` from the phase 0 commit (needed for PRs and Pages) | Yes |
| D3 | GitHub Pages on a private repo needs GitHub Pro | Upgrade to Pro |
| D4 | Seller entity (individual vs organisation) for Apple and EU trader rules | Organisation; start the D-U-N-S process now, it has lead time |
| D5 | Kids Category | Do not join |
| D6 | Price | $4.99 one-time |
| D7 | Content calls for ages 8+: Faithful's death off-screen; the Giant's suicide theme omitted; the River as a crossing | Approve all three |
| D8 | Sun emblem on the shield instead of a cross | Approve |
| D9 | Voice lines | Decide after the phase 2 slice |
| D10 | Pixel cleanup (human pass on sprites and tiles) | Decide after Stage 1 assets exist, with evidence |

## Changes I made to the master prompt (and why)

1. **App Store preview video is captured from the game, not generated.** Apple guideline 2.3.4 allows only screen captures of the app.
2. **Background removal is a local chroma key, not Higgsfield's remover.** Free, and hard pixel edges suit pixel art better than an AI matte.
3. **Sprite videos at 480p, not 720p.** 12 credits instead of 28; a 32 x 48 sprite cannot use more resolution.
4. **Minor NPCs use a single pose with engine-driven idle motion.** Saves about 360 credits.
5. **Git LFS covers only /art-src and /audio-src.** Processed in-game assets stay in plain git so CI never spends LFS bandwidth.
6. **Added:** the Roll item (needed for the stage 5 arbour), Pilgrim's Aid assist option, phase restarts inside the Apollyon fight.
7. **Screen fit:** Godot's built-in integer scaling letterboxed the iPhone by about a quarter of the screen; a small ScreenFit script now fills the screen at a whole-number scale (iPhone 15 Pro: 639 x 294 game pixels at 4x).
