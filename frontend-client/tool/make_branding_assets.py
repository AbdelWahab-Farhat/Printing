#!/usr/bin/env python3
"""Derives the launcher-icon images from the one logo.

Run after replacing `assets/images/logo.png`:

    python tool/make_branding_assets.py
    dart run flutter_launcher_icons

**This is not the staff app's script, and the difference is the artwork.** That app's
`logo.png` is a bare mark on transparent space, so its script trims the margin and re-pads it
by platform. This app's `logo.png` is a *finished icon*: an orange X on flat `#16243C`,
full-bleed, with decorative shapes in two corners. Trimming and re-padding that would shrink
the whole navy square onto a transparent canvas, and the launcher would draw a small square
adrift in the middle of the icon.

So the two outputs are made differently:

* The legacy and iOS icon is the artwork itself, edge to edge. It is already composed; both
  platforms round the corners themselves.
* The Android adaptive foreground is the **mark alone** on transparency, with the navy moved to
  the background layer (`adaptive_icon_background` in pubspec.yaml). An adaptive icon is masked
  to a circle, a squircle or a rounded square depending on the launcher, and the two layers can
  be moved independently — parallax on drag. A foreground carrying its own opaque navy would
  slide against the background and show its edge, and the corner decorations would be eaten by
  every mask anyway.

Everything is written to `assets/branding/`, which is deliberately **not** in the `assets:` list
in pubspec.yaml: these are build inputs, not things the app loads at runtime.
"""

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "assets" / "images" / "logo.png"
OUT = ROOT / "assets" / "branding"

#: The artwork's own background, and the colour `adaptive_icon_background` must repeat. Taken
#: from the file rather than from `theme.dart`: the app's `surface` is `#0F2138`, a shade off
#: this, and an icon whose foreground was cut against one navy and laid on another shows a halo.
BACKGROUND = (22, 36, 60)

#: The mark's own orange, `#EB6234`. Also not the theme's `primary` (`#F4622A`) — same reason.
MARK = (235, 98, 52)

#: Coverage below this is treated as none. See [mark_only].
FLOOR = 0.1


def mark_only(logo: Image.Image) -> Image.Image:
    """The orange mark cut out of its navy, with the antialiased edge kept.

    **Colour-keying would fringe.** Every pixel along the X's edge is a blend of [MARK] and
    [BACKGROUND]; a threshold either keeps those pixels opaque — a dark outline around the mark
    — or drops them, leaving it jagged. Both are visible at launcher size.

    So the blend is undone instead of thresholded. Each pixel is `a·MARK + (1-a)·BACKGROUND` for
    some coverage `a`, and the red channel separates the two colours by 213 of 255, enough to
    recover `a` from it alone. The result is the mark in flat [MARK] with a true alpha edge.

    **[FLOOR] is not a threshold in disguise; it is what makes the crop right.** The decorative
    corner shapes are a lighter navy than the background, so un-mixing hands them a coverage of
    about 4% rather than none, and `getbbox` then sees almost the whole square. Cropping to that
    scaled the mark to 37% of the finished icon instead of 50% — an icon visibly smaller than
    every other on the shelf, from a rounding error in two corners nobody is looking at.
    """
    width, height = logo.size
    pixels = logo.load()
    out = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    written = out.load()

    span = MARK[0] - BACKGROUND[0]
    for y in range(height):
        for x in range(width):
            red = pixels[x, y][0]
            coverage = min(max((red - BACKGROUND[0]) / span, 0.0), 1.0)
            alpha = round(255 * coverage) if coverage >= FLOOR else 0
            if alpha:
                written[x, y] = (*MARK, alpha)

    return out.crop(out.getbbox())


def centred(mark: Image.Image, canvas: int, content: int) -> Image.Image:
    """`mark` scaled to `content` px, centred on a transparent `canvas` px square.

    `resize`, not `thumbnail`: thumbnail only ever shrinks, so with a 512 master every output
    here would silently keep its original size.
    """
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

    # The iOS app icon has to be exactly 1024, and this artwork is drawn edge to edge because it
    # arrived composed that way.
    #
    # Upscaling a 512 master is soft. A real 1024 export of the logo would be sharper, and
    # dropping one in over logo.png is all it takes.
    logo.resize((1024, 1024), Image.LANCZOS).save(OUT / "icon_1024.png")

    # Android adaptive foreground.
    #
    # The mark takes exactly half the artwork, so half of the finished icon is what reproduces
    # it — and half sits well inside the 66% safe zone. The arithmetic is not 50% of *this*
    # canvas, though: flutter_launcher_icons wraps this drawable in `android:inset="16%"`,
    # leaving it 68% of the icon to live in. So the mark takes 73.5% of this canvas —
    # 0.735 × 0.68 ≈ 0.50 — and the rest is the air that inset expects.
    centred(mark_only(logo), canvas=1024, content=753).save(OUT / "adaptive_foreground.png")

    print(f"wrote {OUT.relative_to(ROOT)}/: icon_1024, adaptive_foreground")


if __name__ == "__main__":
    main()
