import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/tickets/presentation/widgets/tickets_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// زرّ «التذاكر» في شريط التطبيق: تذاكر التصميم والعملاء والموظفين خلف أيقونةٍ واحدة.
///
/// كان يظهر بإحدى صلاحيتَي التصميم والدعم وحدهما. **منذ التذاكر الداخلية يظهر لكل موظف**:
/// تبويبُ «الموظفين» بلا صلاحية (INTERNAL-TICKETS-DESIGN §٦)، فلا صفحةَ خلفه تردّ صاحبها.
///
/// Arrange - Act - Assert throughout.
void main() {
  /// آخر مسارٍ دُفع، لأن ما يفعله الزرّ هو الذهاب إلى مكان.
  String? pushed;

  Future<void> arrange(List<AppPermission> grants) async {
    await Injector.reset();
    pushed = null;
    sl.registerSingleton<Session>(
      Session()..adopt(
        AuthUser(
          id: 1,
          name: 'عبدالوهاب',
          phone: '0911234567',
          permissions: [for (final grant in grants) grant.wire],
        ),
      ),
    );
  }

  tearDown(Injector.reset);

  Widget host() {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: SafeArea(child: TicketsButton())),
        ),
        GoRoute(
          path: Routes.tickets,
          builder: (context, state) {
            pushed = state.uri.path;

            return const Scaffold(body: SizedBox.shrink());
          },
        ),
      ],
    );

    return ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (context, _) => MaterialApp.router(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    );
  }

  testWidgets('an employee with no ticket grant at all still gets «التذاكر»', (tester) async {
    // Arrange — «الموظفين» needs no permission, so the page behind the button is never empty.
    await arrange([]);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.byTooltip('التذاكر'), findsOneWidget);
    expect(find.byIcon(AppIcons.comments), findsOneWidget);
  });

  testWidgets('it pushes the tickets screen', (tester) async {
    // Arrange
    await arrange([AppPermission.viewDesignTickets, AppPermission.viewSupportTickets]);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.byType(TicketsButton));
    await tester.pumpAndSettle();

    // Assert
    expect(pushed, Routes.tickets);
  });
}
