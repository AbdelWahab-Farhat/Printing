part of 'save_business_field_cubit.dart';

/// Everything the add/rename sheet can be, and nothing it cannot.
///
/// A Freezed union rather than a class with `isLoading`, `error` and `field` nullable at once:
/// that shape permits a spinner and an error message together, which is exactly how a stuck
/// spinner ends up on top of a failure.
@freezed
sealed class SaveBusinessFieldState with _$SaveBusinessFieldState {
  const factory SaveBusinessFieldState.initial() = SaveBusinessFieldInitial;

  /// In flight. The button shows a spinner and the form is locked, so an impatient double tap
  /// cannot send a second request.
  const factory SaveBusinessFieldState.submitting() = SaveBusinessFieldSubmitting;

  /// Saved. Carries the field the *server* stored, so the list is refreshed from its answer
  /// rather than from what the form happened to hold.
  const factory SaveBusinessFieldState.success(BusinessField field) = SaveBusinessFieldSuccess;

  const factory SaveBusinessFieldState.failure(Failure failure) = SaveBusinessFieldFailure;
}

extension SaveBusinessFieldStateX on SaveBusinessFieldState {
  bool get isSubmitting => this is SaveBusinessFieldSubmitting;

  /// The server's complaint about the name — «مجال العمل مسجّل مسبقاً» belongs under the box
  /// holding the name, not in a toast that leaves the user guessing which field to fix.
  String? get nameError => switch (this) {
    SaveBusinessFieldFailure(:final failure) => switch (failure) {
      ServerFailure(:final fieldErrors) => fieldErrors?['name']?.firstOrNull,
      _ => null,
    },
    _ => null,
  };
}
