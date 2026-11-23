# tools

Asset pipeline scripts (built in phase 2, Python 3 + Pillow, run locally or in CI).

| Script | Purpose |
|---|---|
| `pixelize.py` | Nearest-neighbour downscale to target size from a known pixel grid |
| `palette_map.py` | Map an image to `design/palette.gpl` (48 colours max) |
| `key_out.py` | Remove the flat key-colour background |
| `frames_to_sheet.py` | Pick N evenly spaced frames, shared bottom-centre bounding box, grid sheet <= 4096px |
| `consistency_check.py` | Per-stage batch report: off-palette pixels, mixed pixel sizes, stray alpha |

Spec for each step is in `design/art-bible.md`, section "Pipeline".
