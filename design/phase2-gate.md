# Phase 2 Gate: Stage 1 vertical slice

Status 2026-11-24. For the owner's decision: go to phase 3, or fix the open items first.

## Bottom line

The slice works and costs much less to make than planned. Phase 2 spent **178 credits against a 568 plan**. Re-projected from what each asset actually cost, the full game needs **about 1,680 credits including 20% contingency, down from about 2,980**. You would need to buy **about 950 more** (about 1,075 with voice lines), not 2,070. Two things still gate phase 3: an iPhone test through TestFlight, and a decision on Stage 1's length.

## Scope against the gate

| Gate item | Status | Evidence |
|---|---|---|
| Controller and the Burden | Done | Movement reach test passes all 12 cases in CI |
| Christian's burdened sprite set | Done, 9 animations | `game/assets/sprites/christian-burden` |
| Christian's free set | Walk only (placeholder) | The full set is phase 3 (stage 2 onwards) |
| Tiles and parallax | Done | Mirrored layers are visible in places (the cottage repeats); fix in polish |
| Keyboard, gamepad, touch | Built | Touch not yet tested on a real iPhone |
| Dialogue, checkpoints, saves | Done | Bot playthrough reaches the exit in CI |
| Music and SFX | Done | Owner picked title take A and Stage 1 take B |
| Pause menu, volume | Done | PR 14 |
| TestFlight instructions | Done | `docs/testflight.md` |
| Owner playtest | Browser: "worked well" (2026-11-24) | iPhone: TBD |

## Open items before phase 3

| Item | Why it matters | Proposed action | Owner | Due |
|---|---|---|---|---|
| First TestFlight build | Touch controls, frame rate and safe areas are unproven on a phone | Follow `docs/testflight.md` | Matthew | TBD |
| Stage 1 length | A straight run takes about 57 s against a 3 to 4 minute target | Recommendation below | Matthew to decide | Before phase 3 |
| Pixel cleanup | Faces flicker slightly between frames, about 15 minutes of hand cleanup per sheet | Recommendation below | Matthew to decide | Before phase 3 |
| Parallax mirroring | Repeats are visible | Polish (phase 4): extend layers by outpainting, about 2 credits each | Claude | Phase 4 |
| Bundle ID | Permanent after the first upload | Confirm `com.matthewmeza.pilgrim` | Matthew | Before step 1 of TestFlight |
| Seller entity | Name and, for EU sales, contact details shown on the store | Individual account, EU excluded at launch, unless you form a company | Matthew | Before phase 5 |

**Stage length, recommendation:** lengthen Stage 1 to about 2 minutes now. Use a second street section and one more optional Scroll route, built from the tiles and props we already have (no new credits). Hold later stages to 3 to 4 minutes. Matching the target in a first stage that mostly teaches the controls would pad it.

**Pixel cleanup, recommendation:** accept the current quality for phase 3 and decide on cleanup in phase 4, after seeing the art on a phone. Across about 60 sheets it is roughly 15 hours of work. That work is cheap to do late and wasted if a sheet is regenerated.

## Credits: estimate against actual

| Category | Planned unit cost | Actual unit cost | Why lower |
|---|---|---|---|
| Sprite animation | 20 | 12 | One 480p video each; one start frame reused across the set; no rerolls needed |
| Character or NPC image | 4 | 2 | First attempts were usable |
| Parallax layer | 8 | 2 | Mirror tiling in the engine instead of outpainting |
| Tileset | 12 | 2 | Generated tilesets failed; surface swatches cut from a prop sheet instead |
| Music track | 17 | 11.3 | Two takes, not three |
| Sound effect | 1 | 0.3 | Short clips, no rerolls |
| Exploration (style and sprite tests, walk test) | none planned | 41 | One-off method finding; not repeated |

Phase 2 total: **178.02 credits** (balance from 908.5 to 730.48), against the 568 plan. Part of the phase 2 asset list is not built yet: UI art, the title art, the opening still, most props and five SFX. Some planned NPC sheets and animations were replaced by single poses with an engine idle bob. Everything not yet built is included in the re-projection below.

## Re-projection for the rest of the game

The re-projection uses actual phase 2 unit costs. A buffer is added where an asset type is untested.

| Category | Assets left | Old estimate | New estimate | Basis |
|---|---|---|---|---|
| Sprite animations | 52 | 1,040 | 730 | 14 each: 12 plus a 15% reroll allowance. Bosses are untested |
| Parallax layers | 39 | 312 | 160 | 4 each: base plus one outpaint to break the mirroring |
| Music | 11 | 176 | 125 | Two takes per track |
| Animated props | 8 | 160 | 100 | One video each |
| Cutscene stills | 15 | 90 | 60 | 2 attempts each |
| UI elements and illustrations | 25 | 60 | 60 | Untested; kept at plan |
| Character sheets | 11 | 68 | 45 | Apollyon via Monsters is untested; kept high |
| Tilesets | 10 | 120 | 40 | Swatches, as in Stage 1 |
| Minor NPC poses | 17 | 34 | 34 | Matches actual |
| Props | 40 | 60 | 20 | About 8 props come from one 2-credit sheet |
| SFX | 23 | 23 | 15 | Two takes each |
| App icon, screenshot backgrounds | 2 | 14 | 14 | Kept at plan |
| **Core subtotal** | | **2,157** | **about 1,400** | |
| Contingency 20% | | | about 280 | |
| **Core total** | | | **about 1,680** | |
| Optional voice lines | | 125 | 125 | Untested; kept at plan |

Against the current balance of 730.48: **about 950 credits to buy for the core game, about 1,075 with voice.** The money cost depends on your Higgsfield plan's top-up price: **TBD, check the plan page before phase 3**. Buy in stages, about 300 at a time, and re-project after each stage.

**Biggest risk to this number:** the boss and large-character animations (Giant Despair 80x112, Apollyon 112x112), which are about 12 assets. If the video method fails at that size, plan on 30 each instead of 14. That adds about 190.

## Time

| | Planned | Actual |
|---|---|---|
| Claude working sessions, phase 2 | 8 to 12 | 1 long session (2026-11-23 to 2026-11-24) |
| Owner time, phase 2 | about 4 hours | TBD: your estimate |
| Calendar | by 2026-12-21 | Slice playable 2026-11-24 |

The schedule's phase 3 dates (2027-01-04 to 2027-03-28) can move earlier. The real limits are your review time and the credit top-ups, not build time. I will propose new dates after the TestFlight test.
