"""Shared helpers for the Pilgrim in Progress asset pipeline.

Pipeline order for every generated image (art-bible section 8):
    1. key_out     remove the flat key-colour background (on the full-size image)
    2. pixelize    find the true pixel grid and shrink with block sampling
    3. palette_map map every pixel to design/palette.gpl (CIEDE2000)
Keying first is deliberate: the magenta key would otherwise be mapped to the
nearest palette colour and survive as a visible fringe.
"""
from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image

REPO = Path(__file__).resolve().parent.parent
PALETTE_PATH = REPO / "design" / "palette.gpl"

KEY_COLOURS = {
    "magenta": (255, 0, 255),
    "cyan": (0, 255, 255),
}


# ---------------------------------------------------------------- palette

def load_palette(path: Path = PALETTE_PATH) -> np.ndarray:
    """Return the palette as an (N, 3) uint8 array, in file order."""
    cols = []
    for line in path.read_text().splitlines():
        parts = line.split()
        if len(parts) >= 3 and all(p.isdigit() for p in parts[:3]):
            cols.append([int(p) for p in parts[:3]])
    if not cols:
        raise ValueError(f"No colours found in {path}")
    return np.array(cols, dtype=np.uint8)


# ---------------------------------------------------------------- colour science

def srgb_to_lab(rgb: np.ndarray) -> np.ndarray:
    """sRGB (..., 3) in 0..255 to CIELAB (D65)."""
    c = rgb.astype(np.float64) / 255.0
    c = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    m = np.array([[0.4124564, 0.3575761, 0.1804375],
                  [0.2126729, 0.7151522, 0.0721750],
                  [0.0193339, 0.1191920, 0.9503041]])
    xyz = c @ m.T
    xyz /= np.array([0.95047, 1.0, 1.08883])
    eps, k = 216 / 24389, 24389 / 27
    f = np.where(xyz > eps, np.cbrt(xyz), (k * xyz + 16) / 116)
    L = 116 * f[..., 1] - 16
    a = 500 * (f[..., 0] - f[..., 1])
    b = 200 * (f[..., 1] - f[..., 2])
    return np.stack([L, a, b], axis=-1)


def delta_e2000(lab1: np.ndarray, lab2: np.ndarray) -> np.ndarray:
    """CIEDE2000 between broadcastable Lab arrays (..., 3)."""
    L1, a1, b1 = lab1[..., 0], lab1[..., 1], lab1[..., 2]
    L2, a2, b2 = lab2[..., 0], lab2[..., 1], lab2[..., 2]
    C1 = np.hypot(a1, b1)
    C2 = np.hypot(a2, b2)
    Cm = (C1 + C2) / 2
    G = 0.5 * (1 - np.sqrt(Cm ** 7 / (Cm ** 7 + 25 ** 7)))
    a1p, a2p = (1 + G) * a1, (1 + G) * a2
    C1p, C2p = np.hypot(a1p, b1), np.hypot(a2p, b2)
    h1p = np.degrees(np.arctan2(b1, a1p)) % 360
    h2p = np.degrees(np.arctan2(b2, a2p)) % 360
    dLp = L2 - L1
    dCp = C2p - C1p
    dh = h2p - h1p
    dh = np.where(dh > 180, dh - 360, dh)
    dh = np.where(dh < -180, dh + 360, dh)
    dh = np.where(C1p * C2p == 0, 0, dh)
    dHp = 2 * np.sqrt(C1p * C2p) * np.sin(np.radians(dh / 2))
    Lpm = (L1 + L2) / 2
    Cpm = (C1p + C2p) / 2
    hsum = h1p + h2p
    hpm = np.where(np.abs(h1p - h2p) > 180, (hsum + 360) / 2, hsum / 2)
    hpm = np.where(C1p * C2p == 0, hsum, hpm)
    T = (1 - 0.17 * np.cos(np.radians(hpm - 30)) + 0.24 * np.cos(np.radians(2 * hpm))
         + 0.32 * np.cos(np.radians(3 * hpm + 6)) - 0.20 * np.cos(np.radians(4 * hpm - 63)))
    dtheta = 30 * np.exp(-(((hpm - 275) / 25) ** 2))
    Rc = 2 * np.sqrt(Cpm ** 7 / (Cpm ** 7 + 25 ** 7))
    Sl = 1 + (0.015 * (Lpm - 50) ** 2) / np.sqrt(20 + (Lpm - 50) ** 2)
    Sc = 1 + 0.045 * Cpm
    Sh = 1 + 0.015 * Cpm * T
    Rt = -np.sin(np.radians(2 * dtheta)) * Rc
    return np.sqrt((dLp / Sl) ** 2 + (dCp / Sc) ** 2 + (dHp / Sh) ** 2 + Rt * (dCp / Sc) * (dHp / Sh))


