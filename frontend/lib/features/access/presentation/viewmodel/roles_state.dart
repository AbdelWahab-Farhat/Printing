part of 'roles_cubit.dart';

/// Everything the roles screen can be, and nothing it cannot.
@freezed
sealed class RolesState with _$RolesState {
  const factory RolesState.loading() = RolesLoading;

  const factory RolesState.loaded({
    required List<Role> roles,

    /// Which row is being deleted right now, if any. Inside `loaded` rather than a case of its
    /// own, because the rest of the list stays on screen and usable while it happens.
    int? deletingId,
  }) = RolesLoaded;

  const factory RolesState.failure(Failure failure) = RolesFailure;
}
