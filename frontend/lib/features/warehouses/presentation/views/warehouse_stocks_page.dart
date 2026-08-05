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
import 'package:printing/features/warehouses/models/warehouse.dart';
import 'package:printing/features/warehouses/models/warehouse_stock.dart';
import 'package:printing/features/warehouses/presentation/viewmodel/warehouse_stocks_cubit.dart';
import 'package:printing/features/warehouses/presentation/widgets/record_movement_sheet.dart';
import 'package:printing/features/warehouses/presentation/widgets/stock_row.dart';
import 'package:printing/features/warehouses/presentation/widgets/threshold_sheet.dart';

/// What is on one warehouse's shelves.
///
/// **Nothing here writes a quantity**, and that is the context's whole rule: a balance moves
/// because a movement explains it, in the same transaction. So the button records a *movement*
/// and the list re-reads — the only field this screen edits is the level at which a shelf
/// starts asking to be refilled.
class WarehouseStocksPage extends StatelessWidget {
  const WarehouseStocksPage({required this.warehouseId, this.warehouse, super.key});

  final int warehouseId;

  /// Passed from the list so the bar can name the place without a second request; null on a
  /// cold deep link, where the heading stands alone.
  final Warehouse? warehouse;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WarehouseStocksCubit>(
      create: (_) => sl<WarehouseStocksCubit>(param1: warehouseId)..load(),
      child: _StocksView(warehouseId: warehouseId, warehouse: warehouse),
    );
  }
}

class _StocksView extends StatelessWidget {
  const _StocksView({required this.warehouseId, this.warehouse});

  final int warehouseId;
  final Warehouse? warehouse;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<WarehouseStocksCubit>();
    final canManage = sl<Session>().can(AppPermission.manageInventory);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('الأرصدة'),
            if (warehouse != null)
              Text(
                warehouse!.name,
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'سجل حركات هذا المخزن',
            onPressed: () => context.push(Routes.warehouseMovements(warehouseId)),
            icon: Icon(AppIcons.history),
          ),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              heroTag: 'fab-warehouse-stocks',
              onPressed: () async {
                final movement = await showRecordMovementSheet(
                  context: context,
                  warehouse: warehouse,
                );

                // Re-read rather than patch: the new balance is the server's answer, and this
                // screen has no business computing one.
                if (movement != null) await cubit.refresh();
              },
              icon: Icon(AppIcons.statusChange),
              label: const Text('تسجيل حركة'),
            )
          : null,
      body: Column(
        children: [
          BlocBuilder<WarehouseStocksCubit, WarehouseStocksState>(
            builder: (context, state) => _LowStockFilter(
              selected: cubit.lowStockOnly,
              onSelected: cubit.filterByLowStock,
            ),
          ),
          Expanded(
            child: BlocBuilder<WarehouseStocksCubit, WarehouseStocksState>(
              builder: (context, state) => PagedListView<WarehouseStock>(
                state: state,
                emptyMessage: cubit.lowStockOnly == true
                    ? 'لا توجد أصناف تحت حد التنبيه'
                    : 'لا توجد أرصدة في هذا المخزن بعد',
                onLoadMore: cubit.loadMore,
                onRefresh: cubit.refresh,
                skeletonHeight: 62.h,
                itemBuilder: (context, stock, index) => StockRow(
                  key: ValueKey(stock.id),
                  stock: stock,
                  onTap: canManage ? () => _editThreshold(context, cubit, stock) : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editThreshold(
    BuildContext context,
    WarehouseStocksCubit cubit,
    WarehouseStock stock,
  ) async {
    final threshold = await showThresholdSheet(context: context, stock: stock);

    // Null is a dismissed sheet; an empty string is «لا تنبهني», which is a decision.
    if (threshold == null || !context.mounted) return;

    final failure = await cubit.setThreshold(stock, threshold);

    if (!context.mounted) return;

    if (failure != null) {
      context.showFailure(failure);

      return;
    }

    context.showSuccess(threshold.isEmpty ? 'تم إلغاء التنبيه' : 'تم تحديث حد التنبيه');
  }
}

/// «الكل» or «تحت الحد» — the question this screen is opened for on a busy morning.
class _LowStockFilter extends StatelessWidget {
  const _LowStockFilter({required this.selected, required this.onSelected});

  final bool? selected;
  final ValueChanged<bool?> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 10.h),
      child: Row(
        children: [
          for (final (label, value) in const [('الكل', null), ('تحت الحد', true)]) ...[
            ChoiceChip(
              label: Text(label),
              selected: selected == value,
              showCheckmark: false,
              onSelected: (_) => onSelected(value),
              backgroundColor: scheme.surfaceContainerLowest,
              selectedColor: value == true ? scheme.errorContainer : scheme.primaryContainer,
              labelStyle: context.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: selected != value
                    ? scheme.onSurfaceVariant
                    : value == true
                    ? scheme.onErrorContainer
                    : scheme.onPrimaryContainer,
              ),
              side: BorderSide(
                color: selected == value ? Colors.transparent : scheme.outlineVariant,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            SizedBox(width: 8.w),
          ],
        ],
      ),
    );
  }
}
