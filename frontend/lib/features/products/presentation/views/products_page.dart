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
import 'package:printing/features/products/models/pricing_unit_filter.dart';
import 'package:printing/features/products/models/product.dart';
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
          // Rebuilt with the list, so the selected chip and what is on screen can never disagree.
          BlocBuilder<ProductsCubit, ProductsState>(
            builder: (context, state) => _UnitFilterBar(
              selected: cubit.unit,
              onSelected: cubit.filterByUnit,
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
                itemBuilder: (context, product, index) =>
                    ProductCard(key: ValueKey(product.id), product: product),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// بالقطعة or بالكيلوغرام — a filter, not something to type.
///
/// The search box matches names and slugs, so "كيلو" finds nothing: a bag priced by weight is
/// not called that, the *pricing* is. Making it a tap rather than a word is the difference
/// between an answer and an empty screen.
class _UnitFilterBar extends StatelessWidget {
  const _UnitFilterBar({required this.selected, required this.onSelected});

  final PricingUnitFilter selected;
  final ValueChanged<PricingUnitFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return SizedBox(
      height: 42.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: PricingUnitFilter.values.length,
        separatorBuilder: (context, index) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final filter = PricingUnitFilter.values[index];
          final isSelected = filter == selected;

          return ChoiceChip(
            label: Text(filter.label),
            selected: isSelected,
            // Tapping the chip that is already on is not a way to clear it: "الكل" is, and it
            // is right there. Toggling off would leave two ways to mean the same thing.
            onSelected: (_) => onSelected(filter),
            showCheckmark: false,
            backgroundColor: scheme.surfaceContainerLowest,
            selectedColor: scheme.primaryContainer,
            labelStyle: context.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
            ),
            side: BorderSide(
              color: isSelected ? Colors.transparent : scheme.outlineVariant,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          );
        },
      ),
    );
  }
}
