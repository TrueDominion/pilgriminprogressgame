#!/usr/bin/env python3
"""Build Stage 4 (the Interpreter's House and the Cross) environment art.

Indoors (the house, tiles 0 to 92) uses the house as the "mid" layer; from the walled
way on (field_from 92) the hillside with the Cross fades in as the "fields" layer, under
a dawn sky. Floors and walls reuse Stage 1's stone textures; the grass from the walled
way on reuses Stage 1's field textures.
  backgrounds/stage4/sky-dawn.png    -> layer_sky.png
  backgrounds/stage4/mid-house.png   -> layer_mid.png
  backgrounds/stage4/hill-cross.png  -> layer_fields.png
  tiles/stage4/props.png             -> prop_fire, prop_cross, prop_sepulchre, prop_jug,
                                        prop_basin, prop_broom, prop_brazier
Re-run after replacing a source image: python3 tools/build_stage4_env.py
"""
import shutil

from build_stage1_env import SRC, components, despeckle, mirror_x, process, trim
from pipeline_common import save_rgba

REPO = SRC.parent
OUT = REPO / "game" / "assets" / "env" / "stage4"
STAGE1 = REPO / "game" / "assets" / "env" / "stage1"
FROM_STAGE1 = ["tex_street_top", "tex_earth", "tex_field", "tex_grass_top", "tex_stone_wall",
               "prop_lantern", "prop_signpost"]

LAYERS = {  # name: (source, pitch or 0 to detect, key or None)
    "sky": ("backgrounds/stage4/sky-dawn.png", 3.65, None),   # detection fails on flat bands
    "mid": ("backgrounds/stage4/mid-house.png", 3.65, None),   # the other layers measured 3.65
    "fields": ("backgrounds/stage4/hill-cross.png", 0, "magenta"),
}
PROPS = {0: "fire", 1: "cross", 2: "sepulchre", 3: "jug", 4: "broom", 5: "basin", 6: "brazier"}


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for name in FROM_STAGE1:
        shutil.copyfile(STAGE1 / f"{name}.png", OUT / f"{name}.png")
    print(f"copied from stage1: {', '.join(FROM_STAGE1)}")
    for name, (src, pitch, key) in LAYERS.items():
        img = process(SRC / src, pitch, key)
        if key:
            img = despeckle(trim(img))
        save_rgba(mirror_x(img), OUT / f"layer_{name}.png")
        print(f"layer_{name}: {img.shape[1] * 2}x{img.shape[0]}")
    sheet = process(SRC / "tiles/stage4/props.png", 0, "magenta")
    boxes = components(sheet)
    for idx, name in PROPS.items():
        x0, y0, x1, y1 = boxes[idx]
        save_rgba(despeckle(sheet[y0:y1, x0:x1]), OUT / f"prop_{name}.png")
        print(f"prop_{name}: cell {idx}, {x1 - x0}x{y1 - y0}")


if __name__ == "__main__":
    main()
