import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/warehouses/models/stock_movement.dart';
import 'package:dayaa/features/warehouses/usecases/record_stock_movement.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'record_movement_cubit.freezed.dart';
part 'record_movement_state.dart';

/// The ViewModel for the sheet that writes a line into the ledger.
///
/// **No retry is offered on a network failure**, unlike every other form in this app: a
/// movement carries no unique key, so a request that reached the server before the connection
/// dropped and is sent again moves the stock twice. The sheet says what happened and asks the
/// storekeeper to check the ledger — a wrong balance is far more expensive than a second tap.
class RecordMovementCubit extends Cubit<RecordMovementState> {
  RecordMovementCubit({required RecordStockMovement recordMovement})
    : _recordMovement = recordMovement,
      super(const RecordMovementState.initial());

  final RecordStockMovement _recordMovement;

  Future<void> submit({
    required MovementKind kind,
    required int stockItemId,
    required int warehouseId,
    int? fromWarehouseId,
    required String quantity,
    String? unitCost,
    ShortfallReason? shortfallReason,
    String? notes,
  }) async {
    if (state.isSubmitting) return;

    emit(const RecordMovementState.submitting());

    final result = await _recordMovement(
      kind: kind,
      stockItemId: stockItemId,
      warehouseId: warehouseId,
      fromWarehouseId: fromWarehouseId,
      quantity: quantity,
      // Passed through as typed. Whether this kind may carry a cost at all is the use case's
      // rule, and repeating it here would be a second place to get it wrong.
      unitCost: unitCost,
      // Whether this kind may carry one at all is the use case's rule, like the cost above.
      shortfallReason: shortfallReason,
      notes: notes,
    );

    if (isClosed) return;

    emit(result.fold((f) => RecordMovementState.failure(f), (m) => RecordMovementState.success(m)));
  }

  void clearFailure() {
    if (state is RecordMovementFailure) emit(const RecordMovementState.initial());
  }
}
