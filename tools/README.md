# tools

Asset pipeline (Python 3, numpy, Pillow, ffmpeg). Spec: `design/art-bible.md` section 8.

| Script | Purpose |
|---|---|
| `process_image.py` | **Main entry for stills.** Key out the background (colour read from the image border), detect the art-pixel grid (fractional pitch), sample one colour per art pixel, map to `design/palette.gpl`. Options: `--trim`, `--target WxH`, `--pitch`, `--key` |
| `frames_to_sheet.py` | Video or frame folder → sprite sheet: N evenly spaced frames, per-frame key, shared bounding box, bottom-centre anchor, palette map, grid ≤ 4096 px, Higgsfield naming convention |
| `consistency_check.py` | Per-batch report: off-palette pixels, semi-transparent pixels, unshrunk (upscaled) art, outline colour; writes a Markdown report and a 4x contact sheet |
| `key_out.py`, `pixelize.py`, `palette_map.py` | Single steps, for debugging |
| `pipeline_common.py` | Shared colour science (CIEDE2000), grid detection, keying |
| `tests/test_pipeline.py` | End-to-end test on synthetic damaged input (JPEG, off-grid upscale, H.264 video) |

```bash
python3 tools/tests/test_pipeline.py
```
```bash
python3 tools/process_image.py art-src/concept/style-tests/CON-style-01.png out.png
```

Order matters: key out on the full-size image first, then sample the grid, then map the palette. The grid is detected on the untouched image because keying roughens edges.
