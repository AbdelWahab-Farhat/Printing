part of 'save_shipping_company_cubit.dart';

/// Everything the carrier form can be, and nothing it cannot.
@freezed
sealed class SaveShippingCompanyState with _$SaveShippingCompanyState {
  const factory SaveShippingCompanyState.initial() = SaveShippingCompanyInitial;

  /// In flight. The form is locked and the button shows a spinner.
  const factory SaveShippingCompanyState.submitting() = SaveShippingCompanySubmitting;

  /// Saved. Carries what the server stored, so the list behind can be refreshed from it.
  const factory SaveShippingCompanyState.success(ShippingCompany company) =
      SaveShippingCompanySuccess;

  const factory SaveShippingCompanyState.failure(Failure failure) = SaveShippingCompanyFailure;
}

extension SaveShippingCompanyStateX on SaveShippingCompanyState {
  bool get isSubmitting => this is SaveShippingCompanySubmitting;

  /// The server's complaint about the name — the duplicate is the one that actually happens.
  String? get nameError => _fieldError('name');

  String? get phoneError => _fieldError('phone');

  /// True when the server complained about something this form has nowhere to put, so it has
  /// to be said out loud instead of painted under a box.
  bool get hasUnrenderedErrors => switch (this) {
    SaveShippingCompanyFailure(:final failure) => switch (failure) {
      ServerFailure(:final fieldErrors) when fieldErrors != null && fieldErrors.isNotEmpty =>
        fieldErrors.keys.any((key) => key != 'name' && key != 'phone'),
      // No field errors at all — a 403, a 500, a dropped connection.
      _ => true,
    },
    _ => false,
  };

  String? _fieldError(String field) => switch (this) {
    SaveShippingCompanyFailure(:final failure) => switch (failure) {
      ServerFailure(:final fieldErrors) => fieldErrors?[field]?.firstOrNull,
      _ => null,
    },
    _ => null,
  };
}
