part of 'add_customer_cubit.dart';

/// Everything the add-customer screen can be, and nothing it cannot.
///
/// A Freezed union rather than a class with `isLoading`, `error` and `customer` all nullable at
/// once — that shape permits `isLoading: true` together with an error, which is exactly how a
/// spinner ends up stuck on top of a failure message. Here the compiler refuses to build it,
/// and `switch` in the view is exhaustive.
@freezed
sealed class AddCustomerState with _$AddCustomerState {
  const factory AddCustomerState.initial() = AddCustomerInitial;

  /// In flight. The button shows a spinner and the form is locked, so an impatient double tap
  /// cannot send a second request.
  const factory AddCustomerState.submitting() = AddCustomerSubmitting;

  /// Created. Carries the customer the *server* stored — including the `code` it allocated,
  /// which is the number staff will use to find them afterwards.
  const factory AddCustomerState.success(Customer customer) = AddCustomerSuccess;

  const factory AddCustomerState.failure(Failure failure) = AddCustomerFailure;
}

extension AddCustomerStateX on AddCustomerState {
  bool get isSubmitting => this is AddCustomerSubmitting;

  /// The server's complaint about the name field, if it made one.
  ///
  /// Laravel sends `errors` keyed by field precisely so they can be rendered under the inputs
  /// rather than piled into one toast — this is where that key becomes a widget's `errorText`.
  String? get nameError => _fieldError('name');

  /// The one that matters most here: "رقم الهاتف مستخدم مسبقاً لعميل آخر" belongs under the
  /// phone box, next to the number the user must change.
  String? get phoneError => _fieldError('phone');

  String? _fieldError(String field) => switch (this) {
    AddCustomerFailure(:final failure) => switch (failure) {
      ServerFailure(:final fieldErrors) => fieldErrors?[field]?.firstOrNull,
      _ => null,
    },
    _ => null,
  };
}
