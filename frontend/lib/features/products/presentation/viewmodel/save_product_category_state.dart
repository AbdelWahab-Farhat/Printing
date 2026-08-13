part of 'save_product_category_cubit.dart';

/// Everything the add/rename sheet can be, and nothing it cannot.
///
/// A Freezed union rather than a class with `isLoading`, `error` and `category` nullable at
/// once: that shape permits a spinner and an error message together, which is exactly how a
/// stuck spinner ends up on top of a failure.
@freezed
sealed class SaveProductCategoryState with _$SaveProductCategoryState {
  const factory SaveProductCategoryState.initial() = SaveProductCategoryInitial;

  /// In flight. The button shows a spinner and the form is locked, so an impatient double tap
  /// cannot send a second request.
  const factory SaveProductCategoryState.submitting() = SaveProductCategorySubmitting;

  /// Saved. Carries the category the *server* stored, so the list is refreshed from its answer
  /// rather than from what the form happened to hold.
  const factory SaveProductCategoryState.success(ProductCategory category) =
      SaveProductCategorySuccess;

  const factory SaveProductCategoryState.failure(Failure failure) = SaveProductCategoryFailure;
}

extension SaveProductCategoryStateX on SaveProductCategoryState {
  bool get isSubmitting => this is SaveProductCategorySubmitting;

  /// The server's complaint about the name — «التصنيف مسجّل مسبقاً» belongs under the box
  /// holding the name, not in a toast that leaves the user guessing which field to fix.
  String? get nameError => switch (this) {
    SaveProductCategoryFailure(:final failure) => switch (failure) {
      ServerFailure(:final fieldErrors) => fieldErrors?['name']?.firstOrNull,
      _ => null,
    },
    _ => null,
  };
}
