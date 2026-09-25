import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/fixed_point.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// الكمية: رقمٌ كبير في وسط الصف فوق السلايدر، والسلايدر تحته بزرّي − و+ على طرفيه — الخيار
/// «أ» من صف «الكمية» في لوحة صفحة المنتج.
///
/// **الرقم على محور السلايدر**، فالرقم والسلايدر والزرّان قطعةٌ واحدة تُقرأ معاً، ولا صندوق حوله:
/// الصندوق على طرف سطر «الكمية» كان يُقرأ حقلاً ضائعاً بعيداً عن السلايدر الذي يغيّره. الخط
/// المتقطّع تحته يقول إنه يُلمس: لمسه يفتح ورقة الكتابة ([onEdit]).
///
/// ثلاثة طرقٍ إلى رقمٍ واحد: السلايدر للتقريب السريع، و− و+ للخطوة الواحدة بلا ارتجاف الإصبع،
/// والورقة لأي كميةٍ بعينها — وما فوق آخر السلايدر لا يُطلب إلا كتابةً. لا شيء هنا يقرّر: الخطوة
/// والحدّان من المنتج، وما يحدث عند كل لمسة من الـ Cubit.
class QuantityPicker extends StatelessWidget {
  const QuantityPicker({
    required this.quantity,
    required this.unitLabel,
    required this.value,
    required this.floor,
    required this.ceiling,
    required this.onEdit,
    required this.onSlide,
    required this.onSlideEnd,
    required this.onIncrease,
    required this.onDecrease,
    super.key,
  });

  /// الكمية كما في الحالة — نصٌّ عشري، يُرسم مجمّعاً: «1,000».
  final String quantity;

  /// «قطعة» أو «كجم» كما يرسلها الخادم.
  final String? unitLabel;

  /// موضع الإبهام، محبوساً بين [floor] و[ceiling].
  final double value;
  final double floor;
  final double ceiling;

  /// لمس الرقم: ورقةٌ تُكتب فيها كميةٌ بعينها.
  final VoidCallback onEdit;

  final ValueChanged<double> onSlide;

  /// حين يُرفع الإصبع — وهنا وحده يُطلب السعر.
  final ValueChanged<double> onSlideEnd;

  final VoidCallback onIncrease;

  /// null عند الحد الأدنى، فيُرسم الزر معطّلاً.
  final VoidCallback? onDecrease;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final unit = unitLabel;

    final edgeStyle = context.textTheme.bodySmall?.copyWith(
      fontSize: 12.5.sp,
      fontWeight: FontWeight.w700,
      color: scheme.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Semantics(
            button: true,
            label: 'اكتب الكمية',
            child: InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(10.r),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                // خطٌّ متقطّع واحد تحت الرقم والوحدة معاً. تسطير النص يُرسم لكل مقطعٍ بحجم خطّه،
                // فيخرج غليظاً تحت الرقم ورفيعاً تحت الوحدة وعلى ارتفاعين.
                child: IntrinsicWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text.rich(
                        key: const ValueKey('quantity-display'),
                        TextSpan(
                          children: [
                            TextSpan(text: quantity.asQuantity),
                            if (unit != null)
                              TextSpan(
                                text: ' $unit',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        style: context.textTheme.displaySmall?.copyWith(
                          fontSize: 36.sp,
                          fontWeight: FontWeight.w900,
                          height: 1.25,
                          color: scheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      CustomPaint(
                        size: Size.fromHeight(2.h),
                        painter: _Dashes(color: scheme.outline),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            _StepButton(
              icon: AppIcons.remove,
              tooltip: 'إنقاص الكمية',
              onPressed: onDecrease,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6.h,
                  activeTrackColor: scheme.primary,
                  inactiveTrackColor: scheme.outlineVariant,
                  thumbColor: scheme.primary,
                  trackShape: const RoundedRectSliderTrackShape(),
                  // بلا ظلٍّ يعلو عند الضغط ولا هالةٍ تتّسع: الظل ثابت، ولا شيء يتحرّك إلا الإبهام.
                  thumbShape: RoundSliderThumbShape(
                    enabledThumbRadius: 13.r,
                    elevation: 0,
                    pressedElevation: 0,
                  ),
                  overlayShape: SliderComponentShape.noOverlay,
                  tickMarkShape: SliderTickMarkShape.noTickMark,
                  showValueIndicator: ShowValueIndicator.never,
                ),
                child: Slider(
                  value: value,
                  min: floor,
                  max: ceiling,
                  padding: EdgeInsets.symmetric(horizontal: 13.r, vertical: 9.h),
                  onChanged: onSlide,
                  onChangeEnd: onSlideEnd,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            _StepButton(
              icon: AppIcons.add,
              tooltip: 'زيادة الكمية',
              onPressed: onIncrease,
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 56.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$floor'.asQuantity, style: edgeStyle),
              Text(
                unit == null ? '$ceiling'.asQuantity : '${'$ceiling'.asQuantity} $unit',
                style: edgeStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// خطٌّ متقطّع بعرض ما فوقه: شرطةٌ ست نقاط، وفراغٌ أربع.
class _Dashes extends CustomPainter {
  const _Dashes({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.height;
    final y = size.height / 2;

    for (var x = 0.0; x < size.width; x += 10) {
      canvas.drawLine(Offset(x, y), Offset((x + 6).clamp(0, size.width), y), paint);
    }
  }

  @override
  bool shouldRepaint(_Dashes oldDelegate) => oldDelegate.color != color;
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 20.sp),
      style: IconButton.styleFrom(
        fixedSize: Size.square(44.w),
        backgroundColor: scheme.surfaceContainer,
        foregroundColor: scheme.onSurface,
        disabledBackgroundColor: scheme.surfaceContainer,
        disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.35),
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      ),
    );
  }
}
