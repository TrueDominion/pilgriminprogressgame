#!/usr/bin/env python3
"""Build game audio from audio-src into game/assets/audio (OGG Vorbis).

Music (audio-src/music/<track>-<take>.m4a): the take listed in design/audio-choices.json
is used. The last LOOP_S seconds are cross-faded into the first LOOP_S so the track loops
without a seam, then the whole track is set to MUSIC_LUFS integrated loudness.
SFX (audio-src/sfx/<name>.mp3): leading and trailing silence trimmed, peak normalised
to SFX_PEAK_DB, mono. Mix levels follow Higgsfield's game-audio guidance (music well
below effects; nothing above -3 dBFS true peak).
Run: python3 tools/build_audio.py            (everything)
     python3 tools/build_audio.py stage2 mud_bubble   (only the named tracks and effects;
     rebuilding unchanged files changes their bytes, so build only what changed)
"""
import json
import sys
import subprocess
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SRC = REPO / "audio-src"
OUT = REPO / "game" / "assets" / "audio"
CHOICES = REPO / "design" / "audio-choices.json"
LOOP_S = 3.0
MUSIC_LUFS = -18.0
SFX_PEAK_DB = -3.0


def ff(*args: str) -> str:
    r = subprocess.run(["ffmpeg", "-hide_banner", "-nostats", "-y", *args], capture_output=True, text=True)
    if r.returncode:
        raise SystemExit(r.stderr[-2000:])
    return r.stderr


def duration(path: Path) -> float:
    out = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(path)],
                         capture_output=True, text=True).stdout
    return float(out.strip())


def build_music(src: Path, dst: Path) -> None:
    d = duration(src)
    L = LOOP_S
    graph = (
        f"[0:a]atrim=0:{L},asetpts=PTS-STARTPTS,afade=t=in:d={L}[h];"
        f"[0:a]atrim={d - L}:{d},asetpts=PTS-STARTPTS,afade=t=out:d={L}[t];"
        f"[0:a]atrim={L}:{d - L},asetpts=PTS-STARTPTS[b];"
        f"[t][h]amix=inputs=2:normalize=0[x];"
        f"[x][b]concat=n=2:v=0:a=1,loudnorm=I={MUSIC_LUFS}:TP=-3:LRA=11[o]"
    )
    ff("-i", str(src), "-filter_complex", graph, "-map", "[o]", "-ar", "44100", "-c:a", "libvorbis", "-q:a", "3", str(dst))


def build_sfx(src: Path, dst: Path) -> None:
    trim = ("silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.01,"
            "areverse,silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.02,areverse")
    stats = ff("-i", str(src), "-af", trim + ",volumedetect", "-f", "null", "-")
    peak = float([l for l in stats.splitlines() if "max_volume" in l][-1].split(":")[1].split()[0])
    gain = SFX_PEAK_DB - peak
    ff("-i", str(src), "-af", f"{trim},volume={gain}dB", "-ac", "1", "-ar", "44100",
       "-c:a", "libvorbis", "-q:a", "4", str(dst))


def main() -> None:
    (OUT / "music").mkdir(parents=True, exist_ok=True)
    (OUT / "sfx").mkdir(parents=True, exist_ok=True)
    choices = json.loads(CHOICES.read_text())
    only = set(sys.argv[1:])
    for track, take in choices["music"].items():
        if only and track not in only:
            continue
        src = SRC / "music" / f"{track}-{take}.m4a"
        build_music(src, OUT / "music" / f"{track}.ogg")
        print(f"music {track}: take {take}")
    for src in sorted((SRC / "sfx").glob("*.mp3")):
        if only and src.stem not in only:
            continue
        build_sfx(src, OUT / "sfx" / f"{src.stem}.ogg")
        print(f"sfx {src.stem}")


if __name__ == "__main__":
    main()
