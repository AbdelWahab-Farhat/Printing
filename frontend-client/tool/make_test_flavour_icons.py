"""أيقونةُ نسخة الاختبار — الأصلُ نفسه وعليه شريطٌ لا يُخطئه أحد.

المشكلة التي يحلّها: المُختبِرُ يحمل نسختين على الجهاز نفسه — الإنتاج والاختبار — ولو تشابهت
الأيقونتان فتح الخطأَ وأبلغ عنه، أو أبلغ عن عطلٍ في الإنتاج وهو في الاختبار.

فالتمييزُ يجب أن يُرى **من مشغّل التطبيقات** لا بعد الدخول: شريطٌ قطريّ يحمل كلمة TEST، ولاتينيّةً
لا عربية لأن PIL لا يشكّل العربية بلا مكتبة تشكيل — واسمُ التطبيق تحت الأيقونة عربيٌّ على كل حال
ويقول «تجريبي».

**أصفرُ لا برتقاليّ، بخلاف سكربت تطبيق الموظفين.** القاعدةُ هناك لونٌ ليس من هوية التطبيق كي ينشز،
والبرتقاليُّ هنا هو هويةُ فلايركس نفسُها — علامةُ X برتقالية — فشريطٌ برتقاليّ كان سيذوب فيها.

    python3 tool/make_test_flavour_icons.py
    dart run flutter_launcher_icons
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
BRANDING = ROOT / "assets" / "branding"
FONT = ROOT / "assets" / "fonts" / "Cairo-Black.ttf"

# أصفرُ تحذير — ليس من ألوان التطبيق عن قصد، فالغرضُ أن ينشزَ لا أن ينسجم.
BAND = (250, 204, 21, 255)
# الحبرُ الداكن من هوية فلايركس (Deep Ink ‎#0B1B2B): الأبيضُ على الأصفر لا يُقرأ.
INK = (11, 27, 43, 255)


def ribbon(source: Path, target: Path) -> None:
    base = Image.open(source).convert("RGBA")
    w, h = base.size

    # الشريطُ على طبقةٍ مستقلّة ثم يُدار: الدورانُ يُنعّم الحواف، والرسمُ المباشر يُسنّنها.
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
    # **يُركَّز الشريطُ المُدار على نقطة، لا يُلصَق من ركنه.** `expand=True` يكبّر اللوحةَ حول
    # المحتوى، فحسابُ الموضع من الحافّة يضع النصَّ حيث اتّفق — ويقصّه إن خرج. والنقطةُ في
    # الثلث السفليّ: العلامةُ تسكن الوسط، والمشغّلاتُ الدائرية تقصّ الأسفلَ أقلّ من الركن.
    cx, cy = w // 2, int(h * 0.72)
    out.alpha_composite(strip, (cx - strip.width // 2, cy - strip.height // 2))
    out.save(target)
    print(f"  {target.name}  {out.size[0]}×{out.size[1]}")


def main() -> None:
    print("أيقونات نسخة الاختبار:")
    ribbon(BRANDING / "icon_1024.png", BRANDING / "icon_1024_test.png")
    ribbon(BRANDING / "adaptive_foreground.png", BRANDING / "adaptive_foreground_test.png")


if __name__ == "__main__":
    main()
