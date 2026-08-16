import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/products/models/product.dart';
import 'package:dayaa/features/products/models/product_category.dart';
import 'package:dayaa/features/products/presentation/viewmodel/product_categories_cubit.dart';
import 'package:dayaa/features/products/presentation/viewmodel/products_cubit.dart';
import 'package:dayaa/features/products/presentation/widgets/product_card.dart';
import 'package:dayaa/features/products/presentation/widgets/product_category_filter_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// المنتجات — the catalogue, straight from the API.
///
/// A body, not a screen: the app bar and the tabs belong to the shell above it. The search box
/// and the list are the same two widgets the customers tab uses; only the card differs.
class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProductsCubit>(
      create: (_) => sl<ProductsCubit>()..load(),
      child: BlocProvider<ProductCategoriesCubit>(
        // The offered headings only: filtering by a category nobody may file under any more
        // would be a chip that finds a shrinking list and then nothing.
        create: (_) =>
            sl<ProductCategoriesCubit>(instanceName: Injector.activeProductCategoriesCubit)
              ..load(),
        child: const _ProductsView(),
      ),
    );
  }
}

class _ProductsView extends StatefulWidget {
  const _ProductsView();

  @override
  State<_ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<_ProductsView> {
  /// The heading the sheet last answered with, held here rather than read off the Cubit.
  ///
  /// **Screen state, not list state.** `PagedState` is the answer to a question; this is the
  /// question, and it has to survive the skeleton that replaces the answer while the narrowed
  /// page is in flight — the button must not flick back to neutral for the length of a request.
  /// The Cubit holds it too, because it is what the *request* is made of; this copy is what the
  /// button is drawn from. The same split the customers tab makes.
  int? _categoryId;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProductsCubit>();

    return Scaffold(
      // Transparent: the shell above owns the real Scaffold, and this one exists only to hang
      // a floating button off. The same shape the customers tab uses.
      backgroundColor: Colors.transparent,
      floatingActionButton: sl<Session>().can(AppPermission.manageProducts)
          // A ternary rather than `PermissionGate`, and deliberately: a `SizedBox.shrink()` in
          // the FAB slot still occupies it and shifts the Scaffold's bottom inset. The grep of
          // record for gated controls is `AppPermission.`, which catches both forms.
          //
          // And it is a courtesy, not a boundary — `can:products.manage` on the route is what
          // actually refuses the write.
          ? FloatingActionButton.extended(
              // Unique per screen, because the shell keeps every tab alive in an IndexedStack:
              // two default-tagged FABs in one subtree is the «multiple heroes» assertion.
              heroTag: 'fab-products',
              // Refreshes on the way back: a bag added on that form belongs in this list
              // without the user having to think about pulling down.
              onPressed: () async {
                await context.push(Routes.addProduct);
                await cubit.refresh();
              },
              icon: Icon(AppIcons.addProduct),
              label: const Text('منتج جديد'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
            child: Row(
              children: [
                Expanded(
                  child: SearchField(hint: 'ابحث عن منتج', onChanged: cubit.search),
                ),
                SizedBox(width: 8.w),
                // Beside the search box rather than in a chip row under it — the shape the
                // customers tab already uses, and it gives the catalogue back the band the
                // headings were eating whether or not anybody was filtering.
                //
                // The button draws itself out of the tree entirely until there is more than one
                // heading to choose between: a sheet offering «الكل» and one heading is a
                // control that cannot change anything.
                BlocBuilder<ProductCategoriesCubit, ProductCategoriesState>(
                  builder: (context, state) => ProductCategoryFilterButton(
                    categories: switch (state) {
                      ProductCategoriesLoaded(:final page) => page.items,
                      _ => const <ProductCategory>[],
                    },
                    selected: _categoryId,
                    onApplied: (id) {
                      setState(() => _categoryId = id);
                      unawaited(cubit.filterByProductCategory(id));
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<ProductsCubit, ProductsState>(
              builder: (context, state) => PagedListView<Product>(
                state: state,
                // «لا توجد منتجات بعد» about a *narrowed* catalogue would say the shop makes
                // nothing when it is the heading that came back empty.
                emptyMessage: _categoryId == null
                    ? 'لا توجد منتجات بعد'
                    : 'لا توجد منتجات بهذا التصنيف',
                onLoadMore: cubit.loadMore,
                onRefresh: cubit.refresh,
                // A product card carries its whole price grid, so it is about twice the default
                // placeholder. Left at 106 the list would visibly jump when the real rows land.
                // 210 is the measured height of a four-size product, which is most of them.
                skeletonHeight: 210.h,
                itemBuilder: (context, product, index) => ProductCard(
                  key: ValueKey(product.id),
                  product: product,
                  // No refresh on the way back: that screen only reads. It gets one the day
                  // stopping a product from it lands.
                  onTap: () => unawaited(context.push(Routes.product(product.id))),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
