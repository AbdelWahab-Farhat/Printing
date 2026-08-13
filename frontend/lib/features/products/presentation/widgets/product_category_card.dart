import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/utils/digits.dart';
import 'package:printing/features/products/models/product_category.dart';

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
              _Glyph(isActive: category.isActive),
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
/// Arabic counts its nouns differently at one, two, and beyond ten, and a screen that says «1
/// منتجات» reads as a bug in front of the person using it every day.
String _subtitle(ProductCategory category) {
  final count = category.productsCount;
  final stopped = category.isActive ? '' : ' · موقوف';

  if (count == null) return 'تصنيف$stopped';

  final products = switch (count) {
    0 => 'لا منتجات بعد',
    1 => 'منتج واحد',
    2 => 'منتجان',
    >= 3 && <= 10 => '${count.grouped} منتجات',
    _ => '${count.grouped} منتجاً',
  };

  return '$products$stopped';
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
        // The tint is the only thing that changes when a category is stopped: enough to scan
        // the list by, not enough to make the row read as broken.
        color: isActive ? scheme.secondaryContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Icon(
        AppIcons.productCategory,
        size: 19.sp,
        color: isActive ? scheme.onSecondaryContainer : scheme.onSurfaceVariant,
      ),
    );
  }
}
