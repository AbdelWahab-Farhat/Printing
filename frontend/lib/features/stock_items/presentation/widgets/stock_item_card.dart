import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/features/stock_items/models/stock_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One shelf: what it is called, what it is counted in, and how many product sizes draw on it.
///
/// **There is no thumbnail, and that is not an omission.** A stock line used to carry the
/// product's photograph; a pile is not one product's — «كيس شحن سادة» and «كيس شحن مطبوع» at
/// 25*35 both draw on this row — so a picture of either would be picking one arbitrarily and
/// telling the storekeeper the wrong thing. The server stopped sending `image_url` and
/// `product_name` for exactly that reason. What stands in their place is the item's own `code`,
/// which reads well on a row and is the one thing here safe to read down a phone line, and its
/// `display_name`, which carries the size.
///
/// **The count is the point of the row.** «٣ مقاسات تسحب منه» is what says this pile is shared,
/// and it is also what says the delete will be refused — so it is on the line rather than left
/// to a 422 after the fact.
///
/// A stopped shelf keeps its name in full colour and says «موقوف» beside the unit: it is still a
/// true record of a pile that exists, and greying the row out would misread «لا يُعرض في
/// القوائم» as «خطأ».
class StockItemCard extends StatelessWidget {
  const StockItemCard({required this.item, this.onTap, this.onDelete, super.key});

  final StockItem item;

  /// Opens the form, or answers a picker. Null for somebody who may only read the list.
  final VoidCallback? onTap;

  /// Null for a reader, and null in a picker — which is what keeps a bin off a sheet somebody
  /// opened to *choose* something.
  final VoidCallback? onDelete;

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
              _Code(item: item),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      // Composed by the server from the material and the size, and rendered as
                      // sent — the shortfall message that refuses an order quotes this exact
                      // string, so a second spelling of it here is a second thing to read.
                      item.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      _subtitle(item),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(AppIcons.delete, size: 20.sp),
                  color: scheme.error,
                  tooltip: 'حذف الصنف',
                )
              else if (onTap != null)
                Icon(AppIcons.forward, size: 18.sp, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// «قطعة · ٣ مقاسات تسحب منه · موقوف» — everything the second line can say, in the order it
/// matters in.
///
/// The unit comes first because it is what a number on this shelf *means*. The count is dropped
/// entirely rather than shown as zero when the endpoint did not send one: create and update reply
/// without `variants_count`, and «لا مقاس يسحب منه» about a shelf four products are using would be
/// the worst thing this row could say.
String _subtitle(StockItem item) =>
    [item.unitLabel, ?item.sharedByLabel, if (!item.isActive) 'موقوف'].join(' · ');

/// The item's `code`, in the space a product photograph used to occupy.
///
/// Tinted when more than one product size draws on the pile: that is the whole point of a stock
/// item existing, and it is the row nobody should quietly "tidy up".
class _Code extends StatelessWidget {
  const _Code({required this.item});

  final StockItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      height: 38.w,
      constraints: BoxConstraints(minWidth: 38.w),
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: item.isShared ? scheme.primaryContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        item.code,
        // Latin, and short: left to the RTL layout it would read with its digits on the wrong
        // side of the letter.
        textDirection: TextDirection.ltr,
        style: context.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: item.isShared ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
