import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/features/products/models/product.dart';
import 'package:printing/features/products/presentation/widgets/product_category_badge.dart';
import 'package:printing/features/products/presentation/widgets/product_gallery.dart';

/// One product in the catalogue, priced in full.
///
/// The question this card exists to answer is the one asked on the phone twenty times a day:
/// *"how much for 50*60 at five hundred?"* An earlier version showed one price — `من 0.850` —
/// and hid the sizes behind a `+1` chip, which meant the single most valuable fact in this
/// business, that **the price falls at 300 and again at 1000**, was invisible. Answering took a
/// tap, then reading, then a guess.
///
/// So the whole ladder is on the card, at rest, and the layout is what makes that readable:
///
///   * **one header row** names each threshold *once* — `100+ · 300+ · 1000+` — instead of the
///     twelve restatements a per-size list would need,
///   * **the corner cell** carries `د.ل / قطعة`, so all twelve cells are bare numbers,
///   * **the entry column is headed by the minimum order**, not by the tier's floor of 1. That
///     is where `أقل كمية` went: it is not a stray fact parked at the end of a row, it is what
///     the first column *means*,
///   * **the cheapest column is the only coloured thing** below the title, so the eye lands on
///     the floor price and travels right-to-left up the quantities.
///
/// The category is the one pill left, and it earns that by being the only one. It used to be a
/// chip identical in shape to a size — two different kinds of data in one visual language, so
/// the eye could not separate them — and was then demoted to the first half of a grey subtitle,
/// which is read only by somebody already reading the whole card. It is now
/// [ProductCategoryBadge] in the far top corner: sizes are table rows and nothing else on the
/// card is tinted, so «مطبوعة أو سادة» is answered before the name is and cannot be mistaken for
/// a measurement. What stayed in the subtitle is the billing unit, which is read *after* a bag
/// has been found rather than while looking for one.
///
/// **What it costs:** height. Measured at 430×932 — a four-size product is 213 logical pixels
/// against the old 106, the catalogue's largest (six sizes) is 257, and the two shapes with no
/// grid are 116. So roughly four cards to a screen instead of six. With ten products and a
/// search box above them that is the right trade — but **past roughly sixty products this needs
/// a density toggle**, and that is a decision to take deliberately rather than discover.
///
/// **What it deliberately drops:** `features`. They were on the card for one revision and taken
/// off again: a selling point is what a salesperson says *after* the number, so on a row whose
/// job is the number it was a line of prose the eye had to skip over on every card. They are
/// still on the model, for the day a product screen wants them. Also dropped: `description` (a
/// paragraph, on one product in ten) and `widthCm`/`heightCm` as visible text — though those do
/// become the row's spoken label, so `25*35` is not read out as "twenty-five star thirty-five".
class ProductCard extends StatelessWidget {
  const ProductCard({required this.product, this.onTap, super.key});

  final Product product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _Identity(product: product),
              SizedBox(height: 10.h),
              _PriceBox(product: product),
            ],
          ),
        ),
      ),
    );
  }
}

