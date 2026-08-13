import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/utils/digits.dart';
import 'package:printing/features/business_fields/models/business_field.dart';

/// One trade on the list: what it is called, how many shops are in it, and whether it is still
/// offered.
///
/// **The count is the reason this screen is worth opening.** A list of names says nothing; «بيع
/// ملابس · ٣٤ محلاً» is the first sentence of the answer this whole table exists to give. It is
/// also what decides whether the row can be deleted, which is why the card shows it rather than
/// leaving the user to discover the rule from a 422.
///
/// A stopped field keeps its name in full colour and loses only the tint on its glyph: it is
/// still a true fact about the shops recorded under it, so greying the row out would misread
/// «لم نعد نعرضه» as «خطأ».
class BusinessFieldCard extends StatelessWidget {
  const BusinessFieldCard({
    required this.field,
    this.onTap,
    this.onToggleActive,
    super.key,
  });

  final BusinessField field;

  /// Opens the rename sheet. Null for somebody who may only read the list.
  final VoidCallback? onTap;

  /// Null for a reader, which is what leaves the switch out entirely rather than showing a
  /// control that refuses.
  final ValueChanged<bool>? onToggleActive;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              _Glyph(isActive: field.isActive),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      field.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      _subtitle(field),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (onToggleActive != null)
                Switch(value: field.isActive, onChanged: onToggleActive),
            ],
          ),
        ),
      ),
    );
  }
}

/// «٣٤ محلاً» — and the reason the delete button will refuse.
///
/// Arabic counts its nouns differently at one, two, and beyond ten, and a screen that says «1
/// محلات» reads as a bug in front of the person using it every day.
String _subtitle(BusinessField field) {
  final count = field.shopsCount;
  final stopped = field.isActive ? '' : ' · موقوف';

  if (count == null) return 'مجال عمل$stopped';

  final shops = switch (count) {
    0 => 'لا محلات بعد',
    1 => 'محل واحد',
    2 => 'محلان',
    >= 3 && <= 10 => '${count.grouped} محلات',
    _ => '${count.grouped} محلاً',
  };

  return '$shops$stopped';
}

class _Glyph extends StatelessWidget {
  const _Glyph({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      height: 36.w,
      width: 36.w,
      decoration: BoxDecoration(
        // The tint is the only thing that changes when a field is stopped: enough to scan the
        // list by, not enough to make the row read as broken.
        color: isActive ? scheme.secondaryContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Icon(
        AppIcons.businessField,
        size: 19.sp,
        color: isActive ? scheme.onSecondaryContainer : scheme.onSurfaceVariant,
      ),
    );
  }
}
