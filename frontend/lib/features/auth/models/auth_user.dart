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

    /// What the server says this account may do — the raw permission names, already expanded
    /// for an administrator.
    ///
    /// **Nullable, with no `@Default([])`, and do not "tidy that up".** `null` means "this
    /// response did not say" and `[]` means "this account may do nothing"; collapsing them
    /// would turn a missing eager load on the backend into something that looks like a
    /// permissions problem, with every control hidden from everybody and no way to tell why.
    /// RULES §3: `null` ≠ صفر.
    ///
    /// Read through [Session], never directly — the string is compared against
    /// [AppPermission.wire] there and nowhere else.
    List<String>? permissions,

    /// Whether this account can still sign in.
    ///
    /// A stopped employee stays in the list rather than disappearing, because the screen that
    /// puts them back is the one that lists them. Defaulted to `true` for the responses that
    /// predate the column — an account nobody stopped is an account in use.
    @JsonKey(name: 'is_active') @Default(true) bool isActive,

    /// What this employee is paid a month, as a decimal string — `'2500.00'`.
    ///
    /// **A string, never a double**: money round-tripped through a float is how `2500.10`
    /// becomes `2500.099999`. The same rule as every other amount in this app.
    ///
    /// **Null is two different facts, and the screen tells them apart by permission.** The
    /// server omits the key entirely from a reader without `users.salary` — so `null` there
    /// means «you may not know», and the section is not drawn at all. For a reader who does
    /// hold it, `null` means «لم يُحدَّد»: a real state for an account created before a wage
    /// was agreed, and different from a wage of zero.
    String? salary,

    /// Comes from the server rather than being derived from [roles] here.
    ///
    /// An administrator's access is granted by a rule on the backend, not by permission rows,
    /// so "is this person an admin" is the backend's answer to give. Re-deriving it in the app
    /// would mean two places to change the day that rule moves.
    @JsonKey(name: 'is_admin') @Default(false) bool isAdmin,

    /// Whether this account belongs to an investor rather than to an employee.
    ///
    /// **A fact about a row, not the name of a role.** The server answers it from the
    /// `investors.user_id` link, so renaming the «مستثمر» role — which is ordinary data the
    /// business may edit — cannot strand somebody on a screen built for staff.
    ///
    /// It decides where the app lands after sign-in and nothing else. The boundary is
    /// `can:investor_portal.view` on the route and the query behind it, which resolves the
    /// account from the signed-in user and never from anything the app sends.
    @JsonKey(name: 'is_investor') @Default(false) bool isInvestor,
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
