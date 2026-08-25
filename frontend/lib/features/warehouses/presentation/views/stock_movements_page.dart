import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/features/warehouses/models/stock_movement.dart';
import 'package:dayaa/features/warehouses/models/warehouse_stock.dart';
import 'package:dayaa/features/warehouses/presentation/viewmodel/stock_movements_cubit.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/movement_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The ledger — every movement, newest first.
///
/// **Read at three zoom levels through one screen**, because they are the same list asked a
/// narrower question each time: the whole workshop, one warehouse, or one shelf in one
/// warehouse. Three screens would be three copies of a list whose rows are identical.
///
/// The narrowest level is the one a storekeeper actually asks — «هذا الصنف، من أين جاء ومن
/// أخذه؟» — so when it is opened from a shelf it carries that shelf's balance above the rows
/// that produced it.
///
/// Read-only: a row is written by the recording sheet and never edited. A mistake is corrected
/// by another movement, which is itself a row here — and that is what keeps the ledger and the
/// balance one story rather than two.
class StockMovementsPage extends StatelessWidget {
  const StockMovementsPage({this.warehouseId, this.warehouseName, this.stock, super.key});

  /// One warehouse's movements — counting both ends of a transfer — or all of them.
  final int? warehouseId;

  /// Named in the bar when this was opened from a warehouse.
  final String? warehouseName;

  /// The shelf this was opened from: it narrows the feed to that one صنف مخزني and gives the
  /// header its balance. Null at the wider two levels.
  final WarehouseStock? stock;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StockMovementsCubit>(
      create: (_) =>
          sl<StockMovementsCubit>(param1: warehouseId, param2: stock?.stockItemId)..load(),
      child: _MovementsView(warehouseName: warehouseName, stock: stock),
    );
  }
}

class _MovementsView extends StatelessWidget {
  const _MovementsView({this.warehouseName, this.stock});

  final String? warehouseName;
  final WarehouseStock? stock;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<StockMovementsCubit>();
    final subtitle = [?stock?.title, ?warehouseName].join(' · ');

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('سجل الحركات'),
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (stock case final shelf?) _ShelfHeader(stock: shelf),
          Expanded(
            child: BlocBuilder<StockMovementsCubit, StockMovementsState>(
              builder: (context, state) => PagedListView<StockMovement>(
                state: state,
                emptyMessage: stock == null
                    ? 'لا توجد حركات مسجّلة بعد'
                    : 'لا توجد حركات على هذا المقاس بعد',
                onLoadMore: cubit.loadMore,
                onRefresh: cubit.refresh,
                // One row measured: three lines beside a glyph.
                skeletonHeight: 76.h,
                itemBuilder: (context, movement, index) => MovementRow(
                  key: ValueKey(movement.id),
                  movement: movement,
                  // The shelf is the whole feed here, so repeating it on every row would be a
                  // column of the same three words.
                  showTitle: stock == null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// What this shelf is and how much of it is here.
///
/// The balance sits directly above the ledger that explains it, which is the point of opening
/// a shelf's history: the rows below are what turned it into this number.
///
/// **It no longer leads anywhere, and that is the change rather than an omission.** It used to
/// open the product, because a shelf was one product's size. A shelf is now a pile that several
/// products draw on, so there is no single product to open — and offering either of «كيس شحن
/// سادة» and «كيس شحن مطبوع» here would answer a question nobody asked with a guess. A card that
/// only reads is a card without an `InkWell`, not a greyed-out one.
class _ShelfHeader extends StatelessWidget {
  const _ShelfHeader({required this.stock});

  final WarehouseStock stock;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 6.h),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16.r),
        ),
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // The code first and in the accent, exactly where the product's code used to
                // be: `S7` is what gets read down a phone line, and it names the pile without
                // claiming which of the products sharing it this row is about.
                if (stock.code case final code?) ...[
                  Text(
                    code,
                    textDirection: TextDirection.ltr,
                    style: context.textTheme.titleSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 8.w),
                ],
                Flexible(
                  child: Text(
                    stock.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              'الرصيد الحالي ${stock.quantityLabel}',
              style: context.textTheme.bodySmall?.copyWith(
                color: stock.isLowStock ? scheme.error : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
