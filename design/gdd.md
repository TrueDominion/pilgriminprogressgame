# Pilgrim in Progress: Game Design Document (v1)

Status: phase 1 draft for owner approval. Date: 2026-11-23.
Scope rule: this document refines the master prompt. It adds nothing the prompt did not ask for, except where marked **[added]** with the reason.

---

## 1. The game in one sentence

The player feels the weight of the journey, and then the relief of grace, because the burden is a real physical handicap that is lifted at the Cross.

**Design test for every feature:** does it make the burden heavier before the Cross, or the freedom sweeter after it? If neither, it is a candidate for cutting.

## 2. Audience, tone, platform

| | |
|---|---|
| Audience | Ages 8 and up. Families, church groups, adults who know the book. |
| Tone | Faithful to Bunyan. Dialogue lightly modernised. Scripture in KJV. Bosses dramatic, never frightening: no gore, no death animation, no jump scares. |
| Session length | One stage = 3 to 6 minutes. A full playthrough targets 45 to 60 minutes first time, 30 minutes for a skilled replay. |
| Platform | iOS (primary, landscape only), web (playtests), macOS (optional). |
| Price model | One-time paid. No ads, no in-app purchases, no accounts, no data collected. |

## 3. Core loop

Traverse → meet an obstacle, NPC or temptation → choose or overcome → collect Light → reach a checkpoint → earn a reward that unlocks a new ability.

Per stage the loop runs 4 to 6 times (one per checkpoint section), and the stage reward closes it.

## 4. Movement (frozen numbers)

All values live in `game/data/movement.json`. Units are pixels and seconds; 1 tile is 16 px. The view is at least 30 x 17 tiles.

### 4.1 Burdened vs free

| Value | Burdened (stages 1 to 4) | Free (after the Cross) | Felt difference |
|---|---|---|---|
| Run speed | 78 px/s (4.9 tiles/s) | 120 px/s (7.5 tiles/s) | +54% speed |
| Ground acceleration / deceleration | 500 / 700 px/s² | 900 / 1200 px/s² | Heavy starts and slides vs crisp control |
| Jump height | 40 px (2.5 tiles) | 56 px (3.5 tiles) | Clears 2 tiles vs 3 |
| Time to apex | 0.28 s | 0.36 s | Burdened jumps are short and stubby |
| Fall gravity | 1740 px/s² (1.75x rise) | 1382 px/s² (1.6x rise) | Burdened drops like a stone |
| Max fall speed | 400 px/s | 360 px/s | |
| Double jump | No | Yes, +40 px (2.5 tiles) | The signature reward |
| Heavy landing | Falls over 3 tiles cause 0.25 s stagger (no damage) | None | Every big drop reminds you of the load |
| Mud sink speed | 14 px/s | 6 px/s | Standing still in the Slough is dangerous |
| Hitbox | 14 x 30 | 12 x 30 | The burden makes you wider |

Shared: coyote time 0.10 s, jump buffer 0.12 s, variable jump height (releasing Jump early cuts upward speed), 4 px ledge nudge so near-miss corners do not stop the player.

### 4.2 Why these numbers

- The burdened set is tuned so a player who has never played a platformer can still finish stages 1 to 3. Gaps and steps are small, checkpoints are frequent, nothing is fast.
- The free set is a normal, responsive modern platformer. The contrast does the storytelling: the first jump after the Cross should make players laugh.
- Burden penalty is mainly speed and jump height, not slippery control. Slippery control frustrates children; slowness and short jumps read as weight without being unfair.

### 4.3 Level design limits

Measured with the real controller by `game/tests/movement_test.tscn` (runs in CI). The measured gap reach is one tile more than the phase 1 paper estimate, because a player only needs the hitbox's leading edge to reach the far ledge and can still jump for 0.1 s after leaving an edge (coyote time). Steps matched the estimate exactly.

| | Max step up | Max gap (well-timed) | Gap allowed on the critical path |
|---|---|---|---|
| Burdened | 2 tiles | 3 tiles | 2 tiles |
| Free, single jump | 3 tiles | 5 tiles | 4 tiles |
| Free, double jump | 5 tiles | 8 tiles | 7 tiles |

Required jumps use the critical-path column. Optional Scroll routes may use the full maximum. Re-run the test after any change to `movement.json`.

### 4.4 Tuning rule

Change one value at a time. Log every change in `design/tuning-log.md` with the build number, the reason and the playtest note. The phase 2 vertical slice is where these numbers get their first real test; I expect speed and gravity to move by up to 15% after hands-on play. That is normal, not a failure of the plan.

## 5. Abilities and items

