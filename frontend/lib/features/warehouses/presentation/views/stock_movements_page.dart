import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/widgets/paged_list_view.dart';
import 'package:printing/features/warehouses/models/stock_movement.dart';
import 'package:printing/features/warehouses/presentation/viewmodel/stock_movements_cubit.dart';
import 'package:printing/features/warehouses/presentation/widgets/movement_row.dart';

/// The ledger — every movement, newest first.
///
/// Read-only, and that is the point: a row is written by the recording sheet and never edited,
/// so what this screen shows always adds up to the balances beside it. A mistake is corrected
/// by another movement, which is itself a row here.
class StockMovementsPage extends StatelessWidget {
  const StockMovementsPage({this.warehouseId, this.warehouseName, super.key});

  /// One warehouse's movements — counting both ends of a transfer — or all of them.
  final int? warehouseId;

  /// Named in the bar when this was opened from a warehouse.
  final String? warehouseName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StockMovementsCubit>(
      create: (_) => sl<StockMovementsCubit>(param1: warehouseId)..load(),
      child: _MovementsView(warehouseName: warehouseName),
    );
  }
}

class _MovementsView extends StatelessWidget {
  const _MovementsView({this.warehouseName});

  final String? warehouseName;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<StockMovementsCubit>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('سجل الحركات'),
            if (warehouseName != null)
              Text(
                warehouseName!,
                style: Theme.of(context).textTheme.labelSmall,
              ),
          ],
        ),
      ),
      body: BlocBuilder<StockMovementsCubit, StockMovementsState>(
        builder: (context, state) => PagedListView<StockMovement>(
          state: state,
          emptyMessage: 'لا توجد حركات مسجّلة بعد',
          onLoadMore: cubit.loadMore,
          onRefresh: cubit.refresh,
          // One row measured: three lines beside a glyph.
          skeletonHeight: 76.h,
          itemBuilder: (context, movement, index) => MovementRow(
            key: ValueKey(movement.id),
            movement: movement,
          ),
        ),
      ),
    );
  }
}
