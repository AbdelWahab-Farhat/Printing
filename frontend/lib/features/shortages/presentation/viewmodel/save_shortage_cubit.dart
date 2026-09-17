import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/shortages/models/shortage.dart';
import 'package:dayaa/features/shortages/usecases/shortage_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'save_shortage_cubit.freezed.dart';
part 'save_shortage_state.dart';

/// The ViewModel behind the نواقص form — writing one down by hand, and correcting one.
///
/// It holds no draft: the form owns its controllers, because those are widget-lifecycle
/// resources that have to be disposed.
///
/// **A shortage born of an order never reaches here.** Its quantity belongs to the order screen,
/// the server refuses the edit — «نقصٌ مصدره طلبية — تُعدَّل كميته من شاشة الطلبية لا من هنا» —
/// and `Shortage.isEditable` says so in advance so the form is never opened on one.
class SaveShortageCubit extends Cubit<SaveShortageState> {
  SaveShortageCubit({required CreateShortage createShortage, required UpdateShortage updateShortage})
    : _create = createShortage,
      _update = updateShortage,
      super(const SaveShortageState.initial());

  final CreateShortage _create;
  final UpdateShortage _update;

  Future<void> submit({
    int? id,
    required String name,
    required String quantity,
    int? productId,
    int? productVariantId,
    String? unit,
    String? type,
    int? assignedToUserId,
    String? description,
  }) async {
    // Ignored rather than queued: a second tap while the first is in flight is a second POST, and
    // a shortage has no natural key the server could dedupe on — it would be the same sack
    // written down twice.
    if (state.isSubmitting) return;

    emit(const SaveShortageState.submitting());

    final result = id == null
        ? await _create(
            name: name,
            quantity: quantity,
            productId: productId,
            productVariantId: productVariantId,
            unit: unit,
            type: type,
            assignedToUserId: assignedToUserId,
            description: description,
          )
        : await _update(
            id,
            name: name,
            quantity: quantity,
            // Sent on the correction too: the endpoint rewrites the row from the payload, so a
            // product left out of it is a product taken off the shortage.
            productId: productId,
            productVariantId: productVariantId,
            unit: unit,
            type: type,
            assignedToUserId: assignedToUserId,
            description: description,
          );

    if (isClosed) return;

    emit(result.fold(SaveShortageState.failure, SaveShortageState.success));
  }
}
