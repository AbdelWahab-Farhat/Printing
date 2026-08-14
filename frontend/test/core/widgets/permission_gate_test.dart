import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/widgets/permission_gate.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The gate reads the session and nothing else.
///
/// Arrange - Act - Assert throughout.
void main() {
  late Session session;

  AuthUser userWith(List<String> permissions) => AuthUser(
    id: 1,
    name: 'عبدالوهاب',
    phone: '0911234567',
    permissions: permissions,
  );

  setUp(() async {
    await Injector.reset();
    session = Session();
    sl.registerSingleton<Session>(session);
  });

  tearDown(Injector.reset);

  Widget host() => const MaterialApp(
    home: Scaffold(
      body: PermissionGate(
        permission: AppPermission.manageProducts,
        child: Text('منتج جديد'),
      ),
    ),
  );

  testWidgets('an empty session shows nothing, and does not throw', (tester) async {
    // Arrange
    await tester.pumpWidget(host());

    // Act
    await tester.pump();

    // Assert
    expect(find.text('منتج جديد'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('somebody without the permission does not see the control', (tester) async {
    // Arrange
    session.adopt(userWith(['products.view']));

    // Act
    await tester.pumpWidget(host());

    // Assert
    expect(find.text('منتج جديد'), findsNothing);
  });

  testWidgets('somebody with it does', (tester) async {
    // Arrange
    session.adopt(userWith(['products.view', 'products.manage']));

    // Act
    await tester.pumpWidget(host());

    // Assert
    expect(find.text('منتج جديد'), findsOneWidget);
  });

  testWidgets('the gate follows the session while it is on screen', (tester) async {
    // Arrange — this is the case a non-listening gate gets wrong: a pull-to-refresh or a
    // healed 403 re-reads `/auth/me` with the tree mounted and nothing navigating.
    await tester.pumpWidget(host());
    expect(find.text('منتج جديد'), findsNothing);

    // Act
    session.adopt(userWith(['products.manage']));
    await tester.pump();

    // Assert
    expect(find.text('منتج جديد'), findsOneWidget);

    // Act — and back again on sign-out.
    session.clear();
    await tester.pump();

    // Assert
    expect(find.text('منتج جديد'), findsNothing);
  });

  testWidgets('a fallback takes the space when one is given', (tester) async {
    // Arrange
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PermissionGate(
            permission: AppPermission.manageProducts,
            fallback: Text('لا تملك صلاحية'),
            child: Text('منتج جديد'),
          ),
        ),
      ),
    );

    // Act
    await tester.pump();

    // Assert
    expect(find.text('لا تملك صلاحية'), findsOneWidget);
    expect(find.text('منتج جديد'), findsNothing);
  });
}
