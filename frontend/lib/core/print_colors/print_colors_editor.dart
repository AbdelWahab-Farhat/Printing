import 'package:dayaa/core/print_colors/print_color.dart';
import 'package:dayaa/core/print_colors/print_colors_sheet.dart';
import 'package:dayaa/core/print_colors/print_colors_view.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

export 'package:dayaa/core/print_colors/print_colors_sheet.dart'
    show PrintColorsSheet, showPrintColorsSheet;

/// «ألوان الطباعة» خانةً في نموذج — الكبسولات، و«×» لحذف لون، ولمسةٌ على كبسولة أو على
/// «إضافة لون» تفتح [showPrintColorsSheet] على ذلك اللون أو على خانةٍ جديدة.
///
/// لا حالة فيها: النموذج يملك القائمة ويسمع كل تغيير عبر [onChanged]، كما يملك خانات نصّه.
/// اختياريةٌ حيثما ظهرت — تصميمٌ بلا ألوانٍ مسجّلة جوابٌ صحيح لا نقص.
class PrintColorsField extends StatelessWidget {
  const PrintColorsField({
    required this.colors,
    required this.onChanged,
    this.required = false,
    this.errorText,
    super.key,
  });

  final List<PrintColor> colors;
  final ValueChanged<List<PrintColor>> onChanged;

  /// Colours are mandatory here (PRINT-COLORS.md §9): the heading says so and the sheet refuses
  /// an empty list.
  final bool required;

  /// Said under the chips, in the error colour — the form's refusal to save without them.
  final String? errorText;

  Future<void> _open(BuildContext context, {int? selected}) async {
    final edited = await showPrintColorsSheet(
      context: context,
      initial: colors,
      selected: selected,
      addNew: selected == null,
      required: required,
    );
    if (edited == null) return;

    onChanged(edited);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(AppIcons.printColors, size: 18.r, color: scheme.primary),
            SizedBox(width: 6.w),
            Text(
              required ? 'ألوان الطباعة (مطلوبة)' : 'ألوان الطباعة',
              style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (var i = 0; i < colors.length; i++)
              InkWell(
                borderRadius: BorderRadius.circular(20.r),
                onTap: () => _open(context, selected: i),
                child: PrintColorChip(
                  color: colors[i],
                  trailing: IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'حذف اللون',
                    icon: Icon(AppIcons.close, size: 16.r),
                    onPressed: () => onChanged([...colors]..removeAt(i)),
                  ),
                ),
              ),
            if (colors.length < PrintColor.max)
              ActionChip(
                avatar: Icon(AppIcons.add, size: 18.r),
                label: const Text('إضافة لون'),
                onPressed: () => _open(context),
              ),
          ],
        ),
        if (errorText case final error?) ...[
          SizedBox(height: 6.h),
          Text(error, style: text.bodySmall?.copyWith(color: scheme.error)),
        ],
      ],
    );
  }
}
