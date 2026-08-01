import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/widgets/paged_list_view.dart';
import 'package:printing/core/widgets/search_field.dart';
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

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
          child: SearchField(hint: 'ابحث عن منتج', onChanged: cubit.search),
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
    );
  }
}
