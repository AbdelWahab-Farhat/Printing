import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/widgets/paged_list_view.dart';
import 'package:printing/core/widgets/search_field.dart';
import 'package:printing/features/products/models/product.dart';
import 'package:printing/features/products/presentation/viewmodel/products_cubit.dart';

/// Which product a rate is pinned to — the product, and not one of its sizes.
///
/// **A sheet of its own rather than the order form's picker**, which answers with a bag *and* a
/// size because a line needs both. Asking somebody to choose a size in order to say «كل مقاسات
/// هذا المنتج» would be asking them to make a choice this rung deliberately does not make, and
/// the discarded answer is exactly the kind of thing a user later swears they picked.
///
/// **Stopped products are offered.** Unlike the order picker, which must not promise a customer
/// something nobody prints: a rate is a fact about what production costs, and a bag that came
/// back into the catalogue should find its rate still there.
///
/// Returns null when the user backs out — an ordinary ending, reported nowhere.
Future<Product?> showRateProductPicker({required BuildContext context}) {
  return showModalBottomSheet<Product>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (_) => BlocProvider<ProductsCubit>(
      create: (_) => sl<ProductsCubit>()..load(),
      child: const _RateProductPicker(),
    ),
  );
}

class _RateProductPicker extends StatelessWidget {
  const _RateProductPicker();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProductsCubit>();
    final scheme = context.colorScheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, controller) => Column(
        children: [
          SizedBox(height: 8.h),
          Container(
            height: 4.h,
            width: 40.w,
            decoration: BoxDecoration(
              color: scheme.outlineVariant,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
            child: SearchField(hint: 'ابحث عن منتج', onChanged: cubit.search),
          ),
          Expanded(
            child: BlocBuilder<ProductsCubit, ProductsState>(
              builder: (context, state) => PagedListView<Product>(
                state: state,
                emptyMessage: 'لا توجد منتجات',
                onLoadMore: cubit.loadMore,
                onRefresh: cubit.refresh,
                skeletonHeight: 56.h,
                itemBuilder: (context, product, index) => ListTile(
                  key: ValueKey(product.id),
                  onTap: () => Navigator.of(context).pop(product),
                  title: Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    // The code is what staff say out loud, and «موقوف» is why a product with no
                    // orders on it is still in this list.
                    product.isActive ? product.code : '${product.code} · موقوف',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
