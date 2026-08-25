import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_dialog.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/stock_item_groups/models/stock_item_group.dart';
import 'package:dayaa/features/stock_item_groups/presentation/viewmodel/stock_item_groups_cubit.dart';
import 'package:dayaa/features/stock_item_groups/presentation/widgets/stock_item_group_card.dart';
import 'package:dayaa/features/stock_item_groups/presentation/widgets/stock_item_group_items_sheet.dart';
import 'package:dayaa/features/stock_item_groups/presentation/widgets/stock_item_group_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// مجموعات الأصناف — the materials the workshop buys, and nothing that holds any of them.
///
/// **The line above the list is doing real work.** «مجموعة» looks like a folder and is not one:
/// it is the material itself, «كيس شحن», and the sizes under it are the piles. Somebody who
/// reads it as a folder types a size into the name box, and the shop ends up with a material
/// called «كيس شحن 25*35» whose own sizes are «كيس شحن 25*35 25*35». That mistake is cheap to
/// prevent here and expensive to undo — renaming the material rewrites every shelf beneath it.
///
/// **Nothing on this screen adds a size.** A size is created by the server, at the moment a
/// product names this material and has a size the material has not been cut to yet. There is no
/// button for it because there is no request for it, and inventing one would be inventing a
/// second way for a shelf to come into existence.
///
/// Reading needs `inventory.view`; adding, editing and removing need `inventory.manage`. The
/// screen leaves out what the second permission would allow rather than greying it — the server
/// refuses either way, and a control that fails is worse than one that is not there.
class StockItemGroupsPage extends StatelessWidget {
  const StockItemGroupsPage({super.key, this.isEmbedded = false});

  /// Whether this is a segment of the المخزون tab rather than a screen of its own.
  ///
  /// **The same list either way — only the chrome differs.** Embedded, the shell above already
  /// carries the bar and the title, so a second `AppBar` would stack two headers on one screen;
  /// and the background must come from the shell or the tab reads as a card floating on itself.
  /// Standalone is what a deep link, a picker's «إدارة التصنيفات» and the back-stack still reach,
  /// so both shapes stay real rather than one being a leftover.
  final bool isEmbedded;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StockItemGroupsCubit>(
      create: (_) => sl<StockItemGroupsCubit>()..load(),
      child: _StockItemGroupsView(isEmbedded: isEmbedded),
    );
  }
}

class _StockItemGroupsView extends StatelessWidget {
  const _StockItemGroupsView({required this.isEmbedded});

  final bool isEmbedded;

  /// Opens the sheet, and refreshes only when the server actually stored something.
  ///
  /// A refresh after a dismissed sheet is a request nobody asked for, and it flickers the list
  /// under the user's thumb.
  /// Opens what a category holds, and re-reads the list only if a material was created in there.
  ///
  /// The count on the row is the thing that goes stale — «4 مواد» stays 4 while a fifth is being
  /// filed two taps away — and it is the only thing, so the refresh is worth exactly one request
  /// and only when there was a creation.
  Future<void> _openMaterials(BuildContext context, StockItemGroup group) async {
    final cubit = context.read<StockItemGroupsCubit>();

    final created = await showStockItemGroupItemsSheet(context: context, group: group);

    if (created) await cubit.refresh();
  }

  Future<void> _edit(BuildContext context, StockItemGroup? group) async {
    final cubit = context.read<StockItemGroupsCubit>();

    final saved = await showStockItemGroupSheet(
      context: context,
      group: group,
      // Handed in only for an existing material: the sheet shows the bin, and the list is what
      // owns removing a row and saying why it could not.
      onDelete: group == null
          ? null
          : () => confirmStockItemGroupDelete(context, cubit, group),
    );

    if (saved != null) await cubit.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<StockItemGroupsCubit>();
    final mayManage = sl<Session>().can(AppPermission.manageInventory);

    return Scaffold(
      // Transparent and bar-less when the shell above owns both — see [StockItemGroupsPage.isEmbedded].
      backgroundColor: isEmbedded ? Colors.transparent : null,
      appBar: isEmbedded ? null : AppBar(title: const Text('التصنيفات')),
      // A ternary rather than a PermissionGate: an empty widget in this slot still shifts the
      // bottom inset, so the button has to be absent rather than invisible.
      floatingActionButton: mayManage
          ? FloatingActionButton.extended(
              // Unique per screen, because the shell keeps every tab alive in an IndexedStack:
              // two default-tagged FABs in one subtree is the «multiple heroes» assertion.
              heroTag: 'fab-stock-item-groups',
              onPressed: () => _edit(context, null),
              icon: Icon(AppIcons.add),
              label: const Text('تصنيف جديد'),
            )
          : null,
      body: Column(
        children: [
          // **No explaining sentence here** — see the note in [StockItemsPage].
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
            // «عن مادة», not «عن مجموعة»: the endpoint matches the name only — not the code —
            // so the box invites the one thing it can find.
            child: SearchField(hint: 'ابحث عن تصنيف', onChanged: cubit.search),
          ),
          Expanded(
            child: BlocBuilder<StockItemGroupsCubit, StockItemGroupsState>(
              builder: (context, state) => PagedListView<StockItemGroup>(
                state: state,
                emptyMessage: 'لم يُضف أي تصنيف بعد',
                onLoadMore: cubit.loadMore,
                onRefresh: cubit.refresh,
                // One row measured: a 38 tile with two lines beside it.
                skeletonHeight: 62.h,
                itemBuilder: (context, group, index) => StockItemGroupCard(
                  key: ValueKey(group.id),
                  group: group,
                  // Everybody who can read the table can read what is under a material; the
                  // sizes are the whole content of one.
                  onTap: () => _openMaterials(context, group),
                  onEdit: mayManage ? () => _edit(context, group) : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Removing a material — and, far more often, saying why the server would not.
///
/// Kept beside the list it changes rather than inside the sheet that offers it, exactly as the
/// warehouses screen does: the sheet has nothing left to show once the row is gone, and the
/// refusal has to be readable from the list either way.
///
/// The confirm dialog states what survives, because that is the question somebody hesitating
/// actually has: the sizes are what hold stock, and none of them is touched here — the delete is
/// simply refused while any of them exists. Answering with the server's own Arabic afterwards is
/// what keeps the counts in the refusal true, soft-deleted rows included.
Future<bool> confirmStockItemGroupDelete(
  BuildContext context,
  StockItemGroupsCubit cubit,
  StockItemGroup group,
) async {
  final confirmed = await showDestructiveDialog(
    context: context,
    title: 'حذف «${group.name}»؟',
    description:
        'يختفي التصنيف نهائياً. لا يمكن حذفه ما دامت ترتبط به مادة واحدة أو منتج واحد — '
        'غيّر ارتباطها أولاً. إن كان المقصود التوقف عن شرائها فالإيقاف أفضل.',
  );

  if (confirmed != true || !context.mounted) return false;

  final failure = await cubit.remove(group);

  if (!context.mounted) return failure == null;

  if (failure != null) {
    // The server's own accounting — «لأن 4 صنفاً مخزنياً و 2 منتجاً مرتبط بها» — counted over
    // rows this app cannot see, soft-deleted ones included. Never rebuilt here.
    context.showFailure(failure);

    return false;
  }

  context.showSuccess('تم حذف ${group.name}');

  return true;
}
