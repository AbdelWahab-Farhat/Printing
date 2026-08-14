import 'dart:io';

import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:flutter_test/flutter_test.dart';

/// The one mechanical guard on the only real cost of this layer.
///
/// [AppPermission] is a hand-copy of the backend's `PermissionName.php`, in a different
/// language, with no compiler watching either side. Add a case there and forget it here and the
/// app silently hides a control from everybody; rename one and every gate on it fails closed,
/// which looks like a permissions bug three screens from its cause.
///
/// So this test reads the PHP file. Both repositories live in one workspace, which makes it
/// free — and when the backend is not checked out it **skips** rather than fails, so a
/// frontend-only checkout still goes green.
///
/// Arrange - Act - Assert.
void main() {
  test('the permission catalogue matches the backend, case for case', () {
    // Arrange
    final source = File('../backend/app/Domain/Identity/Enums/PermissionName.php');

    if (!source.existsSync()) {
      markTestSkipped('backend not checked out beside this one — nothing to compare against');

      return;
    }

    // Act
    final backend = RegExp("case \\w+ = '([^']+)';")
        .allMatches(source.readAsStringSync())
        .map((match) => match.group(1)!)
        .toSet();
    final app = AppPermission.values.map((permission) => permission.wire).toSet();

    // Assert — named in each direction, because the two failures need different fixes: one is
    // a case to add here, the other is a case to delete.
    expect(backend, isNotEmpty, reason: 'the regex matched nothing — did the PHP file change shape?');
    expect(
      app.difference(backend),
      isEmpty,
      reason: 'this app knows permissions the backend does not define',
    );
    expect(
      backend.difference(app),
      isEmpty,
      reason: 'the backend defines permissions this app has no AppPermission case for',
    );
  });
}
