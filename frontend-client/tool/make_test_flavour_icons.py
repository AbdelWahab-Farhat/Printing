"""The test build's icon: the production icon with a band across it nobody can miss.

The problem it solves: a tester carries both builds on the same phone, production and test. If
the two icons look alike they open the wrong one and report against it, or report a production
bug that is really in the test build.

So the difference has to show **on the launcher**, not after opening the app: a diagonal band
reading TEST. Latin rather than Arabic, because PIL cannot shape Arabic without a shaping
library, and the name under the icon is Arabic anyway and says «تجريبي».

**A red-orange band, the same as the staff app's.** The rule is a colour that is not in the
app's identity, so it clashes instead of blending in. The Daaya mark is yellow, purple and
green; orange is in none of them. (The FlyerX build used yellow here, because its mark was
orange. The Daaya mark's yellow fill would swallow a yellow band.)

    python3 tool/make_test_flavour_icons.py
    dart run flutter_launcher_icons
"""

from __future__ import annotations

from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
BRANDING = ROOT / "assets" / "branding"
FONT = ROOT / "assets" / "fonts" / "Cairo-Black.ttf"

# A warning orange, deliberately not one of the app's colours: the point is to clash.
BAND = (234, 88, 12, 255)
INK = (255, 255, 255, 255)

#: The test icon's background, `#1b1449`: the same value as `adaptive_icon_background` and
#: `background_color_ios` in flutter_launcher_icons-dev.yaml. It is what makes the customer test
#: build the dark one beside the staff app's white test icon.
BACKGROUND = (27, 20, 73, 255)


def defringed(image: Image.Image, reach: int = 8) -> Image.Image:
    """Every pixel that is not fully opaque takes the colour of its nearest opaque neighbour.

    **Why the test icons need this and production does not.** The logo's soft edge pixels carry
    stray colours, some near black and some a bright green. On white they blend away. The test
    icon sits on indigo (see `flutter_launcher_icons-dev.yaml`), and there they draw a thin halo
    around every line. Alpha is kept, so the edge stays smooth; only its colour changes.

    A breadth-first walk outward from the opaque pixels, `reach` pixels deep. Transparent pixels
    are recoloured too, because the launcher generator downsizes without premultiplying, and a
    transparent pixel's colour then bleeds into its neighbours.
    """
    out = image.copy()
    px = out.load()
    w, h = out.size
    seen = [[False] * w for _ in range(h)]
    queue: deque[tuple[int, int, int]] = deque()
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 255:
                seen[y][x] = True
                queue.append((x, y, 0))

    while queue:
        x, y, depth = queue.popleft()
        if depth >= reach:
            continue
        r, g, b, _ = px[x, y]
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and not seen[ny][nx]:
                seen[ny][nx] = True
                px[nx, ny] = (r, g, b, px[nx, ny][3])
                queue.append((nx, ny, depth + 1))

    return out


def ribbon(source: Path, target: Path, *, flatten: bool = False) -> None:
    base = defringed(Image.open(source).convert("RGBA"))
    w, h = base.size

    # The band is drawn on its own layer and then rotated: rotation antialiases the edges,
    # drawing it at an angle directly would leave them jagged.
    strip_h = int(h * 0.19)
    strip = Image.new("RGBA", (int(w * 1.6), strip_h), BAND)

    draw = ImageDraw.Draw(strip)
    font = ImageFont.truetype(str(FONT), int(strip_h * 0.62))
    text = "TEST"
    left, top, right, bottom = draw.textbbox((0, 0), text, font=font)
    draw.text(
        ((strip.width - (right - left)) / 2 - left, (strip_h - (bottom - top)) / 2 - top),
        text,
        font=font,
        fill=INK,
    )

    strip = strip.rotate(-30, expand=True, resample=Image.BICUBIC)

    out = base.copy()
    # **The rotated band is centred on a point, not pasted from its corner.** `expand=True`
    # grows the canvas around the content, so a position measured from the edge lands the text
    # wherever it happens to, and clips it if it falls outside. The point sits in the lower
    # third: the mark lives in the middle, and circular launchers crop the bottom less than the
    # corners.
    cx, cy = w // 2, int(h * 0.72)
    out.alpha_composite(strip, (cx - strip.width // 2, cy - strip.height // 2))

    # **Flattened here, not by the generator.** `remove_alpha_ios` in flutter_launcher_icons
    # blends edge pixels wrongly onto a dark background: a nearly transparent purple pixel comes
    # out bright green, and every line gets a green halo. On the white production icon the same
    # bug is invisible. Handing it an image with no transparency leaves it nothing to blend.
    if flatten:
        out = Image.alpha_composite(Image.new("RGBA", out.size, BACKGROUND), out)

    out.save(target)
    print(f"  {target.name}  {out.size[0]}×{out.size[1]}")


def main() -> None:
    print("test-flavour icons:")
    # The iOS and legacy Android icon, flattened onto the background. The adaptive foreground
    # stays transparent: Android lays it over `adaptive_icon_background` itself, correctly.
    ribbon(BRANDING / "icon_1024.png", BRANDING / "icon_1024_test.png", flatten=True)
    ribbon(BRANDING / "adaptive_foreground.png", BRANDING / "adaptive_foreground_test.png")


if __name__ == "__main__":
    main()
