part of 'order_detail_cubit.dart';

/// Everything one order can be.
@freezed
sealed class OrderDetailState with _$OrderDetailState {
  const factory OrderDetailState.loading() = OrderDetailLoading;

  const factory OrderDetailState.loaded(
    CustomerOrderDetail order, {
    /// A *refresh* that failed. The order already on screen is still true — losing it because
    /// a pull-to-refresh timed out would be the app throwing away what it has.
    Failure? lastFailure,
  }) = OrderDetailLoaded;

  const factory OrderDetailState.failure(Failure failure) = OrderDetailFailure;
}

extension OrderDetailStateX on OrderDetailState {
  CustomerOrderDetail? get order => switch (this) {
    OrderDetailLoaded(:final order) => order,
    _ => null,
  };

  /// Whether to draw the money block at all. An order still «بانتظار المراجعة» has not been
  /// priced, and drawing zeros beside «الإجمالي» would read as a promise that it is free.
  bool get hasBeenPriced => switch (this) {
    OrderDetailLoaded(:final order) => order.stage != OrderStage.underReview,
    _ => false,
  };
}
