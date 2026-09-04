import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:flutter/foundation.dart';

/// Who is signed in, and what the server says they may do.
///
/// > **This is a courtesy, never a security boundary.** The boundary is `can:products.manage`
/// > on the route in `routes/api.php`, and it stays there whatever this object answers. Hiding a
/// > control spares somebody work they cannot finish; it protects nothing, and anyone holding
/// > the token bypasses it with `curl`. Never relax a server-side `can:` because the app hides
/// > the button.
///
/// It sits beside [TokenStorage] in `core/` and is the same kind of thing: one piece of session
/// truth, **one writer**, every layer reading. The writer is `AuthRepositoryImpl` — `adopt` is
/// called in the same breath as the token is written, for the reason that file already gives
/// about the token itself: a ViewModel that has to remember produces the one screen that forgets.
///
/// ```dart
/// grep -rn "\.adopt(" lib/    // must stay at exactly two lines
/// ```
///
/// **Why a plain object and not a Cubit or a provider.** [can] has to answer *synchronously*,
/// because GoRouter's `redirect` cannot await — a route guard is impossible otherwise. And a
/// provider is scoped to a subtree, so a dialog or a sheet pushed on the root navigator would
/// throw looking for it. GetIt has no subtree. [revision] supplies the reactivity a provider
/// would have given, without the scope.
class Session {
  AuthUser? _user;
  Set<String> _granted = const <String>{};

  final ValueNotifier<int> _revision = ValueNotifier<int>(0);

  AuthUser? get user => _user;

  bool get isSignedIn => _user != null;

  /// Bumped by [adopt] and [clear] — `PermissionGate` listens, and nothing else has to.
  ///
  /// Not decoration: a permission set genuinely does change with the tree mounted and nothing
  /// navigating. Pulling to refresh the home screen re-reads `/auth/me`, and so does the
  /// self-healing refresh after a 403.
  ValueListenable<int> get revision => _revision;

  /// The whole public question.
  ///
  /// Fail-closed: an unfilled session permits nothing, so "not loaded yet" and "not allowed"
  /// give the same answer and no control can flash into existence before the truth arrives.
  bool can(AppPermission permission) => _granted.contains(permission.wire);

  bool canAny(Iterable<AppPermission> permissions) => permissions.any(can);

  /// Whether that account is the one signed in on this phone.
  ///
  /// For the handful of actions that are refused *on yourself* rather than by permission —
  /// stopping an account is the first: doing it to your own would revoke the token making the
  /// request and lock you out of the screen that undoes it. The server refuses it too; this
  /// only spares somebody the tap.
  ///
  /// Fail-closed like the rest: with no session loaded, nothing is you.
  bool isSelf(int userId) => _user?.id == userId;

  /// Whether this account is an administrator.
  ///
  /// **The one gate in this app that is not a permission, and it is deliberate.** Creating a
  /// staff account is administrators-only for now, and the server enforces it with a *gate
  /// ability* rather than a permission — precisely so it cannot be ticked onto a role from the
  /// roles screen. There is no `AppPermission` to ask for, because there is no permission.
  ///
  /// The server's answer, never derived from [AuthUser.roles] here: an administrator's access
  /// comes from a rule on the backend, and re-deriving it would be a second copy of that rule
  /// with nothing keeping the two in step.
  ///
  /// Fail-closed like [can]: an unfilled session is not an administrator.
  ///
  /// **Reach for [can] first.** Anything gated on *what a job may do* belongs in
  /// [AppPermission]; this is only for the handful of things reserved to the role itself. The
  /// day creating staff is delegated, this call site becomes a `can(...)` and this getter goes.
  bool get isAdmin => _user?.isAdmin ?? false;

  /// Whether this account belongs to an investor rather than to an employee.
  ///
  /// The one thing the router branches on. Fail-closed like everything else here: an unfilled
  /// session is not an investor, so nobody is bounced to the portal before the truth arrives.
  ///
  /// **A courtesy, never a boundary** — the same sentence this whole file carries. The boundary
  /// is `can:investor_portal.view` on the Laravel route and the query behind it, which resolves
  /// the account from the signed-in user's own link and takes no id from the app at all.
  bool get isInvestor => _user?.isInvestor ?? false;

  /// Names the server granted that this build has no case for.
  ///
  /// Kept rather than dropped, and that is why [_granted] holds strings and not
  /// [AppPermission]s: parsing would need a lookup that either swallows the unknown name — so
  /// nobody could ever discover the app is behind the API — or throws the day the backend ships
  /// `orders.manage`.
  Set<String> get unrecognised =>
      _granted.difference({for (final permission in AppPermission.values) permission.wire});

  /// Takes the signed-in account and the grants that came with it.
  void adopt(AuthUser user) {
    assert(
      user.permissions != null,
      'adopted a user carrying no `permissions` — the server omitted the key, which means an '
      'eager load is missing on the backend. Everything would be hidden from everyone.',
    );

    _user = user;
    _granted = {...?user.permissions};

    if (kDebugMode && unrecognised.isNotEmpty) {
      debugPrint('ℹ️ الخادم منح صلاحيات لا يعرفها هذا الإصدار: $unrecognised');
    }

    _revision.value++;
  }

  /// Signed out, or the token was disowned. Both halves go, together.
  void clear() {
    _user = null;
    _granted = const <String>{};
    _revision.value++;
  }
}