/// The picture, the name, and what kind of thing this is.
class _Identity extends StatelessWidget {
  const _Identity({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final image = product.primaryImage;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Only a real photograph earns this slot. It used to hold a tinted box icon whenever a
        // product had no image — which is every product — so the eye met the same glyph on every
        // row and learned to skip the whole column. An empty slot says as much and costs nothing.
        if (image != null) ...[
          ProductThumbnail(image: image, side: 48.w),
          SizedBox(width: 10.w),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // First thing on the row, and the only coloured thing on it. The code is what
                  // gets read down a phone line — «عندك P7؟» — so it is where the eye lands, not
                  // a grey afterthought at the far end. Fixed-width and never truncated: a
                  // shortened code is a wrong code.
                  Text(
                    product.code,
                    textDirection: TextDirection.ltr,
                    style: context.textTheme.titleSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Flexible(
                    child: Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  // One word, no container. A stopped product is a decision, not a fault — an
                  // error-coloured badge makes the whole row read as broken, and it is still a
                  // product people ask about.
                  if (!product.isActive) ...[
                    SizedBox(width: 6.w),
                    Text(
                      '· موقوف',
                      style: context.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.error,
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 2.h),
              Text(
                // What is left of the old `مطبوعة · بالقطعة` sentence once the category became a
                // badge: how the bag is *billed*. The server's own Arabic, so the app keeps no
                // translation table.
                'بال${product.pricingUnitLabel}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        // The far corner — the left one, this being an Arabic layout — and outside the name
        // column on purpose: a badge inside it would shift with every name length, and the point
        // of putting it here is that it is in the same place on every card, so the catalogue can
        // be skimmed for «سادة» without reading a word.
        ProductCategoryBadge(
          category: product.category,
          label: product.categoryLabel,
        ),
      ],
    );
  }
}

/// Everything about money, in a box that is always in the same place.
///
/// Three shapes fit here and the caller never has to know which: a grid of breaks, a single
/// price for something sold flat, or the sentence for something quoted by hand. Keeping them in
/// one box at one position is what lets the eye go to the same spot on every card.
class _PriceBox extends StatelessWidget {
  const _PriceBox({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final columns = _breakColumns(product);

    final Widget content;
    if (!product.hasListedPrices || columns.isEmpty) {
      content = _QuoteLine(product: product);
    } else if (columns.length == 1 && product.variants.length == 1) {
      content = _FlatPrice(product: product, tier: product.variants.first.priceTiers.first);
    } else {
      content = _PriceGrid(product: product, columns: columns);
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12.r),
      ),
      // The one region of the card that genuinely cannot reflow: four columns of unbreakable
      // numerals have nowhere to go at 2× text scale. Everything outside this box scales freely.
      child: MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3, child: content),
    );
  }
}

/// Sizes down the side, quantity breaks across the top, one price in each cell.
class _PriceGrid extends StatelessWidget {
  const _PriceGrid({required this.product, required this.columns});

  final Product product;

  /// The quantity thresholds, ascending, as the server's own strings.
  final List<String> columns;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final labels = _breakLabels(product);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _GridRow(
          lead: 'د.ل / ${product.pricingUnitLabel}',
          // The unit belongs to the header, so it reads in Arabic while the cells below it do
          // not: a heading is a sentence, a cell is a number.
          isLeadRtl: true,
          cells: [
            for (var index = 0; index < columns.length; index++)
              _columnLabel(product, columns[index], labels, isFirst: index == 0),
          ],
          style: context.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
          // The last column is the floor price, and it is the only coloured thing below the
          // title — one accent, so it means something.
          highlight: scheme.primary,
        ),
        Divider(
          height: 7.h,
          thickness: 1,
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
        for (var index = 0; index < product.variants.length; index++)
          _VariantRow(
            variant: product.variants[index],
            columns: columns,
            isStriped: index.isOdd,
          ),
      ],
    );
  }
}

class _VariantRow extends StatelessWidget {
  const _VariantRow({
    required this.variant,
    required this.columns,
    required this.isStriped,
  });

  final ProductVariant variant;
  final List<String> columns;
  final bool isStriped;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    // A stopped size keeps its numbers — they are still what it cost — but loses the accent, so
    // nothing about it reads as an offer.
    final isStopped = !variant.isActive;

    final row = _GridRow(
      lead: variant.label,
      // Read out as dimensions where the shop recorded them, because a screen reader says
      // "25 star 35" otherwise.
      leadSemantics: variant.widthCm != null && variant.heightCm != null
          ? 'عرض ${variant.widthCm} سم، ارتفاع ${variant.heightCm}'
          : null,
      cells: [for (final column in columns) _priceAt(variant, column)],
      style: context.textTheme.labelMedium?.copyWith(
        color: isStopped ? scheme.onSurfaceVariant : scheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      highlight: isStopped ? null : scheme.primary,
    );

    // Built only on the odd rows: `Colors.transparent` would be a literal colour, and §7 does
    // not carve out an exception for invisible ones.
    if (!isStriped) return row;

    return ColoredBox(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: row,
    );
  }
}

/// One line of the grid: a label at the reading edge, then equal-width cells.
///
/// `Expanded` and not a `Table`: equal flex aligns every row against every other in a single
/// layout pass, where `Table` and `IntrinsicWidth` both measure twice.
class _GridRow extends StatelessWidget {
  const _GridRow({
    required this.lead,
    required this.cells,
    required this.style,
    this.highlight,
    this.leadSemantics,
    this.isLeadRtl = false,
  });

  final String lead;
  final List<String> cells;
  final TextStyle? style;

