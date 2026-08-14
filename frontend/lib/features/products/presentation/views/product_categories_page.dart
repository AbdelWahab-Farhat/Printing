import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_dialog.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/products/models/product_category.dart';
import 'package:dayaa/features/products/presentation/viewmodel/product_categories_cubit.dart';
import 'package:dayaa/features/products/presentation/widgets/product_category_card.dart';
import 'package:dayaa/features/products/presentation/widgets/product_category_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// تصنيفات المنتجات — the headings the catalogue is organised under.
///
/// A curated list, so the screen is a list plus the three things that can happen to a row:
/// rename it, stop offering it, or remove one that should never have been there.
///
/// **Reading and writing are gated separately.** A reader gets the list with no switch, no
/// button and no sheet; the server refuses either way, and this is only what keeps a control
/// that would fail off the screen in the first place.
class ProductCategoriesPage extends StatelessWidget {
  const ProductCategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProductCategoriesCubit>(
      create: (_) => sl<ProductCategoriesCubit>()..load(),
      child: const _ProductCategoriesView(),
    );
  }
}

/// Stateful for one reason: the order the cards are in between the drag and the server's
/// answer.
///
/// The Cubit re-reads the list after saving, which is what guarantees the screen ends up showing
/// the order that was actually stored. But a list that snapped back to the old order for the
/// length of a round trip would read as the drag having failed, so the moved order is held here
/// — a rendering detail, and it belongs where rendering does.
class _ProductCategoriesView extends StatefulWidget {
  const _ProductCategoriesView();

  @override
  State<_ProductCategoriesView> createState() => _ProductCategoriesViewState();
}

class _ProductCategoriesViewState extends State<_ProductCategoriesView> {
  /// The order shown while a save is in flight, or null when the server's is the one on screen.
  List<ProductCategory>? _dragged;

  /// Whether the list may be dragged at all.
  ///
  /// **Not while a search is narrowing it.** Dragging inside a filtered list would save an
  /// order for the rows that happen to match a word, and the person doing it has no way to see
  /// what that means for the rows that do not.
  bool _isReorderable(ProductCategoriesState state, {required bool canManage}) {
    if (!canManage || (cubitOf(context).currentSearch?.isNotEmpty ?? false)) return false;

    // Nor across pages nobody can see: an order can only be dragged among the cards on screen.
    return state is ProductCategoriesLoaded && !state.page.meta.hasMore;
  }

  ProductCategoriesCubit cubitOf(BuildContext context) =>
      context.read<ProductCategoriesCubit>();

