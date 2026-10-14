#!/usr/bin/env python3
"""Generates BitInstantView iOS app icon assets and in-app branding images
from the single authoritative source logo.

This script is a one-off build utility (not part of the Flutter app itself)
kept in the repository so icon regeneration is reproducible if the source
logo is ever replaced. It intentionally does not redraw, recolor, or distort
the supplied artwork: it only (a) flattens the logo's transparent corners
onto the brand gold backdrop so Xcode receives a fully opaque square asset
(iOS applies its own corner rounding at render time) and (b) resizes that
flattened square to each dimension Apple's AppIcon.appiconset requires.
"""
from __future__ import annotations

import pathlib

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCE_LOGO = ROOT / "assets" / "branding" / "bitinstantview_logo_source.png"
BRANDING_DIR = ROOT / "assets" / "branding"
APPICON_DIR = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
LAUNCHIMAGE_DIR = ROOT / "ios" / "Runner" / "Assets.xcassets" / "LaunchImage.imageset"

# Sampled directly from the supplied logo's opaque gold fill (see inspection
# notes in docs/APP_STORE_READINESS.md). Used only to flatten the fully
# transparent corner padding of the source file -- every opaque pixel of the
# original artwork is preserved unchanged.
BACKDROP_GOLD = (231, 173, 0, 255)  # matches brand "Deep gold" #E7AD00

ICON_SPECS = [
    # (filename, size_points, scale)
    ("Icon-App-20x20@1x.png", 20, 1),
    ("Icon-App-20x20@2x.png", 20, 2),
    ("Icon-App-20x20@3x.png", 20, 3),
    ("Icon-App-29x29@1x.png", 29, 1),
    ("Icon-App-29x29@2x.png", 29, 2),
    ("Icon-App-29x29@3x.png", 29, 3),
    ("Icon-App-40x40@1x.png", 40, 1),
    ("Icon-App-40x40@2x.png", 40, 2),
    ("Icon-App-40x40@3x.png", 40, 3),
    ("Icon-App-60x60@2x.png", 60, 2),
    ("Icon-App-60x60@3x.png", 60, 3),
    ("Icon-App-76x76@1x.png", 76, 1),
    ("Icon-App-76x76@2x.png", 76, 2),
    ("Icon-App-83.5x83.5@2x.png", 83.5, 2),
    ("Icon-App-1024x1024@1x.png", 1024, 1),
]


def build_master_icon() -> Image.Image:
    """Flattens the source logo onto an opaque gold backdrop and returns a
    square, alpha-free master image at 1024x1024.

    The source file has a small fully-transparent margin around the rounded
    gold artwork (confirmed by inspecting the alpha channel). We crop tightly
    to that artwork's bounding box first, so the icon fills the entire
    1024x1024 canvas edge-to-edge -- matching how iOS itself will apply the
    system corner mask on top -- instead of leaving a double rounded-corner
    frame (the artwork's own rounded corners nested inside a second,
    system-applied rounding). No opaque pixel of the original artwork is
    redrawn, recolored, or distorted; only the surrounding transparent
    padding is flattened onto the matching brand gold.
    """
    logo = Image.open(SOURCE_LOGO).convert("RGBA")
    bbox = logo.split()[3].getbbox()
    cropped = logo.crop(bbox) if bbox else logo

    backdrop = Image.new("RGBA", cropped.size, BACKDROP_GOLD)
    flattened = Image.alpha_composite(backdrop, cropped).convert("RGB")

    side = max(flattened.size)
    square = Image.new("RGB", (side, side), BACKDROP_GOLD[:3])
    offset = ((side - flattened.size[0]) // 2, (side - flattened.size[1]) // 2)
    square.paste(flattened, offset)

    return square.resize((1024, 1024), Image.LANCZOS)


def export_app_icons(master: Image.Image) -> None:
    APPICON_DIR.mkdir(parents=True, exist_ok=True)
    for filename, points, scale in ICON_SPECS:
        pixels = round(points * scale)
        resized = master.resize((pixels, pixels), Image.LANCZOS)
        assert resized.mode == "RGB", "App Store icons must not carry an alpha channel"
        resized.save(APPICON_DIR / filename, format="PNG")
        print(f"wrote {filename}: {pixels}x{pixels}")


def export_branding_image() -> None:
    """Exports the UI-facing branding image (splash/settings) with its
    original transparency intact -- only the App Store icon needs the
    opaque-corner treatment.

    Uses Flutter's resolution-variant directory convention (`2.0x/`,
    `3.0x/` subfolders sharing the base filename) so a single
    `Image.asset('assets/branding/bitinstantview_logo.png')` call
    automatically picks the right density, instead of an `@2x`/`@3x` suffix
    (the iOS asset-catalog convention) that Flutter's asset bundler does not
    resolve on its own.
    """
    logo = Image.open(SOURCE_LOGO).convert("RGBA")
    alpha_bbox = logo.split()[3].getbbox()
    cropped = logo.crop(alpha_bbox) if alpha_bbox else logo

    for directory, scale in ((BRANDING_DIR, 1), (BRANDING_DIR / "2.0x", 2), (BRANDING_DIR / "3.0x", 3)):
        directory.mkdir(parents=True, exist_ok=True)
        target = 240 * scale
        resized = cropped.resize((target, target), Image.LANCZOS)
        resized.save(directory / "bitinstantview_logo.png", format="PNG")
        print(f"wrote {directory.name or 'branding'}/bitinstantview_logo.png: {target}x{target}")


def export_launch_image() -> None:
    """Overwrites the native iOS launch-screen image (LaunchScreen.storyboard
    centers this asset over a white background) with the brand logo, keeping
    its original transparency."""
    logo = Image.open(SOURCE_LOGO).convert("RGBA")
    bbox = logo.split()[3].getbbox()
    cropped = logo.crop(bbox) if bbox else logo

    LAUNCHIMAGE_DIR.mkdir(parents=True, exist_ok=True)
    for filename, scale in (
        ("LaunchImage.png", 1),
        ("LaunchImage@2x.png", 2),
        ("LaunchImage@3x.png", 3),
    ):
        target = 120 * scale
        resized = cropped.resize((target, target), Image.LANCZOS)
        resized.save(LAUNCHIMAGE_DIR / filename, format="PNG")
        print(f"wrote {filename}: {target}x{target}")


def main() -> None:
    master = build_master_icon()
    master.save(BRANDING_DIR / "bitinstantview_icon_master_1024.png", format="PNG")
    export_app_icons(master)
    export_branding_image()
    export_launch_image()


if __name__ == "__main__":
    main()
