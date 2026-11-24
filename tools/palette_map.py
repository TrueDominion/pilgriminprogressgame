#!/usr/bin/env python3
"""Map every opaque pixel to the nearest colour in design/palette.gpl (CIEDE2000).

Prints the mean colour shift and the share of pixels that moved more than
delta E 10, a quick signal that the source strayed from the palette.

Usage: python3 tools/palette_map.py IN.png OUT.png
"""
import argparse

from pipeline_common import load_palette, load_rgba, map_to_palette, save_rgba


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("src"); p.add_argument("dst")
    a = p.parse_args()
    out, stats = map_to_palette(load_rgba(a.src), load_palette())
    save_rgba(out, a.dst)
    print(f"{a.dst}: {stats}")


if __name__ == "__main__":
    main()
