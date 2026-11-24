# Christian (burdened): prompts and settings (2026-11-24)

Base sprite A: nano_banana_pro (served nano_banana_2), 1k, 1:1, references CON-sprite-03 (small style and face) and CON-style-01 (burden design). Job abe95453-da7e-4c9a-8fb5-77a76717298b.
Prompt core: "A tiny low-resolution pixel art game sprite of this same pilgrim ... carrying his burden ... an enormous grey-brown sack bound with rope on his back, bigger than his torso, so heavy he is bent forward. Side view facing right ... about 56 pixels tall including the sack ... flat pure magenta (#ff00ff) background."

Videos: seedance_2_5, omni_reference, 480p, 4 s, 1:1, no audio, start frame base A; loops (idle, walk, wade) also use base A as the end frame.
Every prompt = one action + "Keep the exact same blocky low-resolution pixel art style ... Camera locked ... plain static flat magenta background. The character performs ONLY this ... He keeps facing right for the entire video ..."

| Action | Video | Sheet settings (tools/frames_to_sheet.py, --ref-height 502) |
|---|---|---|
| idle | 92de0466 | 9 frames (8 after loop de-dup), 6 fps, loop |
| walk | f7a06332 | 11 (10), 9 fps, loop |
| jump | 326250e7 | 0.26 to 0.375 of the video, 4 frames, 12 fps, --pose-only |
| fall | 326250e7 | 0.385 to 0.49, 3 frames, 10 fps, --pose-only |
| land | 326250e7 | 0.5 to 0.625, 3 frames, 14 fps, --pose-only |
| hurt | 555bdefe | first half, 6 frames, 12 fps |
| interact | da597c28 | 8 frames, 10 fps |
| read | 6f0c5032 | 10 frames, 8 fps |
| wade | 449fd286 | loop |
