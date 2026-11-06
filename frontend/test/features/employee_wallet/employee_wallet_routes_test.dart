import 'dart:io';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// مسارات المحفظة: «محفظتي» بلا حارس لأن كل موظفٍ يقرأ محفظته، والبقية خلف `users.wallet.view` كما
/// على أبوابها — رابطٌ عميق لا يفتح شاشةً كلُّ طلبٍ فيها 403.
///
/// Arrange - Act - Assert throughout.
void main() {
  setUp(() async => Injector.reset());

  tearDown(Injector.reset);

  /// يسأل المسارَ نفسه أين يذهب صاحب [permissions] — بلا شاشةٍ تُبنى.
  Future<String?> redirectFor(
    WidgetTester tester,
    String path, {
    List<String> permissions = const [],
    Map<String, String> parameters = const {},
  }) async {
    sl.registerSingleton<Session>(
      Session()
        ..adopt(
          AuthUser(id: 1, name: 'عبدالوهاب', phone: '0911234567', permissions: permissions),
        ),
    );
    await tester.pumpWidget(const SizedBox());

    final location = Uri.parse(path);
    final configuration = AppRouter.instance.configuration;
    final route = configuration.findMatch(location).matches.last.route as GoRoute;

    if (route.redirect == null) return null;

    return route.redirect!(
      tester.element(find.byType(SizedBox)),
      GoRouterState(
        configuration,
        uri: location,
        matchedLocation: path,
        fullPath: route.path,
        pathParameters: parameters,
        pageKey: const ValueKey('wallet'),
      ),
    );
  }

  testWidgets('«محفظتي» تُفتح بلا صلاحية', (tester) async {
    // Arrange
    const permissions = <String>[];

    // Act
    final target = await redirectFor(tester, Routes.myWallet, permissions: permissions);

    // Assert
    expect(target, isNull);
  });

  testWidgets('محفظة موظف خلف صلاحيتها، لا خلف `users.view`', (tester) async {
    // Arrange
    const path = '/employees/4/wallet';

    // Act
    final target = await redirectFor(tester, path, permissions: const ['users.view']);

    // Assert
    expect(target, Routes.home);
  });

  testWidgets('من يملك رؤية المحافظ يصل إلى محفظة موظف', (tester) async {
    // Arrange
    final path = Routes.employeeWallet(4);

    // Act
    final target = await redirectFor(
      tester,
      path,
      permissions: const ['users.wallet.view'],
      parameters: const {'id': '4'},
    );

    // Assert
    expect(target, isNull);
  });

  testWidgets('«حركات محافظ الموظفين» خلف صلاحيتها', (tester) async {
    // Arrange
    const path = Routes.employeeWalletMovements;

    // Act
    final target = await redirectFor(tester, path);

    // Assert
    expect(target, Routes.home);
  });

  test('الإشعار يفتح مساراً يعرفه التطبيق', () {
    // Arrange — الخادم يكتب المسار في الإشعار، فتغييرُ أحدهما وحده زرٌّ لا يوصل إلى شيء.
    final source = File(
      '../backend/app/Domain/Notification/Definitions/EmployeeWalletMovedForYou.php',
    );

    if (!source.existsSync()) {
      markTestSkipped('backend not checked out beside this one — nothing to compare against');

      return;
    }

    // Act
    final route = RegExp("route: '([^']+)'").firstMatch(source.readAsStringSync())?.group(1);

    // Assert
    expect(route, Routes.myWallet);
  });
}
