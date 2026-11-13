import 'dart:async';

import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/hex_color.dart';
import 'package:dayaa_client/core/widgets/app_button.dart';
import 'package:dayaa_client/core/widgets/app_color_picker.dart';
import 'package:dayaa_client/core/widgets/app_text_field.dart';
import 'package:dayaa_client/features/tools/models/qr_ink.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  /// مفتاحا المنتقي المشترك نفسه — للاختبار وحدهما.
  static const Key saturationKey = AppColorPicker.saturationKey;
  static const Key hueKey = AppColorPicker.hueKey;

  @override
  Widget build(BuildContext context) {
    // اللون المختار من خارج القائمة السريعة يُعرض على قرص المنتقي نفسه، فلا يبقى الصفُّ بلا
    // علامةٍ على ما هو مختارٌ الآن.
    final isCustom = !QrInk.palette.contains(selected);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'لون الرمز',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            _InkCode(ink: selected),
          ],
        ),
        SizedBox(height: 6.h),
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

/// The applied ink's code, copied on a tap.
///
/// The code is what travels on: the same ink typed into the bag design, or sent to the press.
/// Read off this line, it never has to be guessed from a swatch.
class _InkCode extends StatelessWidget {
  const _InkCode({required this.ink});

  final Color ink;

  @override
  Widget build(BuildContext context) {
    final code = HexColor.of(ink);

    return InkWell(
      onTap: () {
        unawaited(Clipboard.setData(ClipboardData(text: code)));
        context.showSuccess('تم نسخ كود اللون');
      },
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              code,
              // A code reads left to right even inside this RTL row.
              textDirection: TextDirection.ltr,
              style: context.textTheme.bodyMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            SizedBox(width: 6.w),
            Icon(AppIcons.copy, size: 14.sp, color: context.colorScheme.outline),
          ],
        ),
      ),
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

/// The sheet: the shared [AppColorPicker], a «كود اللون» field under it, then «اختيار هذا اللون».
///
/// **The picker and the field drive each other.** A drag writes the code; a full code typed or
/// pasted moves the picker. A half-typed code moves nothing and stays as typed until it is
/// complete — rewriting it under the cursor would fight the person typing.
///
/// [_color] and [_hsv] are kept apart on purpose. [_color] is what the sheet returns: exactly
/// the typed code, so `#1E3A8A` comes back as the quick swatch it is rather than an HSV round
/// trip of it. [_hsv] is only where the picker's cursors sit — grey has no hue, and deriving it
/// from the colour would snap the hue bar to red whenever someone dragged down to grey.
class _InkSheet extends StatefulWidget {
  const _InkSheet({required this.initial});

  final Color initial;

  @override
  State<_InkSheet> createState() => _InkSheetState();
}

class _InkSheetState extends State<_InkSheet> {
  late Color _color = widget.initial;
  late HSVColor _hsv = HSVColor.fromColor(widget.initial);
  late final TextEditingController _code = TextEditingController(
    text: HexColor.of(widget.initial),
  );

  /// Whether the field holds a full code. When it does not, there is nothing to choose.
  bool get _codeIsValid => HexColor.normalize(_code.text) != null;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _pick(HSVColor hsv) {
    setState(() {
      _hsv = hsv;
      _color = hsv.toColor();
      _code.text = HexColor.of(_color);
    });
  }

  void _type(String text) {
    setState(() {
      final color = HexColor.parse(HexColor.normalize(text));
      if (color == null) return;

      _color = color;
      _hsv = HSVColor.fromColor(color);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return SafeArea(
      child: Padding(
        // The field opens the keyboard; the sheet climbs above it so the field and the button
        // stay in sight.
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
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
              AppColorPicker(color: _hsv, areaHeight: 200.h, onChanged: _pick),
              SizedBox(height: 20.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _code,
                      label: 'كود اللون',
                      hint: '#E4002B',
                      textDirection: TextDirection.ltr,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp('[#0-9a-fA-F]')),
                        LengthLimitingTextInputFormatter(7),
                      ],
                      errorText: _codeIsValid ? null : 'بصيغة ‎#RRGGBB',
                      onChanged: _type,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // What will be chosen, beside the code that names it.
                  Container(
                    width: 52.w,
                    height: 52.w,
                    decoration: BoxDecoration(
                      color: _color,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                  ),
                ],
              ),
              if (_codeIsValid && QrInk.isLowContrast(_color)) ...[
                SizedBox(height: 10.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(AppIcons.error, size: 18.sp, color: scheme.error),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'لون فاتح — قد لا يقرأه الماسح على خلفية بيضاء',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: 20.h),
              AppButton(
                label: 'اختيار هذا اللون',
                onPressed: _codeIsValid ? () => Navigator.of(context).pop(_color) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
