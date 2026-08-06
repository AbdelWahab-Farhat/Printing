import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/widgets/paged_list_view.dart';
import 'package:printing/core/widgets/search_field.dart';
import 'package:printing/features/products/models/product.dart';
import 'package:printing/features/products/presentation/viewmodel/products_cubit.dart';
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
/// Returns null when the user backs out — an ordinary ending, reported nowhere.
Future<PickedProduct?> showProductPicker({required BuildContext context}) {
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
      child: const _ProductPicker(),
    ),
  );
}

class _ProductPicker extends StatefulWidget {
  const _ProductPicker();

  @override
  State<_ProductPicker> createState() => _ProductPickerState();
}

class _ProductPickerState extends State<_ProductPicker> {
  /// Null while the bag is being chosen; the bag itself while its size is.
  Product? _product;

  void _choose(Product product) {
    final sizes = product.activeVariants;

    // A product whose only size is the obvious one: asking would be a tap with one answer.
    if (sizes.length == 1) {
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
          skeletonHeight: 68.h,
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

                return ListTile(
                  title: Text(size.label),
                  subtitle: Text(size.dimensionsLabel ?? _priceLine(product, size)),
                  trailing: Icon(Icons.chevron_left_rounded, size: 22.r),
                  onTap: () =>
                      Navigator.of(context).pop((product: product, variant: size)),
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

  return 'من ${tiers.first.unitPrice} د.ل';
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sizes = product.activeVariants.length;

    return ListTile(
      title: Text(product.name),
      subtitle: Text(
        product.hasListedPrices
            ? '${product.categoryLabel} · $sizes مقاس'
            : '${product.categoryLabel} · السعر حسب الطلب',
      ),
      trailing: Icon(Icons.chevron_left_rounded, size: 22.r),
      onTap: onTap,
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
  });

  final String title;
  final Widget child;
  final String? searchHint;
  final ValueChanged<String>? onSearch;
  final VoidCallback? onBack;

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
                Expanded(
                  child: Text(
                    title,
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
