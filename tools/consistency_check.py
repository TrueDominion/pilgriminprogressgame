#!/usr/bin/env python3
"""Batch consistency check for processed assets (run once per stage batch).

Checks every PNG in a folder for:
  - off-palette pixels (must be 0)
  - semi-transparent pixels (must be 0; pixel art is fully on or off)
  - mixed pixel sizes (an art pixel larger than 1 real pixel means it was not shrunk)
  - outline colour on sprites (share of edge pixels that use the night ramp)
Writes a Markdown report and a contact sheet at 4x for side-by-side review
against the character reference sheet. Light direction is checked by eye.

Usage: python3 tools/consistency_check.py FOLDER [--report report.md] [--sprites]
"""
from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image

from pipeline_common import load_palette, load_rgba

NIGHT_RAMP = {(15, 10, 26), (29, 21, 48), (36, 26, 56), (53, 42, 82), (74, 63, 107), (107, 95, 138)}


def upscaled_factor(img: np.ndarray) -> int:
    """Return k > 1 only if the image is a clean k-times nearest upscale (unshrunk art)."""
    for k in (8, 6, 5, 4, 3, 2):
        h, w = (img.shape[0] // k) * k, (img.shape[1] // k) * k
        if h < 2 * k or w < 2 * k:
            continue
        for oy in range(k):
            for ox in range(k):
                crop = img[oy:oy + h - k, ox:ox + w - k] if (oy or ox) else img[:h, :w]
                hh, ww = (crop.shape[0] // k) * k, (crop.shape[1] // k) * k
                crop = crop[:hh, :ww]
                small = crop[::k, ::k]
                up = np.repeat(np.repeat(small, k, 0), k, 1)
                if (up == crop).all(-1).mean() > 0.98:
                    return k
    return 1


def check(path: Path, palette_set: set, sprites: bool) -> dict:
    img = load_rgba(path)
    a = img[..., 3]
    opaque = a == 255
    semi = int(((a > 0) & (a < 255)).sum())
    cols = {tuple(c) for c in img[opaque][:, :3]}
    off = sum(1 for c in cols if c not in palette_set)
    off_px = int(sum((img[opaque][:, :3] == np.array(c)).all(1).sum() for c in cols if c not in palette_set))
    scale = upscaled_factor(img)
    res = {"file": path.name, "size": f"{img.shape[1]}x{img.shape[0]}", "colours": len(cols),
           "off_palette_px": off_px, "semi_alpha_px": semi, "pixel_scale": scale, "outline_pct": "n/a"}
    if sprites and opaque.any():
        edge = opaque & ~(np.roll(opaque, 1, 0) & np.roll(opaque, -1, 0) & np.roll(opaque, 1, 1) & np.roll(opaque, -1, 1))
        e = img[edge][:, :3]
        res["outline_pct"] = round(100 * float(np.mean([tuple(c) in NIGHT_RAMP for c in e])), 0)
    res["pass"] = off_px == 0 and semi == 0 and scale == 1 and off == 0
    return res


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("folder")
    p.add_argument("--report", default="")
    p.add_argument("--sprites", action="store_true", help="also check outline colour")
    a = p.parse_args()
    folder = Path(a.folder)
    palette_set = {tuple(int(v) for v in c) for c in load_palette()}
    files = sorted(folder.rglob("*.png"))
    rows = [check(f, palette_set, a.sprites) for f in files]

    lines = [f"# Consistency check: {folder}", "",
             "| File | Size | Colours | Off-palette px | Semi-alpha px | Pixel scale | Outline % | Result |",
             "|---|---|---|---|---|---|---|---|"]
    for r in rows:
        lines.append(f"| {r['file']} | {r['size']} | {r['colours']} | {r['off_palette_px']} | {r['semi_alpha_px']} "
                     f"| {r['pixel_scale']} | {r['outline_pct']} | {'pass' if r['pass'] else 'FAIL'} |")
    passed = sum(r["pass"] for r in rows)
    lines += ["", f"{passed} of {len(rows)} passed. Light direction and likeness to the reference sheet: check the contact sheet by eye."]
    report = "\n".join(lines)
    out = Path(a.report) if a.report else folder / "consistency-report.md"
    out.write_text(report + "\n")

    if files:
        thumbs = [Image.open(f).convert("RGBA") for f in files]
        tw = max(t.width for t in thumbs); th = max(t.height for t in thumbs)
        cols = min(8, len(thumbs)); rws = -(-len(thumbs) // cols)
        sheet = Image.new("RGBA", (cols * (tw + 4), rws * (th + 4)), (29, 21, 48, 255))
        for i, t in enumerate(thumbs):
            sheet.alpha_composite(t, ((i % cols) * (tw + 4), (i // cols) * (th + 4)))
        sheet = sheet.resize((sheet.width * 4, sheet.height * 4), Image.NEAREST)
        sheet.save(out.with_suffix(".png"))
    print(report)


if __name__ == "__main__":
    main()
