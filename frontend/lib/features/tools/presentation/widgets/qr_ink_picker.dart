import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/features/tools/models/qr_ink.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// اختيار حبر الرمز: ألوانٌ سريعة في صفٍّ واحد، وآخِرُ القرص يفتح على أي لون.
///
/// **الصفُّ لا يلتفّ.** كان `Wrap` فالتفّ اللون الأخير إلى سطرٍ وحده على الهاتف — سطرٌ فيه قرصٌ
/// واحد يُقرأ خطأً في التخطيط لا صفَّ ألوان. وهو قابلٌ للتمرير أفقياً لا لأن الألوان لا تسعه —
/// ستةٌ ومنتقٍ تسعها ٤٣٠ منطقياً بمريح — بل لأن هاتفاً بعرض ٣٢٠ أو خطَّ نظامٍ مكبَّراً يجب أن
/// يُمرَّر لا أن يفيض.
class QrInkPicker extends StatelessWidget {
  const QrInkPicker({required this.selected, required this.onSelected, super.key});

  final Color selected;
  final ValueChanged<Color> onSelected;

  /// مفتاحان للاختبار وحدهما: سطحا المنتقي لا نصَّ فيهما ولا دور دلالياً يُعثر بهما عليهما،
  /// والنقر عند إحداثيٍّ بعينه داخلهما هو كلُّ ما يفعله المستخدم بهما.
  static const Key saturationKey = Key('qr-ink-saturation');
  static const Key hueKey = Key('qr-ink-hue');

  @override
  Widget build(BuildContext context) {
    // اللون المختار من خارج القائمة السريعة يُعرض على قرص المنتقي نفسه، فلا يبقى الصفُّ بلا
    // علامةٍ على ما هو مختارٌ الآن.
    final isCustom = !QrInk.palette.contains(selected);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'لون الرمز',
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 10.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final ink in QrInk.palette) ...[
                _Swatch(
                  ink: ink,
                  isSelected: ink == selected,
                  onTap: () => onSelected(ink),
                ),
                SizedBox(width: 12.w),
              ],
              _CustomSwatch(
                ink: isCustom ? selected : null,
                onTap: () async {
                  final picked = await showQrInkSheet(context, initial: selected);
                  if (picked != null) onSelected(picked);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// لونٌ واحد، وعلامة أنه المختار.
///
/// العلامة حلقةٌ حول القرص لا تكبيرٌ له: مقاس العنصر لا يتغيّر، فلا يزحف الصفّ كله عند كل اختيار
/// (§7 — الحركة).
class _Swatch extends StatelessWidget {
  const _Swatch({required this.ink, required this.isSelected, required this.onTap});

  final Color ink;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ink,
          border: Border.all(
            color: isSelected ? context.colorScheme.primary : context.colorScheme.outlineVariant,
            width: isSelected ? 3.w : 1.w,
          ),
        ),
      ),
    );
  }
}

/// آخِرُ الصفّ: يفتح على أي لون.
///
/// يحمل قوس الطيف حين لا يكون المختار من القائمة السريعة — فيقول «من هنا تُختار البقية» — ويحمل
/// اللون نفسه حين يكون مختاراً، فيكون هو علامةَ ما هو مطبَّقٌ الآن.
class _CustomSwatch extends StatelessWidget {
  const _CustomSwatch({required this.ink, required this.onTap});

  /// اللون المختار إن كان من خارج القائمة السريعة، وإلا `null`.
  final Color? ink;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ink,
          gradient: ink != null ? null : const SweepGradient(colors: _wheel),
          border: Border.all(
            color: ink != null ? scheme.primary : scheme.outlineVariant,
            width: ink != null ? 3.w : 1.w,
          ),
        ),
        child: ink != null
            ? null
            : Center(
                child: Container(
                  width: 18.w,
                  height: 18.w,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.surface),
                ),
              ),
      ),
    );
  }

  /// دورةُ الصبغة كاملة. آخرها أحمرُ أوّلها، وإلا ظهر خطٌّ حادّ حيث تلتقي نهاية القوس ببدايته.
  static const List<Color> _wheel = [
    Color(0xFFFF0000),
    Color(0xFFFFFF00),
    Color(0xFF00FF00),
    Color(0xFF00FFFF),
    Color(0xFF0000FF),
    Color(0xFFFF00FF),
    Color(0xFFFF0000),
  ];
}

/// يفتح منتقي اللون، ويعيد ما اختير — أو `null` إن أُغلق بلا اختيار.
Future<Color?> showQrInkSheet(BuildContext context, {required Color initial}) {
  return showModalBottomSheet<Color>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: context.colorScheme.surface,
    builder: (_) => _InkSheet(initial: initial),
  );
}

/// المنتقي: مربّع تشبّعٍ وإضاءة فوق شريط صبغة.
///
/// **مكتوبٌ هنا لا مأخوذٌ من حزمة**، لنفس سبب `flutter_map`: كل منتقٍ جاهز على pub يأتي بشاشته
/// وأزراره وألوانه المكتوبة، و§7 لا تسمح بلونٍ ثابتٍ في شاشة ولا بزرٍّ ليس [AppButton]. وما
/// نحتاجه منه مربّعٌ وشريطٌ ومقبضان.
class _InkSheet extends StatefulWidget {
  const _InkSheet({required this.initial});

  final Color initial;

  @override
  State<_InkSheet> createState() => _InkSheetState();
}

class _InkSheetState extends State<_InkSheet> {
  late HSVColor _hsv = HSVColor.fromColor(widget.initial);

  Color get _color => _hsv.toColor();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'لون مخصّص',
              style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 16.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: SizedBox(
                height: 200.h,
                child: _SaturationValueArea(
                  key: QrInkPicker.saturationKey,
                  hsv: _hsv,
                  onChanged: (hsv) => setState(() => _hsv = hsv),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: SizedBox(
                height: 28.h,
                child: _HueBar(
                  key: QrInkPicker.hueKey,
                  hsv: _hsv,
                  onChanged: (hsv) => setState(() => _hsv = hsv),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            AppButton(
              label: 'اختيار هذا اللون',
              onPressed: () => Navigator.of(context).pop(_color),
            ),
          ],
        ),
      ),
    );
  }
}

/// مربّع التشبّع والإضاءة عند صبغةٍ ثابتة: أفقياً التشبّع، وعمودياً الإضاءة.
class _SaturationValueArea extends StatelessWidget {
  const _SaturationValueArea({required this.hsv, required this.onChanged, super.key});

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
      ..drawRect(rect, Paint()..color = HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor())
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
  bool shouldRepaint(_SaturationValuePainter oldDelegate) => oldDelegate.hsv != hsv;
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
        void handle(Offset position) =>
            onChanged(hsv.withHue((1 - (position.dx / width).clamp(0.0, 1.0)) * 360));

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
            for (var hue = 0; hue <= 360; hue += 30) HSVColor.fromAHSV(1, hue % 360, 1, 1).toColor(),
          ],
        ).createShader(rect),
    );

    _drawCursor(canvas, Offset((1 - hsv.hue / 360) * size.width, size.height / 2));
  }

  @override
  bool shouldRepaint(_HueBarPainter oldDelegate) => oldDelegate.hsv.hue != hsv.hue;
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
