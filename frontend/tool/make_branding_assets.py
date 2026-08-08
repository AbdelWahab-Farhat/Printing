#!/usr/bin/env python3
"""Derives the launcher-icon and splash-screen images from the one logo.

Run after replacing `assets/images/logo.png`:

    python3 tool/make_branding_assets.py
    dart run flutter_launcher_icons
    dart run flutter_native_splash:create

**Why derive rather than hand a single file to both generators.** Two of the three outputs are
not the logo — they are the logo inside a specific amount of empty space, and the amount is
dictated by the platform:

* An Android adaptive icon is masked to a circle, a squircle or a rounded square depending on
  the launcher, and only the middle 66% of it is guaranteed to survive. A full-bleed logo comes
  out with its corners shaved off on some phones and not others.
* Android 12's splash draws the icon inside a 768px circle on a 1152px canvas. Anything outside
  that circle is clipped.

The generators scale what they are given; they do not know how much of it must be air. So the
air is added here, once, and the numbers below are the platforms' own.

Everything is written to `assets/branding/`, which is deliberately **not** in the `assets:` list
in pubspec.yaml: these are build inputs, not things the app loads at runtime. Only
`assets/images/logo.png` is shipped, and the in-app splash screen draws that one.
"""

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "assets" / "images" / "logo.png"
OUT = ROOT / "assets" / "branding"


def trimmed(logo: Image.Image) -> Image.Image:
    """The mark itself, with the file's own transparent margin cut away.

    Every size below is a fraction of *the mark*, and `logo.png` carries about a quarter of its
    width as empty space on each side. Measuring against the file instead of against the ink
    silently shrinks every output — the first cut of this script put the launcher icon's mark at
    45% of the canvas while claiming 88%.
    """
    box = logo.getbbox()

    return logo.crop(box) if box else logo


def centred(logo: Image.Image, canvas: int, content: int) -> Image.Image:
    """The mark scaled to `content` px, centred on a transparent `canvas` px square.

    `resize`, not `thumbnail`: thumbnail only ever shrinks, so with a 512 master every output
    here silently kept its original size and no amount of correcting the numbers moved it.
    """
    mark = trimmed(logo)
    ratio = content / max(mark.width, mark.height)
    scaled = mark.resize(
        (max(1, round(mark.width * ratio)), max(1, round(mark.height * ratio))),
        Image.LANCZOS,
    )

    frame = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    frame.paste(
        scaled,
        ((canvas - scaled.width) // 2, (canvas - scaled.height) // 2),
        scaled,
    )

    return frame


def main() -> None:
    logo = Image.open(SOURCE).convert("RGBA")
    if logo.width != logo.height:
        raise SystemExit(f"{SOURCE} must be square; it is {logo.width}×{logo.height}")
    if logo.width < 512:
        raise SystemExit(f"{SOURCE} is {logo.width}px — too small to make an icon from")

    OUT.mkdir(parents=True, exist_ok=True)

    # The iOS app icon has to be exactly 1024, and it is drawn edge to edge — iOS rounds the
    # corners itself. 80% is the usual weight for a mark on that square: full-bleed touches the
    # rounding, and much less floats.
    #
    # Upscaling a 512 master is soft. A real 1024 export of the logo would be sharper, and
    # dropping one in over logo.png is all it takes.
    centred(logo, canvas=1024, content=819).save(OUT / "icon_1024.png")

    # Android adaptive foreground.
    #
    # The target is the logo filling ~60% of the finished icon — the safe zone is 66%, and a
    # mark at 60% reads right under every mask. The arithmetic is not 60% of *this* file,
    # though: flutter_launcher_icons wraps this drawable in `android:inset="16%"`, leaving it
    # 68% of the icon to live in. So the logo takes 88% of this canvas — 0.88 × 0.68 ≈ 0.60 —
    # and the padding here exists only to keep the LANCZOS resize off the very edge.
    #
    # Feeding a full-bleed logo instead would put it at 68% and shave its corners on a circular
    # mask; feeding it at 60% here would land it at 41%, adrift in the middle of the icon.
    centred(logo, canvas=1024, content=901).save(OUT / "adaptive_foreground.png")

    # Android 12 splash: a 1152 canvas of which only the middle 768 circle is drawn. The mark
    # takes 60% of that circle — Material's own proportion for an unmasked icon.
    centred(logo, canvas=1152, content=461).save(OUT / "splash_android_12.png")

    print(f"wrote {OUT.relative_to(ROOT)}/: icon_1024, adaptive_foreground, splash_android_12")


if __name__ == "__main__":
    main()
