part of 'add_employee_cubit.dart';

/// What the "register a colleague" form is showing.
///
/// A record with fields rather than a sealed union — the same exception the role form makes, and
/// for the same reason: the role list can still be arriving while three boxes have been typed
/// and one role ticked, and a 422 must leave every one of them exactly where it was. The pair a
/// union exists to keep apart, [isSubmitting] and [failure], is kept apart by hand: `submit`
/// clears the failure in the same `emit` that sets the flag, and no path sets both.
@freezed
abstract class AddEmployeeState with _$AddEmployeeState {
  const factory AddEmployeeState({
    /// The roles there are to choose from. Empty while loading, and empty again if the list
    /// could not be fetched — which does not block the form; see [AddEmployeeCubit.loadRoles].
    @Default(<Role>[]) List<Role> roles,

    /// Which of them the new account starts with. Machine names, because that is what the API
    /// is given.
    @Default(<String>{}) Set<String> selectedRoles,

    @Default(false) bool isLoadingRoles,
    @Default(false) bool isSubmitting,

    /// The account as the **server** stored it — including the `employee_code` it allocated,
    /// which is the number colleagues will use to refer to this person.
    AuthUser? created,

    Failure? failure,
  }) = _AddEmployeeState;

  const AddEmployeeState._();

  /// The server's complaint about one field, rendered under that field.
  ///
  /// Laravel sends `errors` keyed by field precisely so they can be shown at the input rather
  /// than piled into one toast — «رقم الهاتف مستخدم مسبقاً» belongs under the number the person
  /// has to change, not in a message that has already faded by the time they look.
  String? get nameError => _fieldError('name');

  String? get emailError => _fieldError('email');

  String? get phoneError => _fieldError('phone');

  String? get passwordError => _fieldError('password');

  /// A complaint about the roles themselves — an unknown name, or a duplicate. Rare, and it has
  /// nowhere better to go than above the list it is about.
  String? get rolesError => switch (failure) {
    ServerFailure(:final fieldErrors) => fieldErrors?.entries
        .where((entry) => entry.key.startsWith('roles'))
        .map((entry) => entry.value.firstOrNull)
        .nonNulls
        .firstOrNull,
    _ => null,
  };

  /// Whether the failure on screen has already been said next to a box.
  ///
  /// The screen uses this to decide whether the snackbar is needed as well: a 422 that is
  /// already marked under three inputs does not also need a red bar over them.
  bool get isFieldFailure =>
      nameError != null ||
      emailError != null ||
      phoneError != null ||
      passwordError != null ||
      rolesError != null;

  String? _fieldError(String field) => switch (failure) {
    ServerFailure(:final fieldErrors) => fieldErrors?[field]?.firstOrNull,
    _ => null,
  };
}
