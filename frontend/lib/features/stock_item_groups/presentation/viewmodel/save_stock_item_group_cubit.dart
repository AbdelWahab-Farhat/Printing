import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/stock_item_groups/models/stock_item_group.dart';
import 'package:dayaa/features/stock_item_groups/usecases/save_stock_item_group.dart';
import 'package:dayaa/features/stock_items/models/stock_unit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'save_stock_item_group_cubit.freezed.dart';
part 'save_stock_item_group_state.dart';

/// The ViewModel for the sheet that adds or edits a material.
///
/// **It does not ask about the rename.** Saving a new name renames every size under the material
/// in the same transaction, and that confirmation belongs to the sheet: a Cubit that opened a
/// dialog would need a `BuildContext`, which is the one thing a Cubit in this app may not have.
/// By the time [submit] is called the decision has been taken.
class SaveStockItemGroupCubit extends Cubit<SaveStockItemGroupState> {
  SaveStockItemGroupCubit({required SaveStockItemGroup saveGroup})
    : _saveGroup = saveGroup,
      super(const SaveStockItemGroupState.initial());

  final SaveStockItemGroup _saveGroup;

  Future<void> submit({
    int? groupId,
    required String name,
    required StockUnit defaultUnit,
    String? description,
    bool isActive = true,
  }) async {
    // Ignored rather than queued: a second tap while the first request is in flight would be a
    // second material — and two materials with one name is the collision the server's unique
    // index exists to prevent, reported as a validation error on a field nobody touched twice.
    if (state.isSubmitting) return;

    emit(const SaveStockItemGroupState.submitting());

    final result = await _saveGroup(
      groupId: groupId,
      name: name,
      defaultUnit: defaultUnit,
      description: description,
      isActive: isActive,
    );

    if (isClosed) return;

    emit(
      result.fold(
        (f) => SaveStockItemGroupState.failure(f),
        (g) => SaveStockItemGroupState.success(g),
      ),
    );
  }

  void clearFailure() {
    if (state is SaveStockItemGroupFailure) {
      emit(const SaveStockItemGroupState.initial());
    }
  }
}