  Future<void> _onReorder(List<ProductCategory> shown, int from, int to) async {
    final cubit = cubitOf(context);

    // `onReorderItem` reports the target index *after* the moved row is taken out, which is
    // why there is no off-by-one adjustment here — the older `onReorder` needed one.
    final moved = [...shown];
    moved.insert(to, moved.removeAt(from));

    setState(() => _dragged = moved);

    final failure = await cubit.reorder([for (final category in moved) category.id]);

    if (!mounted) return;

    // Either way the server's list is the one to trust from here: it was re-read on success,
    // and on failure it never changed.
    setState(() => _dragged = null);

    if (failure != null && context.mounted) context.showFailure(failure);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProductCategoriesCubit>();
    final canManage = sl<Session>().can(AppPermission.manageProducts);

    return Scaffold(
      appBar: AppBar(title: const Text('تصنيفات المنتجات')),
      floatingActionButton: canManage
          // A ternary rather than a gate widget: a `SizedBox.shrink()` in the FAB slot still
          // occupies it and shifts the Scaffold's bottom inset.
          ? FloatingActionButton.extended(
              // Unique per screen, because the shell keeps every tab alive in an IndexedStack:
              // two default-tagged FABs in one subtree is the «multiple heroes» assertion.
              heroTag: 'fab-product-categories',
              onPressed: () async {
                final created = await showProductCategorySheet(
                  context: context,
                  nextSortOrder: _nextSortOrder(cubit.state),
                );

                if (created != null) await cubit.refresh();
              },
              icon: Icon(AppIcons.add),
              label: const Text('تصنيف جديد'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
            child: SearchField(
              hint: 'ابحث عن تصنيف',
              onChanged: cubit.search,
            ),
          ),
          Expanded(
            child: BlocBuilder<ProductCategoriesCubit, ProductCategoriesState>(
              builder: (context, state) {
                if (_isReorderable(state, canManage: canManage)) {
                  final shown =
                      _dragged ?? (state as ProductCategoriesLoaded).page.items;

                  return _DraggableCategories(
                    categories: shown,
                    onRefresh: cubit.refresh,
                    onReorder: (from, to) => unawaited(_onReorder(shown, from, to)),
                    cardFor: (category) => ProductCategoryCard(
                      key: ValueKey(category.id),
                      category: category,
                      onTap: () => _edit(context, cubit, category),
                      onToggleActive: (isActive) =>
                          _toggle(context, cubit, category, isActive: isActive),
                    ),
                  );
                }

                return PagedListView<ProductCategory>(
                  state: state,
                  emptyMessage: 'لا توجد تصنيفات بعد',
                  onLoadMore: cubit.loadMore,
                  onRefresh: cubit.refresh,
                  // One row measured: a 36 tile with two lines beside it.
                  skeletonHeight: 68.h,
                  itemBuilder: (context, category, index) => ProductCategoryCard(
                    key: ValueKey(category.id),
                    category: category,
                    onTap: canManage ? () => _edit(context, cubit, category) : null,
                    onToggleActive: canManage
                        ? (isActive) => _toggle(context, cubit, category, isActive: isActive)
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Opens the rename sheet, and offers the delete from inside it — the one place where both
  /// the name and the product count are already on screen, so «لماذا لا يمكن حذفه؟» is answered
  /// before it is asked.
  Future<void> _edit(
    BuildContext context,
    ProductCategoriesCubit cubit,
    ProductCategory category,
  ) async {
    final saved = await showProductCategorySheet(
      context: context,
      category: category,
      onDelete: () => _confirmDelete(context, cubit, category),
    );

    if (saved != null) await cubit.refresh();
  }

  /// Confirms, then removes. Answers whether the category is gone, so the sheet knows to close.
  Future<bool> _confirmDelete(
    BuildContext context,
    ProductCategoriesCubit cubit,
    ProductCategory category,
  ) async {
    final confirmed = await showDestructiveDialog(
      context: context,
      title: 'حذف «${category.name}»؟',
      description:
          'يختفي التصنيف من قوائم الاختيار نهائياً. الحذف متاح لأنه غير مرتبط بأي منتج — لو '
          'ارتبط به منتج لاحقاً فالإيقاف هو الطريقة.',
    );

    if (confirmed != true || !context.mounted) return false;

    final failure = await cubit.remove(category);

    if (!context.mounted) return failure == null;

    if (failure != null) {
      // The server's own Arabic says which refusal it was — most often «مرتبط بمنتجات», when
      // the count on the card was stale. The app does not guess between them.
      context.showFailure(failure);

      return false;
    }

    context.showSuccess('تم حذف ${category.name}');

    return true;
  }

  Future<void> _toggle(
    BuildContext context,
    ProductCategoriesCubit cubit,
    ProductCategory category, {
    required bool isActive,
  }) async {
    final failure = await cubit.setActivation(category, isActive: isActive);

    if (!context.mounted) return;

    if (failure != null) {
      context.showFailure(failure);

      return;
    }

    context.showSuccess(
      isActive ? 'تم تفعيل ${category.name}' : 'تم إيقاف ${category.name}',
    );
  }
}

/// The list, in an order a finger can change.
///
/// A `ReorderableListView` rather than the shared [PagedListView], because reordering is this
/// screen's alone — every other list in the app is in an order the server decided, and teaching
/// the shared widget to drag would put a handle on all of them.
class _DraggableCategories extends StatelessWidget {
  const _DraggableCategories({
    required this.categories,
    required this.onRefresh,
    required this.onReorder,
    required this.cardFor,
  });

  final List<ProductCategory> categories;
  final Future<void> Function() onRefresh;
  final void Function(int from, int to) onReorder;
  final Widget Function(ProductCategory category) cardFor;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ReorderableListView.builder(
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 96.h),
        itemCount: categories.length,
        onReorderItem: onReorder,
        // Off, because the whole card is the handle — see below. Left on, a long press would
        // pick up a row somebody was only trying to tap.
        buildDefaultDragHandles: false,
        itemBuilder: (context, index) {
          final category = categories[index];

          return Padding(
            // Keyed on the row rather than the position, or Flutter animates the wrong card.
            key: ValueKey('draggable-${category.id}'),
            padding: EdgeInsets.only(bottom: 10.h),
            child: Row(
              children: [
                // An explicit handle rather than a long-press on the card: the card already
                // opens the edit sheet on tap, and a list where holding still does something
                // else is a list people learn to be careful in.
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(end: 6.w),
                    child: Icon(
                      AppIcons.reorder,
                      size: 22.sp,
                      color: context.colorScheme.outline,
                    ),
                  ),
                ),
                Expanded(child: cardFor(category)),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Where a newly added category lands in the catalogue: after everything already on the list.
///
/// Read off what is on screen rather than asked of the server, because it only has to be
/// *after* the rest — the order within a rank falls back to the name, so two categories added
/// on the same page are still sorted rather than arbitrary.
int _nextSortOrder(ProductCategoriesState state) => switch (state) {
  ProductCategoriesLoaded(:final page) when page.items.isNotEmpty =>
    page.items.map((category) => category.sortOrder).reduce((a, b) => a > b ? a : b) + 10,
  _ => 0,
};
