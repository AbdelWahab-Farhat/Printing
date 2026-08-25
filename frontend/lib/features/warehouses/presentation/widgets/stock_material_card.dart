import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/features/warehouses/models/stock_group.dart';
import 'package:dayaa/features/warehouses/models/warehouse_stock.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/stock_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One material, with every size of it this warehouse holds underneath.
///
/// **The material is said once.** The list is one row per *shelf*, which is the truth — a balance
/// belongs to a size and never to a material — but four sizes of «كيس شحن» drew the same name
/// four times, and four rows that differ only in two digits read as four materials until you look
/// twice. The heading carries what they share; the lines carry what they do not.
///
/// **This used to be a product card, and the change is the point of the whole migration.** «كيس
/// شحن سادة» and «كيس شحن مطبوع» at one size are two catalogue rows and one pile of bags, so
/// heading this card with a product's name — or its photograph — would have picked one of the two
/// arbitrarily and told the storekeeper the shelf belonged to it. The heading is the material,
/// which is what the sizes genuinely have in common, and every line carries its own `S7` because
/// each size is its own shelf.
///
/// **No total on the heading.** Each shelf is counted in the unit it was stocked in, and the one
/// number that could be written here would be a sum this app has no business computing — the
/// warehouse's own total is on the card above the list, where the server counted it.
class StockMaterialCard extends StatelessWidget {
  const StockMaterialCard({required this.group, this.onTapShelf, this.onEditThreshold, super.key});

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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    group.materialName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    _sizesLabel(group.shelves.length),
                    style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            for (final (index, shelf) in group.shelves.indexed) ...[
              // A hairline between sizes, not around them: the card is one material, and boxing
              // each line inside it would put a second frame around what is already framed.
              if (index > 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 24.w,
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

  /// «مادتان» for two, «٣ مواد» up to ten and «١١ مادةً» beyond it — Arabic counts the pair
  /// with its own word and changes case past ten, and «2 مواد» is the kind of wrong a reader
  /// notices before the number. Never one: a lone shelf is drawn as a plain row, not a card.
  String _sizesLabel(int count) => switch (count) {
    2 => 'مادتان',
    final n when n <= 10 => '$n مواد',
    final n => '$n مادةً',
  };
}
