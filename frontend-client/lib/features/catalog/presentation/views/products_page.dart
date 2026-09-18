import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/pagination/paged_state.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/bidi.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/fixed_point.dart';
import 'package:dayaa_client/core/widgets/filter_option_chip.dart';
import 'package:dayaa_client/core/widgets/product_thumbnail.dart';
import 'package:dayaa_client/core/widgets/search_field.dart';
import 'package:dayaa_client/features/catalog/models/product.dart';
import 'package:dayaa_client/features/catalog/presentation/viewmodel/products_cubit.dart';
import 'package:dayaa_client/features/notifications/presentation/views/notifications_button.dart';
import 'package:dayaa_client/features/orders/presentation/views/cart_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// The catalogue.
///
/// **Only the live half of it, and that is the server's doing.** There is no «show retired»
/// switch to forget here: `CatalogController` fixes `is_active` rather than reading it from the
/// query string, so nothing this screen can send would reopen what the shop stopped selling.
class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProductsCubit>(
      create: (_) => sl<ProductsCubit>()..start(),
      child: const _ProductsView(),
    );
  }
}

class _ProductsView extends StatelessWidget {
  const _ProductsView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProductsCubit>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('المنتجات'),
        actions: const [NotificationsButton()],
      ),
      // **The basket floats here rather than sitting in the bar.** This screen is a branch of the
      // shell, so the navigation bar is drawn under it and a floating button has somewhere to
      // stand; and a basket that fills while the customer scrolls the catalogue is worth more
      // where the thumb is than in a corner that has scrolled away. The product screen keeps
      // [CartButton] in its bar — see [CartFab] for why the two differ.
      floatingActionButton: const CartFab(),
      floatingActionButtonLocation: CartFab.location,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
              // The debounce lives in `PagedCubit.search`, next to the request it throttles.
              child: SearchField(hint: 'ابحث في المنتجات', onChanged: cubit.search),
            ),

            BlocBuilder<ProductsCubit, ProductsState>(
              builder: (context, state) {
                final categories = cubit.categories;

                // No headings means no chip row at all, rather than a row with «الكل» alone in
                // it — a filter that can only be set to everything is not a filter.
                if (categories.isEmpty) return const SizedBox.shrink();

                return SizedBox(
                  height: 44.h,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    children: [
                      FilterOptionChip(
                        label: 'الكل',
                        isSelected: cubit.categoryId == null,
                        onTap: () => cubit.filterBy(null),
                      ),
                      for (final category in categories) ...[
                        SizedBox(width: 8.w),
                        FilterOptionChip(
                          label: category.name,
                          isSelected: cubit.categoryId == category.id,
                          onTap: () => cubit.filterBy(category.id),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 8.h),

            Expanded(
              child: BlocBuilder<ProductsCubit, ProductsState>(
                builder: (context, state) => _ProductGrid(
                  state: state,
                  onLoadMore: cubit.loadMore,
                  onRefresh: cubit.refresh,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A grid rather than [PagedListView].
///
/// **The one place this app does not reuse the core list.** `PagedListView` renders rows, and a
/// catalogue is pictures — a product without its photograph is a line of text nobody can tell
/// apart from the next one. The five states are still drawn the same way; it is the shape of a
/// loaded page that differs.
class _ProductGrid extends StatefulWidget {
  const _ProductGrid({
    required this.state,
    required this.onLoadMore,
    required this.onRefresh,
  });

  final ProductsState state;
  final Future<void> Function() onLoadMore;
  final Future<void> Function() onRefresh;

  @override
  State<_ProductGrid> createState() => _ProductGridState();
}

class _ProductGridState extends State<_ProductGrid> {
  final _controller = ScrollController();

  /// Asked early, so the grid rarely stops at the bottom to wait.
  static const double _threshold = 400;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) return;

    final remaining = _controller.position.maxScrollExtent - _controller.position.pixels;

    if (remaining <= _threshold) widget.onLoadMore();
  }

  @override
  Widget build(BuildContext context) {
    return switch (widget.state) {
      PagedInitial() || PagedLoading() => const Center(child: CircularProgressIndicator()),

      PagedFailure(:final failure) => _Retry(
        message: failure.message,
        onRetry: widget.onRefresh,
      ),

      PagedLoaded(:final page, :final isLoadingMore, :final search) => RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: page.isEmpty
            ? _Empty(search: search)
            : GridView.builder(
                controller: _controller,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12.h,
                  crossAxisSpacing: 12.w,
                  childAspectRatio: 0.72,
                ),
                itemCount: page.items.length + (isLoadingMore ? 2 : 0),
                itemBuilder: (context, index) {
                  if (index >= page.items.length) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return _ProductCard(product: page.items[index]);
                },
              ),
      ),
    };
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final image = product.primaryImageUrl;
    final from = product.lowestUnitPrice;

    // **`shape` alone, never `shape` *and* `borderRadius`.** Material asserts on the pair, and
    // the shape is the one that can also carry the design's hairline border.
    return Material(
      color: scheme.surfaceContainer,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () => context.push(Routes.product(product.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProductThumbnail(image: image),
                  // «٤ مقاسات» — sits on the picture, where it does not cost the card a line.
                  if (product.variantCount > 1)
                    PositionedDirectional(
                      top: 8.h,
                      start: 8.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(999.r),
                        ),
                        child: Text(
                          '${product.variantCount} مقاسات',
                          style: context.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  // **The size range, when the product has one.** «٢٥×٣٥ … ٤٥×٦٠ سم» answers
                  // the question a grid of pictures otherwise leaves open, and it costs no
                  // request — the variants are already in the list response.
                  if (product.sizeRange case final range?) ...[
                    SizedBox(height: 2.h),
                    Text(
                      range.bidiSafe,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  SizedBox(height: 6.h),
                  // **«اطلب عرض سعر» is a decided answer**, not this app inferring one from an
                  // empty tier list: the server sends `has_listed_prices`, and the pricing modes
                  // behind it are never learned here.
                  Text(
                    product.hasListedPrices && from != null
                        ? 'من ${from.asMoney} د.ل'
                        : 'اطلب عرض سعر',
                    style: context.textTheme.labelMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _Empty extends StatelessWidget {
  const _Empty({required this.search});

  final String? search;

  @override
  Widget build(BuildContext context) {
    // «لا توجد نتائج لـ...» and «الكتالوج فارغ» are different problems, and only one of them is
    // the customer's to fix.
    final message = search == null
        ? 'لا توجد منتجات بعد'
        : 'لا توجد نتائج لـ «$search»';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: 120.h),
        Icon(
          AppIcons.empty,
          size: 48.sp,
          color: context.colorScheme.onSurfaceVariant,
        ),
        SizedBox(height: 12.h),
        Text(message, textAlign: TextAlign.center, style: context.textTheme.bodyMedium),
      ],
    );
  }
}

class _Retry extends StatelessWidget {
  const _Retry({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.error, size: 44.sp, color: context.colorScheme.error),
            SizedBox(height: 12.h),
            // The server's own Arabic, never a generic apology.
            Text(message, textAlign: TextAlign.center, style: context.textTheme.bodyMedium),
            SizedBox(height: 16.h),
            OutlinedButton(onPressed: onRetry, child: const Text('أعد المحاولة')),
          ],
        ),
      ),
    );
  }
}
