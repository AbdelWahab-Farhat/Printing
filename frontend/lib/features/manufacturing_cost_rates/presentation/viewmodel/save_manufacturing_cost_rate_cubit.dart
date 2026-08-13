import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/manufacturing_cost_rates/models/manufacturing_cost_rate.dart';
import 'package:printing/features/manufacturing_cost_rates/usecases/manufacturing_cost_rate_usecases.dart';

part 'save_manufacturing_cost_rate_state.dart';
part 'save_manufacturing_cost_rate_cubit.freezed.dart';

/// The ViewModel behind the rate form.
///
/// It holds no draft: the form owns its controllers, because those are widget-lifecycle resources
/// that must be disposed, and a Cubit is not a disposal mechanism.
class SaveManufacturingCostRateCubit extends Cubit<SaveManufacturingCostRateState> {
  SaveManufacturingCostRateCubit({required SaveManufacturingCostRate saveRate})
    : _saveRate = saveRate,
      super(const SaveManufacturingCostRateState.initial());

  final SaveManufacturingCostRate _saveRate;

  Future<void> submit({
    int? id,
    required RateScope scope,
    int? scopeId,
    required ManufacturingCostType costType,
    required String ratePerUnit,
    String? notes,
    bool isActive = true,
  }) async {
    // Ignored rather than queued: a second tap while the first is in flight is a second POST,
    // and the second one comes back as «يوجد بالفعل معدل…» against the row the first just wrote.
    if (state.isSubmitting) return;

    emit(const SaveManufacturingCostRateState.submitting());

    final result = await _saveRate(
      id: id,
      scope: scope,
      scopeId: scopeId,
      costType: costType,
      ratePerUnit: ratePerUnit,
      notes: notes,
      isActive: isActive,
    );

    // The screen may have been popped while the request was in flight.
    if (isClosed) return;

    emit(
      result.fold(
        SaveManufacturingCostRateState.failure,
        SaveManufacturingCostRateState.success,
      ),
    );
  }

  /// Clears a previous failure so the error under a field disappears as the user corrects it.
  void clearFailure() {
    if (state is SaveManufacturingCostRateFailure) {
      emit(const SaveManufacturingCostRateState.initial());
    }
  }
}
