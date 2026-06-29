#!/usr/bin/env python3
"""Export app icon and launch-optimized logo assets from the moon companion source."""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/AppIcon-moon-companion.png"
APP_ICON = ROOT / "FlnutSpeakPlus/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
LOGO_DIR = ROOT / "FlnutSpeakPlus/Assets.xcassets/LaunchLogo.imageset"
GLOW_DIR = ROOT / "FlnutSpeakPlus/Assets.xcassets/LaunchLogoGlow.imageset"
SIZE = 1024

# LaunchBackdrop palette (keep in sync with generate_launch_assets.py)
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


def backdrop_color_at(x_ratio: float = 0.5, y_ratio: float = 0.42) -> tuple[int, int, int]:
    """Approximate LaunchBackdrop color where the logo sits on screen."""
    t = y_ratio
    if t < 0.55:
        base = lerp_color(ABYSS, DEEP, t / 0.55)
    else:
        base = lerp_color(DEEP, OCEAN, (t - 0.55) / 0.45)

    r, g, b = base
    cx, cy = 0.5, 0.28
    d1 = math.hypot(x_ratio - cx, y_ratio - cy * 0.85)
    glow1 = max(0.0, 1.0 - d1 / 0.72)
    r = min(255, int(r + CYAN[0] * glow1 * 0.10))
    g = min(255, int(g + CYAN[1] * glow1 * 0.10))
    b = min(255, int(b + CYAN[2] * glow1 * 0.08))

    d2 = math.hypot(x_ratio - 0.5, y_ratio - 0.42)
    glow2 = max(0.0, 1.0 - d2 / 0.38)
    r = min(255, int(r + PERI[0] * glow2 * 0.05))
    g = min(255, int(g + PERI[1] * glow2 * 0.05))
    b = min(255, int(b + PERI[2] * glow2 * 0.06))
    return r, g, b


def load_icon(path: Path) -> Image.Image:
    img = Image.open(path).convert("RGB")
    if img.size != (SIZE, SIZE):
        img = img.resize((SIZE, SIZE), Image.LANCZOS)
    return img.filter(ImageFilter.UnsharpMask(radius=1.2, percent=80, threshold=2))


def average_corner_color(img: Image.Image, inset: int = 6) -> tuple[int, int, int]:
    w, h = img.size
    samples = [
        img.getpixel((inset, inset)),
        img.getpixel((w - inset - 1, inset)),
        img.getpixel((inset, h - inset - 1)),
        img.getpixel((w - inset - 1, h - inset - 1)),
    ]
    return tuple(sum(sample[i] for sample in samples) // 4 for i in range(3))


def color_distance(a: tuple[int, int, int], b: tuple[int, int, int]) -> float:
    return math.sqrt(sum((a[i] - b[i]) ** 2 for i in range(3)))


def harmonize_background(img: Image.Image, backdrop: tuple[int, int, int]) -> Image.Image:
    """Blend the icon's flat background toward the launch backdrop color."""
    out = img.copy()
    pixels = out.load()
    w, h = out.size
    icon_bg = average_corner_color(out)
    cx, cy = w * 0.5, h * 0.5
    max_dist = w * 0.56
    threshold = 52

    for y in range(h):
        for x in range(w):
            rgb = pixels[x, y]
            dist_to_bg = color_distance(rgb, icon_bg)
            if dist_to_bg >= threshold:
                continue

            radial = math.hypot(x - cx, y - cy) / max_dist
            edge_weight = min(1.0, max(0.0, (radial - 0.18) / 0.82))
            bg_weight = 1.0 - min(1.0, dist_to_bg / threshold)
            blend = min(1.0, edge_weight * 0.72 + bg_weight * 0.55)

            pixels[x, y] = tuple(
                int(rgb[i] * (1 - blend) + backdrop[i] * blend) for i in range(3)
            )

    return out.filter(ImageFilter.GaussianBlur(radius=0.6))


def rounded_alpha_mask(size: int, corner_ratio: float = 0.22, feather_ratio: float = 0.028) -> Image.Image:
    radius = int(size * corner_ratio)
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size - 1, size - 1), radius=radius, fill=255)
    feather = max(2, int(size * feather_ratio))
    return mask.filter(ImageFilter.GaussianBlur(radius=feather))


