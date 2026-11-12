import 'package:dayaa_client/core/print_colors/print_color.dart';
import 'package:dayaa_client/core/print_colors/print_color_presets.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/widgets/app_button.dart';
import 'package:dayaa_client/core/widgets/app_color_picker.dart';
import 'package:dayaa_client/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «ألوان الطباعة» في ورقةٍ سفلية واحدة — **المكوّن الوحيد الذي يختار به العميل ألوان تصميم**،
/// شكلُ ورقة تطبيق الموظفين نفسه.
///
/// كل ألوان التصميم في الورقة نفسها: صفُّ خاناتٍ مرقّمة (١، ٢، ٣ … و«+»)، والمختارة منها تُحرَّر
/// تحته — المنتقي، ثم «اسم اللون» و«كود اللون» في صفٍّ واحد، والكود يُكتب أو يتبع المنتقي. **لا خانة لرمز المطبعة**: يكتبه
/// فريقنا (PRINT-COLORS.md §8)، ويبقى على اللون كما وصل إن غيّر العميل اسمه أو لونه.
///
/// [selected] الخانة التي تُفتح عليها، و[addNew] يفتحها على خانةٍ فارغة جديدة في آخر الصف.
/// تصميمٌ بلا ألوان يُفتح على خانةٍ فارغة واحدة. يعود `null` عند الإغلاق، والقائمة (ولو فارغة)
/// عند [confirmLabel].
///
/// Every slot on the row must have a colour before saving (PRINT-COLORS.md §9): a design of
/// two colours cannot be saved with one. The only exception is a sheet left entirely blank when
/// [required] is false, which saves as "no colours". With [required] the list may not be empty.
Future<List<PrintColor>?> showPrintColorsSheet({
  required BuildContext context,
  required List<PrintColor> initial,
  int? selected,
  bool addNew = false,
  bool required = false,
  String confirmLabel = 'حفظ',
}) {
  return showModalBottomSheet<List<PrintColor>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => PrintColorsSheet(
      initial: initial,
      selected: selected,
      addNew: addNew,
      required: required,
      confirmLabel: confirmLabel,
    ),
  );
}

class PrintColorsSheet extends StatefulWidget {
  const PrintColorsSheet({
    required this.initial,
    this.selected,
    this.addNew = false,
    this.required = false,
    this.confirmLabel = 'حفظ',
    super.key,
  });

  final List<PrintColor> initial;
  final int? selected;
  final bool addNew;
  final bool required;
  final String confirmLabel;

  @override
  State<PrintColorsSheet> createState() => _PrintColorsSheetState();
}

class _PrintColorsSheetState extends State<PrintColorsSheet> {
  late final List<_Slot> _slots = [
    for (final color in widget.initial) _Slot.from(color),
    if ((widget.addNew && widget.initial.length < PrintColor.max) ||
        widget.initial.isEmpty)
      _Slot.blank(),
  ];

  late int _selected = _slots.length > widget.initial.length
      ? _slots.length - 1
      : (widget.selected ?? 0).clamp(0, _slots.length - 1);

  // خانتا نصٍّ للورقة كلها، لا اثنتان لكل لون: تُملآن من الخانة المختارة كلما تبدّلت.
  final _name = TextEditingController();
  final _hex = TextEditingController();

  /// "Pick the colour" errors stay hidden until «حفظ» is pressed once.
  bool _showErrors = false;

