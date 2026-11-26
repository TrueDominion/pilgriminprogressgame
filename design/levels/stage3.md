# Stage 3: The Wicket Gate

**Source:** Part I, Mr Worldly Wiseman, Mount Sinai, Evangelist's rebuke, Goodwill at the gate, Beelzebub's castle.
**Target playtime:** 4 to 5 minutes. **Length:** about 280 tiles plus the optional Sinai detour (60 tiles). **Movement set:** burdened.
**Reward:** Goodwill (story).

## Beat map

| # | Section | Tension | What happens |
|---|---|---|---|
| 1 | Pleasant fields | Low | Worldly Wiseman walks alongside and offers a shortcut to the village of Morality. Choice: take it, or keep to the narrow way. Checkpoint A. |
| 2a | The detour (optional) | High | A smooth road toward Mount Sinai. The mountain overhangs, rumbles, then drops rocks with shadows that warn 1 s ahead. The path ends at a cliff face that collapses. Evangelist appears and turns Christian back. The detour returns to checkpoint A. It holds one Scroll, so curious players are rewarded for learning the lesson. |
| 2b | The narrow way | Rising | Narrow path, hedges, short platforming. Checkpoint B. |
| 3 | Beelzebub's castle | High | A dark castle on the far parallax layer. Arrows arc across the path in visible volleys (telegraphed by a glint). Cover from rocks and hedges. Burdened movement makes this tense, so volleys are slow. Checkpoint C mid-way. |
| 4 | The gate | Release | Knock (Action). Goodwill pulls Christian through just as the last volley strikes the door. Dialogue. Stage card. |

## Hazards and answers

| Hazard | Answer |
|---|---|
| Falling rocks (Sinai) | Watch shadows, move; better still, do not take the shortcut |
| Arrows | Use cover; time movement between volleys |
| 2-tile platforming | Burdened jump |

## Checkpoints

A: start of fields (30). B: narrow way (120). C: halfway through the arrow field (210).

## Scrolls

1. At the end of the Sinai detour, under the overhang before it falls. Codex: Galatians 2:16.
2. In a hedge alcove on the narrow way. Codex: Matthew 7:7.
3. Behind a rock in the arrow field that requires waiting through two volleys. Codex: Bunyan, Goodwill's "We make no objections against any."

## Notes

- The detour must be clearly optional and clearly wrong in hindsight. The rumble starts the moment the player steps onto the smooth road.
- Arrow damage: 1 Hope. 3 hits in a volley field is the expected worst case for new players.

## Built: greybox, 2026-11-25

`game/data/levels/stage3.json`, 284 tiles, plus the Sinai detour as a separate area (tiles 316 to 404, its own camera region). Borrows Stage 1's field art and music until Stage 3's own exist.

| Item | As built |
|---|---|
| New systems | Hope (3 lamps, top left), hits with 1 s blink and knockback, Pilgrim's Aid toggle in the pause menu, falling rocks, arrow volleys, choices that branch, knocking at a gate |
| Worldly Wiseman | Tile 33, after checkpoint A. Three lines, then "Which way?": the smooth road sends Christian to the detour; the narrow way carries on |
| Sinai detour | Rocks every 1.6 s aimed where Christian will be when they land (1 s warning plus 0.22 s fall); a shadow grows meanwhile. Standing still or stepping back avoids them. Scroll 1 near the end; Evangelist (4 lines) sends him back to waystation A |
| Narrow way | Hedges 1 to 2 tiles high, a 2-tile gap, Scroll 2 on a ledge above a hedge |
| Arrow field | Tiles 130 to 262. A volley every 5 s with a 1.2 s glint and chime first. Nine rocks, 12 tiles apart, each with a ledge 2 tiles out over its hiding spot |
| The gate | Knock (Action). Goodwill appears, three lines at the gate, then the stage ends |
| Dialogue | 18 lines (`content/dialogue/stage3.csv`) |
| Tests | Bot run 67 s, 2 arrow hits while walking blind (with Pilgrim's Aid so it never fails). `arrow_cover_test`: 0 hits behind a rock, 2 in the open. `detour_test`: smooth road, 3 rock hits, sent back to A |

Changes from the beat map:
- Each rock got a ledge. A 2-tile rock alone cannot shield a 36 px Christian from arrows coming in at 45 degrees; the cover test proved it.
- "Goodwill pulls him through as the last volley strikes the door" is told in the closing line, not staged.
- Pilgrim's Aid does not yet return Christian to safe ground after a fall; pits still send him to the last waystation.

Art and audio added 2026-11-25 (22.64 credits): castle on the far layer, Mount Sinai over the detour, rock and hedge textures with stone-slab ledges, the wicket gate, Worldly Wiseman and Goodwill sprites, music (take A until the owner picks), and hurt, knock, arrow and rockfall sounds.
