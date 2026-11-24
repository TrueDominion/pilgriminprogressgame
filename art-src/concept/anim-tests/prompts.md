# Animation test prompts (2026-11-24)

CON-anim-01: seedance_2_5, mode omni_reference, 480p, 4 s, 1:1, no audio, 12 credits.
start_image = end_image = CON-sprite-03 (job 0916d8f5-514b-41ea-a105-dd56c48898e2).

Prompt: "Smooth looping walk cycle in place: the character walks forward on the spot with natural steps, legs alternating, gentle body bob, staff moving with the stride. Keep the exact same blocky low-resolution pixel art style, same large square pixels, same colours, no smoothing. Camera locked, no camera movement, no zoom, subject stays fully in frame, plain static flat magenta background. The character performs ONLY this walk, nothing else happens; the staff stays in his hand and is never swung or raised. The character keeps facing right for the entire video, never turns around, never rotates toward or away from the camera."

Output: 640x640, 24 fps, 97 frames. Sheet: tools/frames_to_sheet.py --frames 12 --cell 40x56 --char-height 48 --fps 10 --loop (11 frames after loop de-duplication).
