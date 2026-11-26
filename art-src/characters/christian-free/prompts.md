# Christian (free, after the Cross): prompts and settings (2026-11-26)

Start frame for every video: CON-sprite-03 (job 0916d8f5-514b-41ea-a105-dd56c48898e2), the small free-Christian sprite also used for the walk test. Loops (idle, run) use it as the end frame too.
Videos: seedance_2_5, omni_reference, 480p, 4 s, 1:1, 12 credits each.
Every prompt = one action + "Keep the exact same blocky low-resolution pixel art style, the same character and the same pixel size as the start frame. Camera locked, no zoom, no pan, plain static flat magenta background. The character performs ONLY this action ... He keeps facing right for the entire video. No other characters, no text, no sack or burden on his back."

Sheets: tools/frames_to_sheet.py, cell 40x56, --char-height 48, --ref-height 590 (the walk test's subject height), so every free sheet shares one pixel size.

| Sheet | Video | Action in the prompt | Settings |
|---|---|---|---|
| walk (the run) | ee39e59a | light, joyful, upright run cycle in place | 11 frames (10 after loop de-dup), 12 fps, loop |
| interact | 87f88ea3 | reaches forward to open or pick up something | 8 frames, 10 fps |
| jump | acf7b9a5 | crouch, high light jump with arms raised, land | 0.25 to 0.41, 4 frames, 12 fps, --pose-only |
| fall | acf7b9a5 | (same video) | 0.58 to 0.72, 3 frames, 10 fps, --pose-only |
| land | acf7b9a5 | (same video) | 0.76 to 0.88, 3 frames, 14 fps, --pose-only |
| double_jump | 77f16578 | tucked somersault at the top of a jump | 0.2 to 0.54, 8 frames, 16 fps, --pose-only |
| hurt | 1d3da2dc | knocked back a step, flinching, recovers | first half, 6 frames, 12 fps |
| idle | 6973f63b, redone as 10467042 | calm breathing idle; the first take dropped his staff, so the redo names the staff in every frame | loop |
| read | 73ec7500 | takes the Book from his satchel, reads, puts it back | |

In the jump video his raised hands touch the top edge of the frame in mid-air; only fingertips are lost.
