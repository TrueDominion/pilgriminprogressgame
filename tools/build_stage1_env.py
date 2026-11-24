#!/usr/bin/env python3
"""Build Stage 1 environment art for the game from the raw Higgsfield outputs.

Inputs (art-src, Git LFS):
  backgrounds/stage1/{sky,far-city,mid-streets,near-walls}.png
  tiles/stage1/{swatches,props}.png
Outputs (game/assets/env/stage1/):
  layer_*.png  parallax layers, mirrored to twice their width so they repeat without a seam
  tex_*.png    ground and wall textures, cropped to the clean centre and mirrored to tile
  prop_*.png   individual props cut from the props sheet

Grid pitches were measured with tools/pipeline_common.detect_pixel_pitch; the three
street layers have weak edges, so their pitch (3.25) is fixed here. Re-run after replacing
any source image: python3 tools/build_stage1_env.py
"""
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image

from pipeline_common import (KEY_COLOURS, detect_pixel_pitch, grid_sample, key_mask, load_palette,
                             load_rgba, map_to_palette, save_rgba)

REPO = Path(__file__).resolve().parent.parent
SRC = REPO / "art-src"
OUT = REPO / "game" / "assets" / "env" / "stage1"
PAL = load_palette()

LAYERS = {  # name: (source, pitch or 0 to detect, key or None, rows to trim at the bottom)
    "sky": ("backgrounds/stage1/sky.png", 3.25, None, 0),
    "far": ("backgrounds/stage1/far-city.png", 0, "magenta", 0),
    "mid": ("backgrounds/stage1/mid-streets.png", 3.25, "magenta", 3),
    "near": ("backgrounds/stage1/near-walls.png", 3.25, "magenta", 0),
    "fields": ("backgrounds/stage1/mid-fields.png", 0, "magenta", 0),
}

# swatch index (reading order on the sheet) -> (name, crop inset, rows to keep from the top or 0 for all)
SWATCHES = {
    0: ("street_top", 0, 16),
    2: ("earth", 8, 0),
    1: ("field", 12, 0),
    7: ("grass_top", 0, 16),
    8: ("stone_wall", 0, 0),
    9: ("timber", 0, 0),
    12: ("planks", 2, 0),
}
PROPS = {0: "signpost", 1: "lantern", 2: "door", 3: "gate", 11: "barrel", 12: "crates", 13: "cart", 10: "stall"}


def process(path: Path, pitch: float, key: str | None) -> np.ndarray:
    img = load_rgba(path)
    if not pitch:
        pitch, ox, oy = detect_pixel_pitch(img)
    else:
        ox = oy = 0.0
    if key:
        img[key_mask(img, KEY_COLOURS[key])] = 0
    img = grid_sample(img, pitch, ox, oy, palette=PAL)
    img, _ = map_to_palette(img, PAL)
    return img


def despeckle(img: np.ndarray) -> np.ndarray:
    """Remove opaque pixels with no opaque neighbour (stray key fringe)."""
    a = img[..., 3] > 0
    n = sum(np.roll(np.roll(a, dy, 0), dx, 1) for dy in (-1, 0, 1) for dx in (-1, 0, 1)) - a
    out = img.copy()
    out[a & (n == 0)] = 0
    return out


def trim_dark_base(img: np.ndarray, share: float = 0.85) -> np.ndarray:
    """Drop bottom rows that are almost all the darkest night colours (painted-in ground)."""
    dark = (img[..., :3].astype(int).sum(-1) < 140) | (img[..., 3] == 0)
    rows = dark.mean(1)
    end = len(rows)
    while end > 1 and rows[end - 1] > share:
        end -= 1
    return img[:end]


def mirror_x(img: np.ndarray) -> np.ndarray:
    return np.concatenate([img, img[:, ::-1]], axis=1)


def mirror_xy(img: np.ndarray) -> np.ndarray:
    row = mirror_x(img)
    return np.concatenate([row, row[::-1]], axis=0)


def trim(img: np.ndarray) -> np.ndarray:
    ys, xs = np.nonzero(img[..., 3])
    return img[ys.min():ys.max() + 1, xs.min():xs.max() + 1]


def components(img: np.ndarray, min_px: int = 30) -> list[tuple[int, int, int, int]]:
    m = img[..., 3] > 0
    lab = np.zeros(m.shape, int)
    boxes, n = [], 0
    for y, x in zip(*np.nonzero(m)):
        if lab[y, x]:
            continue
        n += 1
        q = deque([(y, x)])
        lab[y, x] = n
        ys, xs = [], []
        while q:
            cy, cx = q.popleft()
            ys.append(cy)
            xs.append(cx)
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    ny, nx = cy + dy, cx + dx
                    if 0 <= ny < m.shape[0] and 0 <= nx < m.shape[1] and m[ny, nx] and not lab[ny, nx]:
                        lab[ny, nx] = n
                        q.append((ny, nx))
        if len(ys) >= min_px:
            boxes.append((min(xs), min(ys), max(xs) + 1, max(ys) + 1))
    return sorted(boxes, key=lambda b: (round(b[1] / 25), b[0]))


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for name, (src, pitch, key, cut) in LAYERS.items():
        if not (SRC / src).exists():
            print(f"layer_{name}: source missing, skipped")
            continue
        img = process(SRC / src, pitch, key)
        if cut:
            img = img[:-cut]
        if key:
            img = despeckle(trim(img))
        if name == "near":
            img = trim_dark_base(img)
        save_rgba(mirror_x(img), OUT / f"layer_{name}.png")
        print(f"layer_{name}: {img.shape[1] * 2}x{img.shape[0]}")

    sw = process(SRC / "tiles/stage1/swatches.png", 0, "magenta")
    boxes = components(sw)
    for idx, (name, inset, rows) in SWATCHES.items():
        x0, y0, x1, y1 = boxes[idx]
        tile = sw[y0 + inset:y1 - inset, x0 + inset:x1 - inset]
        if rows:
            tile = sw[y0:y0 + rows, x0 + inset:x1 - inset]
            save_rgba(mirror_x(tile), OUT / f"tex_{name}.png")
        else:
            save_rgba(mirror_xy(tile), OUT / f"tex_{name}.png")
        print(f"tex_{name}: from swatch {idx}")

    pr = process(SRC / "tiles/stage1/props.png", 0, "magenta")
    boxes = components(pr)
    for idx, name in PROPS.items():
        x0, y0, x1, y1 = boxes[idx]
        save_rgba(despeckle(pr[y0:y1, x0:x1]), OUT / f"prop_{name}.png")
        print(f"prop_{name}: {x1 - x0}x{y1 - y0}")


if __name__ == "__main__":
    main()
