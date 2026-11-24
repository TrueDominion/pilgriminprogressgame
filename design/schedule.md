# Production Schedule

Status: phase 1 estimate. Assumes I work in sessions you start, and that you review each gate within 3 days. The calendar is the real constraint: your review time, not build time.

| Phase | Scope | Estimate (my working sessions) | Calendar target | Gate |
|---|---|---|---|---|
| 0 Setup | Repo, Godot, CI | done | 2026-11-23 | Web build passes (done in CI; no Pages deploy: owner chose not to pay for GitHub Pro, 2026-11-24; playtests use the web-build artifact and TestFlight) |
| 1 Plan | This document set | done | 2026-11-23 | **Your approval** |
| 2 Vertical slice | Stage 1 finished: controller, burden, sprite set, tiles, parallax, all three input methods, dialogue, checkpoints, saves, music, SFX, TestFlight instructions | 8 to 12 sessions | by 2026-12-21 | Quality bar and re-projected budget |
| 3 Production | Stages 2 to 9, one PR each; Apollyon its own milestone | 3 to 5 sessions per stage, 30 to 40 total | 2027-01-04 to 2027-03-28 | Per-stage playtest notes |
| 4 Polish | Menus, codex, settings, accessibility, mix, performance on iPhone 12, bug bash, timing | 8 to 10 sessions | 2027-04-25 | Full playthrough sign-off |
| 5 Ship | Icon, screenshots, preview video, listing, privacy page, TestFlight round (2 weeks), fixes, submission | 6 to 8 sessions + your Mac time | submit by 2027-05-23 | App Store approval |

**Your time per phase (estimate):** phase 2 about 4 hours (review, iPhone test, game-feel notes); phase 3 about 1 hour per stage; phase 4 about 4 hours; phase 5 about 6 hours on the Mac (signing, archive, upload, App Store Connect forms). Total about 25 hours over six months.

**Human work outside us (decide in phase 2):** pixel cleanup is the swing factor. If cleanup is needed on most sprites and tiles (art bible 7 and 8), it is roughly 60 to 80 hours of pixel work across the game. Options: you, a hired pixel artist (budget TBD), or accept rougher art. I will give you a concrete recommendation with evidence after the Stage 1 assets exist.

**Critical path:** Christian's sprite sets → Stage 1 slice → Apollyon → stage 9 finale → TestFlight. Everything else can slip a week without moving the ship date.
