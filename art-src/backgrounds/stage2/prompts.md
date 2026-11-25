# Stage 2 environment prompts (2026-11-25)

All nano_banana_pro 1k (served as nano_banana_2), 2 credits each, 10 credits total. Built into the game by tools/build_stage2_env.py.

| File | Job | Ratio | Reference | Subject |
|---|---|---|---|---|
| sky.png | 9a0e55c9 | 21:9 | BG-s1-sky-smoke | Overcast grey-violet sky over a marsh, flat cloud bands, faint gold glow low on the right horizon, no land; edges match to repeat |
| far-bog.png | 94294d13 | 21:9 | BG-s1-mid-fields | Distant flat bogland, low misty hills, bare distant trees, water channels catching the light, fog band; magenta above |
| mid-reeds.png | 8146a343 | 21:9 | BG-s1-mid-fields | Tall reeds and rushes, dark still pools, tussocks, low mist; magenta above |
| near-dead-trees.png | 8e7bee65 | 21:9 | BG-s1-mid-fields | Gnarled dead trees, broken stumps, hanging moss, reed clumps along the bottom; magenta elsewhere |
| ../../tiles/stage2/swatches.png | b670c4a4 | 16:9 | TIL-s1-base | Grid of material swatches: wet mud with bubbles, peat, bog grass edge, tussock, stepping stone, still water, rotten planks, reeds |

Every prompt carried the style formula from design/art-bible.md section 4 verbatim, plus the parallax line for layers.
In game (level file "backdrop"): sky -30, far 6, mid 6, near 12 at 60% brightness so the dead trees stay behind the action.
