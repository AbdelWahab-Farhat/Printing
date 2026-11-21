#!/usr/bin/env python3
"""Derives the launcher-icon images from the one logo.

Run after replacing `assets/images/logo.png`:

    python3 tool/make_branding_assets.py
    python3 tool/make_test_flavour_icons.py
    dart run flutter_launcher_icons

**The logo is the Daaya mark, the same file the staff app ships**: three rounded squares (a
purple outline, a green outline and a yellow fill) on transparent space, with about a quarter
of the file's width as margin on each side. So this script works the way the staff app's does,
by trimming that margin and re-padding the mark by platform. It differs only in skipping the
Android 12 splash image, because this app has no native splash yet (see the note above
`flutter_launcher_icons` in pubspec.yaml).

**Why derive rather than hand the logo straight to the generator.** Both outputs are the mark
inside a platform-specific amount of empty space:

* iOS draws the icon edge to edge and rounds the corners itself, so the mark needs air around
  it or it touches the rounding.
* An Android adaptive icon is masked to a circle, a squircle or a rounded square depending on
  the launcher, and only the middle 66% is guaranteed to survive.

The generator scales what it is given; it does not know how much of it must be air. So the air
is added here, once, and the numbers below are the platforms' own.

The transparent background becomes white on every platform: `background_color_ios` and
`adaptive_icon_background` in pubspec.yaml. White is what the logo was drawn on.

Everything is written to `assets/branding/`, which is deliberately **not** in the `assets:` list
in pubspec.yaml: these are build inputs. Only `assets/images/logo.png` ships, and `BrandMark`
draws that one.
"""

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "assets" / "images" / "logo.png"
OUT = ROOT / "assets" / "branding"


def trimmed(logo: Image.Image) -> Image.Image:
    """The mark itself, with the file's own transparent margin cut away.

    Every size below is a fraction of *the mark*. Measuring against the file instead of the ink
    would silently shrink every output by the width of that margin.
    """
    box = logo.getbbox()

    return logo.crop(box) if box else logo


def centred(logo: Image.Image, canvas: int, content: int) -> Image.Image:
    """The mark scaled to `content` px, centred on a transparent `canvas` px square.

    `resize`, not `thumbnail`: thumbnail only ever shrinks, so with a 512 master every output
    here would silently keep its original size.
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

    # The iOS app icon has to be exactly 1024. 80% is the usual weight for a mark on that
    # square: full-bleed touches the rounding, and much less floats.
    #
    # Upscaling a 512 master is soft. A real 1024 export of the logo would be sharper, and
    # dropping one in over logo.png is all it takes.
    centred(logo, canvas=1024, content=819).save(OUT / "icon_1024.png")

    # Android adaptive foreground.
    #
    # The target is the mark filling ~60% of the finished icon: the safe zone is 66%, and a
    # mark at 60% reads right under every mask. flutter_launcher_icons wraps this drawable in
    # `android:inset="16%"`, leaving it 68% of the icon to live in, so the mark takes 88% of
    # this canvas (0.88 × 0.68 ≈ 0.60).
    centred(logo, canvas=1024, content=901).save(OUT / "adaptive_foreground.png")

    print(f"wrote {OUT.relative_to(ROOT)}/: icon_1024, adaptive_foreground")


if __name__ == "__main__":
    main()
