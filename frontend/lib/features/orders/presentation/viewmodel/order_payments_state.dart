part of 'order_payments_cubit.dart';

/// One order's money, as a closed set of shapes.
///
/// [OrderPaymentsLoaded] carries `isWorking` rather than there being a separate busy case: while
/// an entry is being written the ledger is still on screen and still readable, and a state that
/// replaced it with a spinner would throw away exactly the numbers somebody is checking against.
///
/// [OrderPaymentsFailure] keeps the ledger for the same reason — a refused write must leave the
/// screen showing what it was showing, with the server's sentence over the top.
@freezed
sealed class OrderPaymentsState with _$OrderPaymentsState {
  const factory OrderPaymentsState.loading() = OrderPaymentsLoading;

  const factory OrderPaymentsState.loaded({
    required OrderLedger ledger,
    @Default(false) bool isWorking,
  }) = OrderPaymentsLoaded;

  const factory OrderPaymentsState.failure({required Failure failure, OrderLedger? ledger}) =
      OrderPaymentsFailure;

  const OrderPaymentsState._();

  /// The ledger behind whatever is on screen, when there is one.
  OrderLedger? get ledger => switch (this) {
    OrderPaymentsLoaded(:final ledger) => ledger,
    OrderPaymentsFailure(:final ledger) => ledger,
    OrderPaymentsLoading() => null,
  };

  /// The order's money as the server last stated it.
  PaymentSummary? get summary => ledger?.summary;

  List<OrderPayment> get payments => ledger?.payments ?? const <OrderPayment>[];

  bool get isWorking => switch (this) {
    OrderPaymentsLoaded(:final isWorking) => isWorking,
    _ => false,
  };
}
