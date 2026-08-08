import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/warehouses/models/warehouse.dart';
import 'package:printing/features/warehouses/usecases/save_warehouse.dart';

part 'save_warehouse_state.dart';
part 'save_warehouse_cubit.freezed.dart';

/// The ViewModel for the sheet that adds or edits a warehouse.
class SaveWarehouseCubit extends Cubit<SaveWarehouseState> {
  SaveWarehouseCubit({required SaveWarehouse saveWarehouse})
    : _saveWarehouse = saveWarehouse,
      super(const SaveWarehouseState.initial());

  final SaveWarehouse _saveWarehouse;

  Future<void> submit({
    int? warehouseId,
    required String name,
    required WarehouseType type,
    String? location,
  }) async {
    // Ignored rather than queued: a second tap while the first request is in flight would be a
    // second warehouse.
    if (state.isSubmitting) return;

    emit(const SaveWarehouseState.submitting());

    final result = await _saveWarehouse(
      warehouseId: warehouseId,
      name: name,
      type: type,
      location: location,
    );

    if (isClosed) return;

    emit(result.fold((f) => SaveWarehouseState.failure(f), (w) => SaveWarehouseState.success(w)));
  }

  void clearFailure() {
    if (state is SaveWarehouseFailure) emit(const SaveWarehouseState.initial());
  }
}
