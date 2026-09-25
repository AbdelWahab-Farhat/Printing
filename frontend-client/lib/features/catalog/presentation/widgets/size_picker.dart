import 'package:dayaa_client/core/utils/bidi.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/features/catalog/models/product.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// المقاسات صفّاً واحداً: الاسم، وتحته القياسات.
///
/// **صفٌّ لا قائمة.** كانت كل مقاسٍ في 4c سطراً كاملاً بعرض الشاشة — ثلاثة مقاسات تأخذ ثلث
/// الصفحة. هنا تتقاسم المقاسات العرض بالتساوي، وحين لا تتّسع (خمسة مقاسات بأسماء طويلة) يصير
/// الصف منزلقاً جانباً بعرضٍ أدنى لكل مقاس بدل أن يضيق حتى لا يُقرأ.
class SizePicker extends StatelessWidget {
  const SizePicker({
    required this.variants,
    required this.selectedId,
    required this.onSelected,
    super.key,
  });

  final List<ProductVariant> variants;
  final int? selectedId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'المقاس',
          style: context.textTheme.titleSmall?.copyWith(
            fontSize: 15.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 10.h),
        LayoutBuilder(
          builder: (context, box) {
            final gap = 8.w;
            final narrowest = 84.w;
            final fitted = (box.maxWidth - gap * (variants.length - 1)) / variants.length;

            final chips = [
              for (final variant in variants)
                _SizeChip(
                  variant: variant,
                  isSelected: variant.id == selectedId,
                  onTap: () => onSelected(variant.id),
                ),
            ];

            if (fitted >= narrowest) {
              return Row(
                children: [
                  for (var index = 0; index < chips.length; index++) ...[
                    if (index > 0) SizedBox(width: gap),
                    Expanded(child: chips[index]),
                  ],
                ],
              );
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  for (var index = 0; index < chips.length; index++) ...[
                    if (index > 0) SizedBox(width: gap),
                    SizedBox(width: narrowest, child: chips[index]),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SizeChip extends StatelessWidget {
  const _SizeChip({
    required this.variant,
    required this.isSelected,
    required this.onTap,
  });

  final ProductVariant variant;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final foreground = isSelected ? scheme.onPrimaryContainer : scheme.onSurface;
    final measurements = variant.dimensionsUnderLabel;

    return Semantics(
      selected: isSelected,
      button: true,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: isSelected ? scheme.primaryContainer : scheme.surfaceContainer,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
          side: BorderSide(
            color: isSelected ? scheme.primary : scheme.outlineVariant,
            width: 1.5,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 60.h,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  // «25*35» اسماً يُعزل عن ترتيب العربية حوله، وإلا قُرئ «35*25».
                  variant.label.bidiSafe,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: foreground,
                    height: 1.3,
                  ),
                ),
                if (measurements != null)
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      measurements,
                      style: context.textTheme.bodySmall?.copyWith(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? foreground : scheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
