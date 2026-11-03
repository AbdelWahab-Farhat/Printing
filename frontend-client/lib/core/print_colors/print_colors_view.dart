import 'package:dayaa_client/core/print_colors/print_color.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/text_direction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// نقطةُ لونٍ واحد — ممتلئةٌ بلونه، أو حلقةٌ فارغة حين لا لون.
class PrintColorSwatch extends StatelessWidget {
  const PrintColorSwatch({required this.color, this.size, super.key});

  final PrintColor color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final swatch = color.swatch;
    final side = size ?? 18.r;

    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        color: swatch,
        shape: BoxShape.circle,
        // حدٌّ على كل نقطة، فالأبيض على بطاقةٍ بيضاء يبقى نقطة.
        border: Border.all(
          color: swatch == null ? scheme.outline : scheme.outlineVariant,
          width: swatch == null ? 1.5 : 1,
        ),
      ),
    );
  }
}

/// «ألوان الطباعة» تُقرأ — كل لونٍ بنقطته واسمه، ورمزه حين يكتبه فريقنا.
class PrintColorsView extends StatelessWidget {
  const PrintColorsView({required this.colors, super.key});

  final List<PrintColor> colors;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: [for (final color in colors) PrintColorChip(color: color)],
    );
  }
}

/// لونٌ في كبسولة: نقطة، اسم، ورمزُ فريقنا إن وُجد.
///
/// **الرمز يُرسم من اليسار إلى اليمين وحده**، أيّاً كان اتجاه السطر حوله: `PANTONE 186 C`
/// مرصوفاً من اليمين يخرج «C 186 PANTONE».
class PrintColorChip extends StatelessWidget {
  const PrintColorChip({required this.color, this.trailing, super.key});

  final PrintColor color;

  /// زرٌّ على الكبسولة نفسها — «×» في المحرّر. null حين تُقرأ فقط.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;
    final code = color.code;

    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(
        8.w,
        6.h,
        trailing == null ? 10.w : 2.w,
        6.h,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrintColorSwatch(color: color),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              color.name,
              textDirection: color.name.readingDirection,
              style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (code != null) ...[
            SizedBox(width: 6.w),
            Text(
              code,
              textDirection: TextDirection.ltr,
              style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          ?trailing,
        ],
      ),
    );
  }
}

/// صفٌّ من النقاط وحدها — لبطاقةٍ أصغر من أن تسمّي كل لون. لا شيء حين لا ألوان.
class PrintColorDots extends StatelessWidget {
  const PrintColorDots({required this.colors, this.max, super.key});

  final List<PrintColor> colors;

  /// أكثر ما يُرسم من نقاط، والباقي عددٌ «+2» بعدها — لسطرٍ ضيّقٍ لا يحتمل أن يلتفّ، كسطر الحجم
  /// في بطاقة التصميم. Null يرسمها كلها.
  final int? max;

  @override
  Widget build(BuildContext context) {
    if (colors.isEmpty) return const SizedBox.shrink();

    final shown = max == null ? colors : colors.take(max!).toList();
    final rest = colors.length - shown.length;

    return Wrap(
      spacing: 3.w,
      runSpacing: 3.h,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final color in shown) PrintColorSwatch(color: color, size: 12.r),
        if (rest > 0)
          Text(
            '+$rest',
            textDirection: TextDirection.ltr,
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
