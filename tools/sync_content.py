#!/usr/bin/env python3
"""Copy player-visible text from /content into the Godot project.

content/dialogue/stageN.csv (keys, speaker, en, source) is the source of truth.
This writes:
  game/data/dialogue_strings.csv  keys,en  -> imported by Godot as a translation
  game/data/dialogue_speakers.json         key -> speaker id
Adding a language later means adding a column to the content CSVs and here.
Run after editing content: python3 tools/sync_content.py  (CI runs it too).
"""
import csv
import json
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SRC = REPO / "content" / "dialogue"
OUT = REPO / "game" / "data"


def main() -> None:
    rows, speakers, seen = [], {}, set()
    for f in sorted(SRC.glob("*.csv")):
        for r in csv.DictReader(f.open(encoding="utf-8")):
            key = r["keys"].strip()
            if not key:
                continue
            if key in seen:
                raise SystemExit(f"Duplicate key {key} in {f.name}")
            seen.add(key)
            rows.append((key, r["en"]))
            speakers[key] = r["speaker"].strip()
    with (OUT / "dialogue_strings.csv").open("w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh, lineterminator="\n")
        w.writerow(["keys", "en"])
        w.writerows(rows)
    (OUT / "dialogue_speakers.json").write_text(json.dumps(speakers, indent=1, sort_keys=True) + "\n")
    print(f"{len(rows)} lines synced")


if __name__ == "__main__":
    main()
