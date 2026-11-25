#!/usr/bin/env python3
"""Build single-pose NPC sprites from art-src/characters/npcs/*.png into game/assets/sprites/npc/.

Each source is a tiny-sprite generation on a flat key colour. Key out, find the art grid,
trim, then shrink to the character's height (mode sampling) and map to the palette.
Heights follow the art bible (adults 46-52 px, Christian 48). Re-run after replacing a source;
name sprites to rebuild only those: python3 tools/build_npcs.py help
"""
import sys
from pathlib import Path

from frames_to_sheet import mode_downscale
from pipeline_common import (auto_key_colour, detect_pixel_pitch, grid_sample, key_mask, load_palette,
                             load_rgba, map_to_palette, save_rgba)
import numpy as np

REPO = Path(__file__).resolve().parent.parent
SRC = REPO / "art-src" / "characters" / "npcs"
OUT = REPO / "game" / "assets" / "sprites" / "npc"
HEIGHTS = {"obstinate": 46, "pliable": 46, "wife": 44, "townsfolk_a": 46, "townsfolk_b": 42, "help": 50}


def main() -> None:
    pal = load_palette()
    OUT.mkdir(parents=True, exist_ok=True)
    only = set(sys.argv[1:])
    for name, h in HEIGHTS.items():
        if only and name not in only:
            continue
        img = load_rgba(SRC / f"{name}.png")
        pitch, ox, oy = detect_pixel_pitch(img)
        key = auto_key_colour(img)
        img[key_mask(img, key)] = 0
        img = grid_sample(img, pitch, ox, oy, palette=pal)
        ys, xs = np.nonzero(img[..., 3])
        img = img[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
        if img.shape[0] > h:
            img = mode_downscale(img, (max(1, round(img.shape[1] * h / img.shape[0])), h))
        img, _ = map_to_palette(img, pal)
        save_rgba(img, OUT / f"{name}.png")
        print(f"{name}: pitch {pitch:.2f}, key #{key[0]:02x}{key[1]:02x}{key[2]:02x}, {img.shape[1]}x{img.shape[0]}")


if __name__ == "__main__":
    main()