  _Slot? get _current => _slots.isEmpty ? null : _slots[_selected];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _hex.dispose();
    super.dispose();
  }

  void _load() {
    final slot = _current;
    _name.text = slot?.name ?? '';
    _hex.text = slot?.hexText ?? '';
  }

  void _select(int index) {
    setState(() {
      _selected = index;
      _load();
    });
  }

  void _add() {
    setState(() {
      _slots.add(_Slot.blank());
      _selected = _slots.length - 1;
      _load();
    });
  }

  void _remove(int index) {
    setState(() {
      _slots.removeAt(index);
      if (index < _selected || _selected >= _slots.length) {
        _selected = (_selected - 1).clamp(0, _slots.length);
      }
      if (_slots.isEmpty) _selected = 0;
      _load();
    });
  }

  /// «عدد الألوان»: grows the row with blank slots, or trims it from the end.
  void _setCount(int count) {
    setState(() {
      while (_slots.length < count) {
        _slots.add(_Slot.blank());
      }
      if (_slots.length > count) _slots.removeRange(count, _slots.length);
      _selected = _slots.indexWhere((slot) => slot.hex == null && slot.code.trim().isEmpty);
      if (_selected < 0) _selected = _slots.length - 1;
      _load();
    });
  }

  /// A basic ink in one tap: its swatch, and its name unless somebody typed their own.
  void _pickPreset(PrintColorPreset preset) {
    final slot = _current!;
    setState(() {
      slot
        ..hexText = preset.hex
        ..hsv = HSVColor.fromColor(preset.color);
      if (slot.name.trim().isEmpty || isPresetName(slot.name)) slot.name = preset.name;
      _load();
    });
  }

  void _pick(HSVColor hsv) {
    final slot = _current!;
    setState(() {
      slot
        ..hsv = hsv
        ..hexText = PrintColor.toHex(hsv.toColor());
      _hex.text = slot.hexText;
    });
  }

  void _typeHex(String text) {
    final slot = _current!;
    setState(() {
      slot.hexText = text;
      final swatch = PrintColor.parseHex(slot.hex);
      if (swatch != null) slot.hsv = HSVColor.fromColor(swatch);
    });
  }

  /// «اللون 2» or «الألوان 1، 3» — which slots still have no colour.
  String _missingLabel() {
    final numbers = [
      for (var i = 0; i < _slots.length; i++)
        if (!_slots[i].isValid) '${i + 1}',
    ];

    return numbers.length == 1 ? 'اللون ${numbers.first}' : 'الألوان ${numbers.join('، ')}';
  }

  void _save() {
    // An untouched sheet is "no colours" where colours are optional.
    if (!widget.required && _slots.every((slot) => slot.isBlank)) {
      Navigator.of(context).pop(const <PrintColor>[]);

      return;
    }

    if (_slots.isEmpty) {
      setState(() {
        _showErrors = true;
        _slots.add(_Slot.blank());
        _selected = 0;
        _load();
      });

      return;
    }

    // Every slot on the row is a colour the job is printed in, so a blank one is refused rather
    // than dropped: that is how a two-colour design went out with one.
    for (var i = 0; i < _slots.length; i++) {
      if (!_slots[i].isValid) {
        setState(() {
          _selected = i;
          _showErrors = true;
          _load();
        });

        return;
      }
    }

    Navigator.of(context).pop([for (final slot in _slots) slot.toPrintColor()]);
  }

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final slot = _current;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                'ألوان الطباعة',
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            SizedBox(height: 10.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: _CountChips(count: _slots.length, onChanged: _setCount),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              child: Row(
                children: [
                  for (var i = 0; i < _slots.length; i++) ...[
                    _SlotButton(
                      number: i + 1,
                      swatch: _slots[i].swatch,
                      selected: i == _selected,
                      missing: _showErrors && !_slots[i].isValid,
                      onTap: () => _select(i),
                      onRemove: () => _remove(i),
                    ),
                    SizedBox(width: 10.w),
                  ],
                  if (_slots.length < PrintColor.max) _AddSlotButton(onTap: _add),
                ],
              ),
            ),
            if (_showErrors && _slots.any((slot) => !slot.isValid))
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  'اختر لوناً لكل خانة — ${_missingLabel()}',
                  style: text.bodySmall?.copyWith(color: context.colorScheme.error),
                ),
              ),
            // المنتقي والخانات وحدها تُمرَّر؛ الصفّ فوقها والزرّان تحتها ثابتة، فلا تغطّي لوحة
            // المفاتيح «حفظ» ولا تُخفي أيّ لونٍ يُحرَّر الآن.
            if (slot != null)
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('ألوان أساسية', style: text.labelLarge),
                      SizedBox(height: 8.h),
                      _PresetRow(selectedHex: slot.hex, onPicked: _pickPreset),
                      SizedBox(height: 16.h),
                      Text('أو حدّد اللون يدوياً', style: text.labelLarge),
                      SizedBox(height: 8.h),
                      AppColorPicker(color: slot.pickerColor, onChanged: _pick),
                      SizedBox(height: 22.h),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _name,
                              label: 'اسم اللون (اختياري)',
                              hint: 'أحمر الشعار',
                              maxLength: 60,
                              textInputAction: TextInputAction.next,
                              onChanged: (value) => setState(() => slot.name = value),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: AppTextField(
                              controller: _hex,
                              label: 'كود اللون',
                              hint: '#E4002B',
                              textDirection: TextDirection.ltr,
                              textInputAction: TextInputAction.done,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp('[#0-9a-fA-F]')),
                                LengthLimitingTextInputFormatter(7),
                              ],
                              errorText: !slot.hexIsValid
                                  ? 'بصيغة ‎#RRGGBB'
                                  : _showErrors && !slot.isValid
                                  ? 'اختر اللون'
                                  : null,
                              onChanged: _typeHex,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(label: widget.confirmLabel, onPressed: _save),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: AppButton.outlined(
                      label: 'إلغاء',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// لونٌ واحد قيد التحرير.
///
/// [code] رمز المطبعة كما وصل — لا خانة له في الورقة، ويُعاد كما هو.
/// [hexText] يُحفظ كما كُتب — نصفُ كودٍ يبقى نصفاً حتى يكتمل — و[hsv] منفصلٌ عنه: الرمادي لا
/// صبغة له في الكود، فلو اشتُقّ منه لقفز شريط الصبغة إلى الأحمر كلما نزل أحدٌ إلى الرمادي.
class _Slot {
  _Slot.from(PrintColor color)
    : name = _ownName(color),
      code = color.code ?? '',
      hexText = color.hex ?? '',
      hsv = color.swatch == null ? null : HSVColor.fromColor(color.swatch!);

  _Slot.blank() : name = '', code = '', hexText = '', hsv = null;

  String name;
  String code;
  String hexText;
  HSVColor? hsv;

  /// ما يُرسم عليه المنتقي قبل أن يُلمس: الصبغة الحمراء كاملةً، فأول لمسةٍ لشريط الصبغة تعطي
  /// لوناً لا رمادياً.
  HSVColor get pickerColor => hsv ?? const HSVColor.fromAHSV(1, 0, 1, 1);

  /// `#RRGGBB` بأحرفٍ كبيرة، أو `null` لخانةٍ فارغة أو كودٍ لا يُقرأ.
  String? get hex {
    var value = hexText.trim().toUpperCase();
    if (value.isEmpty) return null;
    if (!value.startsWith('#')) value = '#$value';

    return PrintColor.parseHex(value) == null ? null : value;
  }

  Color? get swatch => PrintColor.parseHex(hex);

  bool get hexIsValid => hexText.trim().isEmpty || hex != null;

  bool get isBlank =>
      name.trim().isEmpty && code.trim().isEmpty && hexText.trim().isEmpty;

  /// The colour is required and the name optional: choosing the colour is why the customer is
  /// asked at all (PRINT-COLORS.md §8).
  bool get isValid => hex != null;

  /// **الاسم اختياري، والخادم يطلبه:** لونٌ بلا اسمٍ يُحفظ وكودُه اسمُه، فيُعرض `#E4002B` حيثما
  /// عُرض اسم لون — وبلا تغييرٍ في الخادم.
  PrintColor toPrintColor() => PrintColor(
    name: name.trim().isNotEmpty ? name.trim() : (hex ?? code.trim()),
    code: code.trim().isEmpty ? null : code.trim(),
    hex: hex,
  );
}

/// اسم اللون كما كتبه أحد — فارغٌ إن كان الاسم المحفوظ هو كودَه نفسه، أي لوناً حُفظ بلا اسم
/// ([_Slot.toPrintColor])، فتُفتح خانة الاسم فارغةً لا مملوءةً بالكود.
String _ownName(PrintColor color) {
  final name = color.name.trim().toUpperCase();
  final standsIn =
      name == color.hex?.trim().toUpperCase() ||
      name == color.code?.trim().toUpperCase();

  return standsIn ? '' : color.name;
}

/// خانةٌ مرقّمة في الصف: لونها ورقمها، وحلقةٌ حول المختارة، و«×» عليها وحدها.
class _SlotButton extends StatelessWidget {
  const _SlotButton({
    required this.number,
    required this.swatch,
    required this.selected,
    required this.onTap,
    required this.onRemove,
    this.missing = false,
  });

  final int number;
  final Color? swatch;
  final bool selected;

  /// Drawn with the error ring: «حفظ» was pressed while this slot had no colour.
  final bool missing;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final swatch = this.swatch;
    final side = 56.r;

    // الرقم أبيض أو أسود حسب اللون تحته — ثابتان عمداً لا من الثيم: الخانة تحمل أيّ لونٍ يطبعه
    // الزبون، ولونٌ من اللوحة كان سيختفي فوق مثله.
    final numberColor = swatch == null
        ? scheme.onSurface
        : ThemeData.estimateBrightnessForColor(swatch) == Brightness.dark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF000000);

    return SizedBox(
      width: side,
      height: side,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Semantics(
            container: true,
            button: true,
            selected: selected,
            label: 'اللون $number',
            excludeSemantics: true,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Container(
                width: side,
                height: side,
                padding: EdgeInsets.all(3.r),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: missing
                        ? scheme.error
                        : selected
                        ? scheme.primary
                        : Colors.transparent,
                    width: 2.5,
                  ),
                ),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: swatch,
                    // حلقةٌ فارغة لا رمادي لخانةٍ بلا لون — كـ`PrintColorSwatch`: الرمادي لونٌ
                    // قد يُطبع.
                    border: Border.all(
                      color: swatch == null ? scheme.outline : scheme.outlineVariant,
                      width: swatch == null ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    '$number',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: numberColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (selected)
            PositionedDirectional(
              top: -4.r,
              end: -4.r,
              child: Tooltip(
                message: 'حذف هذا اللون',
                child: Material(
                  color: scheme.surfaceContainerHighest,
                  shape: CircleBorder(
                    side: BorderSide(color: scheme.surfaceContainerLow, width: 2),
                  ),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onRemove,
                    child: SizedBox(
                      width: 26.r,
                      height: 26.r,
                      child: Icon(AppIcons.close, size: 14.r, color: scheme.onSurface),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// آخر الصف: لونٌ آخر على التصميم نفسه.
class _AddSlotButton extends StatelessWidget {
  const _AddSlotButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Tooltip(
      message: 'إضافة لون',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 56.r,
          height: 56.r,
          padding: EdgeInsets.all(3.r),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: scheme.outline, width: 1.5),
            ),
            child: Icon(AppIcons.add, size: 24.r, color: scheme.primary),
          ),
        ),
      ),
    );
  }
}

/// «عدد الألوان»: asked first, so a two-colour job is two slots before anything is picked.
/// «أكثر» opens a fifth slot; the «+» at the end of the row adds any after that.
class _CountChips extends StatelessWidget {
  const _CountChips({required this.count, required this.onChanged});

  final int count;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('عدد الألوان', style: context.textTheme.labelLarge),
        SizedBox(width: 10.w),
        Expanded(
          child: Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: [
              for (var n = 1; n <= 4; n++)
                ChoiceChip(
                  label: Text('$n'),
                  selected: count == n,
                  showCheckmark: false,
                  onSelected: (_) => onChanged(n),
                ),
              ChoiceChip(
                label: const Text('أكثر'),
                selected: count > 4,
                showCheckmark: false,
                onSelected: (_) => onChanged(count > 4 ? count : 5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The basic inks as round chips, the picked one ringed. Gold is drawn as a gradient because a
/// flat swatch cannot show a metallic ink; its stored value is still one hex.
class _PresetRow extends StatelessWidget {
  const _PresetRow({required this.selectedHex, required this.onPicked});

  final String? selectedHex;
  final ValueChanged<PrintColorPreset> onPicked;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final side = 40.r;

    return Wrap(
      spacing: 10.w,
      runSpacing: 8.h,
      children: [
        for (final preset in printColorPresets)
          Semantics(
            button: true,
            selected: preset.hex == selectedHex,
            label: preset.name,
            excludeSemantics: true,
            child: Tooltip(
              message: preset.name,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => onPicked(preset),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: side + 6.r,
                      height: side + 6.r,
                      padding: EdgeInsets.all(2.r),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: preset.hex == selectedHex ? scheme.primary : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: preset.gradient == null ? preset.color : null,
                          gradient: preset.gradient == null
                              ? null
                              : LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: preset.gradient!,
                                ),
                          // White must not vanish on a light sheet.
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(preset.name, style: context.textTheme.labelSmall),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
