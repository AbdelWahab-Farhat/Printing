import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_order.dart';
import 'package:dayaa/features/purchase_orders/usecases/purchase_order_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'save_purchase_order_cubit.freezed.dart';
part 'save_purchase_order_state.dart';

/// The ViewModel behind the purchase-order form.
///
/// It holds no draft: the form owns its controllers and its line list, because those are
/// widget-lifecycle resources that must be disposed.
class SavePurchaseOrderCubit extends Cubit<SavePurchaseOrderState> {
  SavePurchaseOrderCubit({required SavePurchaseOrder saveOrder})
    : _saveOrder = saveOrder,
      super(const SavePurchaseOrderState.initial());

  final SavePurchaseOrder _saveOrder;

  Future<void> submit({
    int? id,
    required int vendorId,
    required int warehouseId,
    required String orderDate,
    required List<DraftLine> items,
    List<DraftAdditionalCost> additionalCosts = const [],
    String? expectedDate,
    String? notes,
  }) async {
    // Ignored rather than queued: a second tap while the first is in flight is a second POST,
    // and a purchase order has no natural key the server could dedupe on — it would be two
    // orders against the same supplier for the same goods.
    if (state.isSubmitting) return;

    emit(const SavePurchaseOrderState.submitting());

    final result = await _saveOrder(
      id: id,
      vendorId: vendorId,
      warehouseId: warehouseId,
      orderDate: orderDate,
      items: items,
      additionalCosts: additionalCosts,
      expectedDate: expectedDate,
      notes: notes,
    );

    if (isClosed) return;

    emit(
      result.fold(
        SavePurchaseOrderState.failure,
        SavePurchaseOrderState.success,
      ),
    );
  }

  void clearFailure() {
    if (state is SavePurchaseOrderFailure) {
      emit(const SavePurchaseOrderState.initial());
    }
  }
}
