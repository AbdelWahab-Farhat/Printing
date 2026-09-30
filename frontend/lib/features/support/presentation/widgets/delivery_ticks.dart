import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// أين وصل ردُّ المحل: وصل، أو قرأه العميل.
///
/// **لا «في الطريق» هنا** خلافاً لتطبيق العميل: الردُّ هنا يُرسل والصندوقُ ينتظر جوابه، فلا فقاعةَ
/// تُرسم قبل أن يقبلها الخادم.
enum Delivery {
  /// قبلها الخادم ولم يفتح العميل الخيط بعدها — ✓.
  sent,

  /// رآها العميل — ✓✓.
  read,
}

/// ✓ و✓✓ — مرسومتين لا من خطّ الأيقونات، كما في تطبيق العميل.
///
/// **مرسومتان لأن المجموعتين لا تملكانهما معاً.** Cupertino لا علامة مزدوجة فيها، وعلامة Material
/// المزدوجة أعرض من أن تجلس بجانب الوقت في زاوية فقاعة. والعلامة تُقرأ بعددها لا بلونها، كما في
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
      Delivery.sent => 'وصلت',
      Delivery.read => 'قرأها العميل',
    };

    return Semantics(
      label: label,
      child: CustomPaint(
        size: Size(16.w, 11.w),
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
