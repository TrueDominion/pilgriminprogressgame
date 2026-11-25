# Stage 3 art prompts (2026-11-25)

All nano_banana_pro 1k (served as nano_banana_2), 2 credits each. Built by tools/build_stage3_env.py. Stage 3 reuses Stage 1's sky, fields layer, ground textures, lantern, signpost and barrel (same country).

| File | Job | Ratio | Reference | Subject |
|---|---|---|---|---|
| far-castle.png | 494bb9a3 | 21:9 | BG-s1-far-city | Distant dark fortress on a crag, grim towers with lit arrow slits, a long high wall along the horizon, thin smoke; magenta above |
| sinai.png | 26f639b8 | 4:3 | BG-s1-mid-fields | Huge rocky mountain leaning out over the left like a cliff about to fall, fire in its cracks, pebbles tumbling; magenta around |
| ../../tiles/stage3/props.png | fc611bd8 | 16:9 | PRP-stage1-sheet | Rock face swatch, clipped hedge swatch, boulder with a jutting ledge, small boulder, arched wicket gate in a stone wall with a knocker, signpost |

Every prompt carried the style formula from design/art-bible.md section 4 verbatim, plus the type line.
In game: the castle is the far layer, lowered (level file "backdrop": far -20) so its towers show above the fields. The ledged boulder is too large for the 2-tile rocks Christian must hop, so the rocks are drawn with the rock texture and a stone slab ("slab" platforms) instead; prop_shelter is kept for later.
