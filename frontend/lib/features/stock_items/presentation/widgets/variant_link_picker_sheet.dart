import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dialog.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/products/models/product.dart';
import 'package:dayaa/features/products/presentation/viewmodel/products_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Which product sizes draw on one material — ticked out of the catalogue, sent once.
///
/// **The link is a column on a product size, and until now the only way to set it was to save the
/// product.** Pointing four sizes across three products at one pile meant three saves, each one
/// resending prices, tiers and images nobody on this screen had touched. This asks the question
/// from the side that knows the answer: the person looking at the pile.
///
/// **What comes back is the whole set, not the additions.** `PUT /stock-items/{id}/variants`
/// replaces — what is in the list is linked, what is missing comes off — so the caller sends
/// exactly what this returns and unticking a box means something.
///
/// **Ids never rendered stay in the set.** The selection is seeded with [initial] and only what is
/// tapped ever leaves it, so a size on a page that was never scrolled to, or on a product the
/// search never matched, is still in the answer. Any other arrangement would make an unrelated
/// search term silently unlink half a material.
///
/// **Stopped sizes are listed too**, greyed, rather than filtered out the way the sibling picker
/// in `features/warehouses` filters them. That one is choosing something to record a movement
/// against, where offering a size the shop no longer sells creates a balance nobody can explain.
/// This one is editing a set that already exists: a hidden row that cannot be unticked is a row
/// that can never be corrected.
///
/// Answers null when dismissed — the caller keeps whatever it had.
Future<Set<int>?> showVariantLinkPicker({
  required BuildContext context,
  required String materialName,
  required Set<int> initial,
}) {
  return showModalBottomSheet<Set<int>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BlocProvider<ProductsCubit>(
      // The catalogue list, its search debounce and its paging are the same here as on the
      // products tab, and `variants.stockItem` is already eager-loaded on it — which is what lets
      // a row say the size is drawing on something else without a second request.
      create: (_) => sl<ProductsCubit>()..load(),
      child: _VariantLinkPicker(materialName: materialName, initial: initial),
    ),
  );
}

class _VariantLinkPicker extends StatefulWidget {
  const _VariantLinkPicker({required this.materialName, required this.initial});

  /// This material, by the name a person reads — «كيس شحن 25*35». Only ever shown: the request
  /// is the caller's to make.
  final String materialName;

  final Set<int> initial;

  @override
  State<_VariantLinkPicker> createState() => _VariantLinkPickerState();
}

class _VariantLinkPickerState extends State<_VariantLinkPicker> {
  late final Set<int> _selected = {...widget.initial};

  /// Which product's sizes are open. One at a time: two expanded products push the second one
  /// off a sheet that is already sharing the screen with a keyboard.
  int? _openProductId;

  /// Ticks a size, asking first when it is leaving another material.
  ///
  /// **The confirm names the pile it is leaving, because the row cannot.** Somebody ticking «كيس
  /// شحن سادة — 25*35» here is looking at this material's screen; that the size currently eats
  /// from «كيس ورقي 25*35» is on the row in small print and is exactly the fact that makes the
  /// tick consequential. Every deduction that size causes from now on comes off a different heap.
  ///
  /// Unticking asks nothing: a size drawing on nothing is refused by name at the moment anybody
  /// tries to fulfil with it, loudly and before any stock moves.
  Future<void> _toggle(ProductVariant variant) async {
    if (_selected.contains(variant.id)) {
      setState(() => _selected.remove(variant.id));

      return;
    }

    final elsewhere = variant.stockItem;

    if (elsewhere != null) {
      final confirmed = await showCustomDialog(
        context: context,
        title: 'نقل «${variant.label}» إلى «${widget.materialName}»؟',
        description:
            'هذا المقاس يسحب حالياً من «${elsewhere.displayName}». بعد الحفظ سيسحب من '
            '«${widget.materialName}» بدلاً منها. الحركات المسجّلة سابقاً لا تتغيّر — تبقى على '
            'المادة التي خرجت منها فعلاً.',
        severity: DialogSeverity.warning,
        confirmLabel: 'انقله',
      );

      if (!(confirmed ?? false)) return;
    }

    setState(() => _selected.add(variant.id));
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProductsCubit>();
    final scheme = context.colorScheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
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
                  selected: _selected,
                  onToggleOpen: () => setState(
                    () => _openProductId = product.id == _openProductId ? null : product.id,
                  ),
                  onToggleVariant: _toggle,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
            child: AppButton(
              // The count, because the sheet pages and searches: what is ticked three screens up
              // is invisible by the time somebody decides they are done.
              label: _selected.isEmpty
                  ? 'بلا مقاسات'
                  : 'تم — ${_selected.length} ${_selected.length == 1 ? 'مقاس' : 'مقاسات'}',
              onPressed: () => Navigator.of(context).pop(_selected),
            ),
          ),
        ],
      ),
    );
  }
}

/// One product, and its sizes when it is open.
class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.product,
    required this.isOpen,
    required this.selected,
    required this.onToggleOpen,
    required this.onToggleVariant,
  });

  final Product product;
  final bool isOpen;
  final Set<int> selected;
  final VoidCallback onToggleOpen;
  final ValueChanged<ProductVariant> onToggleVariant;

  /// How many of this product's sizes are ticked — drawn on the closed row, so a person scrolling
  /// a long catalogue can see where their selection is without opening anything.
  int get _picked => product.variants.where((v) => selected.contains(v.id)).length;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final variants = product.variants;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          onTap: variants.isEmpty ? null : onToggleOpen,
          title: Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            variants.isEmpty
                ? 'لا مقاسات'
                : '${product.code} · ${variants.length} مقاس'
                      '${_picked == 0 ? '' : ' · $_picked مختار'}',
            style: context.textTheme.labelSmall?.copyWith(
              color: _picked == 0 ? scheme.onSurfaceVariant : scheme.primary,
              fontWeight: _picked == 0 ? FontWeight.w400 : FontWeight.w700,
            ),
          ),
          trailing: variants.isEmpty
              ? null
              : Icon(isOpen ? Icons.expand_less : Icons.expand_more, color: scheme.outline),
        ),
        if (isOpen)
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
            child: Column(
              children: [
                for (final variant in variants)
                  _VariantRow(
                    variant: variant,
                    isSelected: selected.contains(variant.id),
                    onToggle: () => onToggleVariant(variant),
                  ),
              ],
            ),
          ),
        Divider(height: 1, thickness: 1, color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ],
    );
  }
}

/// One size, ticked or not — and what it is drawing on if that is not this material.
class _VariantRow extends StatelessWidget {
  const _VariantRow({
    required this.variant,
    required this.isSelected,
    required this.onToggle,
  });

  final ProductVariant variant;
  final bool isSelected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final shelf = variant.shelfLabel;

    return CheckboxListTile(
      value: isSelected,
      onChanged: (_) => onToggle(),
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Flexible(
            child: Text(
              variant.label,
              textDirection: TextDirection.ltr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(
                // A stopped size is greyed, not hidden: it can still be the one drawing on this
                // material, and hiding it would make it impossible to untick.
                color: variant.isActive ? null : scheme.onSurfaceVariant,
              ),
            ),
          ),
          if (!variant.isActive) ...[
            SizedBox(width: 6.w),
            Text(
              'موقوف',
              style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
      // Only when it draws on something, and only in small print: this is the fact that turns a
      // tick into a move, and the confirm that follows says it in full.
      subtitle: shelf == null
          ? null
          : Text(
              'يسحب من «$shelf»',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
    );
  }
}
