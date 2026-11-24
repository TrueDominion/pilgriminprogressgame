#!/usr/bin/env python3
"""Turn a 4-second animation video (or a folder of frames) into a pixel sprite sheet.

Follows Higgsfield's video-to-sprite-sheet workflow with pixel-art settings
(art-bible section 8):
  1. extract every frame (ffmpeg)            5. one shared bounding box for all frames
  2. pick N evenly spaced, first+last kept   6. shrink to the character height (mode sampling)
  3. key out the background per frame        7. map to the master palette
  4. (loops) drop the duplicate last frame   8. pad to the cell, bottom-centre, grid <= 4096 px

Usage:
  python3 tools/frames_to_sheet.py anim.mp4 --asset christian-burden --action walk \
      --frames 8 --cell 40x56 --char-height 48 --fps 10 --loop --out game/assets/sprites/
"""
from __future__ import annotations

import argparse
import math
import subprocess
import tempfile
from pathlib import Path

import numpy as np

from pipeline_common import KEY_COLOURS, auto_key_colour, key_mask, load_palette, load_rgba, map_to_palette, save_rgba


def extract_frames(video: Path, dst: Path) -> list[Path]:
    dst.mkdir(parents=True, exist_ok=True)
    subprocess.run(["ffmpeg", "-loglevel", "error", "-i", str(video), "-vsync", "0", str(dst / "%04d.png")],
                   check=True)
    return sorted(dst.glob("*.png"))


def select_even(items: list, n: int) -> list:
    if n >= len(items):
        return items
    idx = np.unique(np.round(np.linspace(0, len(items) - 1, n)).astype(int))
    return [items[i] for i in idx]


