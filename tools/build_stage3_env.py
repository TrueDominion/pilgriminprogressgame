#!/usr/bin/env python3
"""Build Stage 3 (the Wicket Gate) environment art.

Stage 3 walks the same fields as the end of Stage 1, so it reuses Stage 1's sky, fields
layer, ground textures and small props, and adds its own:
  backgrounds/stage3/far-castle.png  -> layer_far.png  (Beelzebub's castle on the horizon)
  backgrounds/stage3/sinai.png       -> prop_sinai.png (Mount Sinai, over the detour road)
  tiles/stage3/props.png             -> tex_rock.png, tex_hedge.png, prop_gate.png (wicket
                                        gate), prop_shelter.png and prop_boulder.png (spare)
Re-run after replacing a source image: python3 tools/build_stage3_env.py
"""
import shutil

from build_stage1_env import SRC, components, despeckle, mirror_x, mirror_xy, process, trim
from pipeline_common import save_rgba

REPO = SRC.parent
OUT = REPO / "game" / "assets" / "env" / "stage3"
STAGE1 = REPO / "game" / "assets" / "env" / "stage1"
FROM_STAGE1 = ["layer_sky", "layer_fields", "tex_field", "tex_grass_top", "tex_earth",
               "prop_lantern", "prop_signpost", "prop_barrel"]

# props sheet cells in reading order -> (name, kind): "tex" = tiling swatch, "prop" = object
PROPS = {0: ("rock", "tex"), 1: ("hedge", "tex"), 2: ("shelter", "prop"), 3: ("gate", "prop"),
         5: ("boulder", "prop")}   # cell 4 is a signpost; Stage 1's is used instead


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for name in FROM_STAGE1:
        shutil.copyfile(STAGE1 / f"{name}.png", OUT / f"{name}.png")
    print(f"copied from stage1: {', '.join(FROM_STAGE1)}")

    far = despeckle(trim(process(SRC / "backgrounds/stage3/far-castle.png", 0, "magenta")))
    save_rgba(mirror_x(far), OUT / "layer_far.png")
    print(f"layer_far: {far.shape[1] * 2}x{far.shape[0]}")

    sinai = despeckle(trim(process(SRC / "backgrounds/stage3/sinai.png", 0, "magenta")))
    save_rgba(sinai, OUT / "prop_sinai.png")
    print(f"prop_sinai: {sinai.shape[1]}x{sinai.shape[0]}")

    sheet = process(SRC / "tiles/stage3/props.png", 0, "magenta")
    boxes = components(sheet)
    for idx, (name, kind) in PROPS.items():
        x0, y0, x1, y1 = boxes[idx]
        if kind == "tex":
            inset = 3
            save_rgba(mirror_xy(sheet[y0 + inset:y1 - inset, x0 + inset:x1 - inset]), OUT / f"tex_{name}.png")
        else:
            save_rgba(despeckle(sheet[y0:y1, x0:x1]), OUT / f"prop_{name}.png")
        print(f"{kind}_{name}: cell {idx}, {x1 - x0}x{y1 - y0}")


if __name__ == "__main__":
    main()
