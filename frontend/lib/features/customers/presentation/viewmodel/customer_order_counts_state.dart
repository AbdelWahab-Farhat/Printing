part of 'customer_order_counts_cubit.dart';

/// The three numbers, or the reason there are none.
///
/// **No `changing` and no cached copy through a reload.** Nothing on this screen writes to
/// these; they are read once when the customer opens and read again when the page is pulled
/// down, and a stale number kept beside a fresh request would be the one thing here capable of
/// being wrong.
@freezed
sealed class CustomerOrderCountsState with _$CustomerOrderCountsState {
  const factory CustomerOrderCountsState.loading() = CustomerOrderCountsLoading;

  const factory CustomerOrderCountsState.loaded(OrderCounts counts) = CustomerOrderCountsLoaded;

  /// The counts could not be read. **Not a zero** — «٠ طلبيات» about a customer nobody counted
  /// is a claim this screen has no business making, and the three ways in still open.
  const factory CustomerOrderCountsState.failure(Failure failure) = CustomerOrderCountsFailure;
}

extension CustomerOrderCountsLoadedX on CustomerOrderCountsLoaded {
  /// «كل طلبات العميل» — the server's own sum, cancellations and all.
  ///
  /// Read from `total` rather than added up from [OrderCounts.byStatus], so a status the server
  /// added after this build shipped is still inside the number. Adding it up here would quietly
  /// undercount, and an undercount that never says so is worse than a blank.
  int get total => counts.total;

  /// «الطلبات الجارية» — everything nobody has finished with.
  int get inProgress => counts.forStatuses(OrderStatus.inProgress);

  /// «الطلبات المستلمة» — what reached the customer, settled or not.
  int get received => counts.forStatuses(OrderStatus.received);
}
