import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/utils/digits.dart';
import 'package:printing/core/widgets/paged_list_view.dart';
import 'package:printing/core/widgets/search_field.dart';
import 'package:printing/features/products/models/product.dart';
import 'package:printing/features/products/presentation/viewmodel/products_cubit.dart';
import 'package:printing/features/products/presentation/widgets/product_gallery.dart';
import 'package:printing/features/products/usecases/get_products.dart';

/// What was picked: a bag, and which of its sizes.
///
/// Both, because a line needs both — `product_id` and `product_variant_id` are separate fields
/// on the API, and the price ladder hangs off the size rather than off the product.
typedef PickedProduct = ({Product product, ProductVariant variant});

/// Choosing what goes on a line: the bag, then its size.
///
/// **Two steps in one sheet, and the second is skipped when it has one answer.** A product with
/// a single size in production is picked in one tap; one with five asks which.
///
/// **Stopped products are not offered.** They stay in the catalogue — a past order points at
/// one — but a size nobody prints any more is not something to promise a customer today. The
/// same rule applies inside a product: only its active sizes are listed.
///
/// **No quantity and no price here.** Those belong to the line on the form, where the quantity
/// is re-priced as it is typed and stays visible beside the others. A sheet that collected them
/// would be a second place to edit the same numbers.
///
/// **A size already on the form cannot be picked twice**, and `addedVariantIds` is how the form
/// says which. Two lines of one size climb the price ladder twice — 100 and 200 are quoted as
/// 100 and as 200, never as the 300 the customer is buying — so the duplicate is stopped at the
/// tap that would create it rather than explained afterwards. Left empty by a caller for which
/// repeating a size is ordinary.
///
/// Returns null when the user backs out — an ordinary ending, reported nowhere.
Future<PickedProduct?> showProductPicker({
  required BuildContext context,
  Set<int> addedVariantIds = const {},
}) {
  return showModalBottomSheet<PickedProduct>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (_) => BlocProvider<ProductsCubit>(
      // Constructed here rather than resolved from the injector: this list asks a narrower
      // question than the catalogue tab does — only what is still made.
      create: (_) => ProductsCubit(getProducts: sl<GetProducts>(), onlyOrderable: true)..load(),
      child: _ProductPicker(addedVariantIds: addedVariantIds),
    ),
  );
}

class _ProductPicker extends StatefulWidget {
  const _ProductPicker({required this.addedVariantIds});

  final Set<int> addedVariantIds;

  @override
  State<_ProductPicker> createState() => _ProductPickerState();
}

class _ProductPickerState extends State<_ProductPicker> {
  /// Null while the bag is being chosen; the bag itself while its size is.
  Product? _product;

  bool _isAdded(ProductVariant variant) => widget.addedVariantIds.contains(variant.id);

  void _choose(Product product) {
    final sizes = product.activeVariants;

    // A product whose only size is the obvious one: asking would be a tap with one answer.
    //
    // **Unless that one answer is already on the form.** The shortcut is exactly where a
    // duplicate would slip past every other guard, so the size step is opened instead — a sheet
    // that closed on nothing would leave the clerk tapping the same bag again.
    if (sizes.length == 1 && !_isAdded(sizes.single)) {
      Navigator.of(context).pop((product: product, variant: sizes.single));

      return;
    }

    setState(() => _product = product);
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;

    return product == null ? _buildCatalogue(context) : _buildSizes(context, product);
  }

  Widget _buildCatalogue(BuildContext context) {
    final cubit = context.read<ProductsCubit>();

    return _Sheet(
      title: 'اختيار المنتج',
      searchHint: 'ابحث عن منتج',
      onSearch: cubit.search,
      child: BlocBuilder<ProductsCubit, ProductsState>(
        builder: (context, state) => PagedListView<Product>(
          state: state,
          emptyMessage: 'لا توجد منتجات',
          onLoadMore: cubit.loadMore,
          onRefresh: cubit.refresh,
          // The picture's square plus the padding around it — the placeholder rows are the
          // same height as the real ones, so nothing shifts when the page lands.
          skeletonHeight: 72.h,
          itemBuilder: (context, product, index) => _ProductRow(
            product: product,
            onTap: () => _choose(product),
          ),
        ),
      ),
    );
  }

