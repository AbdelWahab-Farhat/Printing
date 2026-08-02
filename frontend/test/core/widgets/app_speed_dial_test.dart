import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/permissions/app_permission.dart';
import 'package:printing/core/session/session.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/widgets/app_speed_dial.dart';
import 'package:printing/features/auth/models/auth_user.dart';

/// The app's floating button, and the three shapes it takes.
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

  AppAction action(String label, {AppPermission? permission, VoidCallback? onTap}) => AppAction(
    label: label,
    icon: AppIcons.edit,
    permission: permission,
    onTap: (_) => onTap?.call(),
  );

  /// A real phone, not the 800×600 the test binding defaults to.
  ///
  /// The clipping this file guards against only happens when the screen is narrow enough for a
  /// label to reach the far edge — at 800 wide every assertion below passes against nothing.
  void useAPhone(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(430 * 3, 932 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  Widget host(List<AppAction> actions) => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => MaterialApp(
      home: Directionality(
        // Arabic, like every screen in this app — which is the direction the dial gets wrong
        // if it is left to its own devices.
        textDirection: TextDirection.rtl,
        child: Scaffold(
          floatingActionButtonLocation: AppSpeedDial.location,
          floatingActionButton: AppSpeedDial(actions: actions),
        ),
      ),
    ),
  );

  testWidgets('nothing survives the permission filter, so nothing is rendered', (tester) async {
    // Arrange — a staff account with only the read permission.
    useAPhone(tester);
    session.adopt(userWith(['customers.view']));

    // Act
    await tester.pumpWidget(host([action('تعديل', permission: AppPermission.manageCustomers)]));

    // Assert — an empty dial is furniture.
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('one surviving action is a plain button, not a dial to open', (tester) async {
    // Arrange — this really happens: the same screen shows three actions to an admin and one
    // to somebody who may only read.
    session.adopt(userWith(['customers.view']));

    // Act
    await tester.pumpWidget(
      host([
        action('تعديل', permission: AppPermission.manageCustomers),
        action('التصاميم', permission: AppPermission.viewCustomers),
      ]),
    );

    // Assert — the label is on the button itself, with nothing to expand.
    expect(find.text('التصاميم'), findsOneWidget);
    expect(find.text('تعديل'), findsNothing);
  });

  testWidgets('several actions open as a dial, with every label on screen', (tester) async {
    // Arrange — the bug this widget exists to prevent: the package lays its rows out from the
    // start edge, which in Arabic is the far side from the button, and the labels walk off.
    useAPhone(tester);
    session.adopt(userWith(['customers.view', 'customers.manage']));
    await tester.pumpWidget(
      host([
        action('تعديل العميل', permission: AppPermission.manageCustomers),
        action('تعطيل العميل', permission: AppPermission.manageCustomers),
        action('التصاميم', permission: AppPermission.viewCustomers),
      ]),
    );

    // Act
    await tester.tap(find.byType(FloatingActionButton).last);
    await tester.pumpAndSettle();

    // Assert
    final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;

    for (final label in const ['تعديل العميل', 'تعطيل العميل', 'التصاميم']) {
      final rect = tester.getRect(find.text(label));
      expect(rect.left, greaterThanOrEqualTo(0), reason: '«$label» runs off the left edge');
      expect(rect.right, lessThanOrEqualTo(width), reason: '«$label» runs off the right edge');
    }
  });

  testWidgets('tapping an action runs it', (tester) async {
    // Arrange
    session.adopt(userWith(['customers.view']));
    var taps = 0;

    await tester.pumpWidget(
      host([action('التصاميم', permission: AppPermission.viewCustomers, onTap: () => taps++)]),
    );

    // Act
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Assert
    expect(taps, 1);
  });

  testWidgets('an action with no permission is shown to everybody', (tester) async {
    // Arrange — an account holding nothing at all.
    session.adopt(userWith([]));

    // Act
    await tester.pumpWidget(host([action('رجوع')]));

    // Assert
    expect(find.text('رجوع'), findsOneWidget);
  });

  testWidgets('the dial follows the session while it is on screen', (tester) async {
    // Arrange — a pull-to-refresh elsewhere can withdraw a permission with this mounted, and an
    // action left behind would offer work that ends in a 403.
    session.adopt(userWith(['customers.view']));
    await tester.pumpWidget(
      host([
        action('تعديل', permission: AppPermission.manageCustomers),
        action('التصاميم', permission: AppPermission.viewCustomers),
      ]),
    );
    expect(find.text('تعديل'), findsNothing);

    // Act
    session.adopt(userWith(['customers.view', 'customers.manage']));
    await tester.pumpAndSettle();

    // Assert — two actions now, so it is a dial rather than a single button.
    await tester.tap(find.byType(FloatingActionButton).last);
    await tester.pumpAndSettle();
    expect(find.text('تعديل'), findsOneWidget);
  });
}
