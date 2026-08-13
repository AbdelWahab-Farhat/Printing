import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/features/products/models/product_category.dart';
import 'package:printing/features/products/presentation/viewmodel/product_categories_cubit.dart';

/// «التصنيف» on the product form — which heading of the catalogue this product sits under.
///
/// **Required, unlike the business-field picker it is otherwise modelled on.** A shop with no
/// trade recorded is a real shop; a product with no category is a product that cannot be found
/// in the catalogue at all, which is the one thing the catalogue is for. So there is no «غير
/// محدد» entry, and the server refuses a save without one.
///
/// It reads the list from a [ProductCategoriesCubit] provided above the form, narrowed to the
/// categories still on offer — see `Injector.activeProductCategoriesCubit`.
///
/// A category that is no longer offered but is already on this product stays selectable: it is
/// merged into the options below. Otherwise opening an old product would silently blank a
/// heading recorded months ago, which is the one thing a form must never do to data it was only
/// asked to display.
class ProductCategoryPicker extends StatelessWidget {
  const ProductCategoryPicker({
    required this.value,
    required this.onChanged,
    this.current,
    this.errorText,
    super.key,
  });

  /// The id currently on the product, or null while nothing has been picked.
  final int? value;

  final ValueChanged<int?> onChanged;

  /// The category already recorded on this product, when the form was opened on an existing
  /// one. It is what keeps a stopped category selectable rather than blanked.
  final ProductCategory? current;

  /// The server's complaint about `product_category_id`, if it made one.
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductCategoriesCubit, ProductCategoriesState>(
      builder: (context, state) {
        final categories = _options(state, current);

        return DropdownButtonFormField<int?>(
          initialValue: categories.any((category) => category.id == value) ? value : null,
          decoration: InputDecoration(
            labelText: 'التصنيف',
            prefixIcon: Icon(AppIcons.productCategory),
            errorText: errorText,
            // The list may still be arriving, or the account may have no categories to offer.
            // Both are said out loud rather than left as an empty dropdown the user taps twice.
            helperText: switch (state) {
              ProductCategoriesLoading() => 'جارٍ تحميل التصنيفات…',
              ProductCategoriesLoaded() when categories.isEmpty =>
                'لا توجد تصنيفات بعد — أضِف واحداً من «تصنيفات المنتجات»',
              ProductCategoriesFailure() => 'تعذّر تحميل التصنيفات',
              _ => null,
            },
          ),
          items: [
            for (final category in categories)
              DropdownMenuItem<int?>(
                value: category.id,
                child: Text(
                  category.isActive ? category.name : '${category.name} (موقوف)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: onChanged,
          borderRadius: BorderRadius.circular(12.r),
          isExpanded: true,
        );
      },
    );
  }
}

/// What the dropdown offers: the categories on offer, plus this product's own if it is not
/// among them.
List<ProductCategory> _options(ProductCategoriesState state, ProductCategory? current) {
  final loaded = switch (state) {
    ProductCategoriesLoaded(:final page) => page.items,
    _ => const <ProductCategory>[],
  };

  if (current == null || loaded.any((category) => category.id == current.id)) return loaded;

  return [...loaded, current];
}