  /// The colour of the last cell, if it should stand out. `null` leaves the row in one colour.
  final Color? highlight;

  final String? leadSemantics;
  final bool isLeadRtl;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      // Four separate nodes would be read as four unrelated numbers; one node is a size and
      // its prices.
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 3.h),
        child: Row(
          children: [
            SizedBox(
              width: 66.w,
              child: Semantics(
                label: leadSemantics,
                child: Text(
                  lead,
                  // Sizes and thresholds are Latin runs and read left-to-right even here; set
                  // once, on the row, because a `Text` that misses it renders `1000+` as
                  // `+1000` — a different number, not a rendering glitch.
                  textDirection: isLeadRtl ? TextDirection.rtl : TextDirection.ltr,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                  style: style,
                ),
              ),
            ),
            for (var index = 0; index < cells.length; index++)
              Expanded(
                child: Text(
                  cells[index],
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                  style: index == cells.length - 1 && highlight != null
                      ? style?.copyWith(color: highlight, fontWeight: FontWeight.w800)
                      : style,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A product sold at one price, with no volume break to show.
class _FlatPrice extends StatelessWidget {
  const _FlatPrice({required this.product, required this.tier});

  final Product product;
  final ProductPriceTier tier;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Row(
      children: [
        Text(
          tier.unitPrice,
          textDirection: TextDirection.ltr,
          style: context.textTheme.titleSmall?.copyWith(
            color: scheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(width: 4.w),
        Text(
          'د.ل / ${product.pricingUnitLabel}',
          style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const Spacer(),
        _MinimumOrder(product: product),
      ],
    );
  }
}

/// A product whose price is agreed by hand.
class _QuoteLine extends StatelessWidget {
  const _QuoteLine({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          // Never a number the app derived from an empty tier list.
          'السعر حسب الطلب',
          style: context.textTheme.titleSmall?.copyWith(
            color: context.colorScheme.tertiary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        _MinimumOrder(product: product),
      ],
    );
  }
}

/// The minimum, for the two shapes that have no column header to carry it.
class _MinimumOrder extends StatelessWidget {
  const _MinimumOrder({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Text(
      'أقل كمية ${product.minOrderQuantityLabel} ${product.pricingUnitLabel}',
      style: context.textTheme.bodySmall?.copyWith(
        color: context.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// The distinct quantity breaks across **every** variant, ascending.
///
/// The union, not the first variant's list. Taking one size as the authority on the whole ladder
/// works right up until that size is the odd one out — and then every other row degrades to
/// dashes under headings it does not own.
///
/// `num.parse` only ever *orders* these strings. Every value that reaches the screen is the text
/// the server sent.
List<String> _breakColumns(Product product) {
  final breaks = <String>{
    for (final variant in product.variants)
      for (final tier in variant.priceTiers) tier.minQuantity,
  };

  return breaks.toList()..sort((a, b) => num.parse(a).compareTo(num.parse(b)));
}

/// `'300.000'` → `'300'`, borrowing the model's own trimming rather than repeating it here.
Map<String, String> _breakLabels(Product product) => {
  for (final variant in product.variants)
    for (final tier in variant.priceTiers) tier.minQuantity: tier.minQuantityLabel,
};

/// The heading over one column.
///
/// The catalogue's first tier starts at 1, but the shop will not sell fewer than a hundred. So
/// the entry column is headed by whichever is larger — which is how `أقل كمية` stopped being a
/// stray fact at the end of a row and became the meaning of the first column.
String _columnLabel(
  Product product,
  String minQuantity,
  Map<String, String> labels, {
  required bool isFirst,
}) {
  final isBelowMinimum = num.parse(minQuantity) < num.parse(product.minOrderQuantity);
  final label = isFirst && isBelowMinimum
      ? product.minOrderQuantityLabel
      : labels[minQuantity] ?? minQuantity;

  return '$label+';
}

/// The price for a size at one threshold, or a gap.
///
/// A cell prints a price only for a tier that begins exactly where its column says. A number
/// under the wrong heading is how a quote goes out wrong; a dash is not.
String _priceAt(ProductVariant variant, String minQuantity) {
  for (final tier in variant.priceTiers) {
    if (tier.minQuantity == minQuantity) return tier.unitPrice;
  }

  return '—';
}
