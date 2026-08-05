part of 'user_roles_cubit.dart';

/// What the "which jobs does this person hold" sheet is showing.
///
/// A record with fields rather than a sealed union, and that is the deliberate exception to the
/// rule the rest of this app follows. The reason is that four things here are genuinely
/// simultaneous: the list of roles can still be arriving while the user has already ticked two
/// boxes, and a failed save must not blank the selection it failed to send. A union would need
/// a case per combination — and the cases that matter, `isSaving` and `failure`, are exactly the
/// pair a union is meant to keep apart, so they are kept apart by hand: [save] clears the
/// failure before it sets `isSaving`, and no path sets both.
@freezed
abstract class UserRolesState with _$UserRolesState {
  const factory UserRolesState({
    /// What is ticked right now — not what the server has. Nothing here is sent until [save].
    @Default(<String>{}) Set<String> selected,

    /// The roles there are to choose from.
    @Default(<Role>[]) List<Role> roles,

    @Default(false) bool isLoadingRoles,
    @Default(false) bool isSaving,

    /// The account as the server returned it after a successful save. Carries the roles the
    /// server actually stored, so the list behind the sheet is updated from the answer rather
    /// than from what was asked for.
    AuthUser? saved,

    Failure? failure,
  }) = _UserRolesState;

  const UserRolesState._();

  /// Whether the selection differs from what the person came in with. The save button is off
  /// until it does — «حفظ» that would send the roles somebody already has is a request with
  /// nothing to say.
  bool hasChangesAgainst(Set<String> initial) =>
      selected.length != initial.length || !selected.containsAll(initial);
}
