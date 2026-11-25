#!/usr/bin/env python3
"""Build Stage 2 (Slough of Despond) environment art from the raw Higgsfield outputs.

Inputs (art-src, Git LFS):
  backgrounds/stage2/{sky,far-bog,mid-reeds,near-dead-trees}.png
  tiles/stage2/swatches.png
Outputs (game/assets/env/stage2/):
  layer_{sky,far,mid,near}.png  parallax layers, mirrored to repeat without a seam
  tex_street_top.png            the ground's top edge (bog grass); the level builder's
  tex_earth.png                 default ground names, so no field_from is needed
  tex_mud.png, tex_water.png    shallow mud and deep mire

Uses the Stage 1 helpers. Pitch detection failed on the sky (flat bands, no edges);
the other layers measured 3.65, so the sky uses that too.
Re-run after replacing a source image: python3 tools/build_stage2_env.py
"""
from build_stage1_env import SRC, components, despeckle, mirror_x, mirror_xy, process, trim
from pipeline_common import save_rgba

OUT = SRC.parent / "game" / "assets" / "env" / "stage2"

LAYERS = {  # name: (source, pitch or 0 to detect, key or None)
    "sky": ("backgrounds/stage2/sky.png", 3.65, None),
    "far": ("backgrounds/stage2/far-bog.png", 0, "magenta"),
    "mid": ("backgrounds/stage2/mid-reeds.png", 0, "magenta"),
    "near": ("backgrounds/stage2/near-dead-trees.png", 0, "magenta"),
}

# swatch index (reading order of connected cells) -> (texture name, crop inset, (first row, rows) or None)
# cells 4 to 6 are thin strips between the rows; 3 tussock, 7 reeds, 8 stone, 10 planks unused for now
SWATCHES = {
    2: ("street_top", 0, (15, 16)),   # rows 0-14 are the flat green cell background
    1: ("earth", 14, None),   # wide inset: the corners hold leaves that repeat like wallpaper
    0: ("mud", 6, None),
    9: ("water", 4, None),
}


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for name, (src, pitch, key) in LAYERS.items():
        img = process(SRC / src, pitch, key)
        if key:
            img = despeckle(trim(img))
        save_rgba(mirror_x(img), OUT / f"layer_{name}.png")
        print(f"layer_{name}: {img.shape[1] * 2}x{img.shape[0]}")

    sw = process(SRC / "tiles/stage2/swatches.png", 0, "magenta")
    boxes = components(sw)
    for idx, (name, inset, rows) in SWATCHES.items():
        x0, y0, x1, y1 = boxes[idx]
        if rows:
            first, n = rows
            save_rgba(mirror_x(sw[y0 + first:y0 + first + n, x0 + inset:x1 - inset]), OUT / f"tex_{name}.png")
        else:
            save_rgba(mirror_xy(sw[y0 + inset:y1 - inset, x0 + inset:x1 - inset]), OUT / f"tex_{name}.png")
        print(f"tex_{name}: from swatch {idx}")


if __name__ == "__main__":
    main()
