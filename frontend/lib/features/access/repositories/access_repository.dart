import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/access/models/role.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';

/// Everything about who works here and what they may do.
///
/// One contract for both halves — staff and roles — because they are one screenful of the
/// business: a role exists to be given to somebody, and the only thing the app changes about a
/// person is which roles they hold. Splitting them would mean two fakes in every test that
/// touches either.
///
/// **Editing a staff account is still not here**, and that is not an omission: the API offers no
/// rename, no phone change and no deactivate for a user. Only creating one and setting its roles
/// exist, so only those are declared — a method with no endpoint behind it is a promise the
/// repository cannot keep.
abstract interface class AccessRepository {
  /// Staff, searchable by name, email or phone.
  Future<Either<Failure, Paginated<AuthUser>>> users({
    String? search,
    int page = 1,
    int perPage = 20,
  });

  /// Creates a staff account, optionally with the roles it starts with.
  ///
  /// **Administrators only**, and the server says so with a gate ability rather than a
  /// permission — see `Session.isAdmin`. The password is the one the employee will sign in
  /// with; no token comes back, because the person creating the account is not the person
  /// being created.
  Future<Either<Failure, AuthUser>> createUser({
    required String name,
    required String email,
    required String phone,
    required String password,
    List<String> roleNames = const [],
  });

  /// One employee with the roles they hold.
  ///
  /// A second request rather than the row lifted out of the list: the detail screen is opened
  /// on a list that may be minutes old, and a screen built from a stale row shows a phone
  /// number somebody has already corrected.
  Future<Either<Failure, AuthUser>> user(int userId);

  /// Corrects an employee's name, email and phone — and nothing else.
  ///
  /// **No password and no salary**, deliberately: each has its own method below because each
  /// has its own guard. A password sent on this call would be ignored by the server anyway.
  Future<Either<Failure, AuthUser>> updateUser({
    required int userId,
    required String name,
    required String email,
    required String phone,
  });

  /// Sets a new password for somebody who has forgotten theirs.
  ///
  /// **Administrators only** — a gate ability on the server, so it cannot be ticked onto a
  /// role: whoever sets a colleague's password can sign in as them. The current password is
  /// not asked for, because the person typing does not know it; every session already open on
  /// that account is ended by the server.
  Future<Either<Failure, AuthUser>> setUserPassword(int userId, String password);

  /// What this employee is paid a month. `null` records that no wage has been agreed, which is
  /// a real state and different from a wage of zero.
  Future<Either<Failure, AuthUser>> setUserSalary(int userId, String? salary);

  /// Stops an account or starts it again.
  ///
  /// Its own endpoint rather than a field on [updateUser], and that is a safety property rather
  /// than tidiness: because saving an edit never carries `is_active`, correcting a stopped
  /// employee's phone number can never silently let them back in.
  Future<Either<Failure, AuthUser>> setUserActivation(int userId, {required bool isActive});

  /// Replaces a user's **whole** set of roles. An empty list takes them all away.
  ///
  /// Replace rather than add/remove, because that is what the endpoint is: sending the set the
  /// user should end up with makes the request idempotent, where a pair of add and remove calls
  /// leaves a half-applied state when the second one fails.
  Future<Either<Failure, AuthUser>> syncUserRoles(int userId, List<String> roleNames);

  /// Every role. Not paginated — the whole point of a role is that there are few of them.
  Future<Either<Failure, List<Role>>> roles();

  /// One role with its permissions and how many people hold it.
  Future<Either<Failure, Role>> role(int roleId);

  Future<Either<Failure, Role>> createRole({
    required String name,
    required List<String> permissions,
  });

  /// Sending [permissions] replaces the whole set; passing `null` leaves it untouched.
  ///
  /// The distinction is the endpoint's, and it is load-bearing: `[]` strips every permission
  /// from the role, `null` renames it and changes nothing else.
  Future<Either<Failure, Role>> updateRole({
    required int roleId,
    required String name,
    List<String>? permissions,
  });

  /// The server refuses for a role the code references, or one somebody still holds.
  Future<Either<Failure, String>> deleteRole(int roleId);

  /// The catalogue of everything the system can check for, in the server's own sections.
  Future<Either<Failure, List<PermissionGroup>>> permissions();
}
