import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_color_picker.dart';
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

/// المنتقي: [AppColorPicker] المشترك، وتحته «اختيار هذا اللون».
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
            AppColorPicker(
              color: _hsv,
              areaHeight: 200.h,
              onChanged: (hsv) => setState(() => _hsv = hsv),
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
