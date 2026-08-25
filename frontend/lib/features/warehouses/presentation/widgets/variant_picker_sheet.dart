import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/products/models/product.dart';
import 'package:dayaa/features/products/presentation/viewmodel/products_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Which product size is being priced.
///
/// **It no longer picks a shelf, and it lives here only because it was born here.** Stock used to
/// be held per product size, so recording a movement started by walking the catalogue; a shelf is
/// now a صنف مخزني that several products draw on, and `showStockItemPicker` in
/// `features/stock_items` is what the recording sheet asks with. What is left of this one is the
/// question a *cost rate* asks — «كم تكلفة طباعة هذا المقاس؟» — which is genuinely per product
/// size, because printing is what distinguishes two catalogue rows that share one pile.
///
/// Its one caller is `features/manufacturing_cost_rates`. **Move it there when that feature is
/// next opened**; it stayed put in this change only because moving a file two features touch is
/// not something to do in the same commit as a contract swap.
///
/// One sheet rather than two screens: the catalogue is already searchable and each product
/// carries its sizes, so tapping a product opens its sizes underneath it and tapping a size
/// answers.
///
/// It borrows [ProductsCubit] whole. The catalogue list, its search debounce and its paging are
/// the same here as on the products tab, and a second implementation of them would be a second
/// thing to keep in step.
Future<({Product product, ProductVariant variant})?> showVariantPicker({
  required BuildContext context,
}) {
  return showModalBottomSheet<({Product product, ProductVariant variant})>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BlocProvider<ProductsCubit>(
      create: (_) => sl<ProductsCubit>()..load(),
      child: const _VariantPicker(),
    ),
  );
}

class _VariantPicker extends StatefulWidget {
  const _VariantPicker();

  @override
  State<_VariantPicker> createState() => _VariantPickerState();
}

class _VariantPickerState extends State<_VariantPicker> {
  /// Which product's sizes are open. One at a time: two expanded products push the second one
  /// off a sheet that is already sharing the screen with a keyboard.
  int? _openProductId;

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
                itemBuilder: (context, product, index) => _ProductRow(
                  product: product,
                  isOpen: product.id == _openProductId,
                  onToggle: () => setState(
                    () => _openProductId = product.id == _openProductId ? null : product.id,
                  ),
                  onPick: (variant) =>
                      Navigator.of(context).pop((product: product, variant: variant)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.product,
    required this.isOpen,
    required this.onToggle,
    required this.onPick,
  });

  final Product product;
  final bool isOpen;
  final VoidCallback onToggle;
  final ValueChanged<ProductVariant> onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    // A stopped size is not offered: recording stock against something the shop no longer sells
    // is how a balance nobody can explain appears.
    final variants = product.activeVariants;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          onTap: variants.isEmpty ? null : onToggle,
          title: Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            variants.isEmpty ? 'لا مقاسات مفعّلة' : '${product.code} · ${variants.length} مقاس',
            style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        if (isOpen)
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
            child: Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                for (final variant in variants)
                  ActionChip(
                    label: Text(variant.label, textDirection: TextDirection.ltr),
                    onPressed: () => onPick(variant),
                    backgroundColor: scheme.surfaceContainerHighest,
                    side: BorderSide(color: scheme.outlineVariant),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  ),
              ],
            ),
          ),
        Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ],
    );
  }
}
