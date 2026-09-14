part of 'save_shortage_cubit.dart';

/// Everything the نواقص form can be, and nothing it cannot.
@freezed
sealed class SaveShortageState with _$SaveShortageState {
  const factory SaveShortageState.initial() = SaveShortageInitial;

  const factory SaveShortageState.submitting() = SaveShortageSubmitting;

  /// Written. Carries what the server stored, so the screen behind can be handed the new row
  /// rather than made to ask for it.
  const factory SaveShortageState.success(Shortage shortage) = SaveShortageSuccess;

  const factory SaveShortageState.failure(Failure failure) = SaveShortageFailure;
}

extension SaveShortageStateX on SaveShortageState {
  bool get isSubmitting => this is SaveShortageSubmitting;

  String? get nameError => _fieldError('name');

  /// The one that catches people on an edit: «الكمية المطلوبة (…) أقل مما تم توفيره فعلاً (…) —
  /// اعكس عملية التوفير أولاً». It is about a figure already in the ledger, not about the number
  /// just typed, so it has to land under the box rather than in a toast that scrolls away.
  String? get quantityError => _fieldError('required_quantity');

  String? get assigneeError => _fieldError('assigned_to_user_id');

  /// «الوحدة مطلوبة» — required on a create, and the refusal that caught the first hand-written
  /// shortage because the form had no unit picker at all.
  String? get unitError => _fieldError('unit');

  String? _fieldError(String field) => switch (this) {
    SaveShortageFailure(:final failure) => switch (failure) {
      ServerFailure(:final fieldErrors) => fieldErrors?[field]?.firstOrNull,
      _ => null,
    },
    _ => null,
  };
}
