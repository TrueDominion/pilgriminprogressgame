#!/usr/bin/env python3
"""Remove the flat key-colour background (magenta by default) from an image.

Usage: python3 tools/key_out.py IN.png OUT.png [--key magenta|cyan] [--tolerance 60]
"""
import argparse

from pipeline_common import KEY_COLOURS, key_mask, load_rgba, save_rgba


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("src"); p.add_argument("dst")
    p.add_argument("--key", choices=KEY_COLOURS, default="magenta")
    p.add_argument("--tolerance", type=float, default=60.0)
    a = p.parse_args()
    img = load_rgba(a.src)
    bg = key_mask(img, KEY_COLOURS[a.key], a.tolerance)
    img[bg] = 0
    save_rgba(img, a.dst)
    print(f"{a.dst}: removed {bg.mean() * 100:.1f}% of pixels as background")


if __name__ == "__main__":
    main()
