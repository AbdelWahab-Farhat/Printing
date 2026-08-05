part of 'order_detail_cubit.dart';

/// One order's screen, as a closed set of shapes.
///
/// [OrderDetailLoaded] carries `isWorking` rather than there being a separate busy case: while
/// a version of the artwork is being added or judged, the order is still on screen and still
/// readable, and a state that replaced it with a spinner would throw away everything the user
/// was looking at to say "working on it".
///
/// [OrderDetailFailure] keeps the order for the same reason — a refused write must leave the
/// screen showing what it was showing, with the server's sentence over the top.
@freezed
sealed class OrderDetailState with _$OrderDetailState {
  const factory OrderDetailState.loading() = OrderDetailLoading;

  const factory OrderDetailState.loaded({
    required Order order,
    @Default(false) bool isWorking,
  }) = OrderDetailLoaded;

  const factory OrderDetailState.failure({
    required Failure failure,
    Order? order,
  }) = OrderDetailFailure;

  const OrderDetailState._();

  /// The order behind whatever is on screen, when there is one.
  Order? get order => switch (this) {
    OrderDetailLoaded(:final order) => order,
    OrderDetailFailure(:final order) => order,
    OrderDetailLoading() => null,
  };

  bool get isWorking => switch (this) {
    OrderDetailLoaded(:final isWorking) => isWorking,
    _ => false,
  };
}