def apply_soft_rounded_alpha(img: Image.Image, mask: Image.Image) -> Image.Image:
    rgba = img.convert("RGBA")
    rgba.putalpha(mask)
    return rgba


def add_inner_highlight(rgba: Image.Image) -> Image.Image:
    """Subtle top-edge highlight so the logo feels glassy, not pasted on."""
    w, h = rgba.size
    overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    radius = int(w * 0.22)
    draw.rounded_rectangle((1, 1, w - 2, h - 2), radius=radius, outline=(255, 255, 255, 28), width=max(1, w // 180))
    return Image.alpha_composite(rgba, overlay)


def make_launch_logo(source: Image.Image, output_size: int) -> Image.Image:
    work = max(output_size * 4, 512)
    icon = source.resize((work, work), Image.LANCZOS)
    icon = harmonize_background(icon, backdrop_color_at())

    mask = rounded_alpha_mask(work)
    logo = apply_soft_rounded_alpha(icon, mask)
    logo = add_inner_highlight(logo)
    return logo.resize((output_size, output_size), Image.LANCZOS)


def make_logo_glow(output_size: int) -> Image.Image:
    """Soft halo that sits behind the logo on the launch screen."""
    work = output_size * 4
    canvas = Image.new("RGBA", (work, work), (0, 0, 0, 0))
    cx, cy = work // 2, int(work * 0.52)
    px = canvas.load()

    for y in range(work):
        for x in range(work):
            d = math.hypot(x - cx, y - cy) / (work * 0.34)
            if d > 1:
                continue
            falloff = (1 - d) ** 1.8
            alpha = int(255 * falloff * 0.34)
            r = int(CYAN[0] * 0.55 + PERI[0] * 0.45)
            g = int(CYAN[1] * 0.55 + PERI[1] * 0.45)
            b = int(CYAN[2] * 0.55 + PERI[2] * 0.45)
            px[x, y] = (r, g, b, alpha)

    glow = canvas.filter(ImageFilter.GaussianBlur(radius=max(3, work // 28)))
    return glow.resize((output_size, output_size), Image.LANCZOS)


def write_imageset(
    directory: Path,
    stem: str,
    sizes: dict[str, int],
    maker,
    source: Image.Image | None = None,
) -> None:
    directory.mkdir(parents=True, exist_ok=True)
    for suffix, dim in sizes.items():
        filename = f"{stem}{suffix}.png"
        image = maker(source, dim) if source is not None else maker(dim)
        image.save(directory / filename, "PNG", optimize=True)


def main() -> None:
    if not SOURCE.exists():
        raise SystemExit(f"Missing source: {SOURCE}")

    icon = load_icon(SOURCE)
    assert icon.size == (SIZE, SIZE)

    APP_ICON.parent.mkdir(parents=True, exist_ok=True)
    icon.save(APP_ICON, "PNG", optimize=True)

    logo_sizes = {
        "": 120,
        "@2x": 240,
        "@3x": 360,
    }
    write_imageset(LOGO_DIR, "LaunchLogo", logo_sizes, make_launch_logo, icon)

    glow_sizes = {
        "": 160,
        "@2x": 320,
        "@3x": 480,
    }
    write_imageset(GLOW_DIR, "LaunchLogoGlow", glow_sizes, make_logo_glow)

    glow_contents = """{
  "images" : [
    { "filename" : "LaunchLogoGlow.png", "idiom" : "universal", "scale" : "1x" },
    { "filename" : "LaunchLogoGlow@2x.png", "idiom" : "universal", "scale" : "2x" },
    { "filename" : "LaunchLogoGlow@3x.png", "idiom" : "universal", "scale" : "3x" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
"""
    (GLOW_DIR / "Contents.json").write_text(glow_contents, encoding="utf-8")

    print(f"AppIcon ← {SOURCE.name} ({SIZE}×{SIZE})")
    print(f"LaunchLogo + LaunchLogoGlow regenerated with backdrop harmonization")


if __name__ == "__main__":
    main()
