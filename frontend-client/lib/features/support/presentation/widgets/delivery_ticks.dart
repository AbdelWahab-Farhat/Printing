import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// أين وصلت رسالتي: في الطريق، أو وصلت، أو قرأها الدعم.
enum Delivery {
  /// لم يقبلها الخادم بعد — ساعة.
  sending,

  /// قبلها الخادم ولم يفتح الدعم الخيط بعدها — ✓.
  sent,

  /// رآها الدعم — ✓✓.
  read,
}

/// الساعة، و✓، و✓✓ — مرسومةً لا من خطّ الأيقونات.
///
/// **مرسومةٌ لأن المجموعتين لا تملكانها معاً.** Cupertino لا علامة مزدوجة فيها، وعلامة Material
/// المزدوجة أعرض من أن تجلس بجانب الساعة في زاوية فقاعة. والعلامة تُقرأ بعددها لا بلونها، كما في
/// المرجع: اللون لون الوقت بجانبها.
///
/// **لا تنعكس في الاتجاه العربي**: ✓ شكلٌ يُعرف كما هو، لا سهمٌ يشير إلى جهة.
class DeliveryTicks extends StatelessWidget {
  const DeliveryTicks({required this.delivery, required this.color, super.key});

  final Delivery delivery;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final label = switch (delivery) {
      Delivery.sending => 'قيد الإرسال',
      Delivery.sent => 'أُرسلت',
      Delivery.read => 'قرأها الدعم',
    };

    return Semantics(
      label: label,
      child: CustomPaint(
        size: Size(delivery == Delivery.sending ? 11.w : 16.w, 11.w),
        painter: _TicksPainter(delivery: delivery, color: color),
      ),
    );
  }
}

class _TicksPainter extends CustomPainter {
  const _TicksPainter({required this.delivery, required this.color});

  final Delivery delivery;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.height / 11;
    final pen = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4 * unit
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    Offset at(double x, double y) => Offset(x * unit, y * unit);

    switch (delivery) {
      case Delivery.sending:
        final centre = at(5.5, 5.5);
        canvas
          ..drawCircle(centre, 4.6 * unit, pen)
          ..drawLine(centre, at(5.5, 2.8), pen)
          ..drawLine(centre, at(7.4, 5.5), pen);

      case Delivery.sent:
        canvas.drawPath(
          Path()
            ..moveTo(at(2.5, 6).dx, at(2.5, 6).dy)
            ..lineTo(at(5.8, 9.2).dx, at(5.8, 9.2).dy)
            ..lineTo(at(12.5, 2.2).dx, at(12.5, 2.2).dy),
          pen,
        );

      case Delivery.read:
        // الثانية تبدأ من حيث تنتهي ضلعُ الأولى الطويلة، فلا يتقاطع الخطّان — كما في المرجع.
        canvas
          ..drawPath(
            Path()
              ..moveTo(at(0.8, 6).dx, at(0.8, 6).dy)
              ..lineTo(at(4.1, 9.2).dx, at(4.1, 9.2).dy)
              ..lineTo(at(10.8, 2.2).dx, at(10.8, 2.2).dy),
            pen,
          )
          ..drawPath(
            Path()
              ..moveTo(at(7.6, 7.9).dx, at(7.6, 7.9).dy)
              ..lineTo(at(8.9, 9.2).dx, at(8.9, 9.2).dy)
              ..lineTo(at(15.4, 2.2).dx, at(15.4, 2.2).dy),
            pen,
          );
    }
  }

  @override
  bool shouldRepaint(_TicksPainter oldDelegate) =>
      oldDelegate.delivery != delivery || oldDelegate.color != color;
}
