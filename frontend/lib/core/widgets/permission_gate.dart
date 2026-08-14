import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:flutter/widgets.dart';

/// Shows [child] only to somebody the server says may use it.
///
/// > **A courtesy, never a security boundary.** The boundary is `can:` on the route. Hiding a
/// > control spares a person work they cannot finish; it protects nothing. Never relax a
/// > server-side check because the app hides the button.
///
/// **Absent by default, not disabled.** A greyed-out «منتج جديد» advertises a job that is not
/// yours and produces "why is it grey"; and for somebody who genuinely lacks the permission
/// there is no later moment when it arrives, so a spinner would be a lie too. Pass [fallback]
/// only when the space needs to say something else.
///
/// Rebuilds when the session changes, because a permission set really does change with the tree
/// mounted — pulling to refresh the home screen re-reads `/auth/me`, and so does the healing
/// refresh after a 403.
///
/// **Not the inventory of record.** Some gates are ternaries instead: a `floatingActionButton`
/// slot wants `null`, and a `SizedBox.shrink()` there still occupies the slot and shifts the
/// Scaffold's bottom inset. The complete list is `grep -rn "AppPermission\." lib/`, which
/// catches both forms.
class PermissionGate extends StatelessWidget {
  const PermissionGate({
    required this.permission,
    required this.child,
    this.fallback,
    super.key,
  });

  final AppPermission permission;
  final Widget child;

  /// What stands in the child's place. Nothing, unless the layout needs otherwise.
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final session = sl<Session>();

    return ValueListenableBuilder<int>(
      valueListenable: session.revision,
      builder: (context, _, _) =>
          session.can(permission) ? child : (fallback ?? const SizedBox.shrink()),
    );
  }
}
