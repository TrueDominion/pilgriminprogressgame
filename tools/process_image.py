#!/usr/bin/env python3
"""Run the full still-image pipeline: key out, pixelize, palette map.

Usage: python3 tools/process_image.py IN.png OUT.png [--key magenta|cyan|none]
                                      [--scale N] [--target WxH] [--trim]
--trim crops to the opaque bounding box before the target resize (sprites, props).
"""
import argparse
import json

import numpy as np

from pipeline_common import (KEY_COLOURS, auto_key_colour, detect_pixel_pitch, grid_sample, key_mask,
                             load_palette, load_rgba, map_to_palette, nearest_palette_indices, nearest_resize,
                             save_rgba)


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("src"); p.add_argument("dst")
    p.add_argument("--key", choices=list(KEY_COLOURS) + ["auto", "none"], default="auto",
                   help="auto reads the background colour from the image border")
    p.add_argument("--pitch", type=float, default=0.0, help="art pixel size in real pixels; 0 = detect")
    p.add_argument("--target", default="")
    p.add_argument("--trim", action="store_true")
    a = p.parse_args()

    img = load_rgba(a.src)
    report = {"src": a.src}
    # detect the grid on the untouched image: keying roughens the subject's edges
    pitch, ox, oy = (a.pitch, 0.0, 0.0) if a.pitch else detect_pixel_pitch(img)
    palette = load_palette()
    if a.key != "none":
        key = auto_key_colour(img) if a.key == "auto" else KEY_COLOURS[a.key]
        if key is not None:
            bg = key_mask(img, key)
            img[bg] = 0
            report["key"] = "#%02x%02x%02x" % key
            report["background_pct"] = round(float(bg.mean() * 100), 1)
        else:
            report["key"] = "none found"
    opaque = img[..., 3] >= 128
    if opaque.any():
        _, de = nearest_palette_indices(img[opaque][:, :3], palette)
        report["source_mean_delta_e"] = round(float(de.mean()), 2)
        report["source_pct_over_10"] = round(float((de > 10).mean() * 100), 1)
    img = grid_sample(img, pitch, ox, oy, palette=palette)
    report["pitch"] = round(pitch, 2)
    if a.trim:
        ys, xs = np.nonzero(img[..., 3])
        if len(xs):
            img = img[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    if a.target:
        w, h = (int(v) for v in a.target.lower().split("x"))
        img = nearest_resize(img, (w, h))
    img, _ = map_to_palette(img, palette)
    report["size"] = f"{img.shape[1]}x{img.shape[0]}"
    save_rgba(img, a.dst)
    print(json.dumps(report))


if __name__ == "__main__":
    main()
