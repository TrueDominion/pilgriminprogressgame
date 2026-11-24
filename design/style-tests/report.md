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
