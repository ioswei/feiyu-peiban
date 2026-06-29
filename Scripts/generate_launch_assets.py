#!/usr/bin/env python3
"""Generate launch backdrop gradients for storyboard (all screen sizes)."""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "FlnutSpeakPlus/Assets.xcassets/LaunchBackdrop.imageset"

# AppTheme.launch palette
ABYSS = (10, 15, 46)
DEEP = (15, 31, 82)
OCEAN = (20, 56, 122)
CYAN = (89, 217, 255)
PERI = (140, 166, 255)


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def lerp_color(c1: tuple[int, int, int], c2: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return (
        int(lerp(c1[0], c2[0], t)),
        int(lerp(c1[1], c2[1], t)),
        int(lerp(c1[2], c2[2], t)),
    )


def make_backdrop(width: int, height: int) -> Image.Image:
    img = Image.new("RGB", (width, height))
    px = img.load()
    cx, cy = width * 0.5, height * 0.28

    for y in range(height):
        t = y / max(height - 1, 1)
        if t < 0.55:
            base = lerp_color(ABYSS, DEEP, t / 0.55)
        else:
            base = lerp_color(DEEP, OCEAN, (t - 0.55) / 0.45)

        for x in range(width):
            r, g, b = base
            # top cyan glow
            d1 = math.hypot(x - cx, y - cy * 0.85)
            glow1 = max(0.0, 1.0 - d1 / (width * 0.72))
            r = min(255, int(r + CYAN[0] * glow1 * 0.10))
            g = min(255, int(g + CYAN[1] * glow1 * 0.10))
            b = min(255, int(b + CYAN[2] * glow1 * 0.08))

            # softer halo behind logo area — nest the icon instead of a flat field
            d2 = math.hypot(x - width * 0.5, y - height * 0.42)
            glow2 = max(0.0, 1.0 - d2 / (width * 0.34))
            glow2 = glow2 ** 1.35
            r = min(255, int(r + PERI[0] * glow2 * 0.08))
            g = min(255, int(g + PERI[1] * glow2 * 0.08))
            b = min(255, int(b + PERI[2] * glow2 * 0.10))
            r = min(255, int(r + CYAN[0] * glow2 * 0.04))
            g = min(255, int(g + CYAN[1] * glow2 * 0.04))
            b = min(255, int(b + CYAN[2] * glow2 * 0.03))

            px[x, y] = (r, g, b)

    return img


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    sizes = {
        "LaunchBackdrop.png": (430, 932),
        "LaunchBackdrop@2x.png": (860, 1864),
        "LaunchBackdrop@3x.png": (1290, 2796),
    }
    for name, size in sizes.items():
        img = make_backdrop(*size)
        img.save(OUT / name, "PNG", optimize=True)
        print(f"Saved {OUT / name} {size}")

    contents = """{
  "images" : [
    { "filename" : "LaunchBackdrop.png", "idiom" : "universal", "scale" : "1x" },
    { "filename" : "LaunchBackdrop@2x.png", "idiom" : "universal", "scale" : "2x" },
    { "filename" : "LaunchBackdrop@3x.png", "idiom" : "universal", "scale" : "3x" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
"""
    (OUT / "Contents.json").write_text(contents, encoding="utf-8")


if __name__ == "__main__":
    main()
