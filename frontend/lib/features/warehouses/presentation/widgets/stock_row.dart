import 'package:dayaa/core/theme/app_tones.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/products/models/product.dart';
import 'package:dayaa/features/products/presentation/widgets/product_gallery.dart';
import 'package:dayaa/features/warehouses/models/warehouse_stock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One shelf: the bag, its size, how much of it is here, and whether that is too little.
///
/// **The quantity is the loudest thing on the row**, because it is the only question this
/// screen is opened to answer. What changed around it:
///
///   * **a picture leads the row.** A storekeeper standing in front of the rack recognises the
///     bag before they read its name. It is the *product's* photograph — there are none at size
///     level — so every size of «أكياس الشحن» shares one, and the slot is held at a fixed width
///     whether or not it arrives, so a list does not reflow as the pictures land.
///   * **zero is a state, not a number.** `is_low_stock` comes from the server and says nothing
///     about a size nobody set an alert level for, so a line at zero used to render exactly like
///     a healthy one — the emptiest row on the screen was also the calmest. It now says «نافد».
///   * **one badge at a time.** An empty shelf below its threshold is both; only the louder word
///     is worth the space, and two badges saying the same thing twice is not emphasis.
///
/// **Tapping opens this shelf's own history**, which is the second question and the one the
/// balance cannot answer: 100 is a fact, «وصل 500 وخرج 400» is what a storekeeper does anything
/// with. The alert level has a button of its own — the row leads somewhere, and one tap cannot
/// mean two things.
///
/// **Two forms of the same row.** [StockRow.new] is a card of its own, for a product this
/// warehouse holds in one size. [StockRow.inGroup] is a line inside `StockProductCard`, where
/// the picture, the code and the product's name have already been said once above it — so the
/// line drops all three and keeps only what differs between sizes.
class StockRow extends StatelessWidget {
  const StockRow({required this.stock, this.onTap, this.onEditThreshold, super.key})
    : _standalone = true;

  /// One size under its product's heading: no picture, no code, no product name — the card
  /// above carries them, and a row that repeated them would make one bag read as several.
  const StockRow.inGroup({required this.stock, this.onTap, this.onEditThreshold, super.key})
    : _standalone = false;

  final WarehouseStock stock;

  /// Opens this shelf's own history — where the number came from, and who took the rest.
  final VoidCallback? onTap;

  /// Opens the alert-level sheet. Null for somebody who may only read, and then the button is
  /// absent rather than greyed: a control that only ever refuses is a control to leave out.
  final VoidCallback? onEditThreshold;

  /// Whether this row is its own card or a line inside one.
  final bool _standalone;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final radius = BorderRadius.circular(_standalone ? 14.r : 10.r);

    // Empty wins over low: both can be true, and «نافد» is the one that stops somebody.
    final isEmpty = stock.isOutOfStock;
    final needsAttention = isEmpty || stock.isLowStock;

    final row = InkWell(
      onTap: onTap,
      borderRadius: radius,
      child: Container(
        // Inside a card the line is indented to where the product's name starts, so the sizes
        // read as belonging to the heading rather than as three more rows beside it.
        padding: EdgeInsetsDirectional.fromSTEB(_standalone ? 12.w : 66.w, 10.h, 12.w, 10.h),
        decoration: _standalone
            ? BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
              )
            : null,
        child: Row(
          children: [
            // The catalogue's own thumbnail, not a second widget drawing the same thing. It
            // takes a `ProductImage`, so the row's flat url is wrapped in one rather than
            // teaching the thumbnail a second way to be given a picture.
            if (_standalone) ...[
              ProductThumbnail(
                image: switch (stock.variant?.imageUrl) {
                  final url? => ProductImage(id: stock.variant!.id, url: url),
                  _ => null,
                },
                side: 44.w,
                radius: 10.r,
              ),
              SizedBox(width: 10.w),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // The code leads, in the accent it wears on the catalogue card: «P7» is
                      // what a storekeeper is told on the phone and what they search for. In a
                      // group it is the card's, said once at the top.
                      if (stock.variant?.productCode case final code? when _standalone) ...[
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
                          // The size alone under a heading that already named the bag.
                          _standalone ? stock.title : stock.sizeLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textDirection: _standalone ? null : TextDirection.ltr,
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      if (isEmpty)
                        const _StateBadge(label: 'نافد', isEmpty: true)
                      else if (stock.isLowStock)
                        const _StateBadge(label: 'تحت الحد', isEmpty: false),

                      if (needsAttention) SizedBox(width: 6.w),
                      Flexible(
                        child: Text(
                          switch (stock.thresholdLabel) {
                            final level? => 'حد التنبيه ${level.grouped}',
                            // Said, not left blank: a shelf with no alert will never ask to be
                            // refilled, and that is a decision somebody can take here.
                            _ => 'بلا حد تنبيه',
                          },
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            // The unit sits under the number rather than beside it: «250» stays the loudest
            // thing on the row, and a floor holding both bags and kilos stops being ambiguous
            // without the balance having to share its weight with a word.
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  stock.quantityLabel,
                  textDirection: TextDirection.ltr,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    // The number wears the state it is in: red for nothing left, amber for a
                    // shelf that is asking, plain ink for one that is fine.
                    color: switch ((isEmpty, stock.isLowStock)) {
                      (true, _) => scheme.error,
                      (_, true) => scheme.warn,
                      _ => scheme.onSurface,
                    },
                  ),
                ),
                Text(
                  stock.unitLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
            // The alert level gets its own button, because the row itself now leads somewhere:
            // one tap cannot both open a history and edit a number.
            if (onEditThreshold != null)
              IconButton(
                tooltip: 'حد التنبيه',
                onPressed: onEditThreshold,
                visualDensity: VisualDensity.compact,
                icon: Icon(AppIcons.edit, size: 18.sp, color: scheme.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );

    // A line inside a card draws on the card's own surface; only the standalone form is a
    // surface, and an `InkWell` needs one above it either way.
    return _standalone
        ? Material(color: scheme.surfaceContainerLowest, borderRadius: radius, child: row)
        : row;
  }
}

/// «نافد» or «تحت الحد» — a word, with a glyph, never a colour on its own.
///
/// **Amber for the one that is running low, red for the one that has run out.** Two weights of
/// the same red would make «تحت الحد» read as a paler emergency, and the shelf that has actually
/// stopped work needs to be the loudest thing in the list. `warn` is the app's own amber,
/// defined once in `app_tones.dart` for exactly this: Material 3 ships no role between «fine»
/// and «broken».
class _StateBadge extends StatelessWidget {
  const _StateBadge({required this.label, required this.isEmpty});

  final String label;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final (background, foreground) = isEmpty
        ? (scheme.errorContainer, scheme.onErrorContainer)
        : (scheme.warnContainer, scheme.onWarnContainer);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(6.r)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.error, size: 11.sp, color: foreground),
          SizedBox(width: 3.w),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
