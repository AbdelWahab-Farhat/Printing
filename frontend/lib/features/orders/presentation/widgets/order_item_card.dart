import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_line_costs.dart';
import 'package:dayaa/features/products/presentation/widgets/product_gallery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One line of an order — the product it was sold from, and the way back to it.
///
/// A line used to be two lines of text inside the section: what it is, and what it costs. The
/// product itself was a name on an invoice, so anybody who wanted the size chart, the price
/// tiers or the photograph left for the products tab and searched for a word they had just
/// read. The line carries the catalogue's own card now, and the card is the door.
///
/// **The picture is the live product's; the words are the invoice's.** `product_name` and
/// `variant_label` are the snapshot taken when the order was placed and are what an old order
/// must keep saying — a product renamed since must not rewrite an invoice. The code and the
/// photograph come from the catalogue row as it stands today, which is right for an affordance
/// whose whole purpose is to open that row.
///
/// **A slot only a real photograph fills.** `ProductCard` learned this on the catalogue screen:
/// a tinted glyph standing in for every product without an image put the same shape on every
/// row until the eye skipped the column. An empty slot says as much and costs nothing.
///
/// **The chevron appears only when there is somewhere to go.** [onOpenProduct] is null for
/// anybody without `products.view`, and an arrow promising a screen that answers 403 is worse
/// than no arrow.
class OrderItemCard extends StatelessWidget {
  const OrderItemCard({
    required this.item,
    required this.showCosts,
    this.onOpenProduct,
    this.onScrap,
    super.key,
  });

  /// Lets a test assert on the affordance rather than on an icon that may be replaced.
  static const Key chevronKey = Key('order-item-card-chevron');

  final OrderItem item;

  /// Whether the line says what it cost to make, under what it is charged at.
  final bool showCosts;

  /// Null without `products.view`, and on a payload that did not carry the product.
  final VoidCallback? onOpenProduct;

  /// Null when scrapping is not on offer — no grant, or an order with no shelf behind it yet.
  final VoidCallback? onScrap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final corner = BorderRadius.circular(16.r);

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: corner,
      child: InkWell(
        onTap: onOpenProduct,
        borderRadius: corner,
        child: Container(
          padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 10.h),
          decoration: BoxDecoration(
            borderRadius: corner,
            // A hairline instead of a shadow: this card sits *inside* «البنود», and a drop
            // shadow within a panel reads as a bug rather than as depth.
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Identity(item: item, showChevron: onOpenProduct != null),
              SizedBox(height: 10.h),
              // Separates what was bought from what it costs — the two questions this card
              // answers, and the only rule drawn on it.
              Divider(height: 1, thickness: 1, color: scheme.outlineVariant.withValues(alpha: 0.4)),
              SizedBox(height: 10.h),
              _Figures(item: item, showCosts: showCosts),
              // A text button rather than an arm on the dial: the dial acts on the *order*, and
              // «أي بند تلف؟» is a question the line itself is the answer to. It is the same
              // shape «إلغاء الدفعة» takes on a ledger row, for the same reason — and its own
              // tap never reaches the card underneath it, so a foreman reporting a spoiled bag
              // does not land on the catalogue.
              if (onScrap case final scrap?)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: scrap,
                    icon: Icon(AppIcons.delete, size: 16.sp),
                    label: const Text('تسجيل تلف'),
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.error,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What was sold: the picture, the code, the name and the size.
class _Identity extends StatelessWidget {
  const _Identity({required this.item, required this.showChevron});

  final OrderItem item;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final image = item.productImage;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (image != null) ...[
          ProductThumbnail(image: image, side: 52.w, radius: 12.r),
          SizedBox(width: 10.w),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // Same as on the catalogue row: the code is what one colleague says to
                  // another — «عندك P7؟» — so it leads, in the one colour on the card. Absent
                  // on a payload that did not carry the product, and the name simply moves up.
                  if (item.productCode case final code?) ...[
                    Text(
                      code,
                      textDirection: TextDirection.ltr,
                      style: context.textTheme.titleSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 8.w),
                  ],
                  Flexible(
                    child: Text(
                      item.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              // The size, on its own line rather than joined to the name with a dash: it is a
              // different fact, and «٢٥*٣٥» is the one people scan a four-line order for.
              Text(
                item.variantLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        if (showChevron) ...[
          SizedBox(width: 6.w),
          Icon(AppIcons.forward, key: OrderItemCard.chevronKey, size: 18.sp, color: scheme.outline),
        ],
      ],
    );
  }
}

/// What it costs: the rate it was priced at, what is missing from it, and the line's own total.
class _Figures extends StatelessWidget {
  const _Figures({required this.item, required this.showCosts});

  final OrderItem item;
  final bool showCosts;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                // The quantity, its unit and the rate it was priced at — the three numbers
                // somebody checking an invoice reads together.
                //
                // **The quantity here is the one being charged for**, so the line's own
                // arithmetic comes out right on screen: «٢٠٠ قطعة × ١٫٥٥٠» beside «٣١٠٫٠٠».
                // Printing the ordered 300 against a total built on 200 would make every short
                // line look like a pricing error.
                '${item.pricedQuantity.grouped} ${item.pricingUnitLabel} '
                '× ${item.unitPrice.grouped}',
                style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              item.lineTotal.grouped,
              textDirection: TextDirection.ltr,
              style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        // On the line it is missing from, because that is the only place the number means
        // anything: «ناقص ٤٠» of *which* size. What was ordered is said here too — it is no
        // longer on the line above, and «ناقص من كم» is the question that follows «ناقص».
        if (item.hasShortage) ...[
          SizedBox(height: 4.h),
          Text(
            'ناقص: ${item.shortageQuantity!.grouped} من ${item.quantity.grouped} '
            '${item.pricingUnitLabel} — غير محتسب',
            style: context.textTheme.bodySmall?.copyWith(
              color: scheme.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        // Under the price it is being charged at, quietly — see [OrderLineCosts] for why an
        // uncosted line draws nothing here rather than «لم يُحتسب بعد».
        if (showCosts) ...[
          SizedBox(height: 4.h),
          OrderLineCosts(item: item),
        ],
      ],
    );
  }
}
