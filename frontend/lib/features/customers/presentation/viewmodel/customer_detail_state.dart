part of 'customer_detail_cubit.dart';

/// Everything the customer detail screen can be.
///
/// [changing] carries the customer it is changing, so the screen keeps showing them while the
/// activation request is in flight — a detail screen that blanks to a spinner because one
/// switch was flipped has thrown away everything the user was reading.
@freezed
sealed class CustomerDetailState with _$CustomerDetailState {
  const factory CustomerDetailState.loading() = CustomerDetailLoading;

  const factory CustomerDetailState.loaded(Customer customer) = CustomerDetailLoaded;

  /// Loaded, and an activation change is on its way.
  const factory CustomerDetailState.changing(Customer customer) = CustomerDetailChanging;

  const factory CustomerDetailState.failure(Failure failure) = CustomerDetailFailure;
}

extension CustomerDetailStateX on CustomerDetailState {
  /// The customer, whenever there is one to show — including mid-change.
  Customer? get customer => switch (this) {
    CustomerDetailLoaded(:final customer) => customer,
    CustomerDetailChanging(:final customer) => customer,
    _ => null,
  };

  bool get isChanging => this is CustomerDetailChanging;
}
