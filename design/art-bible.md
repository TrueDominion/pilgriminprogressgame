# Art Bible (v1)

Status: phase 1 draft for owner approval. Nothing here has been generated yet.

## 1. Look in one line

A warm storybook told in honest pixels: chunky 16-pixel tiles, readable silhouettes, deep night-purple shadows and parchment-gold light, like a 1990s 16-bit adventure printed on old paper.

## 2. Hard rules

1. **Real pixel art.** Every pixel is the same size. No anti-aliasing, no blur, no gradients except dithered ones, no sub-pixel rotation. Engine filtering is nearest-neighbour everywhere.
2. **One grid.** Tiles are 16 x 16. The player cell is 32 x 48 (Christian himself is about 20 x 40 inside it, burden adds 8 px of width). NPCs share the player's scale: adults 40 to 44 px tall, children not used. Bosses: Apollyon 96 x 96 cell, Giant Despair 64 x 96 cell.
3. **One palette.** The 48 colours in `design/palette.gpl` are the only colours in the game. Anchors (night #1d1530, ink #241a38, parchment #f4ead5, gold #f0b94d, ember #c4513a, moss #6a8f4e) come from the web prototype. Any asset with an off-palette pixel fails the consistency check.
4. **Light comes from the upper left** in every asset, so sprites and backgrounds agree.
5. **Outlines:** sprites have a 1 px dark outline in ink #241a38 (or the darkest ramp colour of the adjacent area); backgrounds have no outlines. This keeps characters readable against busy parallax.
6. **Silhouette first.** Every character must be identifiable as a black silhouette at 1x. Christian's burden is the biggest silhouette element in stages 1 to 4 on purpose.
7. **Depth by value, not detail.** Far parallax layers use the night and sky ramps at low contrast; the gameplay layer has the strongest contrast; the near foreground layer is darkest.

## 3. Palette use

| Ramp | Colours | Used for |
|---|---|---|
| night | 6 | Shadows, night skies, UI backgrounds, outlines |
| parchment | 8 | Skin (light to deep, 4 tones), cloth, paper, UI panels, light stone |
| gold | 5 | Light motes, the shining light, the Cross dawn, UI highlights, the Key |
| ember | 6 | Fire, the burning city sky, Apollyon, danger accents, deep skin tone shadows |
| moss | 7 | Fields, hedges, Slough water and mud tints, the Delectable Mountains |
| sky | 7 | Skies, water, the River, the Shining Ones |
| earth | 4 | Mud, wood, the burden, roads |
| stone | 4 | Walls, castles, Sinai, armour |
| accent | 1 | Vanity Fair finery only (#b83a6b) |

Skin tones: characters are drawn from the parchment and earth ramps across a realistic range. Bunyan's pilgrims are not described physically; the cast should not all share one skin tone. **[owner decision on cast appearance in the character sheets]**

The sprite **key colour** for generation backgrounds is pure magenta #ff00ff (not in the palette). If a subject contains magenta-adjacent colour (Vanity Fair merchants), use pure cyan #00ffff.

## 4. The style formula

Pasted verbatim into every image prompt, after the subject description. Do not edit without approval; every edit invalidates consistency with earlier assets.

> 16-bit era pixel art for a side-scrolling adventure game, crisp hard-edged pixels on a strict 16 pixel grid, every pixel the same size, no anti-aliasing, no blur, no gradients except ordered dithering, limited palette of deep night purples, warm parchment creams, glowing gold, ember red-orange and soft moss green, 1 pixel dark purple outline on characters, light from the upper left, readable chunky silhouettes, warm storybook mood inspired by an illustrated 17th-century English allegory, no text, no logos, no watermark.

Per asset type, add one line after the formula:

| Type | Extra line |
|---|---|
| Character sheet | "character reference sheet: full body front, side profile facing right, and back view, standing neutral pose, evenly spaced on a flat pure magenta (#ff00ff) background, no shadow on the ground" |
| Sprite key pose | "single character, full body, side view facing right, large empty margin above the head and below the feet, flat pure magenta (#ff00ff) background" |
| Parallax layer | "one isolated background layer for parallax: [far sky / distant hills / mid buildings / near foliage], wide panoramic, transparent or flat magenta where the layer is empty, no characters" |
| Tileset | "top-down-free side-view tileset sheet of 16x16 tiles on a grid: ground top, ground fill, left and right edges, inner and outer corners, one-way platform, decorative variants, flat magenta background" |
| Prop | "single object, centred, flat pure magenta background, side view" |
| UI | "game UI element, flat front view, pixel art frame, flat magenta background" |
| Still (cutscene) | "full scene illustration in the same pixel art style, 16:9, cinematic composition" |

Recommended models (verify each at generation time; Higgsfield changes its catalogue): character sheets and stills `nano_banana_pro` (2 credits); key poses `flux_2` (1 credit) with the character sheet as reference; backgrounds and props `gpt_image_2_6` (0.75 credits) or `nano_banana_pro` where detail matters; sprite animation `seedance_2_5` at 480p, 4 s (12 credits).

## 5. Character reference sheets

One sheet per recurring character, generated first and then used as the reference image for every later generation of that character. Stored in `art-src/characters/<id>/sheet.png` with the prompt in `prompt.md`.

| Id | Character | Look notes | Sprite sets |
|---|---|---|---|
| CHR-christian-burden | Christian with the burden | Rough brown tunic and rags, hood down, bare feet in sandals, the Book in a satchel; the burden is a huge grey-brown sack bound with rope, bigger than his torso | Full set A (burdened) |
| CHR-christian-free | Christian without the burden | Same face; after the Cross he wears new white-and-gold clothes (the Shining Ones' gift) | Full set B (free) |
| CHR-christian-armour | Christian armoured | Free outfit plus a simple steel helmet, plain round shield with a gold sun emblem, short sword. **[owner decision]** I recommend against a cross on the shield: a cross on armour reads as crusader imagery, which is a needless offence for players in the Gulf and elsewhere. The Cross stays where Bunyan puts it, on the hill | Set C (adds attack, block) |
| CHR-evangelist | Evangelist | Tall, older, dark blue cloak, staff, kind face, points | Idle, point |
| CHR-pliable | Pliable | Young, eager, bright yellow tunic, easily distracted | Idle, walk |
| CHR-obstinate | Obstinate | Stout, scowling, red vest, arms crossed | Idle, argue |
| CHR-help | Help | Broad-brimmed hat, blue cloak (as in the prototype's Slough image) | Idle, reach |
| CHR-goodwill | Goodwill | Gatekeeper, grey beard, lantern | Idle, welcome |
| CHR-faithful | Faithful | Christian's age, green travelling cloak, steady expression | Idle, walk |
| CHR-hopeful | Hopeful | Younger, sky-blue tunic, warm smile, carries a small lamp | Full follower set (idle, walk, jump, fall, help) |
| CHR-giant-despair | Giant Despair | Huge, hunched, shaggy grey, crab-apple club, bleary eyes, more grumpy than evil | Patrol walk, idle, alert, stunned |
| CHR-apollyon | Apollyon | Scales like a fish, wings like a dragon, feet like a bear, smoke from his belly (Bunyan's description); ember and night ramps; dramatic, not gory | Hover, land, dart throw, swipe, hurt, flee |

Minor NPCs (Worldly Wiseman, Interpreter, Watchful, the four Palace women, Timorous and Mistrust, Formalist and Hypocrisy, merchants, shepherds, Shining Ones, townsfolk) get a single key-pose image each, no reference sheet, and use procedural idle motion in the engine (a 1 px breathing bob and a talk squash). This saves about 300 credits against animating them.

## 6. Backgrounds

- 3 to 5 parallax layers per stage, generated as **separate layers**, never one image cut apart.
- Layer heights cover the maximum view height (416 px) plus 32 px; widths are the level length times the layer's scroll factor, built by outpainting or by seamless horizontal tiling.
- Layer set per stage: L0 sky (static or 0.05), L1 far (0.15), L2 mid (0.35), L3 near (0.6), L4 foreground silhouettes (1.2, optional, used sparingly because it hides gameplay).
- Each layer uses at most 12 palette colours; far layers use the low-contrast end of each ramp.

## 7. Tilesets

- One base tileset per stage (16 x 16 tiles, about 48 tiles): ground top, fill, edges, inner and outer corners, slopes (1:1 and 1:2), one-way platforms, hazard tiles, decoration.
- Generated as a sheet, then cut and cleaned. **Honest expectation:** AI-generated tilesets do not tile seamlessly. Every tileset will need a manual seam pass (an estimated 1 to 2 hours per tileset in Aseprite or LibreSprite). I will list the seams that need fixing after testing each set in a Godot TileMapLayer; whether you, a hired pixel artist, or I (via scripted edits) fix them is a phase 2 decision.

## 8. Pipeline (scripts in `/tools`, built in phase 2)

Every generated asset goes through these steps, in order. The raw output and the prompt are saved to `/art-src` first, so every step can be rerun.

1. **Shrink:** detect the generated image's effective pixel size (AI pixel art is usually drawn at 4 to 8 real pixels per "pixel") and downscale with nearest-neighbour to the true grid.
2. **Palette map:** map every pixel to the nearest colour in `palette.gpl` (perceptual distance, CIEDE2000). Report the percentage of pixels that moved more than a threshold, a quality signal.
3. **Remove the background:** chroma-key the flat magenta or cyan key colour locally. This is free and gives hard pixel edges, which suits pixel art better than an AI matte. Higgsfield's background remover is the fallback only when the key fails.
4. **Consistency check (once per stage batch):** off-palette pixels, mixed pixel sizes, stray semi-transparent pixels, outline colour, light direction (manual), and a side-by-side contact sheet against the character's reference sheet.

Animated sprites follow Higgsfield's video-to-sprite-sheet workflow (loaded and read in phase 1):

1. Key pose with `flux_2`, reference sheet attached, at the action's peak phase, large margins, magenta key background.
2. 4-second video with `seedance_2_5`, 480p, aspect ratio passed explicitly to match the key pose, no audio. Camera, facing and prop locks in the negative block of every prompt. Loops pass the same image as start and end frame; one-shots pass only the start frame.
3. Extract every frame (ffmpeg).
4. Choose 8 to 12 evenly spaced frames (first and last always kept; pixel art does not benefit from more).
5. Remove the background per frame (local chroma key).
6. Crop every frame to one shared bounding box, anchored bottom centre.
7. Assemble a grid sheet, no larger than 4096 px on either side; drop the duplicate last frame on loops.
8. Shrink with nearest-neighbour to the 32 x 48 cell.
9. Map to the master palette.

File naming (from the Higgsfield workflow): `{asset}_{action}_f{count}_{w}x{h}_g{cols}x{rows}_fps{n}_{loop|once}.png`, e.g. `christian-burden_walk_f8_32x48_g4x2_fps10_loop.png`.

**Honest expectation on 32 x 48 sprites:** video-derived frames shrunk to this size often shimmer, and hands, faces and feet lose definition. I expect most animations to need a cleanup pass: fixing 1 to 3 pixels per frame for outline consistency and planting the feet. Budget about 30 to 60 minutes of human pixel work per animation, or accept slightly rougher motion. This is the largest quality risk in the project (see `design/risks.md`, R1).

## 9. UI art

Parchment panels with a 2 px ink border and gold corner studs; Pixelify Sans for titles and buttons; Figtree for long reading (codex entries, settings descriptions) at sizes where it renders crisply. Icons are 16 x 16 on the same palette. Details and wireframes are in `design/ui/`.

## 10. What gets marked as human-modified

For copyright and provenance (`docs/rights.md`), every asset row in `assets.csv` records whether a human changed it after generation (pixel cleanup, recomposition, palette edits beyond the automatic map). Automatic pipeline steps do not count as human modification.
