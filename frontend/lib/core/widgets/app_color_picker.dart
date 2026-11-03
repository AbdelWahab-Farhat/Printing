import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// منتقي اللون — مربّع تشبّعٍ وإضاءة فوق شريط صبغة. **مكوّنٌ واحد للتطبيق كله**: حبر رمز QR
/// و«ألوان الطباعة» يرسمانه هو، فلا يكون في التطبيق منتقيان يختلفان في الشكل واللمس.
///
/// **مكتوبٌ هنا لا مأخوذٌ من حزمة**: كل منتقٍ جاهز على pub يأتي بشاشته وأزراره وألوانه المكتوبة،
/// و§7 لا تسمح بلونٍ ثابتٍ في شاشة ولا بزرٍّ ليس `AppButton`. وما نحتاجه منه مربّعٌ وشريطٌ
/// ومقبضان.
///
/// يأخذ [HSVColor] ويعيده لا [Color]: الرمادي لا صبغة له في RGB، فلو مرّ اللون بـ RGB بين لمستين
/// لقفز شريط الصبغة إلى الأحمر كلما نزل أحدٌ بالمربّع إلى الرمادي.
class AppColorPicker extends StatelessWidget {
  const AppColorPicker({
    required this.color,
    required this.onChanged,
    this.areaHeight,
    super.key,
  });

  final HSVColor color;
  final ValueChanged<HSVColor> onChanged;

  /// ارتفاع المربّع — ١٧٢ إن لم يُعطَ.
  final double? areaHeight;

  /// مفتاحان للاختبار وحدهما: سطحا المنتقي لا نصَّ فيهما ولا دور دلالياً يُعثر بهما عليهما،
  /// والنقر عند إحداثيٍّ بعينه داخلهما هو كلُّ ما يفعله المستخدم بهما.
  static const Key saturationKey = Key('color-picker-saturation');
  static const Key hueKey = Key('color-picker-hue');

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: SizedBox(
            height: areaHeight ?? 172.h,
            child: _SaturationValueArea(
              key: saturationKey,
              hsv: color,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: SizedBox(
            height: 26.h,
            child: _HueBar(key: hueKey, hsv: color, onChanged: onChanged),
          ),
        ),
      ],
    );
  }
}

/// مربّع التشبّع والإضاءة عند صبغةٍ ثابتة: أفقياً التشبّع، وعمودياً الإضاءة.
class _SaturationValueArea extends StatelessWidget {
  const _SaturationValueArea({
    required this.hsv,
    required this.onChanged,
    super.key,
  });

  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;

        void handle(Offset position) {
          // **مقلوبٌ في العربية:** يمين المربّع تشبّعٌ صفر ويساره تشبّعٌ كامل، لأن اللوحة تُقرأ
          // من اليمين كما يُقرأ كل شيء في هذا التطبيق.
          final saturation = 1 - (position.dx / size.width).clamp(0.0, 1.0);
          final value = 1 - (position.dy / size.height).clamp(0.0, 1.0);

          onChanged(hsv.withSaturation(saturation).withValue(value));
        }

        return GestureDetector(
          onPanDown: (details) => handle(details.localPosition),
          onPanUpdate: (details) => handle(details.localPosition),
          child: CustomPaint(
            painter: _SaturationValuePainter(hsv),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}

class _SaturationValuePainter extends CustomPainter {
  const _SaturationValuePainter(this.hsv);

  final HSVColor hsv;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // الصبغة الخالصة، ثم أبيضُ يتناقص نحو اليسار (التشبّع)، ثم أسودُ يتزايد نحو الأسفل (الإضاءة).
    canvas
      ..drawRect(
        rect,
        Paint()..color = HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor(),
      )
      ..drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [Color(0xFFFFFFFF), Color(0x00FFFFFF)],
          ).createShader(rect),
      )
      ..drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x00000000), Color(0xFF000000)],
          ).createShader(rect),
      );

    _drawCursor(
      canvas,
      Offset((1 - hsv.saturation) * size.width, (1 - hsv.value) * size.height),
    );
  }

  @override
  bool shouldRepaint(_SaturationValuePainter oldDelegate) =>
      oldDelegate.hsv != hsv;
}

/// شريط الصبغة.
class _HueBar extends StatelessWidget {
  const _HueBar({required this.hsv, required this.onChanged, super.key});

  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // مقلوبٌ كالمربّع: الصفر على اليمين.
        void handle(Offset position) => onChanged(
          hsv.withHue((1 - (position.dx / width).clamp(0.0, 1.0)) * 360),
        );

        return GestureDetector(
          onPanDown: (details) => handle(details.localPosition),
          onPanUpdate: (details) => handle(details.localPosition),
          child: CustomPaint(
            painter: _HueBarPainter(hsv),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}

class _HueBarPainter extends CustomPainter {
  const _HueBarPainter(this.hsv);

  final HSVColor hsv;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            for (var hue = 0; hue <= 360; hue += 30)
              HSVColor.fromAHSV(1, hue % 360, 1, 1).toColor(),
          ],
        ).createShader(rect),
    );

    _drawCursor(
      canvas,
      Offset((1 - hsv.hue / 360) * size.width, size.height / 2),
    );
  }

  @override
  bool shouldRepaint(_HueBarPainter oldDelegate) =>
      oldDelegate.hsv.hue != hsv.hue;
}

/// المقبض: حلقةٌ بيضاء بخطٍّ أسود حولها.
///
/// اللونان ثابتان عمداً وليسا من الثيم: المقبض يقف فوق كل ألوان الطيف، ولونٌ من اللوحة كان
/// سيختفي فوق نفسه. الأبيضُ داخل الأسود يُرى فوق الفاتح والداكن معاً.
void _drawCursor(Canvas canvas, Offset center) {
  canvas
    ..drawCircle(
      center,
      9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFFFFFFFF),
    )
    ..drawCircle(
      center,
      10.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0x66000000),
    );
}
