import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_dialog.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/stock_items/models/stock_item.dart';
import 'package:dayaa/features/stock_items/presentation/viewmodel/stock_items_cubit.dart';
import 'package:dayaa/features/stock_items/presentation/views/stock_item_form_page.dart';
import 'package:dayaa/features/stock_items/presentation/widgets/stock_item_card.dart';
import 'package:dayaa/features/stock_items/presentation/widgets/stock_item_filter_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «مقاسات المواد» — the shelves themselves, and the screen that curates them.
///
/// **A stock item is a material at a size, and it is what a warehouse actually holds.** That is
/// the sentence the line above the list exists to say: «كيس شحن سادة 25*35» and «كيس شحن مطبوع
/// 25*35» are two rows in the catalogue and one pile of bags here, so an order for 300 of one and
/// 400 of the other is measured against a single balance. Somebody who does not know that reads
/// this list as a duplicate of المنتجات and starts "cleaning it up".
///
/// **Reading and writing are gated separately.** A reader gets the list with no bin, no button
/// and no form; the server refuses either way, and this only keeps a control that would fail off
/// the screen in the first place.
class StockItemsPage extends StatelessWidget {
  const StockItemsPage({super.key, this.isEmbedded = false});

  /// Whether this is a segment of the المخزون tab rather than a screen of its own.
  ///
  /// **The same list either way — only the chrome differs.** Embedded, the shell above already
  /// carries the bar and the title, so a second `AppBar` would stack two headers on one screen;
  /// and the background must come from the shell or the tab reads as a card floating on itself.
  /// Standalone is what a deep link, a picker's «إدارة المقاسات» and the back-stack still reach,
  /// so both shapes stay real rather than one being a leftover.
  final bool isEmbedded;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StockItemsCubit>(
      create: (_) => sl<StockItemsCubit>()..load(),
      child: _StockItemsView(isEmbedded: isEmbedded),
    );
  }
}

class _StockItemsView extends StatelessWidget {
  const _StockItemsView({required this.isEmbedded});

  final bool isEmbedded;

  Future<void> _open(BuildContext context, StockItem? item) async {
    final cubit = context.read<StockItemsCubit>();

    final saved = await openStockItemForm(context, item: item);

    // Only when something actually changed: a refresh after a dismissed form is a request
    // nobody asked for, and it flickers the list under the user's thumb.
    if (saved ?? false) await cubit.refresh();
  }

  Future<void> _confirmDelete(BuildContext context, StockItem item) async {
    final cubit = context.read<StockItemsCubit>();

    // **Answered without a request when the answer is already on the row.** The server refuses
    // while any product size draws on the shelf, and `variants_count` says so — asking anyway
    // would spend a round trip to be told what the list is already showing.
    if (item.isDrawnFrom) {
      context.showInfo(
        'لا يمكن حذف «${item.displayName}»',
        details: '${item.sharedByLabel}. اربطها بمقاس مادة آخر أولاً.',
      );

      return;
    }

    final confirmed = await showDestructiveDialog(
      context: context,
      title: 'حذف «${item.displayName}»؟',
      // The two facts somebody needs before deleting rather than stopping: what survives, and
      // the one refusal the row could not rule out on its own.
      description:
          'يختفي المقاس من القوائم، وتبقى حركاته المسجّلة وسجل تعديلاته كما هي. '
          'يُرفض الحذف إن كان أي مخزن ما زال يحتوي كمية منه — سوِّ الجرد أو انقل الكمية أولاً. '
          'إن كان المقصود التوقف عن عرضه فالإيقاف أفضل.',
    );

    if (confirmed != true || !context.mounted) return;

    final failure = await cubit.remove(item);

    if (!context.mounted) return;

    if (failure != null) {
      // The server's own Arabic says which refusal it was — most often «هناك كمية منه في
      // المخازن».
      context.showFailure(failure);

      return;
    }

    context.showSuccess('تم حذف ${item.displayName}');
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<StockItemsCubit>();
    final mayManage = sl<Session>().can(AppPermission.manageInventory);

    return Scaffold(
      // Transparent and bar-less when the shell above owns both — see [StockItemsPage.isEmbedded].
      backgroundColor: isEmbedded ? Colors.transparent : null,
      appBar: isEmbedded ? null : AppBar(title: const Text('مقاسات المواد')),
      // A ternary rather than a PermissionGate: an empty widget in this slot still shifts the
      // bottom inset, so the button has to be absent rather than invisible.
      floatingActionButton: mayManage
          ? FloatingActionButton.extended(
              // Unique per screen, because the shell keeps every tab alive in an IndexedStack:
              // two default-tagged FABs in one subtree is the «multiple heroes» assertion.
              heroTag: 'fab-stock-items',
              onPressed: () => _open(context, null),
              icon: Icon(AppIcons.add),
              label: const Text('مقاس جديد'),
            )
          : null,
      body: Column(
        children: [
          // **Narrowing and searching sit on one row, because they are one act.** The filter
          // had a line of its own above the box, which spent a whole row on a single icon and
          // put the two halves of «أرِني هذه فقط» at opposite ends of the screen. Beside the
          // box it reads as what it is: the other way to cut the same list down.
          //
          // **No explaining sentence here either.** One used to occupy that row saying what a
          // صنف is; the screen is reached from a tab that already names it, and a paragraph met
          // on every visit is read once and scrolled past forever after.
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
            child: Row(
              children: [
                Expanded(
                  child: SearchField(
                    // Named after what the server actually matches: `search` is an ILIKE on the
                    // material's name — not the code, and not the composed display name.
                    hint: 'ابحث باسم المقاس',
                    onChanged: cubit.search,
                  ),
                ),
                SizedBox(width: 8.w),
                // Rebuilt with the list, so the button's «filtered» fill and the rows it
                // produced can never disagree.
                BlocBuilder<StockItemsCubit, StockItemsState>(
                  builder: (context, state) => StockItemFilterButton(
                    isActive: cubit.isActive,
                    widthCm: cubit.widthCm,
                    heightCm: cubit.heightCm,
                    onApplied: (choice) => cubit.filterBy(
                      isActive: choice.isActive,
                      widthCm: choice.widthCm,
                      heightCm: choice.heightCm,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<StockItemsCubit, StockItemsState>(
              builder: (context, state) => PagedListView<StockItem>(
                state: state,
                // Named for the filter, because «لا توجد أصناف» in front of somebody who
                // narrowed the list to 25*35 reads as «the shelves are empty».
                emptyMessage: cubit.isFiltered
                    ? 'لا توجد مقاسات بهذه التصفية'
                    : 'لم يُضف أي مقاس بعد',
                onLoadMore: cubit.loadMore,
                onRefresh: cubit.refresh,
                // One row measured: a 38 code tile with two lines beside it.
                skeletonHeight: 62.h,
                itemBuilder: (context, item, index) => StockItemCard(
                  key: ValueKey(item.id),
                  item: item,
                  onTap: mayManage ? () => _open(context, item) : null,
                  onDelete: mayManage ? () => _confirmDelete(context, item) : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
