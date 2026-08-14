import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_order.dart';
import 'package:dayaa/features/purchase_orders/usecases/purchase_order_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'purchase_order_detail_cubit.freezed.dart';
part 'purchase_order_detail_state.dart';

/// One purchase order, and everything that can be done to it.
///
/// **Every write ends in a re-read, and one of them has no choice.** Booking a shipment in
/// answers with the *arrival*, not with the order — so the new `quantity_received` and the new
/// status exist only on the server until this asks for them again. Doing the same after a status
/// change keeps one rule instead of two, and costs a request on an action nobody repeats.
class PurchaseOrderDetailCubit extends Cubit<PurchaseOrderDetailState> {
  PurchaseOrderDetailCubit({
    required int purchaseOrderId,
    required GetPurchaseOrder getOrder,
    required ChangePurchaseOrderStatus changeStatus,
    required ReceivePurchaseOrderArrival receiveArrival,
  }) : _id = purchaseOrderId,
       _getOrder = getOrder,
       _changeStatus = changeStatus,
       _receiveArrival = receiveArrival,
       super(const PurchaseOrderDetailState.loading());

  final int _id;
  final GetPurchaseOrder _getOrder;
  final ChangePurchaseOrderStatus _changeStatus;
  final ReceivePurchaseOrderArrival _receiveArrival;

  Future<void> load() async {
    // The order it already has is kept while the next read is in flight, so a pull-to-refresh
    // does not blank the screen the user is reading.
    emit(PurchaseOrderDetailState.loading(order: state.order));

    final result = await _getOrder(_id);

    if (isClosed) return;

    emit(
      result.fold(
        (failure) =>
            PurchaseOrderDetailState.failure(failure, order: state.order),
        (order) => PurchaseOrderDetailState.ready(order),
      ),
    );
  }

  /// Sends the order, or writes it off. Answers with the failure, or null on success.
  Future<Failure?> changeStatus(PurchaseOrderStatus status) =>
      _write(() => _changeStatus(_id, status: status));

  /// Books a shipment in. [quantities] is keyed by product variant; empty boxes are dropped by
  /// the use case, so a partial shipment is simply the boxes that were filled.
  Future<Failure?> receive({
    required Map<int, String> quantities,
    String? invoiceNumber,
    String? notes,
  }) {
    return _write(
      () => _receiveArrival(
        _id,
        quantities: quantities,
        invoiceNumber: invoiceNumber,
        notes: notes,
      ),
    );
  }

  /// Runs a write, then re-reads the order.
  ///
  /// The order on screen is left exactly as it was while the write is in flight — `isWorking`
  /// is what the buttons read — so a refusal returns the user to the screen they were looking
  /// at rather than to a spinner.
  Future<Failure?> _write(
    Future<Either<Failure, Object?>> Function() write,
  ) async {
    final order = state.order;
    if (order == null || state.isWorking) return null;

    emit(PurchaseOrderDetailState.working(order));

    final result = await write();

    if (isClosed) return null;

    final failure = result.fold<Failure?>((f) => f, (_) => null);

    if (failure != null) {
      emit(PurchaseOrderDetailState.ready(order));

      return failure;
    }

    await load();

    return null;
  }
}
