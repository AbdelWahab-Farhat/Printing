import 'package:dayaa_client/core/print_colors/print_color.dart';
import 'package:dayaa_client/core/print_colors/print_colors_view.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/widgets/app_button.dart';
import 'package:dayaa_client/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «ألوان الطباعة» خانةً في نموذج — الكبسولات، ولمسةٌ لتصحيح لون، و«×» لحذفه، و«إضافة لون».
///
/// **الاسم واللون فقط.** الرمز الذي تطابقه المطبعة يكتبه فريقنا، فلا خانة له هنا.
/// لا حالة فيها: النموذج يملك القائمة ويسمع كل تغيير عبر [onChanged].
class PrintColorsField extends StatelessWidget {
  const PrintColorsField({
    required this.colors,
    required this.onChanged,
    super.key,
  });

  final List<PrintColor> colors;
  final ValueChanged<List<PrintColor>> onChanged;

  Future<void> _add(BuildContext context) async {
    final added = await showPrintColorDialog(context: context);
    if (added == null) return;

    onChanged([...colors, added]);
  }

  Future<void> _edit(BuildContext context, int index) async {
    final edited = await showPrintColorDialog(
      context: context,
      initial: colors[index],
    );
    if (edited == null) return;

    onChanged([
      for (var i = 0; i < colors.length; i++) i == index ? edited : colors[i],
    ]);
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
              'ألوان الطباعة',
              style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Text(
          'اختياري — سمِّ كل لون واختره، ويكتب فريقنا رمزه الدقيق للمطبعة',
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
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
                onTap: () => _edit(context, i),
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
                onPressed: () => _add(context),
              ),
          ],
        ),
      ],
    );
  }
}

/// القائمة كلّها في ورقة — لتصميمٍ في المكتبة. null عند الإغلاق، والقائمة (ولو فارغة) عند «حفظ».
Future<List<PrintColor>?> showPrintColorsSheet({
  required BuildContext context,
  required List<PrintColor> initial,
}) {
  return showModalBottomSheet<List<PrintColor>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _PrintColorsSheet(initial: initial),
  );
}

class _PrintColorsSheet extends StatefulWidget {
  const _PrintColorsSheet({required this.initial});

  final List<PrintColor> initial;

  @override
  State<_PrintColorsSheet> createState() => _PrintColorsSheetState();
}

class _PrintColorsSheetState extends State<_PrintColorsSheet> {
  late List<PrintColor> _colors = [...widget.initial];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16.w,
        0,
        16.w,
        MediaQuery.viewInsetsOf(context).bottom + 16.h,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PrintColorsField(
              colors: _colors,
              onChanged: (colors) => setState(() => _colors = colors),
            ),
            SizedBox(height: 18.h),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'حفظ',
                onPressed: () => Navigator.of(context).pop(_colors),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// لونٌ واحد: اسمه ولونه. **اللون مطلوب** — اختياره هو سبب أن يُسأل العميل أصلاً.
Future<PrintColor?> showPrintColorDialog({
  required BuildContext context,
  PrintColor? initial,
}) {
  return showDialog<PrintColor>(
    context: context,
    builder: (_) => _PrintColorDialog(initial: initial),
  );
}

class _PrintColorDialog extends StatefulWidget {
  const _PrintColorDialog({this.initial});

  final PrintColor? initial;

  @override
  State<_PrintColorDialog> createState() => _PrintColorDialogState();
}

class _PrintColorDialogState extends State<_PrintColorDialog> {
  // يُتخلّص منه هنا، في حالة النافذة نفسها، لا عند من فتحها: حركة الإغلاق ما زالت ترسم الحقل
  // بعد أن يعود `showDialog`.
  late final TextEditingController _name = TextEditingController(
    text: widget.initial?.name,
  );

  late Color? _swatch = widget.initial?.swatch;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;
    final swatch = _swatch;

    return AlertDialog(
      title: Text(widget.initial == null ? 'إضافة لون' : 'تعديل اللون'),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: _name,
            label: 'اسم اللون',
            hint: 'مثال: أحمر الشعار',
            autofocus: widget.initial == null,
            maxLength: 60,
            onChanged: (_) => setState(() {}),
          ),
          SizedBox(height: 14.h),
          Text('اختر اللون', style: text.labelLarge),
          SizedBox(height: 2.h),
          Text(
            'الأقرب إلى ما تريد — فريقنا يطابقه بالرمز الدقيق قبل الطباعة',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              for (final option in _palette)
                _SwatchButton(
                  swatch: option,
                  selected:
                      swatch != null && swatch.toARGB32() == option.toARGB32(),
                  onTap: () => setState(() => _swatch = option),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        // `TextButton`, like every other action in a dialog here (RULES §7) — see
        // `shared_controls_test.dart`.
        TextButton(
          onPressed: _name.text.trim().isEmpty || swatch == null
              ? null
              : () => Navigator.of(context).pop(
                  PrintColor(
                    name: _name.text.trim(),
                    hex: PrintColor.toHex(swatch),
                  ),
                ),
          child: const Text('حفظ'),
        ),
      ],
    );
  }

  /// ما يُطبع أكثر شيء — الأسود والأبيض أولاً — ثم درجاتٌ تغطّي ما يطلبه العملاء عادة.
  static const List<Color> _palette = [
    Color(0xFF000000),
    Color(0xFFFFFFFF),
    Color(0xFF8A8D8F),
    Color(0xFFD0D3D4),
    Color(0xFFE4002B),
    Color(0xFF9B2335),
    Color(0xFFFF6A13),
    Color(0xFFFFCD00),
    Color(0xFFB9975B),
    Color(0xFF00843D),
    Color(0xFF1E5B3A),
    Color(0xFF78BE20),
    Color(0xFF41B6E6),
    Color(0xFF0033A0),
    Color(0xFF1B2A4A),
    Color(0xFF6D2077),
    Color(0xFFE10098),
    Color(0xFFF4A6C0),
    Color(0xFF6B4423),
    Color(0xFFD7C4A3),
  ];
}

class _SwatchButton extends StatelessWidget {
  const _SwatchButton({
    required this.swatch,
    required this.selected,
    required this.onTap,
  });

  final Color swatch;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final side = 34.r;

    return Semantics(
      button: true,
      selected: selected,
      label: PrintColor.toHex(swatch),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: side,
          height: side,
          decoration: BoxDecoration(
            color: swatch,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 3 : 1,
            ),
          ),
        ),
      ),
    );
  }
}