| Stage | Reward | What it adds | Data flag |
|---|---|---|---|
| Start | Move, jump, talk | Base abilities | n/a |
| 1 | The Book | Interact with signposts to read a hint; reading certain signs reveals hidden platforms for 8 s | `has_book` |
| 4 | Burden removed | Free movement set, double jump | `burden_off` |
| 4 | The Roll **[added from the book]** | Story item given at the Cross. Lost if Christian rests too long in the arbour (stage 5). No gameplay effect except at the arbour. Needed because the prompt's stage 5 arbour beat depends on it. | `has_roll` |
| 5 | Sword | Attack | `has_sword` |
| 5 | Shield | Hold to block; deflects projectiles back toward the source | `has_shield` |
| 5 | Helmet | Hope 3 → 4 | `has_helmet` |
| 7 | Hopeful | Companion: follows, offers a hint on request, and once per checkpoint catches Christian from a failure (restores 1 Hope in place instead of respawning) | `has_hopeful` |
| 8 | Key called Promise | Opens locks | `has_key` |

The prompt's ability table lists Hopeful at 7 and the Key at 8 out of order; the stage order is correct and I have kept it.

## 6. Health, failure, checkpoints

- **Hope:** 3 points (4 with the Helmet). Shown as small lamps in the top-left safe area.
- **Damage:** 1 Hope per hit, 1.0 s of invulnerability with a soft blink (no red flash when "Reduce flashing" is on), 24 px knockback.
- **Failure:** at 0 Hope, or on falling into a pit or deep water, the screen fades to parchment in 0.6 s and Christian stands at the last checkpoint with full Hope. No death animation, no "game over" screen, no lives.
- **Checkpoints:** a wayside cross-marker or lantern. Spacing target: 30 to 60 seconds of play. Touching one saves the stage state (Light, Scrolls, position) to the active save slot.
- **Light motes kept on failure.** Losing collectibles on failure punishes children for exploring. Light counts only as "collected" when you reach the next checkpoint, so it is still meaningful.
- **Pilgrim's Aid (assist option) [added, accessibility]:** in Settings. Hazards cost no Hope; pits return you to the last safe ground. Off by default, no penalty, no shaming text. Reason: an 8-year-old or a grandparent must be able to see the ending.

## 7. Collectibles

| | Count | Purpose |
|---|---|---|
| Light motes | 60 to 100 per stage | Score per stage; spent (and lost) at Vanity Fair stalls. Total shown on the world map. |
| Scrolls | 3 hidden per stage, 27 total | Each unlocks one codex entry (KJV verse or Bunyan quote). Collecting all 27 unlocks an epilogue illustration in the codex. |

Light has no shop outside Vanity Fair. It is a measure, not a currency: the only thing you can "buy" with it in the whole game is a heavier load. That is the Vanity Fair lesson, so keep it that way.

## 8. Stages (summary)

Full outlines are in `design/levels/stageN.md`.

| # | Stage | Movement set | New mechanic | Reward | Target time |
|---|---|---|---|---|---|
| 1 | City of Destruction | Burdened | Walk, jump, talk, read signs | The Book | 3 to 4 min |
| 2 | Slough of Despond | Burdened | Sinking mud, Book-revealed stepping stones | Help (story) | 4 to 5 min |
| 3 | Wicket Gate | Burdened | Wrong-way shortcut (Sinai), arrows | Goodwill (story) | 4 to 5 min |
| 4 | Interpreter's House and the Cross | Burdened → free | Two puzzle rooms, walled climb, burden cutscene | Burden off, double jump, Roll | 5 to 6 min |
| 5 | Hill Difficulty and Palace Beautiful | Free | Vertical climb, trap side paths, arbour timer, chained lions | Sword, Shield, Helmet | 5 to 6 min |
| 6 | Valley of Humiliation and the Shadow of Death | Free + armour | Apollyon boss (3 phases), lamp-radius darkness | Faithful joins (story) | 5 to 6 min |
| 7 | Vanity Fair | Free + armour | Stalls that pull and add weight | Hopeful | 4 to 5 min |
| 8 | Doubting Castle | Free + armour + Hopeful | Capture, stealth, sunlight stun | Key called Promise | 5 to 6 min |
| 9 | To the Celestial City | Free + armour + Hopeful | Telescope, dimming ground, rising river | Finale | 5 to 6 min |

## 9. Bosses and threats

- **Apollyon (stage 6):** 3 phases, 12 hit points total. Phase 1: he hovers and throws fiery darts; the player blocks and deflects them back (4 deflected hits). Phase 2: he lands and swipes; the player dodges and strikes with the Sword when he recovers (4 hits). Phase 3: he combines both and covers the floor in short-lived fire; a sword hit after a deflect does double. When he falls, Christian says "Rejoice not against me, O mine enemy: when I fall, I shall arise" (Micah 7:8), and Apollyon flies away. He is never killed on screen.
- **Giant Despair (stage 8):** not fought. Stealth patrols with a visible sight cone. Sunlight through high windows stuns him for 3 s. Being caught sends Christian back to the cell checkpoint, not to 0 Hope.
- **Common hazards:** mud, arrows, falling rocks (Sinai), chained lions (safe in the middle lane), pits, fire darts, deep water.
- **No generic enemies to kill.** Christian never fights people. The only sword targets are Apollyon and a few breakable objects. **[clarification]** This is a deliberate reading of the book and of the 8+ audience.

