# Stage 6: The Valley of Humiliation and the Shadow of Death

**Source:** Part I, the fight with Apollyon, the Valley of the Shadow of Death (the ditch, the quag, the narrow path, the voices, Psalm 23), meeting Faithful.
**Target playtime:** 5 to 6 minutes (boss about 2.5). **Movement set:** free + Sword, Shield, Helmet. **Reward:** Faithful joins (story).

## Beat map

| # | Section | Tension | What happens |
|---|---|---|---|
| 1 | Descent into the Valley | Low | A quiet, green, humble valley. Light motes plentiful. Checkpoint A. |
| 2 | Apollyon arrives | Story | Wings blot out the sky; he lands across the path. Dialogue: he claims Christian as his subject. Christian refuses. Checkpoint B (boss start). |
| 3 | Phase 1: darts | High | Apollyon hovers. Fiery darts in readable volleys. Block to deflect them back; 4 deflected hits. |
| 4 | Phase 2: melee | High | He lands, swipes with telegraphed wind-ups. Dodge, strike when he recovers; 4 hits. |
| 5 | Phase 3: both | Climax | Darts and swipes together; short-lived floor fire. A deflect followed by a strike does double. 4 hits. At the last hit Christian quotes Micah 7:8; Apollyon flies away. A healing leaf (from the book) restores Hope. |
| 6 | Valley of the Shadow | Dread | Darkness. Christian's lamp lights a 64 px radius (Light2D, the only light in the scene). A narrow path with a ditch on one side and a quag on the other. Whispers in stereo. No enemies; the danger is the edges. Signposts read by the Book light the path briefly. Checkpoints C and D. |
| 7 | Dawn and Faithful | Release | Light rises; Psalm 23:4 on screen. Faithful is seen ahead and Christian catches up. Stage card. |

## Apollyon tuning

| | Phase 1 | Phase 2 | Phase 3 |
|---|---|---|---|
| Hits to clear | 4 | 4 | 4 |
| Attack telegraph | 0.8 s glow | 0.6 s wind-up | 0.5 s |
| Damage to Christian | 1 Hope | 1 Hope | 1 Hope |
| Mid-fight checkpoint | No. Failure restarts the current phase, not the fight. **[added]** Reason: a 2.5-minute fight lost at phase 3 is too punishing for 8-year-olds. |

## Hazards and answers

| Hazard | Answer |
|---|---|
| Fiery darts | Shield (block and deflect) |
| Melee swipes | Dodge, then Sword |
| Darkness and edges | Lamp radius, Book-lit signposts, slow careful movement |

## Checkpoints

A: valley entrance. B: boss start. Phase restarts inside the fight. C and D: in the dark section, every 45 seconds.

## Scrolls

1. In the green valley, on a hidden ledge. Codex: Bunyan, "He that is down needs fear no fall."
2. Dropped by Apollyon when he flees (always collected; the only guaranteed Scroll). Codex: Ephesians 6:16.
3. In the dark, off the path, only visible by lamp light. Codex: Psalm 23:4.

## Notes

- Apollyon's design: scales, wings, smoke and fire. Dramatic, not grotesque. No open wounds, no gore, no realistic teeth close-ups.
- The dark section must not be unplayable on a bright screen in sunlight: keep a faint ambient at 8%.
- Reduce-flashing setting softens the fire and dart glow.
