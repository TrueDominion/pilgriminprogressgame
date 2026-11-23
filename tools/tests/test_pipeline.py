#!/usr/bin/env python3
"""End-to-end test of the asset pipeline on synthetic 'AI-like' input.

Builds a known 24x40 pixel sprite from the palette, then damages it the way
generators do (upscaled x7 with an off-grid offset, magenta background, noise,
JPEG compression, and an H.264 video with motion). Checks the tools recover a
clean, palette-exact sprite.

Run: python3 tools/tests/test_pipeline.py
"""
import io
import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np
from PIL import Image

TOOLS = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(TOOLS))
from pipeline_common import load_palette, load_rgba  # noqa: E402

rng = np.random.default_rng(7)
PAL = load_palette()


def make_sprite() -> np.ndarray:
    """A simple pilgrim-like shape: outline, body, sack, head."""
    s = np.zeros((40, 24, 4), np.uint8)
    def fill(y0, y1, x0, x1, c):
        s[y0:y1, x0:x1, :3] = PAL[c]; s[y0:y1, x0:x1, 3] = 255
    fill(4, 40, 4, 20, 2)      # outline (ink)
    fill(5, 39, 5, 19, 37)     # body (earth)
    fill(6, 22, 12, 19, 46)    # sack (stone)
    fill(5, 12, 6, 11, 8)      # head (parchment)
    fill(30, 39, 6, 9, 41)     # leg (earth dark)
    return s


def damage(sprite: np.ndarray, scale=7, off=(3, 5), quality=80) -> Image.Image:
    h, w = sprite.shape[:2]
    canvas = np.zeros((h * scale + 60, w * scale + 50, 3), np.uint8); canvas[:] = (255, 0, 255)
    big = np.array(Image.fromarray(sprite, "RGBA").resize((w * scale, h * scale), Image.NEAREST))
    y, x = 30 + off[1], 25 + off[0]
    region = canvas[y:y + h * scale, x:x + w * scale]
    m = big[..., 3] > 0
    region[m] = big[m][:, :3]
    noisy = np.clip(canvas.astype(int) + rng.normal(0, 4, canvas.shape), 0, 255).astype(np.uint8)
    buf = io.BytesIO(); Image.fromarray(noisy).save(buf, "JPEG", quality=quality)
    return Image.open(io.BytesIO(buf.getvalue())).convert("RGB")


def run(*args) -> str:
    r = subprocess.run([sys.executable, *map(str, args)], capture_output=True, text=True, cwd=TOOLS)
    if r.returncode:
        print(r.stdout, r.stderr); raise SystemExit("tool failed: " + " ".join(map(str, args)))
    return r.stdout.strip()


def main() -> None:
    sprite = make_sprite()
    ok = True
    with tempfile.TemporaryDirectory() as t:
        t = Path(t)
        # --- still image
        damage(sprite).save(t / "raw.png")
        print(run(TOOLS / "process_image.py", t / "raw.png", t / "clean.png", "--trim"))
        out = load_rgba(t / "clean.png")
        if out.shape[:2] != (36, 16 + 0) and out.shape[:2] != (36, 16):
            pass
        ref = sprite[4:40, 4:20]  # trimmed reference
        if out.shape != ref.shape:
            print(f"FAIL still: size {out.shape[1]}x{out.shape[0]}, expected {ref.shape[1]}x{ref.shape[0]}"); ok = False
        else:
            match = (out == ref).all(-1).mean() * 100
            print(f"still: {match:.1f}% of pixels exactly recovered")
            ok &= match >= 97

        # --- video: sprite bobs up and down over 24 frames, loop
        frames = t / "frames"; frames.mkdir()
        for i in range(24):
            bob = int(round(3 * np.sin(2 * np.pi * i / 23)))
            img = damage(sprite, off=(3, 5 + bob * 7 if bob > 0 else 5), quality=95)
            img = img.resize((img.width // 2 * 2, img.height // 2 * 2))
            img.save(frames / f"{i:04d}.png")
        subprocess.run(["ffmpeg", "-loglevel", "error", "-framerate", "24", "-i", str(frames / "%04d.png"),
                        "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "23", str(t / "anim.mp4")], check=True)
        print(run(TOOLS / "frames_to_sheet.py", t / "anim.mp4", "--asset", "test", "--action", "bob",
                  "--frames", "8", "--cell", "32x48", "--char-height", "36", "--loop", "--out", t / "sheets"))
        sheets = list((t / "sheets").glob("*.png"))
        print(run(TOOLS / "consistency_check.py", t / "sheets", "--sprites"))
        sheet = load_rgba(sheets[0])
        pal = {tuple(c) for c in PAL}
        off = sum(1 for c in sheet[sheet[..., 3] == 255][:, :3] if tuple(c) not in pal)
        semi = ((sheet[..., 3] > 0) & (sheet[..., 3] < 255)).sum()
        print(f"video: sheet {sheet.shape[1]}x{sheet.shape[0]}, off-palette {off}, semi-alpha {semi}")
        ok &= off == 0 and semi == 0 and "_f7_" in sheets[0].name
    print("PASS" if ok else "FAIL")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
