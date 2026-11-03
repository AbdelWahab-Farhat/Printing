import 'package:dayaa/core/print_colors/print_color.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/text_direction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The swatch of one ink — a filled dot, or an empty ring when there is no swatch on record.
///
/// The ring is deliberate rather than a grey dot: grey is a colour somebody might print in, and
/// a design with «رمادي فاتح» on it must not look like one with no swatch at all.
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
        // An outline on every swatch, so white on a white card is still a dot.
        border: Border.all(
          color: swatch == null ? scheme.outline : scheme.outlineVariant,
          width: swatch == null ? 1.5 : 1,
        ),
      ),
    );
  }
}

/// «ألوان الطباعة», read — each ink with its swatch, its name and its code.
///
/// **The code is drawn left to right on its own**, whatever the line around it reads: `PANTONE
/// 186 C` laid out right to left comes out as «C 186 PANTONE», and the code is the one thing on
/// this card the press must not misread.
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

/// One ink as a pill — swatch, name, code. Shared by [PrintColorsView] and the editor.
class PrintColorChip extends StatelessWidget {
  const PrintColorChip({required this.color, this.trailing, super.key});

  final PrintColor color;

  /// Something to tap on the chip itself — the editor's «×». Null when the chip only reads.
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
              // لونٌ حُفظ بلا اسم اسمُه كودُه، ولا حرف ذا اتجاهٍ فيه — يُكتب من اليسار.
              textDirection: color.name.readingDirection ?? TextDirection.ltr,
              style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // رمز المطبعة يُعرض إن كُتب قبل أن تُخفى خانته، ولا يُنبَّه على غيابه: لا مكان لكتابته
          // بعد اليوم، فكانت «بلا رمز» الحمراء ستلازم كل لونٍ جديد.
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

/// A row of bare swatches — for a tile too small to name each ink. Nothing when there are none.
class PrintColorDots extends StatelessWidget {
  const PrintColorDots({required this.colors, super.key});

  final List<PrintColor> colors;

  @override
  Widget build(BuildContext context) {
    if (colors.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 3.w,
      runSpacing: 3.h,
      children: [
        for (final color in colors) PrintColorSwatch(color: color, size: 12.r),
      ],
    );
  }
}
