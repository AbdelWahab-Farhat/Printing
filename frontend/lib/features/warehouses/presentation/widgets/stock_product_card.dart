import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/features/products/presentation/widgets/product_gallery.dart';
import 'package:dayaa/features/warehouses/models/stock_group.dart';
import 'package:dayaa/features/warehouses/models/warehouse_stock.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/stock_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One bag, with every size of it this warehouse holds underneath.
///
/// **The product is said once.** The list is one row per *size*, which is the truth — a balance
/// belongs to a size and never to a product — but four sizes of «أكياس الشحن» drew the same
/// name, the same code and the same picture four times, and four rows that differ only in two
/// digits read as four products until you look twice. The heading carries what they share; the
/// lines carry what they do not.
///
/// **No total on the heading.** Each shelf is counted in the unit it was stocked in, and the one
/// number that could be written here would be a sum this app has no business computing — the
/// warehouse's own total is on the card above the list, where the server counted it.
class StockProductCard extends StatelessWidget {
  const StockProductCard({
    required this.group,
    this.onTapShelf,
    this.onEditThreshold,
    super.key,
  });

  final StockGroup group;

  /// Opens one shelf's own history. It takes the shelf, because the card holds several and the
  /// line that was tapped is the one the reader asked about.
  final void Function(WarehouseStock stock)? onTapShelf;

  /// Opens the alert-level sheet for one size. Null for somebody who may only read.
  final void Function(WarehouseStock stock)? onEditThreshold;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final radius = BorderRadius.circular(14.r);

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: radius,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 8.h),
              child: Row(
                children: [
                  ProductThumbnail(image: group.image, side: 44.w, radius: 10.r),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            if (group.productCode case final code?) ...[
                              Text(
                                code,
                                textDirection: TextDirection.ltr,
                                style: context.textTheme.labelMedium?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(width: 6.w),
                            ],
                            Flexible(
                              child: Text(
                                group.productName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          _sizesLabel(group.shelves.length),
                          style: context.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            for (final (index, shelf) in group.shelves.indexed) ...[
              // A hairline between sizes, not around them: the card is one product, and boxing
              // each line inside it would put a second frame around what is already framed.
              if (index > 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 12.w,
                  endIndent: 12.w,
                  color: scheme.outlineVariant.withValues(alpha: 0.4),
                ),
              StockRow.inGroup(
                key: ValueKey(shelf.id),
                stock: shelf,
                onTap: onTapShelf == null ? null : () => onTapShelf!(shelf),
                onEditThreshold: onEditThreshold == null ? null : () => onEditThreshold!(shelf),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// «مقاسان» for two and «٣ مقاسات» for more — Arabic counts the pair with its own word, and
  /// «2 مقاسات» is the kind of wrong that a reader notices before the number.
  String _sizesLabel(int count) => count == 2 ? 'مقاسان' : '$count مقاسات';
}
