# Stage 4: The Interpreter's House and the Cross

**Source:** Part I, the Interpreter's House (the dusty parlour; the fire kept burning with oil), the walled way (Salvation), the Cross and the sepulchre, the three Shining Ones, the Roll.
**Target playtime:** 5 to 6 minutes. **Movement set:** burdened, then free after the Cross. **Reward:** burden removed, double jump, the Roll.

## Beat map

| # | Section | Tension | What happens |
|---|---|---|---|
| 1 | Interpreter's door | Low | The Interpreter welcomes Christian: "I will show thee that which will be profitable." Checkpoint A. |
| 2 | Room 1: the dusty parlour | Puzzle | A room choked with dust. Pushing the broom only raises clouds that hide the platforms (the Law stirs sin up). The answer: find the damsel's water jug and pour it (Action), which settles the dust and reveals the route (the Gospel). One-screen puzzle, 60 to 90 seconds. |
| 3 | Room 2: the fire and the wall | Puzzle | A fire on a hearth that a figure keeps dousing; it keeps burning. Behind the wall, a hidden figure pours oil. The player follows a narrow passage behind the wall, climbing with the burden, to find the oil-pourer. Reaching him lights a path of braziers up to the exit. Teaches looking behind the obvious. |
| 4 | The walled way | Rising | A long climbing ascent between two walls (Isaiah 26:1). Steady, steep, burdened steps of 1 and 2 tiles. Music builds. Light motes thin out. Checkpoint B at the foot, C halfway. |
| 5 | The Cross | Climax | The path levels at the top. Christian walks toward the Cross. Input locks gently (walking only). Cutscene: the straps loosen, the burden rolls down the slope into the open sepulchre and is gone. Three Shining Ones: forgiveness, new clothes, the Roll. Christian "gave three leaps for joy." |
| 6 | Three leaps | Release | Control returns with the free movement set. The descent is designed for it: gaps of 4 tiles, ledges of 3, then a double-jump prompt over a 6-tile gap. Christian's three joyful leaps are the player's first three jumps. Checkpoint D. Stage card. |

## Hazards and answers

| Hazard | Answer |
|---|---|
| Dust clouds hiding platforms | Pour water (puzzle) |
| Fire that cannot be put out | Find the oil-pourer behind the wall |
| Long burdened climb | Steady 1 to 2 tile steps; frequent checkpoints |
| 4 to 6 tile gaps after the Cross | Free jump and double jump |

## Checkpoints

A: door. B: foot of the walled way. C: halfway up. D: after the Cross.

## Scrolls

1. Dusty parlour, on the top shelf only visible after the dust settles. Codex: Romans 7:9.
2. Behind the wall in room 2. Codex: 2 Corinthians 12:9.
3. After the Cross, across a gap that needs the double jump: the very first reward of freedom. Codex: Bunyan, "He hath given me rest by his sorrow, and life by his death."

## Notes

- This stage carries the game's emotional payload. It gets the most polish time and the only bespoke music sting.
- The burden must never come off by player action. The input lock is gentle (walking still allowed) so the player is present, not watching.
- Playtest question: do players feel the difference in the first three jumps? If not, increase the free jump height before anything else.

## Built: greybox, 2026-11-26

`game/data/levels/stage4.json`, 232 tiles. Borrows Stage 1's town art and music until Stage 4's own exist.

| Item | As built |
|---|---|
| New systems | Items to take and use (Action), hidden steps that stay once a puzzle is solved (saved), blocks hanging from above (a passage runs under them), a walking-only zone, the burden coming off for good (flag `burden_off`; later stages spawn Christian free) |
| Dusty parlour | Broom (sweeping thickens the dust), the damsel says to bring water, a jug to take, a basin to pour. Pouring settles the dust and raises three steps over a 6-tile wall. Scroll 1 on the top shelf, only reachable once the steps exist |
| Fire room | A fire that cannot be put out; the floor drops into a passage under the wall. At its end the oil-pourer: reaching him lights a step of braziers back up to the floor. Without him the climb out is 4 tiles, too high burdened. Scroll 2 in the passage |
| Walled way | Ten steps of 1 and 2 tiles up to the Cross (0 to 12 tiles high), checkpoints B at the foot and C halfway, the wall behind |
| The Cross | Jumping is locked for the last 12 tiles (walking only). The burden falls, rolls into the sepulchre, three Shining Ones speak, "three leaps for joy" |
| Three leaps | Free set from here: three 4-tile gaps, a 3-tile ledge, a 6-tile gap that needs the double jump (a sign says so first). Scroll 3 on a ledge 5 tiles up, reachable only with the double jump |
| Dialogue | 21 lines (`content/dialogue/stage4.csv`), the most of any stage; this one carries the payload |
| Tests | Bot run 57 s, all puzzles solved, burden off. `stage4_test`: a walker that never uses items stops at the parlour wall (tile 44.6) and in the passage (91.6) |

Art and audio added 2026-11-26 (31.02 credits): dawn sky, the house layer, the hillside with the Cross, props (fire, Cross, tomb, jug, basin, broom, braziers on the lit steps), the Interpreter, the damsel, the oil-pourer, the Shining Ones, music and a one-off sting at the Cross that plays over the music (take A of each until the owner picks). Christian's free animation set was added the same day.
