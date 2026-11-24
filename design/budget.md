# Credit Budget (full game)

Status: phase 1 estimate for approval. Quotes taken from Higgsfield's cost-estimate tools on 2026-11-23; prices can change, so every batch is re-quoted before it runs.

## Bottom line

| | Credits |
|---|---|
| Core production (300 assets) | 2,480 |
| Contingency (20%) | 496 |
| **Core total** | **about 2,980** |
| Optional: voice lines (narrator, Evangelist) | 125 |
| Current balance | 908.5 |
| **Still to buy for the full game** | **about 2,070 (2,200 with voice)** |

Phase 2 (the Stage 1 vertical slice plus shared UI, props and core SFX) is estimated at **568 credits**, which the current balance covers with about 340 to spare. You do not need to buy credits before approving phase 2. The money cost of the remaining credits depends on your Higgsfield plan and top-up pricing, which I cannot see: **TBD, check the plan page before phase 3.**

## Unit prices (quoted 2026-11-23)

| Job | Model | Quoted credits |
|---|---|---|
| Image, key pose | flux_2, 1:1 | 1 |
| Image, general | gpt_image_2_6, 16:9 | 0.75 |
| Image, high detail (sheets, stills, layers) | nano_banana_pro, 16:9 | 2 |
| Video, sprite animation 4 s 480p, no audio | seedance_2_5 | 12 |
| Video, same at 720p | seedance_2_5 | 28 |
| Music, 90 s | sonilo_music | 5.63 |
| Sound effect, 2 s | mirelo_text_to_audio | 0.5 |
| Voice line | inworld_text_to_speech | 2 |
| Background removal | local chroma key in /tools | 0 |

## Estimating rules (per asset, including expected rerolls)

| Asset | Credits | Basis |
|---|---|---|
| Character sheet | 4 | 2 attempts at 2 |
| Boss sheet (Monsters studio, then pixel restyle) | 16 | Monsters workflow cost not quotable until run; held high |
| Sprite animation | 20 | key pose 2 attempts (2) + video 1.5 attempts (18) |
| Minor NPC key pose | 2 | 2 attempts, procedural idle in engine |
| Parallax layer | 8 | base + outpaint extensions + 1 reroll |
| Tileset | 12 | 3 attempts at 2, twice (base and variants) |
| Static prop / UI element | 1.5 | 2 attempts at 0.75 |
| UI illustration, cutscene still | 6 | 3 attempts at 2 |
| Music track | 17 | 3 attempts (music taste needs choices) |
| Sound effect | 1 | 2 attempts |
| App icon | 10 | 5 attempts |

## By category

| Category | Assets | Credits | Share |
|---|---|---|---|
| Sprite animations | 61 | 1,220 | 49% |
| Parallax layers | 43 | 344 | 14% |
| Music | 13 | 210 | 8% |
| Animated props | 8 | 160 | 6% |
| Tilesets | 11 | 132 | 5% |
| Cutscene stills | 15 | 90 | 4% |
| Character sheets | 12 | 72 | 3% |
| Props, UI, NPC poses, SFX, concept, marketing | 136 | 252 | 10% |

## Where the money goes and how to cut it

Animation is half the budget. The levers, in order of value:

1. **480p instead of 720p for sprite videos** (already applied): saves about 1,000 credits. 480p is far more resolution than a 32 x 48 sprite can use.
2. **Local chroma key instead of AI background removal** (already applied): saves one paid call per frame, roughly 500 frames.
3. **Procedural idle for 20 minor NPCs** (already applied): saves about 360 credits.
4. If we need to cut further: merge Christian's free and armoured sets by giving him the armour at the start of stage 5 and drawing set B only for the stage 4 descent (saves about 100). I do not recommend this yet: the free-but-unarmed climb is a good beat.
5. Reroll discipline: at most 2 regenerations per asset, then take the best (master prompt rule 11).

## Tracking

Every batch: quote, log the estimate in `design/credits.csv`, get approval if over 100 credits, run, log the actual. After phase 2 I will report estimated vs actual and re-project the full game.
