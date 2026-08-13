import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/features/products/models/product_category.dart';

/// مطبوعة or سادة, as the one thing on a product row that is a *kind* rather than a number.
///
/// It is the question a customer opens with, and it used to be the first half of a grey
/// subtitle — read only by somebody already reading the whole card. As a tinted badge at the
/// card's far top corner it is answered before the name is, and the catalogue can be skimmed by
/// colour alone.
///
/// **The word comes from the server and only the glyph and the tone are decided here.** A
/// category this build has never heard of still renders — its Arabic arrived with it — in the
/// neutral tone, rather than the app inventing a label or the row dropping out.
///
/// It is deliberately the only pill on the card. The design once tagged sizes this way too, and
/// two different kinds of data in one visual language meant the eye could not separate them;
/// the sizes are a table now, so nothing here can be mistaken for one.
class ProductCategoryBadge extends StatelessWidget {
  const ProductCategoryBadge({required this.category, required this.label, super.key});

  /// The machine value — `printed`, `general` — parsed for the glyph and the tone.
  final String category;

  /// The server's Arabic, rendered as-is.
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final kind = ProductCategory.fromWire(category);
    final (background, foreground) = _tone(scheme, kind);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon(kind), size: 13.sp, color: foreground),
          SizedBox(width: 4.w),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  /// Printed against plain, at 13 points. Not two bags: at this size the difference between two
  /// silhouettes of the same object is invisible, and the badge would be a colour swatch.
  static IconData _icon(ProductCategory category) => switch (category) {
    ProductCategory.printed => AppIcons.printedProduct,
    ProductCategory.general => AppIcons.plainProduct,
    // Nothing is claimed about a category this build has never heard of.
    ProductCategory.unknown => AppIcons.products,
  };

  /// Two roles out of the scheme, never a hex: the theme is generated and gets replaced whole.
  ///
  /// **Not `primary`.** On this card primary means money — the code, and the floor price in the
  /// grid. Spending it on a badge that is present on every single row would leave the price
  /// column competing with a label that never changes.
  static (Color, Color) _tone(ColorScheme scheme, ProductCategory category) => switch (category) {
    ProductCategory.printed => (scheme.secondaryContainer, scheme.onSecondaryContainer),
    ProductCategory.general => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
    ProductCategory.unknown => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
  };
}
