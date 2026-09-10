import 'dart:ui' as ui;

import 'package:dayaa/features/tools/models/bag_type.dart';
import 'package:dayaa/features/tools/models/design_placement.dart';
import 'package:flutter/rendering.dart';

/// يرسم الكيس، ومنطقة الطباعة، والتصميم مقصوصاً عندها.
///
/// **رسّامٌ واحد للشاشة وللملف**، كما في `qr_code_painter.dart` ولنفس السبب: ما يُصدَّر هو
/// حرفياً ما كان معروضاً. والفارق الوحيد بينهما [showGuides] — خطوط الإرشاد تُرى أثناء العمل
/// وتختفي في النتيجة.
class BagPreviewPainter extends CustomPainter {
  const BagPreviewPainter({
    required this.bag,
    required this.mockup,
    required this.placement,
    required this.design,
    required this.showGuides,
    this.guideColor = const Color(0x66000000),
    this.marginColor = const Color(0x1A000000),
  });

  final BagType bag;

  /// صورة الكيس. `null` قبل أن تُفكّ — فتُرسم مساحةٌ فارغة بدل أن تقفز الشاشة حين تصل.
  final ui.Image? mockup;
  final DesignPlacement placement;

  /// التصميم المرفوع، أو `null` قبل أن يُرفع شيء.
  final ui.Image? design;

  /// حدود منطقة الطباعة والهامش المظلَّل.
  ///
  /// **تُرى أثناء التحريك وتُخفى في المعاينة النهائية.** أثناء العمل هي الشيء الوحيد الذي يقول
  /// للموظف أين تقف الطباعة؛ وفي النتيجة هي خطوطٌ ليست على الكيس، وإرسالها للزبون يجعله يسأل
  /// عن إطارٍ لم يطلبه.
  final bool showGuides;

  final Color guideColor;
  final Color marginColor;

  /// الصورة كلها داخل [size]، بنسبتها، في الوسط.
  ///
  /// الصورة مربّعة (١٢٠٠×١٢٠٠) وفيها الكيس وظلّه وخلفيته؛ تمطيطها لتملأ ما أُعطي يشوّه الكيس
  /// نفسه — والزبون يعرف شكل الكيس الذي طلبه.
  static Rect imageRectIn(Size size, ui.Image image) {
    final scale = (size.width / image.width) < (size.height / image.height)
        ? size.width / image.width
        : size.height / image.height;

    final width = image.width * scale;
    final height = image.height * scale;

    return Rect.fromLTWH((size.width - width) / 2, (size.height - height) / 2, width, height);
  }

  /// **وجه الكيس** داخل [imageRect] — وهو ما تُقتطع منه الهوامش بعد ذلك.
  ///
  /// انظر [BagType.face]: الكيس في الصورة يشغل جزءاً من الإطار، فلا يصحّ اقتطاع الهوامش من
  /// الصورة كلها — ٢ سم من ٣٥ ليست ٥٫٧١٪ من عرض **الصورة**، بل من عرض **الكيس**.
  static Rect faceIn(Rect imageRect, BagType bag) => Rect.fromLTRB(
    imageRect.left + imageRect.width * bag.face.left,
    imageRect.top + imageRect.height * bag.face.top,
    imageRect.left + imageRect.width * bag.face.right,
    imageRect.top + imageRect.height * bag.face.bottom,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final image = mockup;
    if (image == null) return;

    final imageRect = imageRectIn(size, image);
    final printArea = DesignPlacement.printAreaIn(faceIn(imageRect, bag), bag);

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      imageRect,
      Paint()..filterQuality = FilterQuality.high,
    );

    if (design case final artwork?) {
      canvas
        ..save()
        // **القصّ هو الشرط لا الزينة.** القيد في [DesignPlacement] يمنع الطرف من عبور الحافة،
        // وهذا يمنع البكسل من ذلك — وهما ليسا تكراراً: القيد حسابٌ قد يخطئ لحظةَ تغيّر مقاسٍ أو
        // دورانِ شاشة، والقصّ لا يخطئ. ما يخرج من منطقة الطباعة لا يُرسم، نقطة.
        ..clipRect(printArea)
        // `multiply` لا `srcOver`، وهو ما يفعله الموقع أيضاً: الحبر يُطبع **على** الكيس فيأخذ
        // تجاعيده وظلّه، ولا يقف فوقه ملصقاً مسطّحاً. تصميمٌ أبيض يختفي على كيسٍ أبيض — وهذا
        // صحيح، فهو كذلك في الطباعة.
        ..saveLayer(printArea, Paint()..blendMode = BlendMode.multiply)
        ..drawImageRect(
          artwork,
          Rect.fromLTWH(0, 0, artwork.width.toDouble(), artwork.height.toDouble()),
          placement.rectIn(
            printArea,
            Size(artwork.width.toDouble(), artwork.height.toDouble()),
          ),
          Paint()..filterQuality = FilterQuality.high,
        )
        ..restore()
        ..restore();
    }

    if (showGuides) _paintGuides(canvas, faceIn(imageRect, bag), printArea);
  }

  /// الهامش مظلَّلاً، وحدُّ منطقة الطباعة متقطّعاً.
  ///
  /// الظلُّ يقول «هنا لا يُطبع» بلا كلمة، والخطُّ المتقطّع يقول «وهذا هو الحدّ» — ومتقطّعاً
  /// لأن الخطّ المتصل يُقرأ حافةً مطبوعة على الكيس.
  void _paintGuides(Canvas canvas, Rect bagRect, Rect printArea) {
    canvas
      ..save()
      ..clipRect(bagRect)
      ..drawPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRect(bagRect),
          Path()..addRect(printArea),
        ),
        Paint()..color = marginColor,
      )
      ..restore();

    final dashes = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = guideColor;

    const dash = 6.0;
    const gap = 4.0;

    for (final metric in (Path()..addRect(printArea)).computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, (distance + dash).clamp(0, metric.length)),
          dashes,
        );
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(BagPreviewPainter oldDelegate) =>
      oldDelegate.bag != bag ||
      !identical(oldDelegate.mockup, mockup) ||
      oldDelegate.placement != placement ||
      !identical(oldDelegate.design, design) ||
      oldDelegate.showGuides != showGuides ||
      oldDelegate.guideColor != guideColor ||
      oldDelegate.marginColor != marginColor;
}
