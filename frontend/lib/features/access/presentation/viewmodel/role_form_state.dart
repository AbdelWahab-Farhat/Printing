part of 'role_form_cubit.dart';

/// What the role form is showing.
///
/// A record with fields rather than a sealed union — the same deliberate exception the roles
/// sheet makes, and for the same reason: the catalogue can still be arriving while the name has
/// been typed and six boxes ticked, and a 422 must leave every tick exactly where it was. The
/// pair a union exists to keep apart, `isSubmitting` and [failure], is kept apart by hand:
/// `submit` clears the failure in the same `emit` that sets the flag, and no path sets both.
@freezed
abstract class RoleFormState with _$RoleFormState {
  const factory RoleFormState({
    /// The catalogue, in the server's own sections.
    @Default(<PermissionGroup>[]) List<PermissionGroup> catalogue,

    /// What is ticked right now. Machine names, because that is what the API is given.
    @Default(<String>{}) Set<String> selected,

    @Default(false) bool isLoadingCatalogue,
    @Default(false) bool isSubmitting,

    /// The role as the **server** stored it. The screen navigates on this rather than on what
    /// was typed, so what appears next is what was actually saved.
    Role? saved,

    Failure? failure,
  }) = _RoleFormState;

  const RoleFormState._();

  int get selectedCount => selected.length;

  /// Every permission the catalogue offers, across all sections.
  int get catalogueCount =>
      catalogue.fold(0, (total, group) => total + group.permissions.length);

  /// The server's complaint about the name box, if it made one.
  ///
  /// Laravel sends `errors` keyed by field precisely so they can be rendered under the input
  /// rather than piled into one toast — «اسم الدور مستخدم مسبقاً» belongs under the name the
  /// user has to change.
  String? get nameError => switch (failure) {
    ServerFailure(:final fieldErrors) => fieldErrors?['name']?.firstOrNull,
    _ => null,
  };

  /// A complaint about the permission list itself — an unknown name, or a duplicate. Rare, and
  /// it has nowhere better to go than above the sections it is about.
  String? get permissionsError => switch (failure) {
    ServerFailure(:final fieldErrors) => fieldErrors?.entries
        .where((entry) => entry.key.startsWith('permissions'))
        .map((entry) => entry.value.firstOrNull)
        .nonNulls
        .firstOrNull,
    _ => null,
  };

  /// How many of one section are ticked — what its header counts.
  int selectedIn(PermissionGroup group) =>
      group.names.where(selected.contains).length;

  bool isWholeGroupSelected(PermissionGroup group) =>
      group.permissions.isNotEmpty && group.names.every(selected.contains);
}