def nearest_palette_indices(rgb: np.ndarray, palette: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    """For an (N, 3) array of colours, return (index into palette, delta E)."""
    uniq, inverse = np.unique(rgb.reshape(-1, 3), axis=0, return_inverse=True)
    lab_u = srgb_to_lab(uniq)[:, None, :]
    lab_p = srgb_to_lab(palette)[None, :, :]
    d = delta_e2000(lab_u, lab_p)
    idx = d.argmin(axis=1)
    return idx[inverse.reshape(-1)], d[np.arange(len(uniq)), idx][inverse.reshape(-1)]


# ---------------------------------------------------------------- image io

def load_rgba(path: Path | str) -> np.ndarray:
    return np.array(Image.open(path).convert("RGBA"))


def save_rgba(arr: np.ndarray, path: Path | str) -> None:
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(arr.astype(np.uint8), "RGBA").save(path, optimize=True)


# ---------------------------------------------------------------- key colour

def key_mask(rgba: np.ndarray, key: tuple[int, int, int], tolerance: float = 60.0, fringe_passes: int = 3) -> np.ndarray:
    """True where the pixel is background: close to the key colour in RGB distance.

    Generators blend the key into the subject's edge, so further passes peel off
    pixels that carry a strong cast of the key hue and touch the background.
    The cast test uses the key's own channel signature, so it works for pure
    magenta, cyan, or the muted key a model actually painted.
    """
    rgb = rgba[..., :3].astype(np.int32)
    k = np.array(key, dtype=np.int32)
    dist = np.sqrt(((rgb - k) ** 2).sum(-1))
    bg = (dist <= tolerance) | (rgba[..., 3] == 0)
    hi = k >= k.max() - 40           # channels that are strong in the key
    if hi.all() or not hi.any():
        return bg
    strong = rgb[..., hi].min(-1)
    weak = rgb[..., ~hi].max(-1)
    cast = (strong - weak) > 70
    for _ in range(fringe_passes):
        near = np.zeros_like(bg)
        near[1:, :] |= bg[:-1, :]; near[:-1, :] |= bg[1:, :]
        near[:, 1:] |= bg[:, :-1]; near[:, :-1] |= bg[:, 1:]
        grown = bg | (cast & near)
        if (grown == bg).all():
            break
        bg = grown
    return bg


# ---------------------------------------------------------------- pixel grid

def _edge_profiles(rgba: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    """Column and row sums of colour-change strength. Peaks sit on art-pixel boundaries."""
    rgb = rgba[..., :3].astype(np.float32)
    dx = np.abs(np.diff(rgb, axis=1)).sum(-1)   # change between column x-1 and x
    dy = np.abs(np.diff(rgb, axis=0)).sum(-1)
    dx = np.where(dx > 40, dx, 0)               # ignore compression noise
    dy = np.where(dy > 40, dy, 0)
    px = np.concatenate([[0], dx.sum(0)])
    py = np.concatenate([[0], dy.sum(1)])
    return px, py


def _coherence(profile: np.ndarray, pitch: float) -> tuple[float, float]:
    """Fourier coherence of the edge profile at one pitch: 1.0 = every edge on the grid."""
    total = profile.sum()
    if total == 0:
        return 0.0, 0.0
    x = np.arange(len(profile))
    z = (profile * np.exp(2j * np.pi * x / pitch)).sum() / total
    return float(abs(z)), float((np.angle(z) / (2 * np.pi) * pitch) % pitch)


def detect_pixel_pitch(rgba: np.ndarray, lo: float = 2.0, hi: float = 40.0, step: float = 0.01,
                       min_coherence: float = 0.3) -> tuple[float, float, float]:
    """Estimate the (possibly fractional) size of one art pixel and the grid offset.

    AI pixel art is rarely on a whole-number grid (one art pixel is often about
    4.2 real pixels). Colour edges still fall on a regular grid, so the Fourier
    coherence of the edge profile peaks at that pitch. Its sub-harmonics (p/2,
    p/3) peak as well, so after finding the best pitch we prefer an integer
    multiple of it when that multiple is nearly as coherent.
    Returns (1.0, 0, 0) when no pitch is coherent: the image is already 1:1.
    """
    px, py = _edge_profiles(rgba)
    pitches = np.arange(lo, hi, step)
    score = np.array([(_coherence(px, q)[0] + _coherence(py, q)[0]) / 2 for q in pitches])
    best_i = int(score.argmax())
    best_p, best_s = float(pitches[best_i]), float(score[best_i])
    if best_s < min_coherence:
        return 1.0, 0.0, 0.0
    chosen = best_p
    for k in (2, 3):
        window = (pitches > best_p * k - 0.06) & (pitches < best_p * k + 0.06)
        if window.any() and score[window].max() >= 0.8 * best_s:
            chosen = float(pitches[window][score[window].argmax()])
    _, ox = _coherence(px, chosen)
    _, oy = _coherence(py, chosen)
    return chosen, ox, oy


def detect_pixel_scale(rgba: np.ndarray, max_scale: int = 16) -> tuple[int, int, int]:
    """Integer version of detect_pixel_pitch, for the consistency check."""
    p, ox, oy = detect_pixel_pitch(rgba, hi=float(max_scale) + 0.5)
    return max(1, int(round(p))), int(round(ox)), int(round(oy))


def auto_key_colour(rgba: np.ndarray, min_share: float = 0.5) -> tuple[int, int, int] | None:
    """The dominant colour along the image border, if one colour clearly dominates.

    Generators often ignore an exact key such as #ff00ff and paint a muted
    magenta instead, so the key is read from the image rather than assumed.
    """
    border = np.concatenate([rgba[0], rgba[-1], rgba[:, 0], rgba[:, -1]])[:, :3].astype(int)
    q = border // 16
    cols, inv, counts = np.unique(q, axis=0, return_inverse=True, return_counts=True)
    top = counts.argmax()
    if counts[top] / len(border) < min_share:
        return None
    return tuple(int(v) for v in np.median(border[inv.reshape(-1) == top], axis=0))


def snap_to_palette(rgba: np.ndarray, palette: np.ndarray) -> np.ndarray:
    """Replace every pixel's colour with its nearest palette colour (alpha untouched)."""
    out = rgba.copy()
    idx, _ = nearest_palette_indices(out[..., :3].reshape(-1, 3), palette)
    out[..., :3] = palette[idx].reshape(out.shape[:2] + (3,))
    return out


def block_sample(rgba: np.ndarray, s: int, ox: int = 0, oy: int = 0, palette: np.ndarray | None = None) -> np.ndarray:
    """Shrink by an integer factor: each block becomes its most common opaque colour.

    With a palette, pixels are snapped to it first so that compression noise
    does not split the vote. A block is transparent when most of it is.
    """
    if palette is not None:
        rgba = snap_to_palette(rgba, palette)
    if s == 1:
        return rgba.copy()
    h, w = rgba.shape[:2]
    H, W = (h - oy) // s, (w - ox) // s
    crop = rgba[oy:oy + H * s, ox:ox + W * s].reshape(H, s, W, s, 4).transpose(0, 2, 1, 3, 4)
    crop = crop.reshape(H, W, s * s, 4)
    out = np.zeros((H, W, 4), dtype=np.uint8)
    for y in range(H):
        for x in range(W):
            px = crop[y, x]
            opaque = px[px[:, 3] >= 128]
            if len(opaque) * 2 < len(px):
                continue
            cols, counts = np.unique(opaque[:, :3], axis=0, return_counts=True)
            out[y, x, :3] = cols[counts.argmax()]
            out[y, x, 3] = 255
    return out


def grid_sample(rgba: np.ndarray, pitch: float, ox: float = 0.0, oy: float = 0.0,
                palette: np.ndarray | None = None) -> np.ndarray:
    """Shrink by a fractional pitch: one output pixel per art-pixel cell.

    Votes over the central half of each cell (edges blur in generated images)
    after snapping to the palette. A cell is transparent when most of it is.
    """
    if palette is not None:
        rgba = snap_to_palette(rgba, palette)
    if pitch <= 1.0:
        return rgba.copy()
    h, w = rgba.shape[:2]
    W = int((w - ox) // pitch)
    H = int((h - oy) // pitch)
    out = np.zeros((H, W, 4), dtype=np.uint8)
    q = pitch / 4
    for y in range(H):
        y0 = int(round(oy + y * pitch + q)); y1 = max(y0 + 1, int(round(oy + (y + 1) * pitch - q)))
        for x in range(W):
            x0 = int(round(ox + x * pitch + q)); x1 = max(x0 + 1, int(round(ox + (x + 1) * pitch - q)))
            px = rgba[y0:y1, x0:x1].reshape(-1, 4)
            opaque = px[px[:, 3] >= 128]
            if len(opaque) * 2 < len(px):
                continue
            cols, counts = np.unique(opaque[:, :3], axis=0, return_counts=True)
            out[y, x, :3] = cols[counts.argmax()]
            out[y, x, 3] = 255
    return out


def nearest_resize(rgba: np.ndarray, size: tuple[int, int]) -> np.ndarray:
    return np.array(Image.fromarray(rgba, "RGBA").resize(size, Image.NEAREST))


def map_to_palette(rgba: np.ndarray, palette: np.ndarray) -> tuple[np.ndarray, dict]:
    """Map opaque pixels to the palette; alpha is forced to 0 or 255."""
    out = rgba.copy()
    opaque = out[..., 3] >= 128
    out[..., 3] = np.where(opaque, 255, 0)
    out[~opaque, :3] = 0
    stats = {"opaque_pixels": int(opaque.sum()), "mean_delta_e": 0.0, "pct_moved_over_10": 0.0}
    if opaque.any():
        idx, de = nearest_palette_indices(out[opaque][:, :3], palette)
        out[opaque, :3] = palette[idx]
        stats["mean_delta_e"] = round(float(de.mean()), 2)
        stats["pct_moved_over_10"] = round(float((de > 10).mean() * 100), 1)
    return out, stats
