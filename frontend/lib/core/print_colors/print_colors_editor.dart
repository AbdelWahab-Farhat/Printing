import 'package:dayaa/core/print_colors/print_color.dart';
import 'package:dayaa/core/print_colors/print_colors_view.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «ألوان الطباعة» as a field on a form — the chips, a tap to correct one, a «×» to drop one, and
/// «إضافة لون».
///
/// Holds no state of its own: the form owns the list and hears every change through
/// [onChanged], the way it owns its text controllers. Optional everywhere it appears — a design
/// with no colors on record is a real answer, not a missing one.
class PrintColorsField extends StatelessWidget {
  const PrintColorsField({
    required this.colors,
    required this.onChanged,
    this.helper = 'اختياري — أضف لون كل حبر بالرمز الذي تطابقه المطبعة',
    super.key,
  });

  final List<PrintColor> colors;
  final ValueChanged<List<PrintColor>> onChanged;

  /// The line under the title.
  final String? helper;

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
    final helperText = helper;

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
        if (helperText != null) ...[
          SizedBox(height: 2.h),
          Text(
            helperText,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
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

/// The whole list in a sheet, for a screen that has nothing else to save with it — a design in
/// the library, a version on an order. Null when dismissed; the list, possibly empty, on «حفظ».
///
/// [confirmLabel] is the button — «حفظ» by default, «إرسال» where the sheet is the last step
/// before an upload.
Future<List<PrintColor>?> showPrintColorsSheet({
  required BuildContext context,
  required List<PrintColor> initial,
  String? subtitle,
  String confirmLabel = 'حفظ',
}) {
  return showModalBottomSheet<List<PrintColor>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _PrintColorsSheet(
      initial: initial,
      subtitle: subtitle,
      confirmLabel: confirmLabel,
    ),
  );
}

class _PrintColorsSheet extends StatefulWidget {
  const _PrintColorsSheet({
    required this.initial,
    required this.confirmLabel,
    this.subtitle,
  });

  final List<PrintColor> initial;
  final String? subtitle;
  final String confirmLabel;

  @override
  State<_PrintColorsSheet> createState() => _PrintColorsSheetState();
}

class _PrintColorsSheetState extends State<_PrintColorsSheet> {
  late List<PrintColor> _colors = [...widget.initial];

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final subtitle = widget.subtitle;

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
            Text(
              'ألوان الطباعة',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (subtitle != null) ...[
              SizedBox(height: 4.h),
              Text(subtitle, style: text.bodySmall),
            ],
            SizedBox(height: 14.h),
            PrintColorsField(
              colors: _colors,
              onChanged: (colors) => setState(() => _colors = colors),
            ),
            SizedBox(height: 18.h),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: widget.confirmLabel,
                onPressed: () => Navigator.of(context).pop(_colors),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One ink — its name, its code and, optionally, a swatch. Null when cancelled.
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
  // Disposed here, in the dialog's own state, and not by whoever opened it: the closing
  // animation still draws these fields after `showDialog` has returned.
  late final TextEditingController _name = TextEditingController(
    text: widget.initial?.name,
  );
  late final TextEditingController _code = TextEditingController(
    text: widget.initial?.code,
  );
  late final TextEditingController _hex = TextEditingController(
    text: widget.initial?.hex,
  );

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _hex.dispose();
    super.dispose();
  }

  /// What is in the hex box, upper-cased with a `#`, or null when the box is empty.
  String? get _typedHex {
    var value = _hex.text.trim().toUpperCase();
    if (value.isEmpty) return null;
    if (!value.startsWith('#')) value = '#$value';

    return value;
  }

  bool get _hexIsValid {
    final hex = _typedHex;

    return hex == null || PrintColor.parseHex(hex) != null;
  }

  void _pick(Color? swatch) {
    setState(() => _hex.text = swatch == null ? '' : PrintColor.toHex(swatch));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;
    final current = PrintColor.parseHex(_typedHex);

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
          SizedBox(height: 10.h),
          AppTextField(
            controller: _code,
            label: 'رمز اللون',
            hint: 'PANTONE 186 C',
            helperText: 'الرمز هو ما تطابقه المطبعة',
            textDirection: TextDirection.ltr,
            maxLength: 60,
          ),
          SizedBox(height: 14.h),
          Text('عيّنة للشاشة (اختياري)', style: text.labelLarge),
          SizedBox(height: 2.h),
          Text(
            'للتمييز بين الألوان فقط — لون الشاشة لا يُطابَق عليه',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _SwatchButton(
                swatch: null,
                selected: _typedHex == null,
                onTap: () => _pick(null),
              ),
              for (final swatch in _palette)
                _SwatchButton(
                  swatch: swatch,
                  selected:
                      current != null &&
                      current.toARGB32() == swatch.toARGB32(),
                  onTap: () => _pick(swatch),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          AppTextField(
            controller: _hex,
            label: 'رمز العيّنة',
            hint: '#E4002B',
            textDirection: TextDirection.ltr,
            errorText: _hexIsValid ? null : 'بصيغة ‎#RRGGBB',
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          // A color with no name is one nobody can talk about on the floor — the server refuses
          // it too, and this says so before the round trip.
          onPressed: _name.text.trim().isEmpty || !_hexIsValid
              ? null
              : () => Navigator.of(context).pop(
                  PrintColor(
                    name: _name.text.trim(),
                    code: _code.text.trim().isEmpty ? null : _code.text.trim(),
                    hex: _typedHex,
                  ),
                ),
          child: const Text('حفظ'),
        ),
      ],
    );
  }

  /// A starting set the shop prints most — black and white first. Anything else goes in the
  /// hex box.
  static const List<Color> _palette = [
    Color(0xFF000000),
    Color(0xFFFFFFFF),
    Color(0xFF8A8D8F),
    Color(0xFFE4002B),
    Color(0xFF9B2335),
    Color(0xFFFF6A13),
    Color(0xFFFFCD00),
    Color(0xFFB9975B),
    Color(0xFF00843D),
    Color(0xFF1E5B3A),
    Color(0xFF41B6E6),
    Color(0xFF0033A0),
    Color(0xFF1B2A4A),
    Color(0xFF6D2077),
    Color(0xFFE10098),
    Color(0xFF6B4423),
  ];
}

class _SwatchButton extends StatelessWidget {
  const _SwatchButton({
    required this.swatch,
    required this.selected,
    required this.onTap,
  });

  /// Null is «بلا عيّنة».
  final Color? swatch;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final side = 32.r;

    return Semantics(
      button: true,
      selected: selected,
      label: swatch == null ? 'بلا عيّنة' : PrintColor.toHex(swatch!),
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
          child: swatch == null
              ? Icon(
                  AppIcons.excluded,
                  size: 18.r,
                  color: scheme.onSurfaceVariant,
                )
              : null,
        ),
      ),
    );
  }
}