def mode_downscale(rgba: np.ndarray, size: tuple[int, int]) -> np.ndarray:
    """Each output pixel takes the most common opaque colour in its source footprint."""
    h, w = rgba.shape[:2]
    W, H = size
    out = np.zeros((H, W, 4), dtype=np.uint8)
    xs = np.linspace(0, w, W + 1).astype(int)
    ys = np.linspace(0, h, H + 1).astype(int)
    for y in range(H):
        for x in range(W):
            block = rgba[ys[y]:max(ys[y + 1], ys[y] + 1), xs[x]:max(xs[x + 1], xs[x] + 1)].reshape(-1, 4)
            opaque = block[block[:, 3] >= 128]
            if len(opaque) * 2 < len(block):
                continue
            # quantise lightly so near-identical video colours vote together
            q = (opaque[:, :3] // 8) * 8 + 4
            cols, counts = np.unique(q, axis=0, return_counts=True)
            out[y, x, :3] = cols[counts.argmax()]
            out[y, x, 3] = 255
    return out


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("src", help="video file or folder of PNG frames")
    p.add_argument("--asset", required=True)
    p.add_argument("--action", required=True)
    p.add_argument("--frames", type=int, default=8)
    p.add_argument("--cell", default="40x56")
    p.add_argument("--char-height", type=int, default=48, help="target height of the subject in pixels")
    p.add_argument("--fps", type=int, default=10)
    p.add_argument("--loop", action="store_true")
    p.add_argument("--key", choices=list(KEY_COLOURS) + ["auto"], default="auto")
    p.add_argument("--out", default=".")
    p.add_argument("--start", type=float, default=0.0, help="first frame to use, as a fraction of the video (0-1)")
    p.add_argument("--end", type=float, default=1.0, help="last frame to use, as a fraction of the video (0-1)")
    p.add_argument("--ref-height", type=float, default=0.0,
                   help="subject height in source pixels that maps to --char-height; use the same value for every sheet of one character so all share one pixel size (default: this video's median)")
    p.add_argument("--pose-only", action="store_true",
                   help="anchor every frame by its own feet and centre: removes travel the engine already does (jump, fall, drift)")
    a = p.parse_args()

    src = Path(a.src)
    with tempfile.TemporaryDirectory() as tmp:
        frames = extract_frames(src, Path(tmp)) if src.is_file() else sorted(src.glob("*.png"))
        if len(frames) < 2:
            raise SystemExit("Need at least 2 frames")
        lo = int(round(a.start * (len(frames) - 1)))
        hi = int(round(a.end * (len(frames) - 1)))
        picked = select_even(frames[lo:hi + 1], a.frames)
        imgs = []
        key = KEY_COLOURS.get(a.key) or auto_key_colour(load_rgba(picked[0]))
        if key is None:
            raise SystemExit("No flat background found on the frame border; pass --key")
        for f in picked:
            img = load_rgba(f)
            img[key_mask(img, key)] = 0
            imgs.append(img)

    if a.loop and len(imgs) > 2:
        imgs = imgs[:-1]  # last frame == first frame for loops

    # shared bounding box
    boxes = []
    for img in imgs:
        ys, xs = np.nonzero(img[..., 3])
        if not len(xs):
            raise SystemExit("A frame is empty after keying: check the key colour")
        boxes.append((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))
    if a.pose_only:
        # move every frame so its feet sit at the same point (bottom and horizontal centre),
        # removing travel the engine already does (jump arcs, drift in a wading loop)
        base = max(b[3] for b in boxes)
        cx = int(round(np.median([(b[0] + b[2]) / 2 for b in boxes])))
        shifted, nb = [], []
        for img, b in zip(imgs, boxes):
            dy = base - b[3]
            dx = cx - int(round((b[0] + b[2]) / 2))
            out = np.roll(np.roll(img, dy, axis=0), dx, axis=1)
            shifted.append(out)
            nb.append((b[0] + dx, b[1] + dy, b[2] + dx, b[3] + dy))
        imgs, boxes = shifted, nb
    x0 = min(b[0] for b in boxes); y0 = min(b[1] for b in boxes)
    x1 = max(b[2] for b in boxes); y1 = max(b[3] for b in boxes)
    median_h = float(np.median([b[3] - b[1] for b in boxes]))
    f = a.char_height / (a.ref_height or median_h)
    out_w, out_h = max(1, round((x1 - x0) * f)), max(1, round((y1 - y0) * f))

    cw, ch = (int(v) for v in a.cell.lower().split("x"))
    if out_w > cw or out_h > ch:
        print(f"warning: motion needs {out_w}x{out_h}, larger than the {cw}x{ch} cell; cell expanded")
        cw, ch = max(cw, out_w), max(ch, out_h)

    palette = load_palette()
    cells, stats = [], []
    for img in imgs:
        small = mode_downscale(img[y0:y1, x0:x1], (out_w, out_h))
        small, st = map_to_palette(small, palette)
        stats.append(st["mean_delta_e"])
        cell = np.zeros((ch, cw, 4), dtype=np.uint8)
        ox = (cw - out_w) // 2
        cell[ch - out_h:, ox:ox + out_w] = small  # bottom-centre anchor
        cells.append(cell)

    n = len(cells)
    cols = math.ceil(math.sqrt(n)); rows = math.ceil(n / cols)
    if cols * cw > 4096 or rows * ch > 4096:
        raise SystemExit("Sheet would exceed 4096 px; reduce frames or cell size")
    sheet = np.zeros((rows * ch, cols * cw, 4), dtype=np.uint8)
    for i, c in enumerate(cells):
        r, q = divmod(i, cols)
        sheet[r * ch:(r + 1) * ch, q * cw:(q + 1) * cw] = c

    name = f"{a.asset}_{a.action}_f{n}_{cw}x{ch}_g{cols}x{rows}_fps{a.fps}_{'loop' if a.loop else 'once'}.png"
    dst = Path(a.out) / name
    save_rgba(sheet, dst)
    print(f"{dst}: {n} frames, subject {out_w}x{out_h}, source height {median_h:.0f}px, mean palette shift {np.mean(stats):.1f}")


if __name__ == "__main__":
    main()
