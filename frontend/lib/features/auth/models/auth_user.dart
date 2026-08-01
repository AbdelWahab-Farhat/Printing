import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_user.freezed.dart';
part 'auth_user.g.dart';

/// The signed-in account.
///
/// **One class, not an entity plus a model.** The pair used to exist so that a rename on the
/// backend could not reach the widgets — but `@JsonKey` already is that seam. A second,
/// near-identical class and a `toEntity()` for every field bought nothing over an annotation,
/// and cost a file per type plus a mapping to keep in step.
@freezed
abstract class AuthUser with _$AuthUser {
  const factory AuthUser({
    required int id,
    required String name,
    required String phone,
    String? email,

    /// The short number this employee is known by — what the home screen shows under their
    /// name. Nullable because the column was added after the first accounts existed; a server
    /// that predates it simply omits the key.
    @JsonKey(name: 'employee_code') String? employeeCode,

    /// The jobs this account holds. Empty is meaningful — a brand-new employee has none yet.
    @Default(<UserRole>[]) List<UserRole> roles,

    /// Comes from the server rather than being derived from [roles] here.
    ///
    /// An administrator's access is granted by a rule on the backend, not by permission rows,
    /// so "is this person an admin" is the backend's answer to give. Re-deriving it in the app
    /// would mean two places to change the day that rule moves.
    @JsonKey(name: 'is_admin') @Default(false) bool isAdmin,
  }) = _AuthUser;

  const AuthUser._();

  factory AuthUser.fromJson(Map<String, dynamic> json) => _$AuthUserFromJson(json);

  bool hasRole(String name) => roles.any((role) => role.name == name);
}

/// A named bundle of permissions, as the API reports it.
@freezed
abstract class UserRole with _$UserRole {
  const factory UserRole({
    /// The machine name the backend compares against — `admin`, `accountant`.
    required String name,

    /// The Arabic label to show. Sent by the server so the app never keeps its own
    /// translation table in step with a list the business can add to at runtime.
    required String label,
  }) = _UserRole;

  factory UserRole.fromJson(Map<String, dynamic> json) => _$UserRoleFromJson(json);
}

/// A successful sign-in: who it is, and the token that proves it.
///
/// The two travel together because neither is useful alone — a token with no user means the
/// UI cannot greet anyone, and a user with no token cannot make a request.
@freezed
abstract class AuthSession with _$AuthSession {
  const factory AuthSession({required AuthUser user, required String token}) = _AuthSession;

  factory AuthSession.fromJson(Map<String, dynamic> json) => _$AuthSessionFromJson(json);
}
