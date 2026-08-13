import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/permissions/app_permission.dart';
import 'package:printing/core/session/session.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/widgets/app_dialog.dart';
import 'package:printing/core/widgets/paged_list_view.dart';
import 'package:printing/core/widgets/search_field.dart';
import 'package:printing/features/products/models/product_category.dart';
import 'package:printing/features/products/presentation/viewmodel/product_categories_cubit.dart';
import 'package:printing/features/products/presentation/widgets/product_category_card.dart';
import 'package:printing/features/products/presentation/widgets/product_category_sheet.dart';

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

class _ProductCategoriesView extends StatelessWidget {
  const _ProductCategoriesView();

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
              builder: (context, state) => PagedListView<ProductCategory>(
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
              ),
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
