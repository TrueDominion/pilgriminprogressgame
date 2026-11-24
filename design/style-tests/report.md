# Style Test Report (CON-style-01 to 10)

Date: 2026-11-23. Spent: 20 credits (estimate 20). Balance after: 888.5.
Raw images: `art-src/concept/style-tests/`. Contact sheets: `contact-1.jpg` to `contact-3.jpg`. Pipeline output: `pipeline-result.png`.

## Verdict

The style formula works for **character reference sheets, stills, UI and the overall look**. It fails, as expected, for **tilesets** and **Apollyon**. It also exposed one problem I had not planned for: **sprite scale.** That needs a decision before the Christian animation batch.

| # | Asset | Result | Use |
|---|---|---|---|
| 01 | Christian reference sheet | Strong. Consistent across front, side and back; reads as Bunyan's pilgrim | Keep as Christian's reference |
| 02 | Christian walk key pose | Good look, but drawn about 190 art pixels tall | Look reference only (see finding 1) |
| 03 | Evangelist sheet | Strong | Keep as Evangelist's reference |
| 04 | City skyline layer | Good mood; shows flames on buildings despite "smoke only" | Usable for the far layer; flames on buildings only, no people |
| 05 | Slough layer | Partial: magenta bands, sky not isolated | Regenerate in phase 3 with a stricter layer prompt |
| 06 | Tileset | Not a usable 16x16 tileset (mixed scales, no consistent grid) | Rejected: tilesets will be built by hand from generated textures |
| 07 | Burden falls (still) | Strong; the best emotional image so far | Keep as the stage 4 still direction |
| 08 | Apollyon | Comic, green, off-palette; not dramatic | Rejected: redo with the Monsters studio as planned |
| 09 | UI kit | Near production-ready; clean on a 99x99 art grid | Keep |
| 10 | Gameplay mock | Sets the target look for Stage 1 | Keep as the Stage 1 target |

Note: I requested `nano_banana_pro`; Higgsfield's job records say `nano_banana_2` served them, at the quoted price. Recorded in `assets.csv`.

## Findings

**1. Sprite scale (decision needed).** The model draws characters at about 190 art pixels tall. Our sprite is 40 pixels tall. Shrinking 5x destroys the art (see the middle of `pipeline-result.png`): no tool can invent a readable small sprite from a large one. The UI kit shows the way out: when asked for small elements, the model draws on a coarse grid (one art pixel = 10 real pixels) and the result shrinks cleanly. So key poses must be prompted as tiny sprites ("a 32x48 pixel game sprite, shown enlarged"), and then animated. This is untested. **Recommendation:** spend about 10 credits on 5 small-sprite prompt tests before the 180-credit animation batch.

**2. Generated pixel art is not on a whole-number grid.** One art pixel was 4.24 real pixels in test 01, not 4. The pipeline now detects fractional grids (Fourier analysis of colour edges) and samples one colour per art pixel. Verified on all 10 images.

**3. Models ignore exact key colours.** Test 09 came back on a muted magenta (#b1437f), not #ff00ff. The pipeline now reads the key from the image border.

**4. Background scale.** The gameplay mock was drawn at about 320x178 art pixels, smaller than our 480x270 screen. A single generated image will not cover a 416-pixel-tall parallax layer at 1:1. Layers will need outpainting or stacking (already budgeted at 8 credits per layer). Confirm on the first Stage 1 layer.

**5. Palette fit.** Generated colours sat a mean of 6.5 to 7.3 delta E from the master palette (7 to 17% of pixels moved more than 10). After mapping, the look holds (see `pipeline-result.png`), so the 48-colour palette is adequate.

## Next

1. Owner decision: approve about 10 credits for small-sprite tests (finding 1).
2. If small sprites work, run the Christian animation batch (about 180 credits) for approval.
3. Tilesets: build Stage 1's tileset from generated texture swatches plus manual assembly in phase 2. This is the human pixel work flagged in risk R1.

---

# Small-sprite tests (CON-sprite-01 to 05)

Date: 2026-11-24. Spent: 9 credits (estimate 9). Balance after: 879.5.
Images: `sprite-tests-raw.jpg` (as generated), `sprite-tests-true-size-4x.png` (after the pipeline, true pixels shown at 4x), `sprite-tests-downscale-4x.png` (shrunk to candidate game sizes).

## Verdict

**Finding 1 is solved, with a size change.** Prompted as a tiny sprite, the model draws genuine low-resolution pixel art that survives the pipeline cleanly. It does not hit an exact size: asked for 40 px tall, it drew 30, 59 and 85. The good results (Christian without the burden at 59 px, Evangelist at 85 px) stay readable when shrunk to **48 px**, and start to break down at 40 px.

| # | Result | True size |
|---|---|---|
| 01 Christian burdened | Clean but crude; head and sack lose definition | 26 x 30 |
| 02 Walk cycle drawn directly | Failed: overlapping high-res figures, not usable frames | n/a |
| 03 Christian free | Clean, readable, on model | 31 x 59 |
| 04 Evangelist | Excellent | 41 x 85 |
| 05 flux_2 | Failed: drawn at high resolution on a gradient background | n/a |

## Recommendation (owner decision)

1. **Raise the character height from 40 to 48 px** (adults 46 to 52 px; sprite cell 40 x 56 to fit the burden and the staff). The 16 px tile, the 480 x 270 view and every movement value stay as they are. The hitbox grows from 30 to 36 px tall to match the taller body; jump reach is set by the feet, so the measured step and gap limits do not change (the reach test re-confirms this in CI). Christian becomes 3 tiles tall, so the burdened jump (2.5 tiles) is lower than his own height, which suits the Burden.
2. **Key poses from nano_banana (tiny-sprite prompt)**, not flux_2. Generate at 50 to 90 px, then shrink to 48 px (at most about 1.8x), then palette-map. Expect a light pixel touch-up on faces and hands.
3. **Animation stays on the video pipeline.** Drawing a walk cycle directly failed. The remaining unknown is whether the video model keeps the blocky pixels when it animates a tiny sprite. **Next test: one 4-second walk video from sprite 03 (12 credits)** before the 180-credit Christian batch.

---

# Walk video test (CON-anim-01)

Date: 2026-11-24. Spent: 12 credits (estimate 12). Balance after: 867.5.
Images: `walk-video-frames.png` (raw video frames), `walk-sheet-4x.png` (finished sheet, 11 frames at 4x), `walk-in-game.png` (in the web build).

## Verdict: the animation pipeline works

| Check | Result |
|---|---|
| Pixel style kept through the video | Yes: blocky pixels, same colours |
| Same character in every frame | Yes |
| Facing locked, camera locked | Yes |
| Loop closes (start = end frame) | Yes |
| Legs alternate, reads as a walk at 48 px | Yes, though the stride is short |
| Automated checks (palette, alpha, scale) | Pass |
| Defects | Light flicker on face and beard between frames; stride too small for a 120 px/s run |

The sheet is in the game now as Christian's free walk (placeholder until the final set).

## Recommendations for the Christian batch

1. Ask for a longer stride ("long confident strides, knees lifting") on walk and run.
2. Burdened key pose first: test 01 (burdened) was too crude. Generate 2 burdened key poses (4 credits), pick the better one, then animate.
3. 8 to 12 frames per loop. Expect a light hand cleanup on faces (about 15 minutes per sheet), the human pass from risk R1.
4. Re-quote: 9 burdened animations at 12 credits each plus key poses and up to 1.5x rerolls: about 170 credits.
