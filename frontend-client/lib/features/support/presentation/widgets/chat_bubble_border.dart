import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// شكلُ فقاعة المحادثة: مستطيلٌ مدوّر، وذيلٌ صغير عند زاويته السفلى من جهة المتكلّم.
///
/// **على طريقة تيليغرام.** الذيل تحت آخر رسالةٍ من السلسلة وحدها، يشير إلى الحافة التي عليها
/// المتكلّم؛ وزوايا جهته داخل السلسلة أصغر، فتُقرأ الرسائل المتتابعة دوراً واحداً لا أدواراً.
///
/// **[atEnd] لا «يمين» ولا «يسار».** رسائلي في نهاية السطر ورسائل الدعم في بدايته، و`end` في
/// هذا التطبيق العربي هو اليسار — يُحلّ مقابل الاتجاه المحيط، كما في شاشة الملاحظات.
///
/// **الذيل يُرسم خارج المستطيل** بعرض [tailWidth]، فيحجز حاملُ الفقاعة ذلك العرض من جهتها كي
/// لا يلمس الذيلُ الحافة ولا ما يجاورها — انظر [ChatBubbleBorder.tailWidth].
class ChatBubbleBorder extends ShapeBorder {
  const ChatBubbleBorder({
    required this.atEnd,
    this.hasTail = false,
    this.startsRun = true,
    this.radius = 16,
    this.tightRadius = 6,
    this.tailWidth = 7,
    this.side = BorderSide.none,
  });

  /// الفقاعة في نهاية السطر (رسائلي)، أم في بدايته (الدعم).
  final bool atEnd;

  /// آخرُ رسالةٍ في سلسلتها: الذيل مكان زاويتها السفلى من جهة المتكلّم.
  final bool hasTail;

  /// أوّلُ رسالةٍ في سلسلتها: زاويتها العليا من جهة المتكلّم كاملة الاستدارة.
  final bool startsRun;

  final double radius;

  /// زوايا جهة المتكلّم داخل السلسلة.
  final double tightRadius;

  final double tailWidth;

  /// الشعرة حول الفقاعة. `BorderSide.none` لا يُرسم شيئاً.
  final BorderSide side;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  ShapeBorder scale(double t) => ChatBubbleBorder(
    atEnd: atEnd,
    hasTail: hasTail,
    startsRun: startsRun,
    radius: radius * t,
    tightRadius: tightRadius * t,
    tailWidth: tailWidth * t,
    side: side.scale(t),
  );

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    // يُرسم الشكل كأن المتكلّم على اليمين، ثم يُعكس حين تكون جهته اليسار.
    final speakerOnRight = atEnd == (textDirection == TextDirection.ltr);
    final path = _speakerOnRight(rect);

    if (speakerOnRight) return path;

    final mirror = Matrix4.identity()
      ..translateByDouble(rect.left + rect.right, 0, 0, 1)
      ..scaleByDouble(-1, 1, 1, 1);

    return path.transform(mirror.storage);
  }

  Path _speakerOnRight(Rect rect) {
    final outer = Radius.circular(radius.clamp(0, rect.shortestSide / 2));
    final topSpeaker = Radius.circular(
      (startsRun ? radius : tightRadius).clamp(0, rect.shortestSide / 2),
    );
    final bottomSpeaker = Radius.circular(tightRadius.clamp(0, rect.shortestSide / 2));

    final path = Path()
      ..moveTo(rect.left + outer.x, rect.top)
      ..lineTo(rect.right - topSpeaker.x, rect.top)
      ..arcToPoint(Offset(rect.right, rect.top + topSpeaker.y), radius: topSpeaker);

    if (hasTail) {
      // الحافة تنزل مستقيمةً، ثم تنعطف إلى الخارج في رأسٍ صغير على خطّ القاع.
      final rise = (tailWidth * 1.6).clamp(0, rect.height - topSpeaker.y).toDouble();

      path
        ..lineTo(rect.right, rect.bottom - rise)
        ..cubicTo(
          rect.right,
          rect.bottom - rise * 0.35,
          rect.right + tailWidth * 0.45,
          rect.bottom - 0.6,
          rect.right + tailWidth,
          rect.bottom,
        )
        ..lineTo(rect.right - tailWidth * 0.2, rect.bottom);
    } else {
      path
        ..lineTo(rect.right, rect.bottom - bottomSpeaker.y)
        ..arcToPoint(Offset(rect.right - bottomSpeaker.x, rect.bottom), radius: bottomSpeaker);
    }

    return path
      ..lineTo(rect.left + outer.x, rect.bottom)
      ..arcToPoint(Offset(rect.left, rect.bottom - outer.y), radius: outer)
      ..lineTo(rect.left, rect.top + outer.y)
      ..arcToPoint(Offset(rect.left + outer.x, rect.top), radius: outer)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width == 0) return;

    canvas.drawPath(
      getOuterPath(rect, textDirection: textDirection),
      side.toPaint()..strokeJoin = ui.StrokeJoin.round,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ChatBubbleBorder &&
      other.atEnd == atEnd &&
      other.hasTail == hasTail &&
      other.startsRun == startsRun &&
      other.radius == radius &&
      other.tightRadius == tightRadius &&
      other.tailWidth == tailWidth &&
      other.side == side;

  @override
  int get hashCode =>
      Object.hash(atEnd, hasTail, startsRun, radius, tightRadius, tailWidth, side);
}