## 10. Narrative delivery

- **Dialogue boxes** with portrait, speaker name and up to 3 lines; tap, Action or A to advance; hold to fast-forward. All text from `content/dialogue/stageN.csv`.
- **Choices** appear at the prototype's key moments (stay or flee, Worldly Wiseman, the Fair). A wrong choice is never a fail state: it plays out (Sinai collapses, the stalls weigh you down) and the player walks back.
- **Cutscenes** are in-engine: the same sprites plus 1 to 3 full-screen illustrated stills per stage (opening, the burden falling, Apollyon's arrival, the River, the City). No pre-rendered video in v1; it keeps the build small and avoids style drift.
- **Narrator:** optional voice lines for the narrator and Evangelist only (section 13 of the master prompt). Recommendation: decide after the phase 2 slice; budget is held separately.

## 11. Controls

Every action works on every input method.

| Action | Touch | Gamepad (MFi, Xbox, PlayStation) | Keyboard (physical keys) |
|---|---|---|---|
| Move | Virtual stick, left side (or D-pad option) | Left stick / D-pad | A D or ← → |
| Look down / crouch | Stick down | Down | S or ↓ |
| Jump | Right button | A / Cross | Space, K, or ↑ |
| Action (talk, read, attack) | Right button 2 | X / Square | J or E |
| Block (after stage 5) | Right button 3, hold | Left/right shoulder, hold | L or Shift |
| Pause | Top-right icon | Menu / Options | Esc or P |

Touch rules: buttons at least 44 x 44 pt (Apple's minimum), placed inside the safe area, never under the home indicator. Layout options: left-handed swap, size (S/M/L), opacity (20 to 100%), stick or D-pad. The block button appears only after stage 5.

## 12. Save system

- 3 local save slots, stored with Godot's `user://` path (iOS app sandbox; nothing leaves the device).
- Saved per slot: current stage, checkpoint id, Light per stage, Scrolls collected, flags (section 5), playtime, settings are global not per slot.
- Autosave at every checkpoint and stage end. No manual save needed.
- iCloud sync: not in v1. It would require an Apple entitlement and changes nothing for a 1-hour game.

## 13. Accessibility (v1)

Text size (3 steps), dialogue speed (3 steps, plus instant), screen-shake toggle, reduce-flashing toggle, touch layout and opacity, audio sliders (music, effects, voice), Pilgrim's Aid, high-contrast dialogue box option, and full gamepad and keyboard support. Colour is never the only signal for a hazard.

## 14. Technical budget (fixed before code)

Target: locked 60 fps on iPhone 12 (A14) native build. Web build targets 60 fps on a 2020 MacBook Air in Safari and Chrome; web is for playtesting, not the performance reference.

| Budget per frame (16.6 ms) | Limit |
|---|---|
| Game logic + physics | 4 ms |
| Rendering (CPU side) | 5 ms |
| Audio + other | 1 ms |
| Headroom for spikes | 6.6 ms |

| Resource | Limit | Why |
|---|---|---|
| Draw calls | under 150 | Compatibility renderer on mobile GPUs |
| Parallax layers | 5 per stage max | Overdraw on full-screen layers is the main GPU cost |
| Texture atlases | 2048 x 2048 max per atlas, sprite sheets 4096 max side | Older device limits and memory |
| Texture memory per stage | 64 MB | Leaves room on 4 GB devices |
| Active physics bodies | under 60 | |
| Light2D nodes | 0 except stage 6 darkness and stage 8 sunlight (max 4) | Light2D is expensive on Compatibility |
| Music | OGG Vorbis, 96 kbps stereo, streamed | |
| SFX | WAV 22 kHz mono for short sounds, OGG for long | |
| App download size | under 150 MB | Faster install over cellular |

Profile on device at the end of phase 2 and again in phase 4. If the iPhone 12 drops frames, cut overdraw first (parallax layers), then particles.

## 15. Localisation readiness

All player-visible strings come from CSV with a key column and an `en` column. Godot's TranslationServer reads CSV directly, so adding a language later is a data task. The UI must tolerate text 40% longer than English. v1 ships English only.

## 16. Out of scope for v1

New Game Plus, achievements via Game Center, iCloud saves, Christiana's journey (Part II), multiplayer, Android. Each is a reasonable v1.1 idea. None should enter v1.
