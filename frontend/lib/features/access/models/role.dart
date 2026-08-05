import 'package:freezed_annotation/freezed_annotation.dart';

part 'role.freezed.dart';
part 'role.g.dart';

/// A named bundle of permissions.
///
/// Staff get their access by holding one, so changing what a job may do is a single edit here
/// rather than a change to every person doing it.
///
/// **Every "may the UI offer this?" is a field, not a rule.** `canBeRenamed`, `canBeDeleted`,
/// `canEditPermissions` and [grantsEverything] all arrive from the server. Re-deriving them from
/// [name] — `if (name == 'admin')` — would put a copy of the backend's policy in the app, and
/// the copy goes stale silently: the symptom is an enabled button that answers 403.
@freezed
abstract class Role with _$Role {
  const factory Role({
    required int id,

    /// The machine name the gate compares against — `admin`, `accountant`. Lowercase Latin,
    /// and what `PATCH /users/{id}/roles` is given.
    required String name,

    /// Arabic, for a person. Falls back to [name] on the server for roles the code knows
    /// nothing about, so this is always safe to print.
    required String label,

    /// The administrator: its access comes from a gate rule, not from permission rows, so its
    /// [permissions] list is **empty while its actual access is total**. Saying so explicitly is
    /// what stops that reading as a bug on a permissions screen.
    @JsonKey(name: 'grants_everything') @Default(false) bool grantsEverything,

    /// The code references this role by name, so it cannot be deleted.
    @JsonKey(name: 'is_system') @Default(false) bool isSystem,

    @JsonKey(name: 'can_be_renamed') @Default(true) bool canBeRenamed,
    @JsonKey(name: 'can_be_deleted') @Default(false) bool canBeDeleted,
    @JsonKey(name: 'can_edit_permissions') @Default(true) bool canEditPermissions,

    /// What this role grants, as `{name, label}` pairs. Empty is meaningful: a role created a
    /// minute ago grants nothing, and so does the administrator — see [grantsEverything].
    @Default(<PermissionOption>[]) List<PermissionOption> permissions,

    /// How many people hold it. The reason a role cannot be deleted, when it cannot.
    @JsonKey(name: 'users_count') int? usersCount,
  }) = _Role;

  const Role._();

  factory Role.fromJson(Map<String, dynamic> json) => _$RoleFromJson(json);

  /// The set the editor ticks against, and what an update sends back.
  Set<String> get permissionNames => {for (final permission in permissions) permission.name};

  bool get hasPermissions => permissions.isNotEmpty;

  /// Held by somebody. The server refuses to delete such a role, so the app does not offer to.
  bool get isHeld => (usersCount ?? 0) > 0;

  /// Whether deleting is worth putting in front of the user at all.
  ///
  /// Two separate reasons to say no, and the screen tells them apart: a system role is never
  /// deletable, while a role somebody holds becomes deletable once it is taken off them.
  bool get isDeletable => canBeDeleted && !isHeld;
}

/// One permission — the machine name the gate checks, and the Arabic for a person.
///
/// The same shape whether it comes from the catalogue at `GET /permissions` or from a role's
/// own list, because it is the same thing seen from two sides.
@freezed
abstract class PermissionOption with _$PermissionOption {
  const factory PermissionOption({
    /// Exactly the string a route's `can:` middleware names.
    required String name,

    /// Sent by the server so the app keeps no translation table of its own.
    required String label,
  }) = _PermissionOption;

  factory PermissionOption.fromJson(Map<String, dynamic> json) =>
      _$PermissionOptionFromJson(json);
}

/// One section of the permission catalogue — «الطلبيات», «حالات الطلبيات», «العملاء» …
///
/// The grouping is the **server's**, not the app's. Twenty-five checkboxes in one column is a
/// list nobody reads to the end; the backend already knows which permission belongs to which
/// part of the business, so it says, and both the editor and the read-only view render the
/// same sections in the same order.
@freezed
abstract class PermissionGroup with _$PermissionGroup {
  const factory PermissionGroup({
    /// The section heading, in Arabic.
    @JsonKey(name: 'group') required String title,
    required List<PermissionOption> permissions,
  }) = _PermissionGroup;

  const PermissionGroup._();

  factory PermissionGroup.fromJson(Map<String, dynamic> json) =>
      _$PermissionGroupFromJson(json);

  List<String> get names => [for (final permission in permissions) permission.name];
}

/// The catalogue, narrowed to what one role actually holds.
///
/// Used by the role screen to show a granted set **in the same sections the editor ticks it
/// in** — so «٤ من ٦ في الطلبيات» is a sentence somebody can act on, where a flat list of
/// twenty-five Arabic phrases is not.
///
/// A pure function over two lists rather than a method on [Role]: the role does not know the
/// catalogue exists, and this way it stays testable without either.
///
/// Anything held but missing from the catalogue lands in a trailing «صلاحيات أخرى» section
/// rather than vanishing — that combination means the server is ahead of this build, and
/// silently dropping it would hide exactly the fact worth knowing.
List<PermissionGroup> groupHeldPermissions({
  required Set<String> held,
  required List<PermissionGroup> catalogue,
}) {
  final grouped = <PermissionGroup>[];
  final placed = <String>{};

  for (final group in catalogue) {
    final matching = group.permissions.where((p) => held.contains(p.name)).toList();
    if (matching.isEmpty) continue;

    placed.addAll(matching.map((p) => p.name));
    grouped.add(PermissionGroup(title: group.title, permissions: matching));
  }

  final unknown = held.difference(placed).toList()..sort();
  if (unknown.isNotEmpty) {
    grouped.add(
      PermissionGroup(
        title: 'صلاحيات أخرى',
        // No label to show but the machine name — which is the honest thing to print for a
        // permission this build has never heard of.
        permissions: [for (final name in unknown) PermissionOption(name: name, label: name)],
      ),
    );
  }

  return grouped;
}
