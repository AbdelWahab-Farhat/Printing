part of 'purchase_order_detail_cubit.dart';

/// Everything the purchase-order screen can be.
///
/// **Each case carries the order it already has**, which is what lets a refusal put the user
/// back on the screen they were reading rather than on a spinner or an error page. Only the
/// very first load has nothing to show.
@freezed
sealed class PurchaseOrderDetailState with _$PurchaseOrderDetailState {
  const factory PurchaseOrderDetailState.loading({PurchaseOrder? order}) =
      PurchaseOrderDetailLoading;

  const factory PurchaseOrderDetailState.ready(PurchaseOrder order) =
      PurchaseOrderDetailReady;

  /// A write is in flight — sending, cancelling, or booking a shipment in. The order stays on
  /// screen and the buttons lock.
  const factory PurchaseOrderDetailState.working(PurchaseOrder order) =
      PurchaseOrderDetailWorking;

  const factory PurchaseOrderDetailState.failure(
    Failure failure, {
    PurchaseOrder? order,
  }) = PurchaseOrderDetailFailure;
}

extension PurchaseOrderDetailStateX on PurchaseOrderDetailState {
  /// What is on screen, whatever else is happening. Null only before the first read lands.
  PurchaseOrder? get order => switch (this) {
    PurchaseOrderDetailLoading(:final order) => order,
    PurchaseOrderDetailReady(:final order) => order,
    PurchaseOrderDetailWorking(:final order) => order,
    PurchaseOrderDetailFailure(:final order) => order,
  };

  bool get isWorking => this is PurchaseOrderDetailWorking;
}
