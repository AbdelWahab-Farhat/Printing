part of 'push_preferences_cubit.dart';

/// Everything the push settings page can be.
///
/// [loaded] carries an optional [failure] from a refused switch, so the page stays and the
/// reason goes to a snackbar over it.
@freezed
sealed class PushPreferencesState with _$PushPreferencesState {
  const factory PushPreferencesState.loading() = PushPreferencesLoading;

  const factory PushPreferencesState.loaded(List<PushPreferenceGroup> groups, {Failure? failure}) =
      PushPreferencesLoaded;

  /// Nothing to show at all — the first read failed.
  const factory PushPreferencesState.failure(Failure failure) = PushPreferencesFailure;
}

extension PushPreferencesStateX on PushPreferencesState {
  List<PushPreferenceGroup>? get groups => switch (this) {
    PushPreferencesLoaded(:final groups) => groups,
    _ => null,
  };
}
