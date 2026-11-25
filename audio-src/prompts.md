# Stage 1 audio prompts (2026-11-24)

Music: sonilo_music, 90 s, 5.63 credits each. Built by tools/build_audio.py (3 s loop crossfade, -18 LUFS, OGG q3). Take used: design/audio-choices.json.
| File | Job | Prompt summary |
|---|---|---|
| title-a | 0e77e2f6 | Recorder and lute over string drone, English folk-hymn melody, D major, 72 bpm, hopeful, no drums |
| title-b | c3f3426d | Harp and wooden flute over soft organ, folk-hymn melody, G major, 70 bpm, a long road and a distant light |
| stage1-a | 81351b79 | Cello/viola ostinato, sorrowful oboe, D minor, frame drum like a heavy footstep, 76 bpm, burden with a thread of hope |
| stage1-b | c50aa831 | Pizzicato bass, hurdy-gurdy drone, recorder tune in A minor lifting toward hope, 80 bpm |

SFX: mirelo_text_to_audio, 1-2 s, 0.25-0.5 credits each. Built by tools/build_audio.py (silence trim, peak -3 dBFS, mono OGG q4).
jump, jump_burdened, land, land_heavy, step_stone, step_grass, step_mud, light, scroll, checkpoint, book, dialogue, menu_move, menu_select, respawn. Each prompt asked for one isolated, dry sound (no music).

# Stage 2 audio prompts (2026-11-25)

| File | Job | Prompt summary |
|---|---|---|
| stage2-a | b81eed4d | Low cello drone, slow sorrowful solo viola, sparse plucked harp like dripping water, E minor, 66 bpm, no drums; despair but not horror |
| stage2-b | f7eea322 | Muted hurdy-gurdy drone, low recorder melody in D dorian, soft frame drum like slow wading steps, 70 bpm, small rising hope near the end |

SFX (mirelo_text_to_audio): mud_squelch_a 4fd3195e and mud_squelch_b fa067f18 (stepping into mud, one picked at random), mud_bubble 2475d7cc (while sinking, louder and higher as he sinks), mud_pull 9d32518a (Help pulls him out).

# Stage 3 audio prompts (2026-11-25)

| File | Job | Prompt summary |
|---|---|---|
| stage3-a | 83e09eed | Steady low-string walking pulse, lute and recorder in G dorian, soft frame drum undercurrent, 84 bpm, resolute and hopeful |
| stage3-b | 9e93c3df | Hurdy-gurdy drone, plucked viol bass ostinato, tin whistle in D minor rising to D major, light tabor, 88 bpm, courage under pressure |

SFX (mirelo_text_to_audio): hurt 26daab7f (soft knock-back thud, no voice), knock ac8f3091 (three knocks on a wooden door), arrow dc3fa820 (whistle and thud, once per volley), rockfall a94c7378 (rock crashing on stony ground).
