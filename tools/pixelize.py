#!/usr/bin/env python3
"""Shrink AI pixel art to its true pixel grid.

Auto mode detects how many real pixels make one art pixel and samples one colour
per block. Target mode resizes to an exact size with nearest-neighbour (use for
sprite cells once the subject is cropped).

Usage:
  python3 tools/pixelize.py IN.png OUT.png                 # auto-detect grid
  python3 tools/pixelize.py IN.png OUT.png --scale 6       # force block size
  python3 tools/pixelize.py IN.png OUT.png --target 40x56  # exact size
"""
import argparse

from pipeline_common import block_sample, detect_pixel_scale, load_rgba, nearest_resize, save_rgba


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("src"); p.add_argument("dst")
    p.add_argument("--scale", type=int, default=0, help="block size; 0 = detect")
    p.add_argument("--target", default="", help="WxH, nearest-neighbour")
    a = p.parse_args()
    img = load_rgba(a.src)
    if a.target:
        w, h = (int(v) for v in a.target.lower().split("x"))
        out = nearest_resize(img, (w, h))
        print(f"{a.dst}: resized to {w}x{h}")
    else:
        if a.scale:
            s, ox, oy = a.scale, 0, 0
        else:
            s, ox, oy = detect_pixel_scale(img)
        out = block_sample(img, s, ox, oy)
        print(f"{a.dst}: detected scale {s} (offset {ox},{oy}) -> {out.shape[1]}x{out.shape[0]}")
    save_rgba(out, a.dst)


if __name__ == "__main__":
    main()
