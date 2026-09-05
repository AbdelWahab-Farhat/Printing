import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/products/models/product_category.dart';
import 'package:dayaa/features/products/models/production_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One heading in the catalogue: what it is called, how many products are under it, and whether
/// it is still offered.
///
/// **The count is the reason this screen is worth opening.** A list of names says nothing;
/// «أكياس · ١٢ منتجاً» says where the catalogue's weight actually sits. It is also what decides
/// whether the row can be deleted, which is why the card shows it rather than leaving the user
/// to discover the rule from a 422.
///
/// A stopped category keeps its name in full colour and loses only the tint on its glyph: it is
/// still a true fact about the products under it, so greying the row out would misread «لم نعد
/// نعرضه» as «خطأ».
class ProductCategoryCard extends StatelessWidget {
  const ProductCategoryCard({
    required this.category,
    this.onTap,
    this.onToggleActive,
    super.key,
  });

  final ProductCategory category;

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
              _Thumbnail(category: category),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      _subtitle(category),
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
                Switch(value: category.isActive, onChanged: onToggleActive),
            ],
          ),
        ),
      ),
    );
  }
}

/// «١٢ منتجاً» — and the reason the delete button will refuse.
///
/// Counts the whole heading, subheadings included: «أكياس · ١٢ منتجاً» is true of what a
/// customer finds under it, and a parent's own count is zero by construction.
///
/// Arabic counts its nouns differently at one, two, and beyond ten, and a screen that says «1
/// منتجات» reads as a bug in front of the person using it every day.
String _subtitle(ProductCategory category) {
  final stopped = category.isActive ? '' : ' · موقوف';

  // Read the same way «موقوف» is: a short tail on the line that already summarises the row, so
  // the list can be scanned for the headings whose orders leave the press without opening each
  // sheet in turn. The printed road is the quiet default and says nothing; سادة and وسيط each
  // say their own word — the server's — because the boolean that used to stand here called
  // both «بدون طباعة» and could not tell a shelf from a vendor. Only this row's own answer: a
  // subheading inheriting its parent's mode is not marked, because this is the value its sheet
  // would put back.
  final mode = category.productionMode == ProductionMode.inHouse
      ? ''
      : ' · ${category.productionModeCaption}';

  // A heading holding subheadings says so first: it is why no product can be filed on it, and
  // why the delete button will refuse.
  final children = switch (category.childrenCount ?? 0) {
    0 => null,
    1 => 'تصنيف فرعي',
    2 => 'تصنيفان فرعيان',
    final int many when many <= 10 => '$many تصنيفات فرعية',
    final int many => '$many تصنيفاً فرعياً',
  };

  // Read the same way «سادة» is, and only where this row itself says yes: «أي التصنيفات
  // مفتوحة للمستثمرين؟» is a question about the list, and without the tail it takes opening
  // every sheet in turn. A subheading inheriting a yes is not marked, for the reason given
  // just above — this is the value its own sheet would put back.
  final investable = category.isInvestable == true ? ' · قابل للاستثمار' : '';

  final count = category.shownProductsCount;
  final products = switch (count) {
    null => children == null ? 'تصنيف' : null,
    0 => 'لا منتجات بعد',
    1 => 'منتج واحد',
    2 => 'منتجان',
    >= 3 && <= 10 => '${count.grouped} منتجات',
    _ => '${count.grouped} منتجاً',
  };

  return [?children, ?products].join(' · ') + mode + investable + stopped;
}

/// The heading's picture, or the glyph that stands in for one.
///
/// **The same square either way**, so a list of headings — some pictured, some not — stays a
/// column of rows rather than a ragged edge.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.category});

  final ProductCategory category;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isActive = category.isActive;
    final corner = BorderRadius.circular(10.r);

    return ClipRRect(
      borderRadius: corner,
      child: Container(
        height: 36.w,
        width: 36.w,
        // The tint is the only thing that changes when a category is stopped: enough to scan
        // the list by, not enough to make the row read as broken.
        color: isActive ? scheme.secondaryContainer : scheme.surfaceContainerHighest,
        child: category.hasImage
            ? Image.network(
                category.imageUrl!,
                fit: BoxFit.cover,
                // A signed link that has expired, or a phone with no connection. The glyph is
                // what this row looks like without a picture anyway, so a broken-image icon
                // would only say «شيء ما تعطّل» about something that reads fine.
                errorBuilder: (context, _, _) => _Glyph(isActive: isActive),
              )
            : _Glyph(isActive: isActive),
      ),
    );
  }
}

class _Glyph extends StatelessWidget {
  const _Glyph({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Icon(
      AppIcons.productCategory,
      size: 19.sp,
      color: isActive ? scheme.onSecondaryContainer : scheme.onSurfaceVariant,
    );
  }
}
