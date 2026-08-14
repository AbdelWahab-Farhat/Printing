part of 'vendor_purchase_order_counts_cubit.dart';

/// The four numbers, or the reason there are none.
///
/// **No `changing` and no cached copy through a reload.** Nothing on this screen writes to
/// these; they are read when the supplier opens and read again when the page is pulled down, and
/// a stale number kept beside a fresh request would be the one thing here capable of being wrong.
@freezed
sealed class VendorPurchaseOrderCountsState
    with _$VendorPurchaseOrderCountsState {
  const factory VendorPurchaseOrderCountsState.loading() =
      VendorPurchaseOrderCountsLoading;

  const factory VendorPurchaseOrderCountsState.loaded(
    PurchaseOrderCounts counts,
  ) = VendorPurchaseOrderCountsLoaded;

  /// The counts could not be read. **Not a zero** — «٠ أوامر شراء» about a supplier nobody
  /// counted is a claim this screen has no business making, and the ways in still open.
  const factory VendorPurchaseOrderCountsState.failure(Failure failure) =
      VendorPurchaseOrderCountsFailure;
}

extension VendorPurchaseOrderCountsLoadedX on VendorPurchaseOrderCountsLoaded {
  /// «كل أوامر الشراء» — the server's own sum, cancellations and all.
  int get total => counts.total;

  /// «الجارية» — drafted or on its way, nothing on the shelf yet.
  int get inProgress => counts.forStatuses(PurchaseOrderStatus.inProgress);

  /// «المكتملة» — every line received in full.
  int get fulfilled => counts.forStatuses(PurchaseOrderStatus.fulfilled);

  /// «الملغاة» — called off.
  int get cancelled => counts.forStatuses(PurchaseOrderStatus.cancellations);
}
