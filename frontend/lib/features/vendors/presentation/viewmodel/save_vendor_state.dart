part of 'save_vendor_cubit.dart';

/// Everything the supplier form can be, and nothing it cannot.
///
/// A Freezed union rather than a class with `isLoading`, `error` and `vendor` all nullable at
/// once: that shape permits `isLoading: true` beside an error, which is exactly how a spinner
/// ends up stuck on top of a failure message.
@freezed
sealed class SaveVendorState with _$SaveVendorState {
  const factory SaveVendorState.initial() = SaveVendorInitial;

  /// In flight. The form is locked and the button shows a spinner.
  const factory SaveVendorState.submitting() = SaveVendorSubmitting;

  /// Written. Carries what the server stored, so the list behind can be updated from it rather
  /// than re-fetched.
  const factory SaveVendorState.success(Vendor vendor) = SaveVendorSuccess;

  const factory SaveVendorState.failure(Failure failure) = SaveVendorFailure;
}

extension SaveVendorStateX on SaveVendorState {
  bool get isSubmitting => this is SaveVendorSubmitting;

  String? get nameError => _fieldError('name');

  /// The one that actually happens: the phone is unique among suppliers, so «هذا الرقم مسجّل
  /// لمورد آخر» is the refusal this form earns most.
  String? get phoneError => _fieldError('phone');

  String? get emailError => _fieldError('email');

  /// True when the server complained about something this form has nowhere to paint, so it has
  /// to be said out loud instead. Anything the form renders inline would otherwise be said twice.
  bool get hasUnrenderedErrors => switch (this) {
    SaveVendorFailure(:final failure) => switch (failure) {
      ServerFailure(:final fieldErrors) when fieldErrors != null && fieldErrors.isNotEmpty =>
        fieldErrors.keys.any((key) => !_rendered.contains(key)),
      // No field errors at all — a 403, a 500, a dropped connection. Nothing is inline, so it
      // all has to be said out loud.
      _ => true,
    },
    _ => false,
  };

  String? _fieldError(String field) => switch (this) {
    SaveVendorFailure(:final failure) => switch (failure) {
      ServerFailure(:final fieldErrors) => fieldErrors?[field]?.firstOrNull,
      _ => null,
    },
    _ => null,
  };
}

/// The exact keys the form paints under an input. Everything else goes to a snackbar.
const Set<String> _rendered = {'name', 'phone', 'email'};
