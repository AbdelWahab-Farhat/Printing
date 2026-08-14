import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/permissions/app_permission.dart';
import 'package:printing/core/router/app_router.dart';
import 'package:printing/core/session/session.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/widgets/paged_list_view.dart';
import 'package:printing/core/widgets/search_field.dart';
import 'package:printing/features/products/models/product.dart';
import 'package:printing/features/products/models/product_category.dart';
import 'package:printing/features/products/presentation/viewmodel/product_categories_cubit.dart';
import 'package:printing/features/products/presentation/viewmodel/products_cubit.dart';
import 'package:printing/features/products/presentation/widgets/product_card.dart';

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

class _ProductsView extends StatelessWidget {
  const _ProductsView();

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
            child: SearchField(hint: 'ابحث عن منتج', onChanged: cubit.search),
          ),
          // Above the type row, because it is the broader question — «أين أبحث؟» before
          // «مطبوعة أم سادة؟» — and the same order the product form asks them in.
          //
          // Absent entirely until there is more than one heading to choose between: a single
          // chip beside «الكل» is a control that cannot change anything.
          BlocBuilder<ProductCategoriesCubit, ProductCategoriesState>(
            builder: (context, state) => _ProductCategoryFilterBar(
              categories: switch (state) {
                ProductCategoriesLoaded(:final page) => page.items,
                _ => const <ProductCategory>[],
              },
              selected: cubit.productCategoryId,
              onSelected: cubit.filterByProductCategory,
            ),
          ),
          Expanded(
            child: BlocBuilder<ProductsCubit, ProductsState>(
              builder: (context, state) => PagedListView<Product>(
                state: state,
                emptyMessage: 'لا توجد منتجات بعد',
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

/// «التصنيف» — أكياس, علب وكراتين, ستيكرات. The catalogue's own headings, as chips.
///
/// **Built from the server's list rather than from an enum**, because the headings are rows the
/// business curates: a chip row spelled out in code would go stale the first time somebody adds
/// one from «تصنيفات المنتجات».
///
/// It takes no room at all while there is nothing to choose between — one heading and «الكل»
/// filter to the same list, and a control that cannot change anything is worse than none.
class _ProductCategoryFilterBar extends StatelessWidget {
  const _ProductCategoryFilterBar({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<ProductCategory> categories;

  /// The id being filtered on, or null for «الكل».
  final int? selected;

  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (categories.length < 2) return const SizedBox.shrink();

    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: SizedBox(
        height: 42.h,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          // One more than the headings: «الكل» leads, and is what clears the filter.
          itemCount: categories.length + 1,
          separatorBuilder: (context, index) => SizedBox(width: 8.w),
          itemBuilder: (context, index) {
            final category = index == 0 ? null : categories[index - 1];
            final isSelected = category?.id == selected;

            return ChoiceChip(
              label: Text(category?.name ?? 'الكل'),
              selected: isSelected,
              // Tapping the chip that is already on is not a way to clear it: «الكل» is, and it
              // is right there. Toggling off would leave two ways to mean the same thing.
              onSelected: (_) => onSelected(category?.id),
              showCheckmark: false,
              backgroundColor: scheme.surfaceContainerLowest,
              selectedColor: scheme.primaryContainer,
              labelStyle: context.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
              ),
              side: BorderSide(
                color: isSelected ? Colors.transparent : scheme.outlineVariant,
              ),
            );
          },
        ),
      ),
    );
  }
}