  Widget _buildSizes(BuildContext context, Product product) {
    final sizes = product.activeVariants;

    return _Sheet(
      title: product.name,
      // The same picture that was tapped, at the size a title is tall. Which bag is being sized
      // is the one thing this step assumes is still known, and after the catalogue slides away
      // the name is all that was left saying it.
      leading: ProductThumbnail(image: product.primaryImage, side: 36.w, radius: 8.r),
      // No search: a product has a handful of sizes, and a box that filters four rows is
      // furniture. The back arrow returns to the catalogue, which does have one.
      onBack: () => setState(() => _product = null),
      child: sizes.isEmpty
          // Possible and worth saying out loud: a product can be in the catalogue before its
          // sizes are, and «لا توجد مقاسات» explains a sheet that would otherwise look broken.
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Text(
                  'لا توجد مقاسات متاحة لهذا المنتج',
                  style: context.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(8.w, 0, 8.w, 16.h),
              itemCount: sizes.length,
              separatorBuilder: (_, _) => Divider(height: 1.h),
              itemBuilder: (context, index) {
                final size = sizes[index];
                final added = _isAdded(size);

                // Shown and refused rather than dropped from the list: a size that vanishes
                // reads as «نفد», and the answer the clerk needs is the opposite of that.
                return ListTile(
                  enabled: !added,
                  title: Text(size.label),
                  subtitle: Text(
                    added
                        ? 'مضاف — عدّل كميته من البنود'
                        : size.dimensionsLabel ?? _priceLine(product, size),
                  ),
                  trailing: added
                      ? Icon(Icons.check_rounded, size: 22.r)
                      : Icon(Icons.chevron_left_rounded, size: 22.r),
                  onTap: added
                      ? null
                      : () => Navigator.of(context).pop((product: product, variant: size)),
                );
              },
            ),
    );
  }
}

/// What a size costs at its cheapest break, or the sentence for a bag quoted by hand.
///
/// A starting price, never *the* price: what this line actually costs depends on the quantity,
/// and that answer comes from the server once one is typed.
String _priceLine(Product product, ProductVariant variant) {
  if (!product.hasListedPrices) return 'السعر حسب الطلب';

  final tiers = variant.tiersByQuantity;
  if (tiers.isEmpty) return 'بلا سعر مسجَّل';

  return 'من ${tiers.first.unitPrice.grouped} د.ل';
}

/// One bag on offer: what it looks like, what it is called, and how many sizes it comes in.
///
/// **The picture is the row's first element and always the same square.** Staff know these bags
/// by sight — «الشفافة بسحاب» and «الشفافة عادية» are one word apart in a list and nothing alike
/// on a shelf — so a picker read only as two lines of Arabic makes somebody who could have
/// pointed at the answer read for it instead.
///
/// **A product without a photograph gets the placeholder square rather than no square.** This is
/// the opposite of what the catalogue card does, and deliberately: a card is read one at a time,
/// where this is a column scanned top to bottom, and a row that starts its text 58 pixels further
/// out breaks the line the eye is running down. Photographs are mandatory now, so the empty
/// square is the legacy row and the not-yet-loaded one — the exceptions, which is exactly what a
/// placeholder should mark.
///
/// **A `Row` rather than the `ListTile` this used to be**, and for one reason: `ListTile` caps
/// whatever it is given as `leading` at 56 logical pixels tall while letting it keep its width,
/// so on any screen wider than a phone — where ScreenUtil scales 48 past that ceiling — the
/// photograph is squashed into a rectangle. A picture that changes shape with the device is
/// worse than none.
class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final sizes = product.activeVariants.length;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        // No horizontal inset: the list already carries the sheet's 16, so the picture's edge
        // sits under the search box's edge — the line everything else here starts from.
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            ProductThumbnail(image: product.primaryImage, side: 48.w),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    product.hasListedPrices
                        ? 'بال${product.pricingUnitLabel} · $sizes مقاس'
                        : 'بال${product.pricingUnitLabel} · السعر حسب الطلب',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Icon(Icons.chevron_left_rounded, size: 22.r, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// The frame both steps share: a grab handle, a title, an optional search box, and the list.
///
/// Deliberately the same furniture as the city picker rather than a shared widget extracted
/// from it — the two sheets have drifted apart once already (this one has a back arrow and a
/// conditional search box), and a frame with four flags is harder to read than two frames.
class _Sheet extends StatelessWidget {
  const _Sheet({
    required this.title,
    required this.child,
    this.searchHint,
    this.onSearch,
    this.onBack,
    this.leading,
  });

  final String title;
  final Widget child;
  final String? searchHint;
  final ValueChanged<String>? onSearch;
  final VoidCallback? onBack;

  /// Something small to put before the title — the chosen product's picture, on the step that
  /// has one. Null on the step that is still choosing.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final search = onSearch;

    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Column(
        children: [
          SizedBox(height: 12.h),
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: scheme.outlineVariant,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
            child: Row(
              children: [
                if (onBack != null)
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    tooltip: 'رجوع إلى المنتجات',
                  ),
                if (leading != null) ...[leading!, SizedBox(width: 10.w)],
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (search != null)
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
              child: SearchField(hint: searchHint ?? 'ابحث', onChanged: search),
            ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
