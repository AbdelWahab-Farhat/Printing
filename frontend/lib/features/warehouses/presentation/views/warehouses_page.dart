import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_dialog.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/warehouses/models/warehouse.dart';
import 'package:dayaa/features/warehouses/presentation/viewmodel/warehouses_cubit.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/warehouse_card.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/warehouse_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// المخزن — the places stock sits, and the way into everything else in this context.
///
/// A body, not a screen: since it traded places with المنتجات this is the المخزون tab, and the
/// app bar belongs to the shell above — including the «سجل الحركات» door, which the shell hangs
/// off its bar because «ماذا حدث اليوم؟» is a question about the whole workshop rather than
/// about one room.
///
/// Reading needs `inventory.view` — the branch's redirect enforces it and the shell hides the
/// tab without it. Adding, editing and removing need `inventory.manage`; the screen hides what
/// that permission would allow rather than greying it out — the server refuses either way.
class WarehousesPage extends StatelessWidget {
  const WarehousesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WarehousesCubit>(
      create: (_) => sl<WarehousesCubit>()..load(),
      child: const _WarehousesView(),
    );
  }
}

class _WarehousesView extends StatelessWidget {
  const _WarehousesView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<WarehousesCubit>();
    final canManage = sl<Session>().can(AppPermission.manageInventory);

    return Scaffold(
      // Transparent: the shell above owns the real Scaffold, and this one exists only to hang
      // a floating button off. The same shape the customers tab uses.
      backgroundColor: Colors.transparent,
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              // Unique per screen, because the shell keeps every tab alive in an IndexedStack:
              // two default-tagged FABs in one subtree is the «multiple heroes» assertion.
              heroTag: 'fab-warehouses',
              onPressed: () async {
                final created = await showWarehouseSheet(context: context);

                // Re-read: this list is in the server's order rather than newest-first, so
                // where a new warehouse belongs is its answer. A dismissed sheet returns
                // nothing and the list does not move.
                if (created != null) await cubit.refresh();
              },
              icon: Icon(AppIcons.add),
              label: const Text('مخزن جديد'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
            child: SearchField(hint: 'ابحث عن مخزن', onChanged: cubit.search),
          ),
          Expanded(
            child: BlocBuilder<WarehousesCubit, WarehousesState>(
              builder: (context, state) => PagedListView<Warehouse>(
                state: state,
                emptyMessage: 'لا توجد مخازن بعد',
                onLoadMore: cubit.loadMore,
                onRefresh: cubit.refresh,
                // One row measured: a 38 tile with two lines beside it.
                skeletonHeight: 62.h,
                itemBuilder: (context, warehouse, index) => WarehouseCard(
                  key: ValueKey(warehouse.id),
                  warehouse: warehouse,
                  onTap: () async {
                    // **Only when something was written in there.** A movement changes the count
                    // on this row and the count is the server's arithmetic — this screen cannot
                    // patch it, so it re-reads. But walking in to look at the shelves and
                    // walking back out changes nothing, and used to cost a request and a jump
                    // to the top of the list all the same.
                    final changed = await context.push<bool>(
                      Routes.warehouseStocks(warehouse.id),
                      extra: warehouse,
                    );

                    if (changed ?? false) await cubit.refresh();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Editing and removing, offered from the shelves screen's own bar — see [WarehouseStocksPage].
/// Kept here so the confirm dialog and the refusal message live beside the list they change.
Future<bool> confirmWarehouseDelete(
  BuildContext context,
  WarehousesCubit cubit,
  Warehouse warehouse,
) async {
  final confirmed = await showDestructiveDialog(
    context: context,
    title: 'حذف «${warehouse.name}»؟',
    description: 'يختفي المخزن نهائياً. الحركات المسجّلة عليه تبقى في السجل كما هي.',
  );

  if (confirmed != true || !context.mounted) return false;

  final failure = await cubit.remove(warehouse);

  if (!context.mounted) return failure == null;

  if (failure != null) {
    // The server's own Arabic says which refusal it was — most often «ما زال يحتوي على مخزون».
    context.showFailure(failure);

    return false;
  }

  context.showSuccess('تم حذف ${warehouse.name}');

  return true;
}
