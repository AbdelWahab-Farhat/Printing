import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/stock_item_groups/models/stock_item_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One material: what it is called, what it is counted in, and how much is hanging off it.
///
/// **The two counts are the row's reason for being on the right-hand side.** Together they are
/// the answer to «هل يمكن حذفها؟» — the server refuses while either is above zero — and they are
/// also the size of the blast radius of a rename, since every one of those sizes takes the new
/// name in the same transaction. A row that showed only the name would make both of those a
/// surprise arriving as a 422.
///
/// A stopped material keeps its name in full colour and loses only the tint on its glyph. It is
/// still a true record of a paper the shop once bought, and every shelf filed under it still
/// holds what it holds; greying the row would misread «لم نعد نشتريها» as «خطأ».
class StockItemGroupCard extends StatelessWidget {
  const StockItemGroupCard({required this.group, this.onTap, this.onEdit, super.key});

  final StockItemGroup group;

  /// Opens the sizes filed under it — the material's only content.
  final VoidCallback? onTap;

  /// Null for somebody who may only read the table, which leaves the pencil off the row
  /// entirely rather than showing a control the server would refuse.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final radius = BorderRadius.circular(16.r);

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              Container(
                height: 38.w,
                width: 38.w,
                decoration: BoxDecoration(
                  color: group.isActive
                      ? scheme.secondaryContainer
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  // A label, not a warehouse: a material is what a pile is *labelled* with and
                  // holds nothing itself. `core/utils/app_icons.dart` has no glyph of its own
                  // for it yet, and adding one is a change to a file this module does not own.
                  AppIcons.tag,
                  size: 19.sp,
                  color: group.isActive
                      ? scheme.onSecondaryContainer
                      : scheme.onSurfaceVariant,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      group.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      // The server's own Arabic for the unit — «G3 · قطعة». «موقوف» rides on
                      // the same line rather than becoming a badge, which on a narrow phone
                      // would push the counts off the row.
                      [
                        group.code,
                        group.defaultUnitLabel,
                        if (!group.isActive) 'موقوف',
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              _Counts(group: group),
              if (onEdit != null)
                IconButton(
                  onPressed: onEdit,
                  icon: Icon(AppIcons.edit, size: 20.sp),
                  color: scheme.onSurfaceVariant,
                  tooltip: 'تعديل المادة',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What hangs off the material — sizes above, products below.
///
/// Both are `whenCounted` on the wire and simply **absent** from a create's or an edit's answer,
/// which is why each is drawn only when it arrived. Zero is drawn; unknown is not. The two say
/// different things, and a row that printed «0 صنفاً» because nobody counted would be inviting a
/// delete the server is about to refuse.
class _Counts extends StatelessWidget {
  const _Counts({required this.group});

  final StockItemGroup group;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (group.itemsCount case final count?)
          Text(
            // The server's own noun for a shelf — it is «صنف مخزني» in every refusal this
            // screen can produce, so the list counts the same thing by the same name.
            count == 0 ? 'بلا مقاسات' : '${count.grouped} مقاساً',
            style: context.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: count == 0 ? scheme.onSurfaceVariant : scheme.primary,
            ),
          ),
        if (group.productsCount case final count? when count > 0)
          Text(
            '${count.grouped} منتجاً',
            style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
      ],
    );
  }
}
