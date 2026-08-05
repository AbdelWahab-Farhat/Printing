import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/warehouses/models/stock_movement.dart';
import 'package:printing/features/warehouses/usecases/record_stock_movement.dart';

part 'record_movement_state.dart';
part 'record_movement_cubit.freezed.dart';

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
    required int productVariantId,
    required int warehouseId,
    int? fromWarehouseId,
    required String quantity,
    String? notes,
  }) async {
    if (state.isSubmitting) return;

    emit(const RecordMovementState.submitting());

    final result = await _recordMovement(
      kind: kind,
      productVariantId: productVariantId,
      warehouseId: warehouseId,
      fromWarehouseId: fromWarehouseId,
      quantity: quantity,
      notes: notes,
    );

    if (isClosed) return;

    emit(result.fold(RecordMovementState.failure, RecordMovementState.success));
  }

  void clearFailure() {
    if (state is RecordMovementFailure) emit(const RecordMovementState.initial());
  }
}
