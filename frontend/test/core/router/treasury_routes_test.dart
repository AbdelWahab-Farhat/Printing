import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// «إعدادات المالية» خلف `treasury.manage` كبقية المسارات المحروسة — رابطٌ عميق أو زرٌّ قديم
/// لا يفتحها لمن لا يدير الخزينة، فيعود إلى «الحسابات والخزائن».
///
/// Arrange - Act - Assert throughout.
void main() {
  setUp(() async {
    await Injector.reset();
  });

  tearDown(Injector.reset);

  AuthUser userWith(List<String> permissions) => AuthUser(
    id: 1,
    name: 'عبدالوهاب',
    phone: '0911234567',
    permissions: permissions,
  );

  /// يسأل المسارَ نفسه أين يذهب صاحب [permissions] — بلا شاشةٍ تُبنى.
  Future<String?> redirectFor(WidgetTester tester, List<String> permissions) async {
    sl.registerSingleton<Session>(Session()..adopt(userWith(permissions)));
    await tester.pumpWidget(const SizedBox());

    final location = Uri.parse(Routes.treasurySettings);
    final configuration = AppRouter.instance.configuration;
    final route = configuration.findMatch(location).matches.last.route as GoRoute;

    return route.redirect!(
      tester.element(find.byType(SizedBox)),
      GoRouterState(
        configuration,
        uri: location,
        matchedLocation: Routes.treasurySettings,
        fullPath: Routes.treasurySettings,
        pathParameters: const {},
        pageKey: const ValueKey('treasury-settings'),
      ),
    );
  }

  testWidgets('somebody who does not manage the treasury is sent back to the accounts', (
    tester,
  ) async {
    // Arrange
    const reader = ['treasury.view'];

    // Act
    final target = await redirectFor(tester, reader);

    // Assert
    expect(target, Routes.treasury);
  });

  testWidgets('somebody who manages it goes through', (tester) async {
    // Arrange
    const manager = ['treasury.view', 'treasury.manage'];

    // Act
    final target = await redirectFor(tester, manager);

    // Assert
    expect(target, isNull);
  });
}
