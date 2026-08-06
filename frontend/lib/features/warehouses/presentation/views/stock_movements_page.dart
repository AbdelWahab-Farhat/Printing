import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/router/app_router.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/widgets/paged_list_view.dart';
import 'package:printing/features/warehouses/models/stock_movement.dart';
import 'package:printing/features/warehouses/models/warehouse_stock.dart';
import 'package:printing/features/warehouses/presentation/viewmodel/stock_movements_cubit.dart';
import 'package:printing/features/warehouses/presentation/widgets/movement_row.dart';

/// The ledger — every movement, newest first.
///
/// **Read at three zoom levels through one screen**, because they are the same list asked a
/// narrower question each time: the whole workshop, one warehouse, or one size in one
/// warehouse. Three screens would be three copies of a list whose rows are identical.
///
/// The narrowest level is the one a storekeeper actually asks — «هذا المقاس، من أين جاء ومن
/// أخذه؟» — so when it is opened from a shelf it carries that shelf's balance above the rows
/// that produced it, and a way into the product itself.
///
/// Read-only: a row is written by the recording sheet and never edited. A mistake is corrected
/// by another movement, which is itself a row here — and that is what keeps the ledger and the
/// balance one story rather than two.
class StockMovementsPage extends StatelessWidget {
  const StockMovementsPage({
    this.warehouseId,
    this.warehouseName,
    this.stock,
    super.key,
  });

  /// One warehouse's movements — counting both ends of a transfer — or all of them.
  final int? warehouseId;

  /// Named in the bar when this was opened from a warehouse.
  final String? warehouseName;

  /// The shelf this was opened from: it narrows the feed to that one size and gives the header
  /// its balance. Null at the wider two levels.
  final WarehouseStock? stock;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StockMovementsCubit>(
      create: (_) =>
          sl<StockMovementsCubit>(param1: warehouseId, param2: stock?.productVariantId)..load(),
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
                  // The size is the whole feed here, so repeating it on every row would be a
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

/// What this size is, how much of it is here, and the way into the product.
///
/// The balance sits directly above the ledger that explains it, which is the point of opening
/// a shelf's history: the rows below are what turned it into this number.
class _ShelfHeader extends StatelessWidget {
  const _ShelfHeader({required this.stock});

  final WarehouseStock stock;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final variant = stock.variant;
    final radius = BorderRadius.circular(16.r);

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 6.h),
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: radius,
        child: InkWell(
          // Into the product itself: from a shelf, «بكم نبيع هذا المقاس؟» is one question away,
          // and this app already has the screen that answers it.
          onTap: variant == null
              ? null
              : () => context.push(Routes.product(variant.productId)),
          borderRadius: radius,
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          // The code first and in the accent, as it is on the catalogue card:
                          // it is what gets read down a phone line.
                          if (variant?.productCode case final code?) ...[
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
                              style: context.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
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
                if (variant != null)
                  Icon(AppIcons.forward, size: 18.sp, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
