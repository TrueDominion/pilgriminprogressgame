# Stage 2: Slough of Despond

**Source:** Part I, the Slough; Pliable turns back; Help pulls Christian out ("the steps").
**Target playtime:** 4 to 5 minutes. **Length:** about 260 tiles. **Movement set:** burdened.
**New mechanic:** sinking mud. **Reward:** Help (story).

## Mechanic: the mud

- Mud tiles sink Christian at 14 px/s while he stands; moving slows him to 55% speed but stops the sinking. Jumping out of mud is possible until he is chest-deep (16 px sunk), then only walking out works.
- Fully sunk (30 px) = failure, fade to checkpoint.
- Clear visual: bubbles and a darkening ring at the sink line. Sound: a low squelch that rises in pitch as he sinks.

## Beat map

| # | Section | Tension | What happens |
|---|---|---|---|
| 1 | Edge of the bog | Low | Pliable chats. Shallow mud patches teach "keep moving". Checkpoint A. |
| 2 | Into the Slough | Rising | Longer mud with tufts of firm grass 2 tiles apart. |
| 3 | Pliable turns back | Story | Both fall into a deep pool. Pliable climbs out on the near side: "You may have the brave country alone for me." He leaves. |
| 4 | The despond | High | Fog, darker palette, music thins. Long mud runs. A signpost the player can only reach by wading: reading it reveals the hidden stepping stones ("the steps") for 8 seconds. Checkpoint B. |
| 5 | The steps | Rising | Timed crossings using Book reveals: read, then cross before the stones fade. Two signs, two crossings. Checkpoint C. |
| 6 | Help | Release | Christian sinks in the last pool no matter what (scripted, no failure). Help reaches down and pulls him out. Dialogue on why the steps were missed. |
| 7 | Firm ground | Breather | Short walk out. Stage card. |

## Hazards and answers

| Hazard | Answer |
|---|---|
| Sinking mud | Keep moving; jump early |
| Gaps between firm tufts | 2-tile burdened jump |
| Invisible stepping stones | Read signs with the Book |

## Checkpoints

A: 40 tiles. B: 140 (before the steps). C: 200. Spacing is tighter than stage 1 because mud failures are frequent for young players.

## Scrolls

1. On a dead tree above the first pool (jump from a firm tuft). Codex: Psalm 40:2.
2. On a revealed stone off the main crossing; requires a second read. Codex: Bunyan on the Slough ("the King's labourers").
3. Behind Pliable's exit, back toward the start; reached only after he leaves. Codex: Luke 9:62.

## Notes

- Playtest risk: timing windows for revealed stones. Start at 8 s, tune with children.
- Pilgrim's Aid makes the mud stop sinking at chest depth.

## Built: greybox, 2026-11-25

`game/data/levels/stage2.json`, 244 tiles.

| Item | As built |
|---|---|
| Checkpoints | A 39, B 141 (just before the steps), C 189 |
| Mud | 14 patches: three single patches at the edge, mud between firm tufts, the pool where Pliable turns back, long runs in the Despond, Help's pool |
| The steps | Crossing 1 (sign at 146): four stones with 1-tile gaps, to teach the reveal. Crossing 2 (sign at 167): four stones with 2-tile gaps, plus a higher stone holding Scroll 2 |
| Gloom | Tiles 96 to 200 darken gradually, then lift for Help |
| Pliable | Follows from the start; at tile 92 both fall in, he complains and walks back toward home. Scroll 3 (on a ledge above tile 84) appears only once he has gone |
| Help | Scripted: Christian sinks in the last pool whatever the player does (no failure), Help appears, then pulls him out to firm ground at 211 |
| Dialogue | 14 lines (`content/dialogue/stage2.csv`), about 1,100 characters, roughly 80 s to read; down from 30 lines in Stage 1 |
| Bot run | 71 s of movement, no respawns, all 40 Light |

Changes from the beat map: the despond sign "reachable only by wading" became a sign on firm ground at the edge of each crossing, because reading freezes Christian and standing in mud while reading would sink him. The edge sign is a plain mud hint.

Expected first play: about 2.5 minutes for a clean run, more with mud failures. Below the 4 to 5 minute target; judge in playtest before adding length.

Art and audio added 2026-11-25 (24.90 credits): four parallax layers, bog ground, mud and mire textures, Help's sprite, music (take A in the game until the owner picks), and mud sounds: a squelch on stepping in, bubbles that get louder and higher as Christian sinks, and a wet pull when Help lifts him out. Still to do: visible bubbles that grow with sink depth, and breaking the mirror repeat in the dead-tree layer (phase 4).
